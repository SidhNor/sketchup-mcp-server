# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/regions/sample_window'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_cell_window'

class TerrainOutputCellWindowTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_derives_overlap_cells_for_interior_dirty_window
    window = cell_window(dirty_window(2, 2, 3, 3), columns: 6, rows: 5)

    assert_equal(1, window.min_column)
    assert_equal(1, window.min_row)
    assert_equal(3, window.max_column)
    assert_equal(3, window.max_row)
    assert_equal(9, window.cell_count)
    assert_equal([[1, 1], [2, 1], [3, 1], [1, 2], [2, 2], [3, 2],
                  [1, 3], [2, 3], [3, 3]], window.each_cell.to_a)
  end

  def test_clips_first_row_and_column_dirty_window
    window = cell_window(dirty_window(0, 0, 1, 1), columns: 5, rows: 4)

    assert_equal([0, 0, 1, 1], bounds_for(window))
    assert_equal(4, window.cell_count)
  end

  def test_clips_last_sample_column_and_row_on_non_square_terrain
    window = cell_window(dirty_window(6, 3, 6, 3), columns: 7, rows: 4)

    assert_equal([5, 2, 5, 2], bounds_for(window))
    assert_equal([[5, 2]], window.each_cell.to_a)
  end

  def test_single_interior_sample_touches_four_neighboring_cells
    window = cell_window(dirty_window(2, 2, 2, 2), columns: 5, rows: 5)

    assert_equal([1, 1, 2, 2], bounds_for(window))
    assert_equal(4, window.cell_count)
  end

  def test_single_edge_sample_touches_only_available_neighboring_cells
    window = cell_window(dirty_window(0, 2, 0, 2), columns: 5, rows: 5)

    assert_equal([0, 1, 0, 2], bounds_for(window))
    assert_equal(2, window.cell_count)
  end

  def test_full_grid_sample_window_covers_entire_cell_grid
    state = state(columns: 4, rows: 3)
    window = SU_MCP::Terrain::TerrainOutputCellWindow.from_sample_window(
      window: SU_MCP::Terrain::SampleWindow.full_grid(state),
      state: state
    )

    assert_equal([0, 0, 2, 1], bounds_for(window))
    assert_equal(6, window.cell_count)
    assert_predicate(window, :whole_grid?)
    refute_predicate(window, :empty?)
  end

  def test_empty_sample_window_derives_empty_cell_window
    window = cell_window(SU_MCP::Terrain::SampleWindow.new(empty: true), columns: 4, rows: 3)

    assert_predicate(window, :empty?)
    assert_equal(0, window.cell_count)
    assert_empty(window.each_cell.to_a)
    refute_predicate(window, :whole_grid?)
  end

  private

  def bounds_for(window)
    [window.min_column, window.min_row, window.max_column, window.max_row]
  end

  def cell_window(window, columns:, rows:)
    SU_MCP::Terrain::TerrainOutputCellWindow.from_sample_window(
      window: window,
      state: state(columns: columns, rows: rows)
    )
  end

  def dirty_window(min_column, min_row, max_column, max_row)
    SU_MCP::Terrain::SampleWindow.new(
      min_column: min_column,
      min_row: min_row,
      max_column: max_column,
      max_row: max_row
    )
  end

  def state(columns:, rows:)
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: Array.new(columns * rows, 1.0),
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end
end
