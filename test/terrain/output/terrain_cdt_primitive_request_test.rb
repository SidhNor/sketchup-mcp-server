# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/terrain_cdt_primitive_request'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class TerrainCdtPrimitiveRequestTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_builds_deterministic_json_safe_request_from_state_and_feature_geometry
    first = primitive_request(feature_geometry)
    second = primitive_request(feature_geometry)

    assert_equal(first, second)
    assert_equal('state-1', first.fetch(:stateId))
    assert_includes(first.fetch(:points), [0.0, 0.0])
    assert_includes(first.fetch(:hardAnchors), [1.0, 1.0])
    assert(JSON.parse(JSON.generate(first)))
    refute_includes(JSON.generate(first), 'Sketchup::')
  end

  def test_intersecting_constraints_are_diagnostic_for_ruby_cdt_not_preflight_fallback
    request = primitive_request(intersecting_feature_geometry)

    assert_includes(
      request.fetch(:limitations).map { |item| item.fetch(:category) },
      'intersecting_constraints'
    )
    refute_includes(request.keys, :fallbackReason)
  end

  def test_unsupported_primitives_map_to_deterministic_limitations
    request = primitive_request(unsupported_feature_geometry)

    assert_includes(
      request.fetch(:limitations).map { |item| item.fetch(:category) },
      'unsupported_constraint_shape'
    )
  end

  private

  def primitive_request(geometry)
    SU_MCP::Terrain::TerrainCdtPrimitiveRequest.build(
      state: state,
      feature_geometry: geometry,
      limits: { pointBudget: 256, faceBudget: 512 },
      epsilon: 1e-9
    )
  end

  def state
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 3, 'rows' => 3 },
      elevations: Array.new(9, 1.0),
      revision: 1,
      state_id: 'state-1'
    )
  end

  def feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        { id: 'fixed', ownerLocalPoint: [1.0, 1.0], strength: 'hard' }
      ],
      protectedRegions: [
        { id: 'preserve', primitive: 'rectangle', ownerLocalBounds: [[0.0, 0.0], [1.0, 1.0]] }
      ],
      referenceSegments: [
        { id: 'center', ownerLocalStart: [0.0, 1.0], ownerLocalEnd: [2.0, 1.0] }
      ]
    )
  end

  def intersecting_feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        { id: 'a', ownerLocalStart: [0.0, 0.0], ownerLocalEnd: [2.0, 2.0] },
        { id: 'b', ownerLocalStart: [0.0, 2.0], ownerLocalEnd: [2.0, 0.0] }
      ]
    )
  end

  def unsupported_feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      protectedRegions: [
        { id: 'poly', primitive: 'polygon', ownerLocalPoints: [[0.0, 0.0], [1.0, 0.0]] }
      ]
    )
  end
end
