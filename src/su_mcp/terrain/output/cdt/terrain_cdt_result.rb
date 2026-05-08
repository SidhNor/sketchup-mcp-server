# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Internal CDT result envelope. This stays below public terrain responses.
    class TerrainCdtResult
      FALLBACK_REASONS = %w[
        cdt_disabled feature_geometry_failed native_unavailable native_input_violation
        input_normalization_failed unsupported_constraint_shape intersecting_constraints
        pre_triangulate_budget_exceeded point_budget_exceeded face_budget_exceeded
        runtime_budget_exceeded residual_gate_failed constraint_recovery_failed
        hard_geometry_gate_failed topology_gate_failed invalid_mesh adapter_exception
      ].freeze

      INTERNAL_DETAIL_KEYS = %i[
        errorClass exceptionClass exceptionMessage backtrace stack trace solverPredicates
        rawTriangles expandedConstraints triangulatorKind triangulatorVersion backend provenance
      ].freeze

      def self.accepted(mesh:, metrics:, limits:, limitations:, feature_geometry_digest: nil,
                        reference_geometry_digest: nil, state_digest: nil, timing: {})
        base_envelope(
          status: 'accepted',
          metrics: metrics,
          limits: limits,
          limitations: limitations,
          feature_geometry_digest: feature_geometry_digest,
          reference_geometry_digest: reference_geometry_digest,
          state_digest: state_digest,
          timing: timing
        ).merge(mesh: mesh)
      end

      def self.fallback(reason:, metrics:, limits:, limitations:,
                        feature_geometry_digest: nil, reference_geometry_digest: nil,
                        state_digest: nil, timing: {}, details: {})
        fallback_reason = reason.to_s
        unless FALLBACK_REASONS.include?(fallback_reason)
          raise ArgumentError, "unsupported CDT fallback reason #{fallback_reason.inspect}"
        end

        base_envelope(
          status: 'fallback',
          metrics: metrics,
          limits: limits,
          limitations: limitations,
          feature_geometry_digest: feature_geometry_digest,
          reference_geometry_digest: reference_geometry_digest,
          state_digest: state_digest,
          timing: timing
        ).merge(
          fallbackReason: fallback_reason,
          fallbackDetails: sanitize_details(details)
        )
      end

      def self.base_envelope(status:, metrics:, limits:, limitations:, feature_geometry_digest:,
                             reference_geometry_digest:, state_digest:, timing:)
        {
          status: status,
          metrics: sanitize_value(metrics || {}),
          limits: limits || {},
          limitations: sanitized_limitations(limitations || []),
          featureGeometryDigest: feature_geometry_digest,
          referenceGeometryDigest: reference_geometry_digest,
          stateDigest: state_digest,
          timing: timing || {}
        }.compact
      end
      private_class_method :base_envelope

      def self.sanitized_limitations(limitations)
        Array(limitations).map { |item| sanitize_value(item) }
      end
      private_class_method :sanitized_limitations

      def self.sanitize_details(details)
        sanitize_value(details)
      end
      private_class_method :sanitize_details

      def self.sanitize_value(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), memo|
            next if INTERNAL_DETAIL_KEYS.include?(key.to_sym)

            memo[key] = sanitize_value(nested)
          end
        when Array
          value.map { |nested| sanitize_value(nested) }
        else
          value
        end
      end
      private_class_method :sanitize_value
    end
  end
end
