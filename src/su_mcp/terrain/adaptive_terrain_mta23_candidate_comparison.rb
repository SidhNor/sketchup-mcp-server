# frozen_string_literal: true

require_relative 'intent_aware_enhanced_adaptive_grid_prototype'
require_relative 'mta23_failure_capture_artifact'
require_relative 'terrain_feature_geometry_builder'

module SU_MCP
  module Terrain
    # MTA-23 fixture comparison harness for validation-only candidate rows.
    class AdaptiveTerrainMta23CandidateComparison
      PRODUCTION_FACE_COUNT_MULTIPLIER_GATE = 1.5
      HOSTED_MAX_NORMAL_BREAK_DEG_PRODUCTION_GATE = 30.0

      def initialize(
        builder: TerrainFeatureGeometryBuilder.new,
        prototype: IntentAwareEnhancedAdaptiveGridPrototype.new
      )
        @builder = builder
        @prototype = prototype
      end

      def compare(pack:, case_ids: nil)
        selected_ids = case_ids || pack.cases.map { |fixture_case| fixture_case.fetch('id') }
        rows = selected_ids.map { |case_id| candidate_row_for(pack, pack.case(case_id)) }
        { candidateRows: rows }
      end

      def recommendation_for(rows:, hosted_evidence:)
        categories = rows.map { |row| row.fetch(:failureCategory) }
        save_reopen_gap = hosted_evidence.fetch(:saveReopenStatus, nil) == 'skipped'
        if categories.include?('comparison_not_applicable') ||
           categories.include?('candidate_generation_failed')
          return recommendation('stop_or_replan', categories, save_reopen_gap)
        end

        if categories.include?('feature_geometry_failed')
          return recommendation('fix_feature_geometry_first', categories, save_reopen_gap)
        end
        if productionizable?(rows, hosted_evidence)
          return recommendation('productionize_adaptive_candidate_later', categories, false)
        end

        recommendation('pursue_constrained_delaunay_or_cdt_follow_up', categories, save_reopen_gap)
      end

      private

      attr_reader :builder, :prototype

      def candidate_row_for(pack, fixture_case)
        unless fixture_case.fetch('replayableLocally')
          return comparison_not_applicable_row(pack.baseline_result(fixture_case.fetch('id')))
        end

        replay = pack.replay_case(fixture_case)
        state = replay.fetch(:state)
        feature_geometry = builder.build(state: state)
        candidate = prototype.run(
          state: state,
          feature_geometry: feature_geometry,
          base_tolerance: 0.05,
          max_cell_budget: 512,
          max_face_budget: dense_equivalent_face_count(fixture_case),
          max_runtime_budget: 5.0
        )
        baseline = pack.baseline_result(fixture_case.fetch('id'))
        candidate.merge(
          caseId: fixture_case.fetch('id'),
          baselineMetrics: baseline.fetch('metrics')
        )
      end

      def comparison_not_applicable_row(baseline)
        {
          caseId: baseline.fetch('caseId'),
          resultSchemaVersion: 1,
          backend: IntentAwareEnhancedAdaptiveGridPrototype::BACKEND,
          evidenceMode: 'provenance_capture',
          metrics: baseline.fetch('metrics'),
          budgetStatus: 'ok',
          failureCategory: 'comparison_not_applicable',
          featureGeometryDigest: nil,
          referenceGeometryDigest: nil,
          knownResiduals: baseline.fetch('knownResiduals', []),
          limitations: [
            'Fixture is not locally replayable; candidate comparison not locally applicable.'
          ],
          provenance: baseline.fetch('provenance')
        }
      end

      def productionizable?(rows, hosted_evidence)
        return false if hosted_evidence.fetch(:saveReopenStatus, nil) == 'skipped'

        rows.all? do |row|
          metrics = row.fetch(:metrics)
          topology = metrics.fetch(:topologyChecks)
          baseline = row.fetch(:baselineMetrics, {})
          row.fetch(:failureCategory) == 'none' &&
            row.fetch(:budgetStatus) == 'ok' &&
            metrics.fetch(:hardViolationCounts, {}).empty? &&
            topology.fetch(:downFaceCount).zero? &&
            topology.fetch(:nonManifoldEdgeCount).zero? &&
            topology.fetch(:maxNormalBreakDeg) <= HOSTED_MAX_NORMAL_BREAK_DEG_PRODUCTION_GATE &&
            within_face_gate?(metrics, baseline)
        end
      end

      def within_face_gate?(metrics, baseline)
        return true unless baseline.key?(:faceCount)

        metrics.fetch(:faceCount) <=
          baseline.fetch(:faceCount) * PRODUCTION_FACE_COUNT_MULTIPLIER_GATE
      end

      def recommendation(name, evidence, save_reopen_gap)
        gaps = []
        gaps << 'save/reopen validation gap' if save_reopen_gap
        adjusted = if name == 'productionize_adaptive_candidate_later' && save_reopen_gap
                     'pursue_constrained_delaunay_or_cdt_follow_up'
                   else
                     name
                   end
        {
          recommendation: adjusted,
          evidence: evidence.join(', '),
          validationGaps: gaps
        }
      end

      def dense_equivalent_face_count(fixture_case)
        dimensions = fixture_case.fetch('terrain').fetch('dimensions')
        (dimensions.fetch('columns') - 1) * (dimensions.fetch('rows') - 1) * 2
      end
    end
  end
end
