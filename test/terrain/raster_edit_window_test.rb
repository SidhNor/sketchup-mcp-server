# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/tiled_heightmap_state'
require_relative '../../src/su_mcp/terrain/raster_edit_window'
require_relative '../../src/su_mcp/terrain/sample_window'

class RasterEditWindowTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_reads_writes_commits_and_reports_dirty_tiles
    state = build_state
    window = SU_MCP::Terrain::RasterEditWindow.new(
      state: state,
      sample_window: SU_MCP::Terrain::SampleWindow.new(
        min_column: 1,
        min_row: 0,
        max_column: 2,
        max_row: 1
      )
    )

    assert_equal(2.0, window.elevation_at(column: 1, row: 0))
    assert_equal(3.0, window.elevation_at_xy(x: 2.0, y: 0.0))

    window.write_elevation(column: 2, row: 1, elevation: 30.0)
    committed = window.commit(revision: 2)

    assert_equal({ min: { column: 2, row: 1 }, max: { column: 2, row: 1 } },
                 window.dirty_sample_bounds)
    assert_equal(%w[tile-1-0], window.dirty_tile_ids)
    assert_instance_of(SU_MCP::Terrain::TiledHeightmapState, committed)
    assert_equal(30.0, committed.elevations.fetch(6))
  end

  def test_refuses_oversized_window_before_allocation
    state = build_state(dimensions: { 'columns' => 600, 'rows' => 600 },
                        elevations: Array.new(600 * 600, 1.0))

    error = assert_raises(ArgumentError) do
      SU_MCP::Terrain::RasterEditWindow.new(
        state: state,
        sample_window: SU_MCP::Terrain::SampleWindow.full_grid(state)
      )
    end

    assert_match(/too large/i, error.message)
  end

  private

  def build_state(overrides = {})
    columns = overrides.dig(:dimensions, 'columns') || 4
    rows = overrides.dig(:dimensions, 'rows') || 3
    elevations = overrides[:elevations] || (1..(columns * rows)).map(&:to_f)
    SU_MCP::Terrain::TiledHeightmapState.new(
      {
        basis: BASIS,
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: { 'columns' => columns, 'rows' => rows },
        elevations: elevations,
        tile_size: 2,
        revision: 1,
        state_id: 'terrain-state-1'
      }.merge(overrides)
    )
  end
end
