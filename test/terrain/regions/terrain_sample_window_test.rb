# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/regions/sample_window'

class TerrainSampleWindowTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_full_grid_window_describes_every_sample_and_existing_changed_region_vocabulary
    window = SU_MCP::Terrain::SampleWindow.full_grid(state)

    assert_equal(false, window.empty?)
    assert_equal(12, window.sample_count)
    assert_equal(
      { min: { column: 0, row: 0 }, max: { column: 3, row: 2 } },
      window.to_changed_region
    )
  end

  def test_owner_bounds_map_to_inclusive_grid_samples_with_non_zero_origin
    window = SU_MCP::Terrain::SampleWindow.from_owner_bounds(
      state,
      { 'minX' => 12.0, 'minY' => 23.0, 'maxX' => 14.0, 'maxY' => 26.0 }
    )

    assert_equal(
      { min: { column: 1, row: 1 }, max: { column: 2, row: 2 } },
      window.to_changed_region
    )
  end

  def test_owner_bounds_are_clipped_to_grid_and_can_be_empty
    clipped = SU_MCP::Terrain::SampleWindow.from_owner_bounds(
      state,
      { 'minX' => 8.0, 'minY' => 18.0, 'maxX' => 12.0, 'maxY' => 23.0 }
    )
    empty = SU_MCP::Terrain::SampleWindow.from_owner_bounds(
      state,
      { 'minX' => 100.0, 'minY' => 100.0, 'maxX' => 110.0, 'maxY' => 110.0 }
    )

    assert_equal(
      { min: { column: 0, row: 0 }, max: { column: 1, row: 1 } },
      clipped.to_changed_region
    )
    assert(empty.empty?)
    assert_nil(empty.to_changed_region)
  end

  def test_windows_support_intersection_and_union
    left = SU_MCP::Terrain::SampleWindow.from_owner_bounds(
      state,
      { 'minX' => 10.0, 'minY' => 20.0, 'maxX' => 12.0, 'maxY' => 23.0 }
    )
    right = SU_MCP::Terrain::SampleWindow.from_owner_bounds(
      state,
      { 'minX' => 12.0, 'minY' => 23.0, 'maxX' => 16.0, 'maxY' => 26.0 }
    )

    assert_equal(
      { min: { column: 1, row: 1 }, max: { column: 1, row: 1 } },
      left.intersection(right).to_changed_region
    )
    assert_equal(
      { min: { column: 0, row: 0 }, max: { column: 3, row: 2 } },
      left.union(right).to_changed_region
    )
  end

  def test_window_from_samples_matches_changed_region_summary
    window = SU_MCP::Terrain::SampleWindow.from_samples([
                                                          { column: 2, row: 1 },
                                                          { column: 1, row: 2 },
                                                          { column: 3, row: 0 }
                                                        ])

    assert_equal(
      { min: { column: 1, row: 0 }, max: { column: 3, row: 2 } },
      window.to_changed_region
    )
  end

  def test_invalid_bounds_are_rejected_inside_the_domain_primitive
    assert_raises(ArgumentError) do
      SU_MCP::Terrain::SampleWindow.from_owner_bounds(
        state,
        { 'minX' => 14.0, 'minY' => 20.0, 'maxX' => 10.0, 'maxY' => 26.0 }
      )
    end
    assert_raises(ArgumentError) do
      SU_MCP::Terrain::SampleWindow.from_owner_bounds(
        state,
        { 'minX' => Float::NAN, 'minY' => 20.0, 'maxX' => 10.0, 'maxY' => 26.0 }
      )
    end
  end

  private

  def state
    @state ||= SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 10.0, 'y' => 20.0, 'z' => 0.0 },
      spacing: { 'x' => 2.0, 'y' => 3.0 },
      dimensions: { 'columns' => 4, 'rows' => 3 },
      elevations: Array.new(12, 1.0),
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end
end
