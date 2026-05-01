# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/tiled_heightmap_state'

class TiledHeightmapStateTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_builds_deterministic_v2_tiles_from_flat_elevations
    state = build_state(dimensions: { 'columns' => 3, 'rows' => 2 }, tile_size: 2)

    assert_equal('heightmap_grid', state.payload_kind)
    assert_equal(2, state.schema_version)
    assert_equal(2, state.tile_size)
    assert_equal([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], state.elevations)
    assert_equal(%w[tile-0-0 tile-1-0], state.tiles.map { |tile| tile.fetch('tileId') })
    assert_equal(
      [{ tileId: 'tile-0-0', originColumn: 0, originRow: 0, columns: 2, rows: 2 },
       { tileId: 'tile-1-0', originColumn: 2, originRow: 0, columns: 1, rows: 2 }],
      state.tile_summary
    )
  end

  def test_round_trips_v2_payload_without_exposing_sketchup_objects
    state = build_state(dimensions: { 'columns' => 3, 'rows' => 2 }, tile_size: 2)
    restored = SU_MCP::Terrain::TiledHeightmapState.from_h(state.to_h)

    assert_equal(state, restored)
    refute_includes(JSON.generate(restored.to_h), 'Sketchup::')
  end

  def test_with_elevations_preserves_v2_metadata_and_retiles
    state = build_state(dimensions: { 'columns' => 3, 'rows' => 2 }, tile_size: 2)

    edited = state.with_elevations([10.0, 2.0, 3.0, 4.0, 5.0, 12.0], revision: 8)

    assert_instance_of(SU_MCP::Terrain::TiledHeightmapState, edited)
    assert_equal(8, edited.revision)
    assert_equal(state.state_id, edited.state_id)
    assert_equal(state.tile_size, edited.tile_size)
    assert_equal([10.0, 2.0, 3.0, 4.0, 5.0, 12.0], edited.elevations)
  end

  private

  def build_state(overrides = {})
    dimensions = overrides[:dimensions] || { 'columns' => 2, 'rows' => 2 }
    elevations = overrides[:elevations] ||
                 (1..(dimensions.fetch('columns') * dimensions.fetch('rows'))).map(&:to_f)
    SU_MCP::Terrain::TiledHeightmapState.new(
      {
        basis: BASIS,
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: dimensions,
        elevations: elevations,
        revision: 1,
        state_id: 'terrain-state-1',
        source_summary: { 'sourceElementId' => 'source-1' },
        constraint_refs: [],
        owner_transform_signature: 'transform-a'
      }.merge(overrides)
    )
  end
end
