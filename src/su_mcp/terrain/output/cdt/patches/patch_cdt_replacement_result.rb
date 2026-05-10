# frozen_string_literal: true

require 'digest'
require 'json'

module SU_MCP
  module Terrain
    # Production-safe handoff from patch CDT proof evidence to local output mutation.
    class PatchCdtReplacementResult
      EMPTY_MESH = { vertices: [], triangles: [] }.freeze
      SIDES = %w[south east north west].freeze
      DEFAULT_TIMING = {
        commandPreparationSeconds: 0.0,
        mta33SelectionSeconds: 0.0,
        mta32PatchSolveSeconds: 0.0,
        replacementAdaptationSeconds: 0.0,
        ownershipSnapshotSeconds: 0.0,
        seamValidationSeconds: 0.0,
        mutationSeconds: 0.0,
        auditSeconds: 0.0
      }.freeze

      attr_reader :status, :patch_domain, :patch_domain_digest, :mesh, :border_spans,
                  :topology, :quality, :feature_digest, :stop_reason, :evidence,
                  :replacement_batch_id, :timing

      def self.from_proof(proof_result:, feature_geometry:, replacement_batch_id: nil,
                          timing: {})
        new(
          proof_result: proof_result,
          feature_geometry: feature_geometry,
          replacement_batch_id: replacement_batch_id,
          timing: timing
        )
      end

      def initialize(proof_result:, feature_geometry:, replacement_batch_id:, timing:)
        @proof_result = symbolize_top_level(proof_result)
        @feature_geometry = feature_geometry
        @patch_domain = @proof_result[:patchDomain] || {}
        @patch_domain_digest = digest_for(@patch_domain)
        @replacement_batch_id = replacement_batch_id || "patch-#{@patch_domain_digest[0, 12]}"
        @timing = DEFAULT_TIMING.merge(timing)
        @topology = @proof_result[:topology] || {}
        @quality = @proof_result[:residualQuality] || {}
        @feature_digest = feature_digest_for(feature_geometry)
        @mesh = normalized_mesh(@proof_result[:mesh] || @proof_result[:debugMesh] || EMPTY_MESH)
        @border_spans = []
        @status = 'accepted'
        @stop_reason = nil
        validate!
        @evidence = evidence_hash
      rescue KeyError, TypeError, ArgumentError
        fail_with('patch_result_incomplete')
      end

      def accepted?
        status == 'accepted'
      end

      def to_h
        {
          status: status,
          patchDomain: patch_domain,
          patchDomainDigest: patch_domain_digest,
          replacementBatchId: replacement_batch_id,
          mesh: mesh,
          border: { spans: border_spans },
          topology: topology,
          quality: quality,
          featureDigest: feature_digest,
          stopReason: stop_reason,
          evidence: evidence,
          timing: timing
        }
      end

      private

      attr_reader :proof_result, :feature_geometry

      def validate!
        return fail_with(proof_result[:stopReason] || 'patch_result_incomplete') unless
          proof_result[:status] == 'accepted'

        return fail_with('patch_result_incomplete') if mesh.fetch(:vertices).empty? ||
                                                       mesh.fetch(:triangles).empty?
        return fail_with('topology_invalid') unless topology.fetch(:passed, false)
        return fail_with('topology_invalid') unless vertices_in_domain?
        return fail_with('patch_result_incomplete') if duplicate_triangles?

        @border_spans = build_border_spans
        return fail_with('patch_result_incomplete') unless complete_border_spans?

        self
      end

      def fail_with(reason)
        @status = 'failed'
        @stop_reason = reason
        @mesh ||= EMPTY_MESH
        @border_spans ||= []
        @evidence = evidence_hash
        self
      end

      def normalized_mesh(raw_mesh)
        {
          vertices: Array(raw_mesh.fetch(:vertices) { raw_mesh.fetch('vertices') }).map do |vertex|
            Array(vertex).map(&:to_f)
          end,
          triangles: Array(raw_mesh.fetch(:triangles) { raw_mesh.fetch('triangles') }).map do |tri|
            Array(tri).map { |index| Integer(index) }
          end
        }
      end

      def vertices_in_domain?
        bounds = patch_domain.fetch(:ownerLocalBounds) do
          patch_domain.fetch('ownerLocalBounds')
        end
        mesh.fetch(:vertices).all? do |vertex|
          vertex[0].between?(bounds.fetch(:minX) { bounds.fetch('minX') },
                             bounds.fetch(:maxX) { bounds.fetch('maxX') }) &&
            vertex[1].between?(bounds.fetch(:minY) { bounds.fetch('minY') },
                               bounds.fetch(:maxY) { bounds.fetch('maxY') })
        end
      end

      def duplicate_triangles?
        keys = mesh.fetch(:triangles).map(&:sort)
        keys.uniq.length != keys.length
      end

      def build_border_spans
        bounds = patch_domain.fetch(:ownerLocalBounds) do
          patch_domain.fetch('ownerLocalBounds')
        end
        sides = {
          'south' => [:y, bounds.fetch(:minY) { bounds.fetch('minY') }],
          'east' => [:x, bounds.fetch(:maxX) { bounds.fetch('maxX') }],
          'north' => [:y, bounds.fetch(:maxY) { bounds.fetch('maxY') }],
          'west' => [:x, bounds.fetch(:minX) { bounds.fetch('minX') }]
        }
        sides.map do |side, (axis, value)|
          vertices = border_vertices(axis, value)
          {
            side: side,
            spanId: "#{side}-0",
            patchDomainDigest: patch_domain_digest,
            fresh: true,
            protectedBoundaryCrossing: false,
            vertices: ordered_border_vertices(side, vertices)
          }
        end
      end

      def border_vertices(axis, value)
        coordinate = axis == :x ? 0 : 1
        mesh.fetch(:vertices).select { |vertex| (vertex[coordinate] - value).abs <= 1e-6 }
      end

      def ordered_border_vertices(side, vertices)
        case side
        when 'east', 'west'
          vertices.sort_by { |vertex| [vertex[1], vertex[0]] }
        else
          vertices.sort_by { |vertex| [vertex[0], vertex[1]] }
        end
      end

      def complete_border_spans?
        border_spans.all? { |span| span.fetch(:vertices).length >= 2 }
      end

      def evidence_hash
        {
          replacementStatus: status,
          faceCount: mesh.fetch(:triangles, []).length,
          vertexCount: mesh.fetch(:vertices, []).length,
          borderSpanCountsBySide: border_spans.to_h do |span|
            [span.fetch(:side), span.fetch(:vertices).length]
          end
        }
      end

      def digest_for(value)
        Digest::SHA256.hexdigest(JSON.generate(value))
      end

      def feature_digest_for(feature_geometry)
        return nil unless feature_geometry.respond_to?(:feature_geometry_digest)

        feature_geometry.feature_geometry_digest
      end

      def symbolize_top_level(hash)
        hash.each_with_object({}) { |(key, value), memo| memo[key.to_sym] = value }
      end
    end
  end
end
