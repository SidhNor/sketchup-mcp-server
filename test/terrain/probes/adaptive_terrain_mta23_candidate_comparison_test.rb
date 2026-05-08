# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/adaptive_terrain_regression_fixtures'
require_relative '../../../src/su_mcp/terrain/probes/adaptive_terrain_mta23_candidate_comparison'

class AdaptiveTerrainMta23CandidateComparisonTest < Minitest::Test
  def test_replayable_fixture_rows_compare_candidate_against_baseline_without_mutating_baselines
    pack = AdaptiveTerrainRegressionFixtures.load
    before = JSON.generate(pack.baseline_results)

    result = comparison.compare(pack: pack, case_ids: ['created_flat_corridor_mta21'])
    row = result.fetch(:candidateRows).first

    assert_equal('created_flat_corridor_mta21', row.fetch(:caseId))
    assert_equal(1, row.fetch(:resultSchemaVersion))
    assert_equal('mta23_intent_aware_adaptive_grid_prototype', row.fetch(:backend))
    assert_includes(row.keys, :featureGeometryDigest)
    assert_includes(row.keys, :referenceGeometryDigest)
    assert_equal(before, JSON.generate(pack.baseline_results))
  end

  def test_non_replayable_provenance_only_rows_are_comparison_not_applicable_with_limitations
    pack = AdaptiveTerrainRegressionFixtures.load

    result = comparison.compare(pack: pack, case_ids: ['adopted_irregular_off_grid_corridor_mta21'])
    row = result.fetch(:candidateRows).first

    assert_equal('comparison_not_applicable', row.fetch(:failureCategory))
    assert_includes(JSON.generate(row.fetch(:limitations)), 'not locally replayable')
  end

  def test_failure_categories_and_final_recommendation_paths_are_distinguishable
    result = comparison.recommendation_for(rows: [
                                             row('feature_geometry_failed'),
                                             row('candidate_generation_failed'),
                                             row('hard_output_geometry_violation'),
                                             row('topology_invalid'),
                                             row('performance_limit_exceeded'),
                                             row('firm_feature_residual_high'),
                                             row('comparison_not_applicable')
                                           ], hosted_evidence: { saveReopenStatus: 'skipped' })

    assert_equal('stop_or_replan', result.fetch(:recommendation))
    assert_includes(result.fetch(:evidence), 'comparison_not_applicable')
  end

  def test_production_recommendation_is_downgraded_when_save_reopen_is_skipped
    result = comparison.recommendation_for(rows: [productionizable_row],
                                           hosted_evidence: { saveReopenStatus: 'skipped' })

    assert_equal('pursue_constrained_delaunay_or_cdt_follow_up', result.fetch(:recommendation))
    assert_includes(result.fetch(:validationGaps), 'save/reopen validation gap')
  end

  private

  def comparison
    @comparison ||= SU_MCP::Terrain::AdaptiveTerrainMta23CandidateComparison.new
  end

  def row(category)
    { failureCategory: category, metrics: { faceCount: 10, topologyChecks: {} },
      budgetStatus: 'ok', limitations: [] }
  end

  def productionizable_row
    {
      failureCategory: 'none',
      budgetStatus: 'ok',
      metrics: {
        faceCount: 10,
        denseRatio: 0.25,
        topologyChecks: { downFaceCount: 0, nonManifoldEdgeCount: 0, maxNormalBreakDeg: 10.0 },
        hardViolationCounts: {},
        firmResidualsByRole: {}
      },
      baselineMetrics: { faceCount: 20, denseRatio: 0.5 },
      limitations: []
    }
  end
end
