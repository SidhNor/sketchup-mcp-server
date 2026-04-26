# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/terrain_mesh_generator'
require_relative '../../src/su_mcp/terrain/terrain_output_plan'

class TerrainMeshGeneratorTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  include SemanticTestSupport

  def test_generate_uses_entities_builder_without_candidate_response_fields
    model = build_semantic_model
    owner = model.active_entities.add_group

    result = identity_generator.generate(
      owner: owner,
      state: build_state(columns: 3, rows: 2),
      terrain_state_summary: { digest: 'abc123' }
    )

    assert_equal(1, owner.entities.build_calls)
    assert_equal(%i[outcome summary], result.keys)
    assert_equal('generated', result.fetch(:outcome))
    refute_internal_output_fields(result)
  end

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
    assert_all_faces_point_up(owner.entities.faces)
  end

  def test_marks_generated_faces_and_edges_as_derived_output
    model = build_semantic_model
    owner = model.active_entities.add_group

    identity_generator.generate(
      owner: owner,
      state: build_state(columns: 2, rows: 2),
      terrain_state_summary: { digest: 'abc123' }
    )

    assert_equal(2, owner.entities.faces.length)
    owner.entities.faces.each do |face|
      assert_derived_output(face)
      face.edges.each { |edge| assert_derived_output(edge) }
    end
  end

  def test_generate_summary_matches_full_grid_output_plan
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 2)
    terrain_state_summary = { digest: 'abc123' }

    result = identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: terrain_state_summary
    )

    assert_equal(
      SU_MCP::Terrain::TerrainOutputPlan
        .full_grid(state: state, terrain_state_summary: terrain_state_summary)
        .to_summary,
      result.fetch(:summary)
    )
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
    assert_all_faces_point_up(owner.entities.faces)
  end

  def test_normalizes_generated_faces_to_positive_z_normals
    model = build_semantic_model
    owner = model.active_entities.add_group
    force_added_faces_downward(owner.entities)

    identity_generator.generate(
      owner: owner,
      state: build_state(columns: 3, rows: 3),
      terrain_state_summary: { digest: 'abc123' }
    )

    assert_equal(8, owner.entities.faces.length)
    assert_all_faces_point_up(owner.entities.faces)
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

  def test_bulk_candidate_remains_validation_only_diagnostic_entrypoint
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 2)

    result = identity_generator.generate_bulk_candidate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'abc123' }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(true, result.fetch(:validationOnly))
    assert_equal(1, owner.entities.build_calls)
    assert_equal(4, owner.entities.faces.length)
    assert_all_faces_point_up(owner.entities.faces)
  end

  def test_generate_uses_per_face_compatibility_when_entities_do_not_support_build
    owner = OwnerWithoutBuilder.new

    result = identity_generator.generate(
      owner: owner,
      state: build_state(columns: 2, rows: 2),
      terrain_state_summary: { digest: 'abc123' }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(2, owner.entities.faces.length)
    refute_internal_output_fields(result)
  end

  def test_generate_does_not_fall_back_to_per_face_after_builder_failure
    owner = OwnerWithFailingBuilder.new

    assert_raises(RuntimeError) do
      identity_generator.generate(
        owner: owner,
        state: build_state(columns: 2, rows: 2),
        terrain_state_summary: { digest: 'abc123' }
      )
    end
    assert_empty(owner.entities.faces)
  end

  def test_regenerate_removes_prior_derived_faces_before_rebuilding
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)

    result = identity_generator.regenerate(
      owner: owner,
      state: build_state(columns: 2, rows: 2),
      terrain_state_summary: { digest: 'digest-2' }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal('digest-2', result.dig(:summary, :derivedMesh, :derivedFromStateDigest))
    assert_equal(1, owner.entities.build_calls)
    refute_includes(owner.entities.faces, old_face)
    assert_equal(2, owner.entities.faces.length)
  end

  def test_regenerate_refuses_unexpected_child_entities_before_erasing_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    owner.entities.add_group
    old_face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)

    result = identity_generator.regenerate(
      owner: owner,
      state: build_state(columns: 2, rows: 2),
      terrain_state_summary: { digest: 'digest-2' }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_contains_unsupported_entities', result.dig(:refusal, :code))
    assert_includes(owner.entities.faces, old_face)
  end

  private

  def assert_derived_output(entity)
    assert_equal(
      true,
      entity.get_attribute(
        SU_MCP::Terrain::TerrainMeshGenerator::DERIVED_OUTPUT_DICTIONARY,
        SU_MCP::Terrain::TerrainMeshGenerator::DERIVED_OUTPUT_KEY
      )
    )
  end

  def refute_internal_output_fields(result)
    serialized = JSON.generate(result)

    refute_includes(result.keys, :validationOnly)
    refute_includes(serialized, 'validationOnly')
    refute_includes(serialized, 'bulk')
    refute_includes(serialized, 'candidate')
    refute_includes(serialized, 'strategy')
    refute_includes(serialized, 'regeneration')
    refute_includes(serialized, 'sampleWindow')
    refute_includes(serialized, 'outputRegions')
    refute_includes(serialized, 'chunks')
    refute_includes(serialized, 'tiles')
    refute_includes(serialized, 'faceId')
    refute_includes(serialized, 'vertexId')
  end

  def identity_generator
    SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0)
    )
  end

  def assert_all_faces_point_up(faces)
    assert(
      faces.all? { |face| face.normal.z.positive? },
      'expected every terrain face normal to point up'
    )
  end

  def force_added_faces_downward(entities)
    original_add_face = entities.method(:add_face)
    entities.define_singleton_method(:add_face) do |*points|
      face = original_add_face.call(*points)
      face.reverse! if face.normal.z.positive?
      face
    end
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

  class OwnerWithoutBuilder
    attr_reader :entities

    def initialize
      @entities = EntitiesWithoutBuilder.new
    end
  end

  class OwnerWithFailingBuilder
    attr_reader :entities

    def initialize
      @entities = EntitiesWithFailingBuilder.new
    end
  end

  class EntitiesWithoutBuilder
    attr_reader :faces

    def initialize
      @faces = []
    end

    def add_face(*points)
      face = SemanticTestSupport::FakeFace.new(
        entity_id: faces.length + 1,
        persistent_id: "compat-#{faces.length + 1}",
        layer: nil,
        material: nil,
        points: points
      )
      faces << face
      face
    end
  end

  class EntitiesWithFailingBuilder < EntitiesWithoutBuilder
    def build
      raise 'builder failed'
    end
  end
end
