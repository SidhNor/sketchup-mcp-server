# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/terrain_mesh_generator'

class TerrainMeshGeneratorTest < Minitest::Test
  include SemanticTestSupport

  def test_generates_regular_grid_mesh_with_deterministic_counts_and_digest_linkage
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 2)

    result = SU_MCP::Terrain::TerrainMeshGenerator.new.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'abc123' }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(
      {
        meshType: 'regular_grid',
        vertexCount: 6,
        faceCount: 4,
        derivedFromStateDigest: 'abc123'
      },
      result.fetch(:summary).fetch(:derivedMesh)
    )
    assert_equal(4, owner.entities.faces.length)
  end

  def test_uses_one_deterministic_diagonal_direction_for_every_cell
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3)

    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'abc123' }
    )

    triangles = owner.entities.faces.map(&:points)
    assert_includes(triangles, [[0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [1.0, 1.0, 1.0]])
    refute_includes(triangles, [[0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0]])
  end

  def test_converts_public_meter_state_values_to_internal_geometry_units
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 2, rows: 2, origin: { 'x' => 1.0, 'y' => 2.0, 'z' => 0.0 })
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 10.0)
    )

    generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'abc123' }
    )

    assert_includes(
      owner.entities.faces.map(&:points),
      [[10.0, 20.0, 10.0], [20.0, 20.0, 10.0], [20.0, 30.0, 10.0]]
    )
  end

  private

  def identity_generator
    SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0)
    )
  end

  def build_state(columns:, rows:, origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 })
    SU_MCP::Terrain::HeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: origin,
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: Array.new(columns * rows, 1.0),
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  class ScalingLengthConverter
    def initialize(multiplier:)
      @multiplier = multiplier
    end

    def public_meters_to_internal(value)
      value.to_f * @multiplier
    end
  end
end
