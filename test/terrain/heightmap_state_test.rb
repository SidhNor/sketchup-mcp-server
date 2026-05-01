# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'

class HeightmapStateTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_valid_state_is_sketchup_free_and_storage_safe
    state = build_state

    assert_equal('heightmap_grid', state.payload_kind)
    assert_equal(1, state.schema_version)
    assert_equal('meters', state.units)
    assert_equal({ 'columns' => 2, 'rows' => 2 }, state.dimensions)
    assert_equal([10.0, nil, 11.5, 12.0], state.elevations)
    assert_equal(1, state.revision)
    assert_equal('terrain-state-1', state.state_id)

    encoded = JSON.generate(state.to_h)
    assert_includes(encoded, '"payloadKind":"heightmap_grid"')
    refute_includes(encoded, 'Sketchup::')
  end

  def test_rejects_invalid_dimensions_spacing_basis_and_elevation_count
    assert_raises(ArgumentError) { build_state(dimensions: { 'columns' => 0, 'rows' => 2 }) }
    assert_raises(ArgumentError) { build_state(spacing: { 'x' => 1.0, 'y' => 0.0 }) }
    assert_raises(ArgumentError) { build_state(basis: BASIS.merge('xAxis' => [2.0, 0.0, 0.0])) }
    assert_raises(ArgumentError) { build_state(elevations: [1.0, 2.0, 3.0]) }
  end

  def test_rejects_non_json_safe_no_data_values
    assert_raises(ArgumentError) { build_state(elevations: [1.0, Float::NAN, 2.0, 3.0]) }
  end

  def test_equality_uses_normalized_owner_local_values
    first = build_state
    second = SU_MCP::Terrain::HeightmapState.from_h(first.to_h)

    assert_equal(first, second)
    refute_equal(first, build_state(elevations: [10.0, nil, 11.5, 13.0]))
  end

  def test_with_elevations_preserves_legacy_state_class_for_migration_fixtures
    edited = build_state.with_elevations([1.0, 2.0, 3.0, 4.0], revision: 5)

    assert_instance_of(SU_MCP::Terrain::HeightmapState, edited)
    assert_equal(5, edited.revision)
    assert_equal([1.0, 2.0, 3.0, 4.0], edited.elevations)
  end

  private

  def build_state(overrides = {})
    SU_MCP::Terrain::HeightmapState.new(
      {
        basis: BASIS,
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: { 'columns' => 2, 'rows' => 2 },
        elevations: [10.0, nil, 11.5, 12.0],
        revision: 1,
        state_id: 'terrain-state-1',
        source_summary: { 'sourceElementId' => 'source-1' },
        constraint_refs: [{ 'sourceElementId' => 'path-1', 'role' => 'reference' }],
        owner_transform_signature: 'transform-a'
      }.merge(overrides)
    )
  end
end
