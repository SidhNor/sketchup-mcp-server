# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Production-safe replacement result keyed only by PatchLifecycle patch IDs.
    class StableDomainCdtReplacementResult
      EMPTY_MESH = { vertices: [], triangles: [] }.freeze

      attr_reader :status, :mesh, :topology, :quality, :stop_reason, :border_spans,
                  :affected_patch_ids, :replacement_patch_ids, :replacement_patches,
                  :replacement_batch_id, :state_digest, :policy_fingerprint

      def self.from_solver(solver_result:, batch_plan:, state: nil, timing: nil)
        new(solver_result: solver_result, batch_plan: batch_plan, state: state, timing: timing)
      end

      def initialize(solver_result:, batch_plan:, state: nil, timing: nil)
        @solver_result = symbolize_top_level(solver_result)
        @batch_plan = batch_plan
        @state = state
        @timing = timing
        @affected_patch_ids = batch_plan.affected_patch_ids
        @replacement_patch_ids = batch_plan.replacement_patch_ids
        @replacement_patches = batch_plan.replacement_patches
        @replacement_batch_id = replacement_batch_id_for(batch_plan)
        @state_digest = value_from(batch_plan.terrain_state_summary, :digest)
        @policy_fingerprint = value_from(solver_result, :policyFingerprint, nil)
        @mesh = normalized_mesh(@solver_result.fetch(:mesh, EMPTY_MESH))
        @topology = @solver_result.fetch(:topology, {})
        @quality = @solver_result.fetch(:residualQuality, {})
        @border_spans = Array(@solver_result.fetch(:borderSpans, []))
        @status = @solver_result.fetch(:status, 'failed')
        @stop_reason = @solver_result[:stopReason]
        validate!
      rescue KeyError, TypeError, ArgumentError
        fail_with('stable_domain_result_incomplete')
      end

      def accepted?
        status == 'accepted'
      end

      def to_h
        {
          status: status,
          affectedPatchIds: affected_patch_ids,
          replacementPatchIds: replacement_patch_ids,
          replacementBatchId: replacement_batch_id,
          mesh: mesh,
          topology: topology,
          quality: quality,
          stopReason: stop_reason
        }.compact
      end

      def timing
        return @timing.to_h if @timing.respond_to?(:to_h)

        @timing
      end

      private

      attr_reader :solver_result, :batch_plan, :state

      def validate!
        return fail_with(solver_result[:stopReason] || 'stable_domain_solve_failed') unless
          solver_result[:status] == 'accepted'

        failure_reason = acceptance_failure_reason
        return fail_with(failure_reason) if failure_reason

        self
      end

      def acceptance_failure_reason
        [
          ['production_mesh_missing', !solver_result.key?(:mesh)],
          ['stable_domain_result_incomplete', mesh.fetch(:vertices).empty? ||
            mesh.fetch(:triangles).empty?],
          ['topology_invalid', !topology.fetch(:passed, false)],
          ['duplicate_triangles', duplicate_triangles?],
          ['duplicate_boundary_edges', duplicate_boundary_edges?],
          ['stale_retained_faces', stale_retained_faces?],
          ['seam_z_mismatch', seam_z_mismatch?],
          ['bad_winding', bad_winding?],
          ['out_of_domain_geometry', !mesh_inside_replacement_domains?]
        ].find { |_reason, failed| failed }&.first
      end

      def fail_with(reason)
        @status = 'failed'
        @stop_reason = reason
        @mesh ||= EMPTY_MESH
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

      def symbolize_top_level(hash)
        hash.each_with_object({}) { |(key, value), memo| memo[key.to_sym] = value }
      end

      def replacement_batch_id_for(batch_plan)
        "cdt-batch-#{value_from(batch_plan.terrain_state_summary, :digest)}"
      end

      def value_from(hash, key, default = nil)
        hash.fetch(key) { hash.fetch(key.to_s, default) }
      end

      def duplicate_triangles?
        seen = {}
        mesh.fetch(:triangles).any? do |triangle|
          key = triangle.sort
          if seen.key?(key)
            true
          else
            seen[key] = true
            false
          end
        end
      end

      def bad_winding?
        mesh.fetch(:triangles).any? do |triangle|
          signed_area_for(triangle) <= 0.0
        end
      end

      def signed_area_for(triangle)
        points = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        points.each_with_index.sum do |point, index|
          successor = points.fetch((index + 1) % points.length)
          (point.fetch(0) * successor.fetch(1)) - (successor.fetch(0) * point.fetch(1))
        end / 2.0
      end

      def mesh_inside_replacement_domains?
        domains = replacement_patches.map { |patch| sample_domain_for(patch) }
        mesh.fetch(:vertices).all? do |vertex|
          domains.any? { |domain| vertex_inside_domain?(vertex, domain) }
        end
      end

      def sample_domain_for(patch)
        bounds = value_from(patch, :sampleBounds) || value_from(patch, :bounds)
        return owner_coordinate_domain_for(bounds) if state

        {
          min_x: value_from(bounds, :minColumn).to_f,
          min_y: value_from(bounds, :minRow).to_f,
          max_x: value_from(bounds, :maxColumn).to_f,
          max_y: value_from(bounds, :maxRow).to_f
        }
      end

      def owner_coordinate_domain_for(bounds)
        min_column = value_from(bounds, :minColumn).to_f
        min_row = value_from(bounds, :minRow).to_f
        max_column = value_from(bounds, :maxColumn).to_f
        max_row = value_from(bounds, :maxRow).to_f
        {
          min_x: owner_coordinate('x', min_column),
          min_y: owner_coordinate('y', min_row),
          max_x: owner_coordinate('x', max_column),
          max_y: owner_coordinate('y', max_row)
        }
      end

      def owner_coordinate(axis, index)
        state.origin.fetch(axis) + (index * state.spacing.fetch(axis))
      end

      def vertex_inside_domain?(vertex, domain)
        vertex.fetch(0).between?(domain.fetch(:min_x), domain.fetch(:max_x)) &&
          vertex.fetch(1).between?(domain.fetch(:min_y), domain.fetch(:max_y))
      end

      def duplicate_boundary_edges?
        seen = {}
        border_spans.any? do |span|
          Array(value_from(span, :vertices, [])).each_cons(2).any? do |first, second|
            key = [boundary_vertex_key(first), boundary_vertex_key(second)].sort
            if seen.key?(key)
              true
            else
              seen[key] = true
              false
            end
          end
        end
      end

      def boundary_vertex_key(vertex)
        [vertex.fetch(0).to_f, vertex.fetch(1).to_f, vertex.fetch(2).to_f]
      end

      def stale_retained_faces?
        batch_plan.retained_boundary_spans.any? do |span|
          !value_from(span, :fresh, false) || stable_patch_identity(span).nil?
        end
      end

      def stable_patch_identity(span)
        value_from(span, :patchId, nil)
      end

      def seam_z_mismatch?
        seam = solver_result[:seamValidation] || solver_result[:seam]
        return false unless seam.is_a?(Hash)

        reason = value_from(seam, :reason, nil).to_s
        return true if reason.include?('z_') || reason.include?('seam_z')

        value_from(seam, :zToleranceExceeded, false) == true
      end
    end
  end
end
