# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/adaptive_terrain_regression_fixtures'
require_relative '../../../src/su_mcp/terrain/probes/mta24_three_way_terrain_comparison'

class Mta24ThreeWayTerrainComparisonTest < Minitest::Test
  def test_replayable_fixture_emits_current_adaptive_and_cdt_rows_from_same_state
    result = comparison.compare(pack: pack, case_ids: ['created_flat_corridor_mta21'])
    rows = result.fetch(:comparisonRows)

    assert_three_backend_rows(rows)
    assert_shared_source(rows)
    assert(rows.all? { |row| row.dig(:provenance, :sourceStateReuse) == 'shared_replay_state' })
  end

  def test_current_row_uses_production_adaptive_plan_not_dense_fixture_baseline
    result = comparison.compare(pack: pack, case_ids: ['created_flat_corridor_mta21'])
    current = result.fetch(:comparisonRows).find do |row|
      row.fetch(:backend) == 'mta21_current_adaptive'
    end

    assert_equal('adaptive_tin', current.dig(:metrics, :meshType))
    assert_operator(current.dig(:metrics, :denseRatio), :<, 1.0)
    assert_equal(current.dig(:metrics, :faceCount), current.dig(:mesh, :triangles).length)
    assert_operator(current.dig(:mesh, :vertices).length, :>, 0)
  end

  def assert_three_backend_rows(rows)
    assert_equal(%w[
                   mta21_current_adaptive mta23_intent_aware_adaptive_grid_prototype
                   mta24_constrained_delaunay_cdt_prototype
                 ], rows.map { |row| row.fetch(:backend) }.sort)
    assert_equal(['created_flat_corridor_mta21'], rows.map { |row| row.fetch(:caseId) }.uniq)
    assert_equal(1, rows.map { |row| row.fetch(:resultSchemaVersion) }.uniq.length)
  end

  def assert_shared_source(rows)
    assert_equal(1, rows.map { |row| row.fetch(:stateDigest) }.uniq.length)
    assert_equal(1, rows.map { |row| row.fetch(:sourceDimensions) }.uniq.length)
    assert_equal(1, rows.map { |row| row.fetch(:sourceSpacing) }.uniq.length)
    assert_equal(1, rows.map { |row| row.fetch(:featureGeometryDigest) }.uniq.length)
    assert_equal(1, rows.map { |row| row.fetch(:referenceGeometryDigest) }.uniq.length)
  end

  def test_non_replayable_fixture_keeps_provenance_rows_without_fake_local_cdt
    result = comparison.compare(pack: pack,
                                case_ids: ['adopted_irregular_off_grid_corridor_mta21'])
    rows = result.fetch(:comparisonRows)

    assert_equal(3, rows.length)
    assert(rows.all? { |row| row.fetch(:failureCategory) == 'comparison_not_applicable' })
    assert_includes(JSON.generate(rows), 'not locally replayable')
  end

  def test_recommendation_blocks_without_joint_hosted_visual_validation
    rows = production_candidate_rows

    result = comparison.recommendation_for(
      rows: rows,
      hosted_evidence: { familyCoverage: {}, jointVisualValidationStatus: 'not_run' }
    )

    assert_equal('hosted_validation_required', result.fetch(:recommendation))
    assert_includes(result.fetch(:validationGaps), 'joint live visual validation gap')
  end

  def test_hybrid_recommendation_requires_measurable_routing_gates
    result = comparison.recommendation_for(
      rows: production_candidate_rows,
      hosted_evidence: hosted_evidence.merge(
        requestedRecommendation: 'hybrid_fallback',
        routingGates: []
      )
    )

    assert_equal('recommendation_blocked', result.fetch(:recommendation))
    assert_includes(result.fetch(:validationGaps), 'hybrid routing gates missing')
  end

  def test_recommendation_blocks_dense_cdt_even_when_topology_and_constraints_are_clean
    rows = production_candidate_rows
    cdt_row = rows.find { |row| row.fetch(:backend).include?('mta24') }
    cdt_row.fetch(:metrics)[:denseRatio] = 0.95
    cdt_row.fetch(:metrics)[:maxHeightError] = 0.0

    result = comparison.recommendation_for(rows: rows, hosted_evidence: hosted_evidence)

    assert_equal('hybrid_or_adaptive_follow_up', result.fetch(:recommendation))
  end

  def test_recommendation_requires_every_cdt_row_to_be_viable
    rows = production_candidate_rows + [
      production_candidate_rows.find { |row| row.fetch(:backend).include?('mta24') }.merge(
        metrics: {
          denseRatio: 0.1,
          maxHeightError: 0.2,
          topologyChecks: { downFaceCount: 0, nonManifoldEdgeCount: 0, maxNormalBreakDeg: 5.0 },
          hardViolationCounts: {},
          firmResidualsByRole: {}
        }
      )
    ]

    result = comparison.recommendation_for(rows: rows, hosted_evidence: hosted_evidence)

    assert_equal('hybrid_or_adaptive_follow_up', result.fetch(:recommendation))
  end

  def test_recommendation_allows_cdt_when_all_cdt_rows_are_viable
    result = comparison.recommendation_for(
      rows: production_candidate_rows,
      hosted_evidence: hosted_evidence
    )

    assert_equal('productionize_cdt_later', result.fetch(:recommendation))
  end

  private

  def comparison
    @comparison ||= SU_MCP::Terrain::Mta24ThreeWayTerrainComparison.new
  end

  def pack
    @pack ||= AdaptiveTerrainRegressionFixtures.load
  end

  def production_candidate_rows
    %w[
      mta21_current_adaptive mta23_intent_aware_adaptive_grid_prototype
      mta24_constrained_delaunay_cdt_prototype
    ].map do |backend|
      {
        backend: backend,
        failureCategory: 'none',
        budgetStatus: 'ok',
        metrics: {
          faceCount: 10,
          denseRatio: backend.include?('mta24') ? 0.1 : nil,
          maxHeightError: backend.include?('mta24') ? 0.01 : nil,
          topologyChecks: { downFaceCount: 0, nonManifoldEdgeCount: 0, maxNormalBreakDeg: 5.0 },
          hardViolationCounts: {},
          firmResidualsByRole: {}
        },
        constrainedEdgeCoverage: backend.include?('mta24') ? 1.0 : nil
      }
    end
  end

  def hosted_evidence
    {
      jointVisualValidationStatus: 'passed',
      familyCoverage: SU_MCP::Terrain::Mta24HostedBakeoffProbe::REQUIRED_FAMILIES.to_h do |family|
        [family, { status: 'passed', backends: %w[current adaptive cdt] }]
      end
    }
  end
end
