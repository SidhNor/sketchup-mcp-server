# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/output/feature_aware_adaptive_policy'

class FeatureAwareAdaptivePolicyTest < Minitest::Test
  def test_missing_feature_geometry_uses_baseline_policy_with_fallback_summary
    policy = build_policy(feature_geometry: nil)

    assert_in_delta(0.01, policy.local_tolerance_for(bounds(0, 0, 8, 8)), 0.000001)
    assert_nil(policy.target_cell_size_for(bounds(0, 0, 8, 8)))
    assert_equal(
      {
        absentFeatureGeometry: 1,
        partialFeatureGeometry: 0,
        unsupportedFeatureGeometry: 0
      },
      policy.summary.fetch(:fallbackCounts)
    )
  end

  def test_strictest_overlapping_tolerance_wins_and_soft_pressure_cannot_weaken_it
    policy = build_policy(
      feature_geometry: geometry(
        outputAnchorCandidates: [
          {
            'id' => 'hard-control',
            'featureId' => 'feature-hard',
            'role' => 'control',
            'strength' => 'hard',
            'ownerLocalPoint' => [4.0, 4.0]
          }
        ],
        pressureRegions: [
          rectangle_pressure('firm-region', 'firm', [[2.0, 2.0], [6.0, 6.0]], 2),
          rectangle_pressure('soft-region', 'soft', [[0.0, 0.0], [8.0, 8.0]], 4)
        ]
      )
    )

    assert_in_delta(0.0025, policy.local_tolerance_for(bounds(3, 3, 5, 5)), 0.000001)
    assert_in_delta(0.01, policy.local_tolerance_for(bounds(10, 10, 12, 12)), 0.000001)
  end

  def test_target_cell_size_uses_strictest_overlapping_density_pressure
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          rectangle_pressure('soft-target', 'soft', [[0.0, 0.0], [8.0, 8.0]], 4),
          rectangle_pressure('firm-corridor', 'firm', [[2.0, 2.0], [6.0, 6.0]], 1)
        ]
      )
    )

    assert_equal(1, policy.target_cell_size_for(bounds(3, 3, 5, 5)))
    assert_equal(4, policy.target_cell_size_for(bounds(7, 7, 8, 8)))
    assert_nil(policy.target_cell_size_for(bounds(10, 10, 12, 12)))
  end

  def test_summary_is_deterministic_compact_and_aggregate_only
    first = build_policy(feature_geometry: hard_and_density_geometry)
    second = build_policy(feature_geometry: hard_and_density_geometry)

    first.local_tolerance_for(bounds(3, 3, 5, 5))
    first.target_cell_size_for(bounds(3, 3, 5, 5))
    second.local_tolerance_for(bounds(3, 3, 5, 5))
    second.target_cell_size_for(bounds(3, 3, 5, 5))

    first_summary = first.summary
    assert_equal(first_summary, second.summary)
    assert_match(/\A[a-f0-9]{64}\z/, first_summary.fetch(:policyFingerprint))
    assert_match(/\A[a-f0-9]{64}\z/, first_summary.fetch(:featureGeometryDigest))
    assert_equal({ min: 0.0025, max: 0.0025 }, first_summary.fetch(:toleranceRange))
    assert_equal(1, first_summary.fetch(:hardProtectedToleranceHitCount))
    assert_equal(1, first_summary.fetch(:densityHitCount))
    refute_includes(JSON.generate(first_summary), 'ownerLocalPoint')
    refute_includes(JSON.generate(first_summary), 'ownerLocalShape')
  end

  def test_partial_or_unsupported_geometry_degrades_without_public_refusal
    policy = build_policy(
      feature_geometry: geometry(
        pressureRegions: [
          { 'id' => 'unsupported-shape', 'featureId' => 'bad', 'primitive' => 'polygon' }
        ],
        limitations: [
          { 'featureId' => 'bad', 'category' => 'polygon_derivation', 'reason' => 'unsupported' }
        ]
      )
    )

    assert_in_delta(0.01, policy.local_tolerance_for(bounds(0, 0, 8, 8)), 0.000001)
    assert_nil(policy.target_cell_size_for(bounds(0, 0, 8, 8)))
    assert_equal(1, policy.summary.fetch(:fallbackCounts).fetch(:unsupportedFeatureGeometry))
  end

  private

  def build_policy(feature_geometry:)
    SU_MCP::Terrain::FeatureAwareAdaptivePolicy.new(
      feature_geometry: feature_geometry,
      state: state,
      base_tolerance: 0.01
    )
  end

  def hard_and_density_geometry
    geometry(
      outputAnchorCandidates: [
        {
          'id' => 'hard-control',
          'featureId' => 'feature-hard',
          'role' => 'control',
          'strength' => 'hard',
          'ownerLocalPoint' => [4.0, 4.0]
        }
      ],
      pressureRegions: [
        rectangle_pressure('firm-corridor', 'firm', [[2.0, 2.0], [6.0, 6.0]], 1)
      ]
    )
  end

  def geometry(values = {})
    SU_MCP::Terrain::TerrainFeatureGeometry.new(values)
  end

  def rectangle_pressure(id, strength, owner_local_bounds, target_cell_size)
    {
      'id' => id,
      'featureId' => id,
      'role' => strength == 'firm' ? 'centerline' : 'target_support',
      'strength' => strength,
      'primitive' => 'rectangle',
      'ownerLocalShape' => owner_local_bounds,
      'targetCellSize' => target_cell_size
    }
  end

  def bounds(min_column, min_row, max_column, max_row)
    {
      min_column: min_column,
      min_row: min_row,
      max_column: max_column,
      max_row: max_row
    }
  end

  def state
    Struct.new(:origin, :spacing).new(
      { 'x' => 0.0, 'y' => 0.0 },
      { 'x' => 1.0, 'y' => 1.0 }
    )
  end
end
