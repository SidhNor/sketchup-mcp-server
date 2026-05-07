# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/intent_aware_adaptive_grid_policy'
require_relative '../../src/su_mcp/terrain/terrain_feature_geometry'

class IntentAwareAdaptiveGridPolicyTest < Minitest::Test
  def test_split_priority_is_hard_first_height_then_firm_soft_area_and_row_major
    policy = SU_MCP::Terrain::IntentAwareAdaptiveGridPolicy.new(
      feature_geometry: feature_geometry,
      base_tolerance: 1.0,
      tile_columns: 10
    )
    hard = cell(0, 0, 4, 4, hard_requirement_status: 'unresolved', height_error: 0.0)
    height = cell(0, 0, 4, 4, height_error: 2.0, local_tolerance: 1.0)
    firm = cell(0, 0, 4, 4, firm_pressure: true)

    assert_equal(1, policy.split_priority(hard) <=> policy.split_priority(height))
    assert_equal(1, policy.split_priority(height) <=> policy.split_priority(firm))
    row_major_policy = SU_MCP::Terrain::IntentAwareAdaptiveGridPolicy.new(
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 1.0,
      tile_columns: 10
    )
    assert_equal([0, 0, 0, 0, 16, 0], row_major_policy.split_priority(cell(0, 0, 4, 4)))
    assert_equal([0, 0, 0, 0, 16, 11], row_major_policy.split_priority(cell(1, 1, 5, 5)))
    assert_equal(
      [0, 0, 0, 0, 16, 11],
      row_major_policy.split_priority({ min_column: 1, min_row: 1, max_column: 5, max_row: 5 })
    )
    assert_equal(
      [0, 0, 0, 0, 16, 11],
      row_major_policy.split_priority({ 'min_column' => 1, 'min_row' => 1,
                                        'max_column' => 5, 'max_row' => 5 })
    )
  end

  def test_pressure_coverage_uses_overlap_max_target_cell_size_without_weighted_scoring
    policy = SU_MCP::Terrain::IntentAwareAdaptiveGridPolicy.new(
      feature_geometry: feature_geometry,
      base_tolerance: 1.0,
      tile_columns: 10
    )

    assert(policy.pressure_coverage_needed?(cell(0, 0, 4, 4), 'firm'))
    refute(policy.pressure_coverage_needed?(cell(0, 0, 1, 1), 'firm'))
    assert_equal(false, policy.respond_to?(:weighted_score))
  end

  def test_local_tolerance_tightens_monotonically_with_named_defaults_and_floor
    policy = SU_MCP::Terrain::IntentAwareAdaptiveGridPolicy.new(
      feature_geometry: feature_geometry,
      base_tolerance: 1.0,
      tile_columns: 10
    )

    assert_in_delta(0.25, policy.local_tolerance(cell(1, 1, 2, 2)), 0.0001)
    assert_in_delta(0.5, policy.local_tolerance(cell(3, 0, 5, 1)), 0.0001)
    assert_in_delta(1.0, policy.local_tolerance(cell(8, 8, 9, 9)), 0.0001)
    assert_in_delta(0.1, policy.local_tolerance(cell(1, 1, 2, 2), hard_tolerance: 0.001), 0.0001)
  end

  private

  def cell(min_col, min_row, max_col, max_row, overrides = {})
    {
      min_col: min_col, min_row: min_row, max_col: max_col, max_row: max_row,
      height_error: 0.0, local_tolerance: 1.0, hard_requirement_status: 'none',
      firm_pressure: false, soft_pressure: false
    }.merge(overrides)
  end

  def feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      protectedRegions: [
        { id: 'p1', featureId: 'f1', role: 'protected', primitive: 'rectangle',
          ownerLocalBounds: [[1.0, 1.0], [2.0, 2.0]] }
      ],
      pressureRegions: [
        { id: 'firm', featureId: 'f2', role: 'centerline', strength: 'firm',
          primitive: 'rectangle', ownerLocalShape: [[0.0, 0.0], [4.0, 4.0]],
          targetCellSize: 1 },
        { id: 'soft', featureId: 'f3', role: 'falloff', strength: 'soft',
          primitive: 'circle', ownerLocalShape: [6.0, 6.0, 2.0], targetCellSize: 3 }
      ]
    )
  end
end
