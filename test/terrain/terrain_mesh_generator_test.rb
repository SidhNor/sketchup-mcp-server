# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/terrain/tiled_heightmap_state'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/terrain_mesh_generator'
require_relative '../../src/su_mcp/terrain/terrain_output_cell_window'
require_relative '../../src/su_mcp/terrain/terrain_output_plan'

# rubocop:disable Metrics/AbcSize
class TerrainMeshGeneratorTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  include SemanticTestSupport

  TERRAIN_GEOMETRY_TOLERANCE = 1e-9

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

  def test_full_grid_generation_stamps_face_ownership_metadata_without_global_state_digest
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 2, revision: 7)

    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-7', revision: 7 }
    )

    assert_equal(4, owner.entities.faces.length)
    assert_equal(
      [[0, 0, 0], [0, 0, 1], [1, 0, 0], [1, 0, 1]],
      owner.entities.faces.map { |face| ownership_tuple(face) }.sort
    )
    owner.entities.faces.each do |face|
      assert_equal(1, terrain_attribute(face, 'outputSchemaVersion'))
      refute(terrain_attribute(face, 'terrainStateDigest'))
      refute(terrain_attribute(face, 'terrainStateRevision'))
    end
  end

  def test_full_grid_generation_keeps_edges_marker_only
    model = build_semantic_model
    owner = model.active_entities.add_group

    identity_generator.generate(
      owner: owner,
      state: build_state(columns: 2, rows: 2, revision: 3),
      terrain_state_summary: { digest: 'digest-3', revision: 3 }
    )

    owner.entities.faces.flat_map(&:edges).each do |edge|
      assert_derived_output(edge)
      refute(terrain_attribute(edge, 'gridCellColumn'))
      refute(terrain_attribute(edge, 'gridCellRow'))
      refute(terrain_attribute(edge, 'gridTriangleIndex'))
      refute(terrain_attribute(edge, 'terrainStateDigest'))
      refute(terrain_attribute(edge, 'terrainStateRevision'))
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

  def test_generate_uses_supplied_dirty_window_plan_summary_while_emitting_full_grid_mesh
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 2)
    plan = dirty_window_plan(state, digest: 'dirty-plan-digest')

    result = identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'fallback-digest' },
      output_plan: plan
    )

    assert_equal(plan.to_summary, result.fetch(:summary))
    assert_equal('dirty-plan-digest', result.dig(:summary, :derivedMesh, :derivedFromStateDigest))
    assert_equal(4, owner.entities.faces.length)
    assert_all_faces_point_up(owner.entities.faces)
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

  def test_regenerate_forwards_supplied_dirty_window_plan_after_cleanup
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    state = build_state(columns: 2, rows: 2)
    plan = dirty_window_plan(state, digest: 'dirty-regenerate-digest')

    result = identity_generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'fallback-digest' },
      output_plan: plan
    )

    assert_equal(plan.to_summary, result.fetch(:summary))
    assert_equal(
      'dirty-regenerate-digest',
      result.dig(:summary, :derivedMesh, :derivedFromStateDigest)
    )
    refute_includes(owner.entities.faces, old_face)
    assert_equal(2, owner.entities.faces.length)
  end

  def test_owned_faces_for_cell_window_accepts_complete_current_metadata
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 4)
    terrain_state_summary = { digest: 'digest-4', revision: 4 }
    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: terrain_state_summary
    )

    result = identity_generator.send(
      :owned_faces_for_cell_window,
      owner.entities,
      output_cell_window(0, 0, 1, 1)
    )

    assert_equal(:owned, result.fetch(:outcome))
    assert_equal(8, result.fetch(:faces).length)
  end

  def test_owned_faces_for_cell_window_accepts_sketchup_faces_without_points_helper
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 2, rows: 2, revision: 4)
    terrain_state_summary = { digest: 'digest-4', revision: 4 }
    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: terrain_state_summary
    )
    owner.entities.faces.each do |face|
      face.define_singleton_method(:respond_to?) do |method_name, include_private = false|
        return false if method_name == :points

        super(method_name, include_private)
      end
    end

    result = identity_generator.send(
      :owned_faces_for_cell_window,
      owner.entities,
      output_cell_window(0, 0, 0, 0)
    )

    assert_equal(:owned, result.fetch(:outcome))
    assert_equal(2, result.fetch(:faces).length)
  end

  def test_owned_faces_for_cell_window_falls_back_for_legacy_marker_only_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    face.set_attribute('su_mcp_terrain', 'derivedOutput', true)

    result = identity_generator.send(
      :owned_faces_for_cell_window,
      owner.entities,
      output_cell_window(0, 0, 0, 0)
    )

    assert_equal(:fallback, result.fetch(:outcome))
    assert_equal(:legacy_output, result.fetch(:reason))
  end

  def test_owned_faces_for_cell_window_accepts_stale_digest_metadata
    model = build_semantic_model
    owner = model.active_entities.add_group
    add_owned_face(owner.entities, column: 0, row: 0, triangle: 0, digest: 'old', revision: 1)
    add_owned_face(owner.entities, column: 0, row: 0, triangle: 1, digest: 'old', revision: 1)

    result = identity_generator.send(
      :owned_faces_for_cell_window,
      owner.entities,
      output_cell_window(0, 0, 0, 0)
    )

    assert_equal(:owned, result.fetch(:outcome))
    assert_equal(2, result.fetch(:faces).length)
  end

  def test_owned_faces_for_cell_window_falls_back_for_duplicate_or_incomplete_ownership
    model = build_semantic_model
    owner = model.active_entities.add_group
    add_owned_face(owner.entities, column: 0, row: 0, triangle: 0, digest: 'digest-1', revision: 1)
    add_owned_face(owner.entities, column: 0, row: 0, triangle: 0, digest: 'digest-1', revision: 1)

    duplicate = identity_generator.send(
      :owned_faces_for_cell_window,
      owner.entities,
      output_cell_window(0, 0, 0, 0)
    )

    assert_equal(:fallback, duplicate.fetch(:outcome))
    assert_equal(:duplicate_ownership, duplicate.fetch(:reason))

    owner = model.active_entities.add_group
    add_owned_face(owner.entities, column: 0, row: 0, triangle: 0, digest: 'digest-1', revision: 1)
    incomplete = identity_generator.send(
      :owned_faces_for_cell_window,
      owner.entities,
      output_cell_window(0, 0, 0, 0)
    )

    assert_equal(:fallback, incomplete.fetch(:outcome))
    assert_equal(:incomplete_ownership, incomplete.fetch(:reason))
  end

  def test_partial_regenerate_replaces_only_affected_faces_and_preserves_adjacent_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    before_state = build_state(columns: 4, rows: 3, revision: 1)
    after_state = build_state(
      columns: 4,
      rows: 3,
      revision: 2,
      elevations: [1.0, 1.0, 1.0, 1.0,
                   1.0, 4.0, 1.0, 1.0,
                   1.0, 1.0, 1.0, 1.0]
    )
    identity_generator.generate(
      owner: owner,
      state: before_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 }
    )
    original_faces = owner.entities.faces.dup
    unchanged_face = original_faces.find { |face| ownership_tuple(face) == [2, 0, 0] }
    plan = dirty_window_plan(
      after_state,
      digest: 'digest-2',
      revision: 2,
      previous_digest: 'digest-1',
      previous_revision: 1,
      window: dirty_window(1, 1, 1, 1)
    )

    result = identity_generator.regenerate(
      owner: owner,
      state: after_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: plan
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_includes(owner.entities.faces, unchanged_face)
    refute_includes(
      owner.entities.faces,
      original_faces.find { |face| ownership_tuple(face) == [0, 0, 0] }
    )
    assert_equal(12, owner.entities.faces.length)
    assert(owner.entities.faces.all? { |face| terrain_attribute(face, 'terrainStateDigest').nil? })
    assert(
      owner.entities.faces.all? { |face| terrain_attribute(face, 'terrainStateRevision').nil? }
    )
    assert_all_faces_point_up(owner.entities.faces)
    assert_seams_coherent(owner.entities.faces, tolerance: TERRAIN_GEOMETRY_TOLERANCE)
  end

  def test_partial_regenerate_does_not_relink_retained_faces_to_whole_state_digest
    model = build_semantic_model
    owner = model.active_entities.add_group
    before_state = build_state(columns: 4, rows: 3, revision: 1)
    after_state = build_state(
      columns: 4,
      rows: 3,
      revision: 2,
      elevations: [1.0, 1.0, 1.0, 1.0,
                   1.0, 4.0, 1.0, 1.0,
                   1.0, 1.0, 1.0, 1.0]
    )
    identity_generator.generate(
      owner: owner,
      state: before_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 }
    )
    owner.entities.faces.each do |face|
      face.set_attribute('su_mcp_terrain', 'terrainStateDigest', 'legacy-digest')
      face.set_attribute('su_mcp_terrain', 'terrainStateRevision', 1)
    end
    unchanged_face = owner.entities.faces.find { |face| ownership_tuple(face) == [2, 0, 0] }

    identity_generator.regenerate(
      owner: owner,
      state: after_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: dirty_window_plan(
        after_state,
        digest: 'digest-2',
        revision: 2,
        previous_digest: 'digest-1',
        previous_revision: 1,
        window: dirty_window(1, 1, 1, 1)
      )
    )

    assert_includes(owner.entities.faces, unchanged_face)
    assert_equal('legacy-digest', terrain_attribute(unchanged_face, 'terrainStateDigest'))
    assert_equal(1, terrain_attribute(unchanged_face, 'terrainStateRevision'))
    assert_equal(4, owner.entities.faces.count do |face|
      terrain_attribute(face, 'terrainStateDigest') == 'legacy-digest'
    end)
    assert_equal(8, owner.entities.faces.count do |face|
      terrain_attribute(face, 'terrainStateDigest').nil?
    end)
  end

  def test_partial_regenerate_falls_back_to_full_grid_for_unsafe_ownership
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    state = build_state(columns: 3, rows: 2, revision: 2)

    result = identity_generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: dirty_window_plan(
        state,
        digest: 'digest-2',
        revision: 2,
        window: dirty_window(1, 0, 1, 0)
      )
    )

    assert_equal('generated', result.fetch(:outcome))
    refute_includes(owner.entities.faces, old_face)
    assert_equal(4, owner.entities.faces.length)
    assert(owner.entities.faces.all? { |face| terrain_attribute(face, 'terrainStateDigest').nil? })
  end

  def test_partial_edge_cleanup_selects_only_edges_owned_by_affected_faces
    shared_edge = EdgeWithFaces.new
    affected_edge = EdgeWithFaces.new
    retained_face = FaceWithEdges.new([shared_edge])
    affected_a = FaceWithEdges.new([shared_edge, affected_edge])
    affected_b = FaceWithEdges.new([affected_edge])
    shared_edge.faces = [affected_a, retained_face]
    affected_edge.faces = [affected_a, affected_b]

    result = identity_generator.send(:edges_owned_only_by, [affected_a, affected_b])

    assert_equal([affected_edge], result)
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

  def test_v2_adaptive_generation_reduces_planar_faces_and_omits_grid_cell_identity
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_v2_state(columns: 5, rows: 5, elevations: Array.new(25, 2.0))

    result = identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    assert_equal('adaptive_tin', result.dig(:summary, :derivedMesh, :meshType))
    assert_operator(result.dig(:summary, :derivedMesh, :faceCount), :<, 32)
    assert_equal(2, owner.entities.faces.length)
    owner.entities.faces.each do |face|
      assert_derived_output(face)
      refute(terrain_attribute(face, 'gridCellColumn'))
      refute(terrain_attribute(face, 'gridCellRow'))
      refute(terrain_attribute(face, 'gridTriangleIndex'))
    end
  end

  def test_v2_adaptive_generation_refuses_no_data_before_emitting_faces
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_v2_state(columns: 2, rows: 2, elevations: [1.0, nil, 1.0, 1.0])

    result = identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('adaptive_output_generation_failed', result.dig(:refusal, :code))
    assert_empty(owner.entities.faces)
  end

  def test_v2_adaptive_regeneration_refuses_no_data_before_erasing_existing_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    state = build_v2_state(columns: 2, rows: 2, elevations: [1.0, nil, 1.0, 1.0])

    result = identity_generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('adaptive_output_generation_failed', result.dig(:refusal, :code))
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

  def terrain_attribute(entity, key)
    entity.get_attribute(
      SU_MCP::Terrain::TerrainMeshGenerator::DERIVED_OUTPUT_DICTIONARY,
      key
    )
  end

  def ownership_tuple(face)
    [
      terrain_attribute(face, 'gridCellColumn'),
      terrain_attribute(face, 'gridCellRow'),
      terrain_attribute(face, 'gridTriangleIndex')
    ]
  end

  def output_cell_window(min_column, min_row, max_column, max_row)
    SU_MCP::Terrain::TerrainOutputCellWindow.new(
      {
        min_column: min_column,
        min_row: min_row,
        max_column: max_column,
        max_row: max_row
      }
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

  def add_owned_face(entities, column:, row:, triangle:, digest:, revision:)
    face = entities.add_face([column, row, 0], [column + 1, row, 0], [column + 1, row + 1, 0])
    face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    face.set_attribute('su_mcp_terrain', 'outputSchemaVersion', 1)
    face.set_attribute('su_mcp_terrain', 'terrainStateDigest', digest)
    face.set_attribute('su_mcp_terrain', 'terrainStateRevision', revision)
    face.set_attribute('su_mcp_terrain', 'gridCellColumn', column)
    face.set_attribute('su_mcp_terrain', 'gridCellRow', row)
    face.set_attribute('su_mcp_terrain', 'gridTriangleIndex', triangle)
    face
  end

  def assert_seams_coherent(faces, tolerance:)
    by_coordinate = Hash.new { |hash, key| hash[key] = [] }
    faces.each do |face|
      face.points.each do |point|
        by_coordinate[[point[0], point[1]]] << point[2]
      end
    end

    by_coordinate.each_value do |z_values|
      next if z_values.length < 2

      assert_operator(
        z_values.max - z_values.min,
        :<=,
        tolerance,
        'expected shared seam vertices to have matching elevations'
      )
    end
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

  def build_state(columns:, rows:, origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
                  revision: 1, elevations: nil)
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
      elevations: elevations || Array.new(columns * rows, 1.0),
      revision: revision,
      state_id: 'terrain-state-1'
    )
  end

  def build_v2_state(columns:, rows:, elevations:)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  def dirty_window_plan(state, digest:, revision: 1, previous_digest: nil,
                        previous_revision: nil, window: nil)
    SU_MCP::Terrain::TerrainOutputPlan.dirty_window(
      state: state,
      terrain_state_summary: { digest: digest, revision: revision },
      previous_terrain_state_summary: previous_state_summary(previous_digest, previous_revision),
      window: window || SU_MCP::Terrain::SampleWindow.new(
        min_column: 0,
        min_row: 0,
        max_column: 0,
        max_row: 0
      )
    )
  end

  def previous_state_summary(digest, revision)
    return nil unless digest || revision

    {
      digest: digest,
      revision: revision
    }
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

  class FaceWithEdges
    attr_reader :edges

    def initialize(edges)
      @edges = edges
    end
  end

  class EdgeWithFaces
    attr_accessor :faces
  end
end
# rubocop:enable Metrics/AbcSize
