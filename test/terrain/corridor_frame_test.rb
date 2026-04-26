# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/sample_window'
begin
  require_relative '../../src/su_mcp/terrain/corridor_frame'
rescue LoadError
  # Skeleton-first TDD: implementation file is introduced after this failing surface exists.
end

class CorridorFrameTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_horizontal_vertical_diagonal_and_reversed_controls_normalize_direction
    horizontal = build_frame(start_point: { 'x' => 1.0, 'y' => 2.0 },
                             end_point: { 'x' => 5.0, 'y' => 2.0 })
    vertical = build_frame(start_point: { 'x' => 2.0, 'y' => 1.0 },
                           end_point: { 'x' => 2.0, 'y' => 5.0 })
    diagonal = build_frame(start_point: { 'x' => 1.0, 'y' => 1.0 },
                           end_point: { 'x' => 4.0, 'y' => 5.0 })
    reversed = build_frame(start_point: { 'x' => 5.0, 'y' => 2.0 },
                           end_point: { 'x' => 1.0, 'y' => 2.0 })

    assert_in_delta(0.0, horizontal.signed_lateral_distance('x' => 3.0, 'y' => 2.0), 1e-9)
    assert_in_delta(0.0, vertical.signed_lateral_distance('x' => 2.0, 'y' => 3.0), 1e-9)
    assert_in_delta(0.0, diagonal.signed_lateral_distance('x' => 2.5, 'y' => 3.0), 1e-9)
    assert_in_delta(0.5, reversed.longitudinal_parameter('x' => 3.0, 'y' => 2.0), 1e-9)
  end

  def test_weights_cover_center_strip_cosine_side_blend_and_hard_edge
    blended = build_frame(width: 2.0, side_blend: { 'distance' => 2.0, 'falloff' => 'cosine' })
    hard = build_frame(width: 2.0, side_blend: { 'distance' => 0.0, 'falloff' => 'none' })

    assert_in_delta(1.0, blended.weight_at('x' => 3.0, 'y' => 0.9), 1e-9)
    assert_in_delta(0.5, blended.weight_at('x' => 3.0, 'y' => 2.0), 1e-9)
    assert_in_delta(0.0, blended.weight_at('x' => 3.0, 'y' => 3.1), 1e-9)
    assert_in_delta(0.0, hard.weight_at('x' => 3.0, 'y' => 1.1), 1e-9)
  end

  def test_outer_bounds_are_conservative_for_non_zero_origin_and_non_uniform_spacing
    state = terrain_state(origin: { 'x' => 10.0, 'y' => 20.0, 'z' => 0.0 },
                          spacing: { 'x' => 1.0, 'y' => 2.5 },
                          columns: 8,
                          rows: 6)
    frame = build_frame(
      start_point: { 'x' => 11.0, 'y' => 20.0 },
      end_point: { 'x' => 16.0, 'y' => 32.5 },
      width: 1.0,
      side_blend: { 'distance' => 2.0, 'falloff' => 'cosine' }
    )
    window = SU_MCP::Terrain::SampleWindow.from_owner_bounds(
      state,
      frame.outer_bounds(expand_by: state.spacing)
    )

    assert_non_zero_weight_samples_inside_window(state, frame, window)
  end

  def test_diagonal_corridor_bounds_expansion_covers_edge_samples_with_non_uniform_spacing
    state = terrain_state(origin: { 'x' => 100.0, 'y' => 200.0, 'z' => 0.0 },
                          spacing: { 'x' => 0.5, 'y' => 1.25 },
                          columns: 21,
                          rows: 21)
    frame = build_frame(
      start_point: { 'x' => 101.0, 'y' => 202.5 },
      end_point: { 'x' => 106.0, 'y' => 207.5 },
      width: 0.7,
      side_blend: { 'distance' => 1.1, 'falloff' => 'cosine' }
    )
    window = SU_MCP::Terrain::SampleWindow.from_owner_bounds(
      state,
      frame.outer_bounds(expand_by: state.spacing)
    )

    assert_non_zero_weight_samples_inside_window(state, frame, window)
  end

  def test_coincident_endpoints_are_invalid_corridor_geometry
    assert_raises(ArgumentError) do
      build_frame(start_point: { 'x' => 1.0, 'y' => 1.0 },
                  end_point: { 'x' => 1.0, 'y' => 1.0 })
    end
  end

  def test_negative_bounds_expansion_is_rejected
    frame = build_frame

    assert_raises(ArgumentError) do
      frame.outer_bounds(expand_by: { 'x' => -1.0, 'y' => 1.0 })
    end
  end

  private

  def build_frame(start_point: { 'x' => 1.0, 'y' => 0.0 },
                  end_point: { 'x' => 5.0, 'y' => 0.0 },
                  width: 2.0,
                  side_blend: { 'distance' => 0.0, 'falloff' => 'none' })
    SU_MCP::Terrain::CorridorFrame.new(
      start_control: { 'point' => start_point, 'elevation' => 0.0 },
      end_control: { 'point' => end_point, 'elevation' => 1.0 },
      width: width,
      side_blend: side_blend
    )
  end

  def non_zero_weight_samples(state, frame)
    columns = state.dimensions.fetch('columns')
    rows = state.dimensions.fetch('rows')
    (0...rows).flat_map do |row|
      (0...columns).filter_map do |column|
        point = {
          'x' => state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          'y' => state.origin.fetch('y') + (row * state.spacing.fetch('y'))
        }
        next unless frame.weight_at(point).positive?

        { column: column, row: row }
      end
    end
  end

  def assert_non_zero_weight_samples_inside_window(state, frame, window)
    non_zero_weight_samples(state, frame).each do |sample|
      assert_operator(sample.fetch(:column), :>=, window.min_column)
      assert_operator(sample.fetch(:column), :<=, window.max_column)
      assert_operator(sample.fetch(:row), :>=, window.min_row)
      assert_operator(sample.fetch(:row), :<=, window.max_row)
    end
  end

  def terrain_state(origin:, spacing:, columns:, rows:)
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: origin,
      spacing: spacing,
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: Array.new(columns * rows, 1.0),
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end
end
