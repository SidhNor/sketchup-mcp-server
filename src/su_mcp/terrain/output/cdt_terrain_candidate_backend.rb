# frozen_string_literal: true

require_relative 'cdt_triangulator'
require_relative 'residual_cdt_engine'

module SU_MCP
  module Terrain
    # MTA-24 comparison-only CDT candidate row wrapper over the production residual engine.
    class CdtTerrainCandidateBackend
      BACKEND = 'mta24_constrained_delaunay_cdt_prototype'
      RESULT_SCHEMA_VERSION = 1
      TRIANGULATOR_KIND = 'ruby_bowyer_watson_constraint_recovery'
      RESIDUAL_REFINEMENT_POINT_RATIO = 1.0
      RESIDUAL_REFINEMENT_BATCH_SIZE = 128
      RESIDUAL_REFINEMENT_MAX_PASSES = 24

      def initialize(
        point_planner: CdtTerrainPointPlanner.new,
        height_error_meter: CdtHeightErrorMeter.new,
        triangulator: CdtTriangulator.new,
        residual_refinement_point_ratio: RESIDUAL_REFINEMENT_POINT_RATIO,
        residual_refinement_max_passes: RESIDUAL_REFINEMENT_MAX_PASSES,
        residual_refinement_batch_size: RESIDUAL_REFINEMENT_BATCH_SIZE,
        residual_engine: nil
      )
        @residual_refinement_point_ratio = normalized_residual_refinement_point_ratio(
          residual_refinement_point_ratio
        )
        @residual_refinement_max_passes = normalized_residual_refinement_max_passes(
          residual_refinement_max_passes
        )
        @residual_refinement_batch_size = normalized_residual_refinement_batch_size(
          residual_refinement_batch_size
        )
        @residual_engine = residual_engine || ResidualCdtEngine.new(
          point_planner: point_planner,
          height_error_meter: height_error_meter,
          triangulator: triangulator,
          residual_refinement_point_ratio: @residual_refinement_point_ratio,
          residual_refinement_max_passes: @residual_refinement_max_passes,
          residual_refinement_batch_size: @residual_refinement_batch_size
        )
      end

      def run(state:, feature_geometry:, base_tolerance:, max_point_budget:,
              max_face_budget:, max_runtime_budget:)
        engine_result = residual_engine.run(
          state: state,
          feature_geometry: feature_geometry,
          base_tolerance: base_tolerance,
          max_point_budget: max_point_budget,
          max_face_budget: max_face_budget,
          max_runtime_budget: max_runtime_budget
        )
        result_row(engine_result)
      rescue StandardError => e
        candidate_error(e)
      end

      private

      attr_reader :residual_engine, :residual_refinement_point_ratio,
                  :residual_refinement_max_passes, :residual_refinement_batch_size

      def result_row(engine_result)
        {
          resultSchemaVersion: RESULT_SCHEMA_VERSION,
          backend: BACKEND,
          evidenceMode: 'local_backend_capture',
          mesh: engine_result.fetch(:mesh),
          metrics: engine_result.fetch(:metrics),
          budgetStatus: engine_result.fetch(:budgetStatus),
          failureCategory: engine_result.fetch(:failureCategory),
          featureGeometryDigest: engine_result.fetch(:featureGeometryDigest),
          referenceGeometryDigest: engine_result.fetch(:referenceGeometryDigest),
          stateDigest: engine_result.fetch(:stateDigest),
          selectedPointCount: engine_result.fetch(:selectedPointCount),
          denseSourcePointCount: engine_result.fetch(:denseSourcePointCount),
          sourceDimensions: engine_result.fetch(:sourceDimensions),
          constraintCount: engine_result.fetch(:constraintCount),
          constraintSourceSummary: engine_result.fetch(:constraintSourceSummary),
          constrainedEdgeCoverage: engine_result.fetch(:constrainedEdgeCoverage),
          constrainedEdges: engine_result.fetch(:constrainedEdges),
          delaunayViolationCount: engine_result.fetch(:delaunayViolationCount),
          triangulatorKind: TRIANGULATOR_KIND,
          triangulatorVersion: CdtTriangulator::VERSION,
          knownResiduals: [],
          limitations: engine_result.fetch(:limitations),
          provenance: { source: 'MTA-24 comparison-only prototype' }
        }
      end

      def candidate_error(error)
        {
          resultSchemaVersion: RESULT_SCHEMA_VERSION,
          backend: BACKEND,
          evidenceMode: 'local_backend_capture',
          mesh: { vertices: [], triangles: [] },
          metrics: {},
          budgetStatus: 'ok',
          failureCategory: 'candidate_generation_failed',
          knownResiduals: [],
          limitations: [{ reason: error.message }],
          provenance: { source: 'MTA-24 comparison-only prototype' }
        }
      end

      def normalized_residual_refinement_point_ratio(value)
        Float(value).clamp(0.35, 1.0)
      rescue ArgumentError, TypeError
        RESIDUAL_REFINEMENT_POINT_RATIO
      end

      def normalized_residual_refinement_max_passes(value)
        Integer(value).clamp(0, 48)
      rescue ArgumentError, TypeError
        RESIDUAL_REFINEMENT_MAX_PASSES
      end

      def normalized_residual_refinement_batch_size(value)
        Integer(value).clamp(1, 256)
      rescue ArgumentError, TypeError
        RESIDUAL_REFINEMENT_BATCH_SIZE
      end
    end
  end
end
