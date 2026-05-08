# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/terrain_surface_state_builder'

class TerrainSurfaceStateBuilderTest < Minitest::Test
  def test_builds_tiled_heightmap_create_state_from_existing_grid_definition_shape
    state = SU_MCP::Terrain::TerrainSurfaceStateBuilder.new.build_create_state(
      create_request,
      owner_transform_signature: 'matrix:owner'
    )

    assert_instance_of(SU_MCP::Terrain::TiledHeightmapState, state)
    assert_equal('heightmap_grid', state.payload_kind)
    assert_equal(3, state.schema_version)
    assert_equal({ 'columns' => 3, 'rows' => 2 }, state.dimensions)
    assert_equal({ 'x' => 1.5, 'y' => 2.5 }, state.spacing)
    assert_equal([8.25, 8.25, 8.25, 8.25, 8.25, 8.25], state.elevations)
    assert_equal('matrix:owner', state.owner_transform_signature)
    assert_nil(state.source_summary)
  end

  def test_builds_create_state_from_public_grid_elevations_when_present
    request = create_request
    request.fetch('definition').fetch('grid')['elevations'] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

    state = SU_MCP::Terrain::TerrainSurfaceStateBuilder.new.build_create_state(request)

    assert_equal([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], state.elevations)
  end

  def test_builds_adopted_tiled_heightmap_state_with_source_summary
    sampled_source = {
      state_input: {
        origin: { 'x' => 40.0, 'y' => 10.0, 'z' => 0.0 },
        spacing: { 'x' => 2.0, 'y' => 2.5 },
        dimensions: { 'columns' => 2, 'rows' => 3 },
        elevations: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
      },
      source_summary: { sourceElementId: 'source-terrain', sourceAction: 'replaced' }
    }

    state = SU_MCP::Terrain::TerrainSurfaceStateBuilder.new.build_adopted_state(
      sampled_source,
      owner_transform_signature: 'matrix:adopted'
    )

    assert_instance_of(SU_MCP::Terrain::TiledHeightmapState, state)
    assert_equal({ 'columns' => 2, 'rows' => 3 }, state.dimensions)
    assert_equal([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], state.elevations)
    assert_equal('source-terrain', state.source_summary.fetch('sourceElementId'))
    assert_equal('matrix:adopted', state.owner_transform_signature)
  end

  private

  def create_request
    {
      'definition' => {
        'grid' => {
          'origin' => { 'x' => 4.0, 'y' => 5.0, 'z' => 0.0 },
          'spacing' => { 'x' => 1.5, 'y' => 2.5 },
          'dimensions' => { 'columns' => 3, 'rows' => 2 },
          'baseElevation' => 8.25
        }
      }
    }
  end
end
