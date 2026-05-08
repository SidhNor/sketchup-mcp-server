# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/intent_aware_adaptive_grid_policy'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'

class IntentAwareAdaptiveGridHardChecksTest < Minitest::Test
  def test_rectangle_and_circle_protected_crossings_record_count_and_severity
    checks = policy.protected_crossing_metrics(
      triangles: [
        [[0.0, 2.0, 0.0], [5.0, 2.0, 0.0], [0.0, 5.0, 0.0]],
        [[6.0, 2.0, 0.0], [9.0, 2.0, 0.0], [6.0, 5.0, 0.0]]
      ]
    )

    assert_operator(checks.fetch(:protectedCrossingCount), :>=, 2)
    assert_operator(checks.fetch(:protectedCrossingSeverity), :>, 0.0)
  end

  def test_boundary_endpoint_tolerance_does_not_count_boundary_edges_as_crossings
    checks = policy.protected_crossing_metrics(
      triangles: [
        [[1.0, 1.0, 0.0], [2.0, 1.0, 0.0], [3.0, 1.0, 0.0]]
      ]
    )

    assert_equal(0, checks.fetch(:protectedCrossingCount))
  end

  def test_fixed_anchor_uses_owner_local_euclidean_xy_distance
    result = policy.anchor_hit_metrics(vertices: [[0.0, 0.0, 9.0], [2.02, 2.03, -4.0]])

    assert_in_delta(0.036, result.fetch(:anchorHitDistances).fetch('anchor-1'), 0.001)
    assert_empty(result.fetch(:hardViolationCounts))
  end

  def test_firm_survey_anchor_is_not_treated_as_hard_output_requirement
    result = firm_anchor_policy.anchor_hit_metrics(vertices: [[0.0, 0.0, 0.0]])

    assert_empty(result.fetch(:anchorHitDistances))
    assert_empty(result.fetch(:hardViolationCounts))
  end

  def test_min_size_missing_anchor_classifies_hard_violation
    result = policy.hard_requirement_status_for(cell(2, 2, 3, 3), vertices: [[0.0, 0.0, 0.0]])

    assert_equal('violated_at_min_size', result.fetch(:status))
    assert_equal({ fixed_anchor_missing: 1 }, result.fetch(:hardViolationCounts))
  end

  private

  def policy
    @policy ||= SU_MCP::Terrain::IntentAwareAdaptiveGridPolicy.new(
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new(
        outputAnchorCandidates: [
          { id: 'anchor-1', featureId: 'fixed', role: 'control', strength: 'hard',
            ownerLocalPoint: [2.0, 2.0], tolerance: 0.05 }
        ],
        protectedRegions: [
          { id: 'rect', featureId: 'preserve', role: 'protected', primitive: 'rectangle',
            ownerLocalBounds: [[1.0, 1.0], [3.0, 3.0]], boundaryTolerance: 0.0001 },
          { id: 'circle', featureId: 'preserve-c', role: 'protected', primitive: 'circle',
            ownerLocalCenterRadius: [7.0, 2.0, 1.0] }
        ]
      ),
      base_tolerance: 1.0,
      tile_columns: 10
    )
  end

  def firm_anchor_policy
    SU_MCP::Terrain::IntentAwareAdaptiveGridPolicy.new(
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new(
        outputAnchorCandidates: [
          { id: 'survey-1', featureId: 'survey', role: 'survey_anchor', strength: 'firm',
            ownerLocalPoint: [2.0, 2.0], tolerance: 0.05 }
        ]
      ),
      base_tolerance: 1.0,
      tile_columns: 10
    )
  end

  def cell(min_col, min_row, max_col, max_row)
    { min_col: min_col, min_row: min_row, max_col: max_col, max_row: max_row }
  end
end
