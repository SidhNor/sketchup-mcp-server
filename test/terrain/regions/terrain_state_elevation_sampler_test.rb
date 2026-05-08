# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/regions/terrain_state_elevation_sampler'

class TerrainStateElevationSamplerTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_interpolates_public_owner_local_heightmap_elevation
    sampler = build_sampler(
      elevations: [
        0.0, 10.0,
        20.0, 30.0
      ]
    )

    assert_in_delta(15.0, sampler.elevation_at('x' => 0.5, 'y' => 0.5), 1e-9)
  end

  def test_reports_owner_local_points_inside_and_outside_state_bounds
    sampler = build_sampler

    assert_equal(true, sampler.inside_bounds?('x' => 0.0, 'y' => 0.0))
    assert_equal(true, sampler.inside_bounds?('x' => 1.0, 'y' => 1.0))
    assert_equal(false, sampler.inside_bounds?('x' => -0.001, 'y' => 0.5))
    assert_equal(false, sampler.inside_bounds?('x' => 0.5, 'y' => 1.001))
  end

  def test_refuses_to_hide_no_data_samples_behind_interpolation
    sampler = build_sampler(
      elevations: [
        0.0, nil,
        20.0, 30.0
      ]
    )

    assert_nil(sampler.elevation_at('x' => 0.5, 'y' => 0.5))
  end

  private

  def build_sampler(elevations: [0.0, 10.0, 20.0, 30.0])
    SU_MCP::Terrain::TerrainStateElevationSampler.new(
      SU_MCP::Terrain::HeightmapState.new(
        basis: BASIS,
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: { 'columns' => 2, 'rows' => 2 },
        elevations: elevations,
        revision: 1,
        state_id: 'terrain-state-1'
      )
    )
  end
end
