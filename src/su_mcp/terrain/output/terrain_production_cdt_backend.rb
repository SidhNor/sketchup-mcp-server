# frozen_string_literal: true

require_relative 'residual_cdt_engine'
require_relative 'terrain_production_cdt_result'

module SU_MCP
  module Terrain
    # Translates residual CDT engine output into production accepted/fallback envelopes.
    class TerrainProductionCdtBackend
      DEFAULT_POINT_BUDGET = 4096
      DEFAULT_FACE_BUDGET = 8192
      DEFAULT_RUNTIME_BUDGET = 10.0
      DEFAULT_BASE_TOLERANCE = 0.05
      DEFAULT_MAX_RESIDUAL_ERROR = 0.05
      DEFAULT_STRICT_QUALITY_GATES = false

      BUDGET_FALLBACKS = {
        'max_point_budget_exceeded' => 'point_budget_exceeded',
        'max_face_budget_exceeded' => 'face_budget_exceeded'
      }.freeze

      STRICT_BUDGET_FALLBACKS = BUDGET_FALLBACKS.merge(
        'max_runtime_budget_exceeded' => 'runtime_budget_exceeded'
      ).freeze

      FAILURE_FALLBACKS = {
        'feature_geometry_failed' => 'feature_geometry_failed',
        'topology_invalid' => 'topology_gate_failed',
        'topology_degraded' => 'topology_gate_failed',
        'hard_output_geometry_violation' => 'hard_geometry_gate_failed',
        'candidate_generation_failed' => 'adapter_exception'
      }.freeze

      STRICT_FAILURE_FALLBACKS = FAILURE_FALLBACKS.merge(
        'firm_feature_residual_high' => 'constraint_recovery_failed'
      ).freeze

      def initialize(
        enabled: true,
        residual_engine: ResidualCdtEngine.new,
        point_budget: DEFAULT_POINT_BUDGET,
        face_budget: DEFAULT_FACE_BUDGET,
        runtime_budget: DEFAULT_RUNTIME_BUDGET,
        base_tolerance: DEFAULT_BASE_TOLERANCE,
        max_residual_error: DEFAULT_MAX_RESIDUAL_ERROR,
        strict_quality_gates: DEFAULT_STRICT_QUALITY_GATES
      )
        @enabled = enabled
        @residual_engine = residual_engine
        @point_budget = point_budget
        @face_budget = face_budget
        @runtime_budget = runtime_budget
        @base_tolerance = base_tolerance
        @max_residual_error = max_residual_error
        @strict_quality_gates = strict_quality_gates
      end

      def build(state:, feature_geometry:, state_digest: nil, feature_geometry_digest: nil,
                reference_geometry_digest: nil, feature_geometry_failed: false, **)
        context = digest_context(
          state_digest: state_digest,
          feature_geometry_digest: feature_geometry_digest,
          reference_geometry_digest: reference_geometry_digest
        )
        return fallback('cdt_disabled', empty_engine_result(context)) unless enabled
        if feature_geometry_failed || feature_geometry_failed?(feature_geometry)
          return fallback('feature_geometry_failed', empty_engine_result(context))
        end

        engine_result = residual_engine.run(
          state: state,
          feature_geometry: feature_geometry,
          base_tolerance: base_tolerance,
          max_point_budget: point_budget,
          max_face_budget: face_budget,
          max_runtime_budget: runtime_budget
        )
        engine_result = engine_result.merge(context.compact)
        reason = fallback_reason(engine_result)
        return fallback(reason, engine_result) if reason

        accepted(engine_result)
      rescue ArgumentError, KeyError, TypeError
        fallback('input_normalization_failed', empty_engine_result(context || {}))
      rescue StandardError
        fallback('adapter_exception', empty_engine_result(context || {}))
      end

      private

      attr_reader :enabled, :residual_engine, :point_budget, :face_budget, :runtime_budget,
                  :base_tolerance, :max_residual_error, :strict_quality_gates

      def digest_context(state_digest:, feature_geometry_digest:, reference_geometry_digest:)
        {
          stateDigest: state_digest,
          featureGeometryDigest: feature_geometry_digest,
          referenceGeometryDigest: reference_geometry_digest
        }
      end

      def feature_geometry_failed?(feature_geometry)
        feature_geometry.respond_to?(:failure_category) &&
          feature_geometry.failure_category == 'feature_geometry_failed'
      end

      def fallback_reason(engine_result)
        budget_reason = budget_fallbacks[engine_result.fetch(:budgetStatus, 'ok')]
        return budget_reason if budget_reason
        if strict_quality_gates && residual_gate_failed?(engine_result)
          return 'residual_gate_failed'
        end
        return 'topology_gate_failed' unless topology_valid?(engine_result)

        failure_fallbacks[engine_result.fetch(:failureCategory, 'none')]
      end

      def budget_fallbacks
        strict_quality_gates ? STRICT_BUDGET_FALLBACKS : BUDGET_FALLBACKS
      end

      def failure_fallbacks
        strict_quality_gates ? STRICT_FAILURE_FALLBACKS : FAILURE_FALLBACKS
      end

      def residual_gate_failed?(engine_result)
        engine_result.dig(:metrics, :maxHeightError).to_f > max_residual_error
      end

      def topology_valid?(engine_result)
        topology = engine_result.dig(:metrics, :topologyChecks) || {}
        topology.fetch(:downFaceCount, 0).zero? &&
          topology.fetch(:nonManifoldEdgeCount, 0).zero? &&
          topology.fetch(:invalidFaceCount, 0).zero?
      end

      def accepted(engine_result)
        TerrainProductionCdtResult.accepted(
          mesh: engine_result.fetch(:mesh),
          metrics: engine_result.fetch(:metrics, {}),
          limits: limits_for(engine_result),
          limitations: engine_result.fetch(:limitations, []),
          feature_geometry_digest: engine_result.fetch(:featureGeometryDigest, nil),
          reference_geometry_digest: engine_result.fetch(:referenceGeometryDigest, nil),
          state_digest: engine_result.fetch(:stateDigest, nil),
          timing: timing_for(engine_result)
        )
      end

      def fallback(reason, engine_result)
        TerrainProductionCdtResult.fallback(
          reason: reason,
          metrics: engine_result.fetch(:metrics, {}),
          limits: limits_for(engine_result),
          limitations: engine_result.fetch(:limitations, []),
          feature_geometry_digest: engine_result.fetch(:featureGeometryDigest, nil),
          reference_geometry_digest: engine_result.fetch(:referenceGeometryDigest, nil),
          state_digest: engine_result.fetch(:stateDigest, nil),
          timing: timing_for(engine_result),
          details: { category: engine_result.fetch(:failureCategory, reason) }
        )
      end

      def limits_for(engine_result)
        engine_result.fetch(
          :limits,
          { pointBudget: point_budget, faceBudget: face_budget, runtimeBudget: runtime_budget }
        )
      end

      def timing_for(engine_result)
        engine_result.fetch(:timing, engine_result.dig(:metrics, :timing) || {})
      end

      def empty_engine_result(context)
        {
          metrics: {},
          limits: { pointBudget: point_budget, faceBudget: face_budget,
                    runtimeBudget: runtime_budget },
          limitations: [],
          timing: {}
        }.merge(context)
      end
    end
  end
end
