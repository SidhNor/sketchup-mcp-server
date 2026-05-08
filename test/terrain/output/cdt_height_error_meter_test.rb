# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/cdt_height_error_meter'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class CdtHeightErrorMeterTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_local_feature_tolerance_reports_residual_excess_below_base_tolerance
    terrain_state = bumped_state(columns: 5, rows: 5, bumps: { [2, 2] => 0.75 })
    samples = meter.worst_samples_with_local_tolerance(
      state: terrain_state,
      mesh: flat_mesh_for(terrain_state),
      limit: 4,
      base_tolerance: 1.0,
      feature_geometry: firm_rectangle_feature
    )

    center = samples.find { |sample| sample.fetch(:column) == 2 && sample.fetch(:row) == 2 }
    refute_nil(center)
    assert_operator(center.fetch(:error), :<, 1.0)
    assert_operator(center.fetch(:residualExcess), :>, 0.0)
    assert_operator(center.fetch(:localTolerance), :<, 1.0)
  end

  def test_distributed_residual_sampling_keeps_distant_hotspots
    terrain_state = bumped_state(
      columns: 9,
      rows: 9,
      bumps: { [1, 1] => 3.0, [7, 7] => 2.8, [1, 2] => 2.7 }
    )
    samples = meter.worst_samples_with_local_tolerance(
      state: terrain_state,
      mesh: flat_mesh_for(terrain_state),
      limit: 2,
      base_tolerance: 0.25,
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
    )

    coordinates = samples.map { |sample| [sample.fetch(:column), sample.fetch(:row)] }
    assert_includes(coordinates, [1, 1])
    assert_includes(coordinates, [7, 7])
  end

  private

  def meter
    @meter ||= SU_MCP::Terrain::CdtHeightErrorMeter.new
  end

  def bumped_state(columns:, rows:, bumps:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      bumps.fetch([column, row], 0.0)
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'cdt-height-error-meter'
    )
  end

  def flat_mesh_for(terrain_state)
    max_x = terrain_state.origin.fetch('x') +
            ((terrain_state.dimensions.fetch('columns') - 1) * terrain_state.spacing.fetch('x'))
    max_y = terrain_state.origin.fetch('y') +
            ((terrain_state.dimensions.fetch('rows') - 1) * terrain_state.spacing.fetch('y'))
    {
      vertices: [[0.0, 0.0, 0.0], [max_x, 0.0, 0.0], [max_x, max_y, 0.0], [0.0, max_y, 0.0]],
      triangles: [[0, 1, 2], [0, 2, 3]]
    }
  end

  def firm_rectangle_feature
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      pressureRegions: [
        { id: 'firm', featureId: 'firm', role: 'grading', strength: 'firm',
          primitive: 'rectangle', ownerLocalShape: [[1.0, 1.0], [3.0, 3.0]] }
      ]
    )
  end
end
