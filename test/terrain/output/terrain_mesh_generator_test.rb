# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/semantic_test_support'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/output/feature_output_policy_diagnostics'
require_relative '../../../src/su_mcp/terrain/output/terrain_mesh_generator'
require_relative '../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_policy'
require_relative '../../../src/su_mcp/terrain/output/cdt/patches/' \
                 'stable_domain_cdt_replacement_provider'
require_relative '../../../src/su_mcp/terrain/output/cdt/patches/stable_domain_cdt_solver'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_cell_window'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_plan'

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

  def test_batch_edge_marking_marks_shared_edges_once
    edge = CountingEdge.new
    faces = [
      FaceWithEdges.new([edge]),
      FaceWithEdges.new([edge])
    ]

    identity_generator.send(:mark_unique_derived_edges, faces)

    assert_equal(1, edge.attribute_write_count)
    assert_derived_output(edge)
    assert(edge.hidden?)
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

  def test_feature_policy_diagnostics_do_not_change_generation_for_replay_rows
    canonical_replay_non_interference_rows.each do |row|
      state = row.fetch(:state)
      policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 16)
      detached_plan = adaptive_dirty_plan(
        state,
        "detached-#{row.fetch(:row_id)}",
        policy,
        row.fetch(:window)
      )
      attached_plan = adaptive_dirty_plan(
        state,
        "attached-#{row.fetch(:row_id)}",
        policy,
        row.fetch(:window),
        feature_output_policy_diagnostics: build_feature_output_policy_diagnostics(row)
      )

      detached = generate_with_plan(state, detached_plan)
      attached = generate_with_plan(state, attached_plan)

      assert_equal(detached.fetch(:summary), attached.fetch(:summary))
      assert_equal(detached.fetch(:faces), attached.fetch(:faces))
    end
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

  def test_v2_adaptive_generation_emits_conforming_topology_for_mixed_resolution_cells
    model = build_semantic_model
    owner = model.active_entities.add_group

    identity_generator.generate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    assert_no_unsplit_emitted_axis_edges(owner.entities.faces)
  end

  def test_v2_adaptive_generation_summary_counts_match_emitted_geometry
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = mixed_resolution_v2_state

    result = identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    derived_mesh = result.fetch(:summary).fetch(:derivedMesh)
    assert_equal(owner.entities.faces.length, derived_mesh.fetch(:faceCount))
    assert_equal(
      unique_face_vertices(owner.entities.faces).length,
      derived_mesh.fetch(:vertexCount)
    )
  end

  def test_v2_adaptive_split_vertices_use_source_grid_sample_elevations
    model = build_semantic_model
    owner = model.active_entities.add_group

    identity_generator.generate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    assert_includes(unique_face_vertices(owner.entities.faces), [4.0, 2.0, 0.0])
  end

  def test_v2_adaptive_generation_marks_edges_as_hidden_derived_output
    model = build_semantic_model
    owner = model.active_entities.add_group

    identity_generator.generate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    owner.entities.faces.flat_map(&:edges).each do |edge|
      assert_derived_output(edge)
      assert_equal(true, edge.hidden?)
      refute(terrain_attribute(edge, 'gridCellColumn'))
      refute(terrain_attribute(edge, 'gridCellRow'))
      refute(terrain_attribute(edge, 'gridTriangleIndex'))
    end
  end

  def test_v2_adaptive_generation_preserves_positive_z_normals_after_split_emission
    model = build_semantic_model
    owner = model.active_entities.add_group
    force_added_faces_downward(owner.entities)

    identity_generator.generate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    assert_all_faces_point_up(owner.entities.faces)
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

  def test_v2_adaptive_regeneration_removes_prior_derived_faces_and_orphan_edges
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    old_edge = SemanticTestSupport::FakeEdge.new
    old_edge.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    owner.entities.add_edge_entity(old_edge)

    result = identity_generator.regenerate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 2 }
    )

    assert_equal('generated', result.fetch(:outcome))
    refute_includes(owner.entities.faces, old_face)
    refute_includes(owner.entities.edges, old_edge)
    assert_no_unsplit_emitted_axis_edges(owner.entities.faces)
  end

  def test_v2_adaptive_regeneration_refuses_unsupported_children_before_erasing_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    owner.entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)

    result = identity_generator.regenerate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 2 }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_contains_unsupported_entities', result.dig(:refusal, :code))
    assert_includes(owner.entities.faces, old_face)
  end

  def test_cdt_preflight_runs_before_compute_and_before_erasing_existing_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    owner.entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    cdt_backend = RecordingCdtBackend.new(status: 'accepted')

    result = generator_with_cdt(cdt_backend).regenerate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 2 },
      feature_context: { featureGeometryDigest: 'feature-digest' }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal(0, cdt_backend.calls)
    assert_includes(owner.entities.faces, old_face)
  end

  def test_accepted_cdt_emits_faces_through_existing_derived_output_conventions
    model = build_semantic_model
    owner = model.active_entities.add_group
    cdt_backend = RecordingCdtBackend.new(
      status: 'accepted',
      mesh: {
        vertices: [[0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0]],
        triangles: [[0, 1, 2]]
      }
    )

    result = generator_with_cdt(cdt_backend).regenerate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-cdt', revision: 2 },
      feature_context: { featureGeometryDigest: 'feature-digest' }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal('adaptive_tin', result.dig(:summary, :derivedMesh, :meshType))
    assert_equal(1, owner.entities.faces.length)
    assert_derived_output(owner.entities.faces.first)
    assert_all_faces_point_up(owner.entities.faces)
  end

  def test_default_cdt_backend_is_disabled_so_current_output_remains_active
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 2, rows: 2, elevations: [1.0, 2.0, 3.0, 4.0])

    result = identity_generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-default', revision: 2 },
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal('regular_grid', result.dig(:summary, :derivedMesh, :meshType))
    assert_equal(2, owner.entities.faces.length)
  end

  def test_create_generation_uses_cdt_when_feature_geometry_context_exists
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    cdt_backend = RecordingCdtBackend.new(
      status: 'accepted',
      mesh: {
        vertices: [[0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0]],
        triangles: [[0, 1, 2]]
      }
    )

    result = generator_with_cdt(cdt_backend).generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-create-cdt', revision: 1 },
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(1, cdt_backend.calls)
    assert_equal(1, owner.entities.faces.length)
    assert_equal(3, result.dig(:summary, :derivedMesh, :vertexCount))
  end

  def test_cdt_create_generation_bootstraps_lifecycle_patch_registry_and_face_ownership
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_v2_state(columns: 17, rows: 17, elevations: Array.new(289, 1.0))
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      conformance_ring: 0,
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    cdt_backend = RecordingCdtBackend.new(
      status: 'accepted',
      mesh: {
        vertices: [
          [0.0, 0.0, 1.0],
          [16.0, 0.0, 1.0],
          [16.0, 16.0, 1.0],
          [0.0, 16.0, 1.0]
        ],
        triangles: [[0, 1, 2], [0, 2, 3]]
      }
    )

    generator = generator_with_cdt(cdt_backend)
    result = generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-bootstrap', revision: 1 },
      output_plan: adaptive_full_plan(state, 'digest-cdt-bootstrap', policy),
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(2, owner.entities.faces.length)
    assert(owner.entities.faces.all? do |face|
      terrain_attribute(face, 'outputKind') == 'cdt_patch_face'
    end)
    assert_equal(
      ['cdt-patch-v1-c0-r0'],
      owner.entities.faces.map { |face| terrain_attribute(face, 'cdtPatchId') }.uniq
    )
    assert_equal(
      [0, 1],
      owner.entities.faces.map { |face| terrain_attribute(face, 'cdtPatchFaceIndex') }.sort
    )
    registry = read_cdt_registry(owner)
    assert_equal('valid', registry.fetch(:status))
    assert_equal(policy.output_policy_fingerprint, registry.fetch(:outputPolicyFingerprint))
    assert_equal('digest-cdt-bootstrap', registry.fetch(:stateDigest))
    assert_equal(1, registry.fetch(:patches).length)
    assert_equal(2, registry.fetch(:patches).first.fetch(:faceCount))
    refute_includes(JSON.generate(result), 'cdt-patch-v1')
    refute_includes(JSON.generate(result), 'adaptivePatchRegistry')
    assert_cdt_timing_buckets(
      generator,
      :cdt_input_build,
      :solve,
      :mutation,
      :registry_write,
      :audit,
      :total
    )
  end

  def test_cdt_patch_provider_bootstraps_one_owned_mesh_per_lifecycle_patch
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_v2_state(columns: 33, rows: 17, elevations: Array.new(561, 1.0))
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      conformance_ring: 0,
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    global_backend = RecordingCdtBackend.new(status: 'fallback')
    patch_backend = PatchLocalRecordingCdtBackend.new
    provider = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(
      solver: SU_MCP::Terrain::StableDomainCdtSolver.new(cdt_backend: patch_backend)
    )
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_backend: global_backend,
      cdt_patch_replacement_provider: provider,
      fallback_on_cdt_failure: false
    )

    result = generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-provider-bootstrap', revision: 1 },
      output_plan: adaptive_full_plan(state, 'digest-cdt-provider-bootstrap', policy),
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(0, global_backend.calls)
    assert_equal(2, patch_backend.calls)
    assert_equal(%w[cdt-patch-v1-c0-r0 cdt-patch-v1-c1-r0], cdt_patch_ids(owner))
    registry = read_cdt_registry(owner)
    assert_equal(2, registry.fetch(:patches).length)
    assert_equal(
      {
        'cdt-patch-v1-c0-r0' => 2,
        'cdt-patch-v1-c1-r0' => 2
      },
      registry.fetch(:patches).to_h { |patch| [patch.fetch(:patchId), patch.fetch(:faceCount)] }
    )

    rebuild = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-provider-rebuild', revision: 2 },
      output_plan: adaptive_full_plan(state, 'digest-cdt-provider-rebuild', policy),
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )

    assert_equal('generated', rebuild.fetch(:outcome))
    assert_equal(0, global_backend.calls)
    assert_equal(4, patch_backend.calls)
    assert_equal(%w[cdt-patch-v1-c0-r0 cdt-patch-v1-c1-r0], cdt_patch_ids(owner))
    assert(owner.entities.faces.all? do |face|
      terrain_attribute(face, 'outputKind') == 'cdt_patch_face'
    end)
    assert_equal('digest-cdt-provider-rebuild', read_cdt_registry(owner).fetch(:stateDigest))
  end

  def test_cdt_create_generation_records_internal_fallback_timing_before_safe_mesh_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_v2_state(columns: 17, rows: 17, elevations: Array.new(289, 1.0))
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      conformance_ring: 0,
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    cdt_backend = RecordingCdtBackend.new(
      status: 'fallback',
      fallback_reason: 'topology_gate_failed'
    )

    generator = generator_with_cdt(cdt_backend)
    result = generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-bootstrap-fallback', revision: 1 },
      output_plan: adaptive_full_plan(state, 'digest-cdt-bootstrap-fallback', policy),
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal('adaptive_tin', result.dig(:summary, :derivedMesh, :meshType))
    assert_equal(1, cdt_backend.calls)
    assert_cdt_timing_buckets(generator, :solve, :fallback_route, :audit, :total)
    refute_includes(JSON.generate(result), 'topology_gate_failed')
  end

  def test_cdt_full_regenerate_rebuilds_lifecycle_patch_registry_and_face_ownership
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    state = build_v2_state(columns: 17, rows: 17, elevations: Array.new(289, 1.0), revision: 2)
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      conformance_ring: 0,
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    cdt_backend = RecordingCdtBackend.new(
      status: 'accepted',
      mesh: {
        vertices: [
          [0.0, 0.0, 1.0],
          [16.0, 0.0, 1.0],
          [16.0, 16.0, 1.0],
          [0.0, 16.0, 1.0]
        ],
        triangles: [[0, 1, 2], [0, 2, 3]]
      }
    )

    generator = generator_with_cdt(cdt_backend)
    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-rebuild', revision: 2 },
      output_plan: adaptive_full_plan(state, 'digest-cdt-rebuild', policy),
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    refute_includes(owner.entities.faces, old_face)
    assert_equal(
      ['cdt-patch-v1-c0-r0'],
      owner.entities.faces.map { |face| terrain_attribute(face, 'cdtPatchId') }.uniq
    )
    assert_equal('valid', read_cdt_registry(owner).fetch(:status))
    assert_equal('digest-cdt-rebuild', read_cdt_registry(owner).fetch(:stateDigest))
    assert_cdt_timing_buckets(
      generator,
      :cdt_input_build,
      :solve,
      :mutation,
      :registry_write,
      :audit,
      :total
    )
  end

  def test_cdt_dirty_replacement_uses_bootstrapped_lifecycle_metadata_and_registry
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_v2_state(columns: 50, rows: 50, elevations: Array.new(2500, 1.0), revision: 1)
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      conformance_ring: 0,
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    cdt_backend = RecordingCdtBackend.new(
      status: 'accepted',
      mesh: {
        vertices: [
          [0.0, 0.0, 1.0],
          [16.0, 0.0, 1.0],
          [16.0, 16.0, 1.0],
          [0.0, 16.0, 1.0],
          [16.0, 0.0, 1.0],
          [32.0, 0.0, 1.0],
          [32.0, 16.0, 1.0],
          [16.0, 16.0, 1.0]
        ],
        triangles: [[0, 1, 2], [0, 2, 3], [4, 5, 6], [4, 6, 7]]
      }
    )
    provider = RecordingPatchReplacementProvider.accepted(
      patch_id: 'cdt-patch-v1-c0-r0',
      patch_size: 16.0
    )
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_backend: cdt_backend,
      cdt_patch_replacement_provider: provider
    )
    generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-bootstrap', revision: 1 },
      output_plan: adaptive_full_plan(state, 'digest-cdt-bootstrap', policy),
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
      }
    )
    bootstrapped_patch_faces = owner.entities.faces.select do |face|
      terrain_attribute(face, 'cdtPatchId') == 'cdt-patch-v1-c0-r0'
    end

    result = generator.regenerate(
      owner: owner,
      state: build_v2_state(columns: 17, rows: 17, elevations: Array.new(289, 2.0), revision: 2),
      terrain_state_summary: { digest: 'digest-cdt-dirty', revision: 2 },
      output_plan: adaptive_dirty_plan(
        state,
        'digest-cdt-dirty',
        policy,
        dirty_window(0, 0, 1, 1)
      ),
      feature_context: {
        terrainState: state,
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'eligible' }
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(2, provider.calls)
    bootstrapped_patch_faces.each { |face| refute_includes(owner.entities.faces, face) }
    replacement_faces = owner.entities.faces.select do |face|
      terrain_attribute(face, 'cdtPatchId') == 'cdt-patch-v1-c0-r0'
    end
    assert_equal(
      [0, 1],
      replacement_faces.map { |face| terrain_attribute(face, 'cdtPatchFaceIndex') }.sort
    )
    registry = read_cdt_registry(owner)
    assert_equal('digest-cdt-dirty', registry.fetch(:stateDigest))
    replaced_record = registry.fetch(:patches).find do |patch|
      patch.fetch(:patchId) == 'cdt-patch-v1-c0-r0'
    end
    assert_equal(2, replaced_record.fetch(:faceCount))
    assert(
      provider.last_batch_plan.retained_boundary_spans.any? do |span|
        span.fetch(:patchId) == 'cdt-patch-v1-c1-r0' && span.fetch(:side) == 'west'
      end,
      'dirty replacement should receive retained spans from adjacent bootstrap CDT patches'
    )
    refute_includes(JSON.generate(result), 'cdt-patch-v1')
  end

  def test_cdt_fallback_selects_current_backend_before_erasing_existing_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    cdt_backend = RecordingCdtBackend.new(
      status: 'fallback',
      fallback_reason: 'point_budget_exceeded'
    )

    result = generator_with_cdt(cdt_backend).regenerate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-current', revision: 2 },
      feature_context: { featureGeometryDigest: 'feature-digest' }
    )

    assert_equal('generated', result.fetch(:outcome))
    refute_includes(owner.entities.faces, old_face)
    refute_includes(JSON.generate(result), 'point_budget_exceeded')
  end

  def test_cdt_backend_exception_selects_current_backend_without_leaking_internal_error
    model = build_semantic_model
    owner = model.active_entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)

    result = generator_with_cdt(RaisingCdtBackend.new).regenerate(
      owner: owner,
      state: mixed_resolution_v2_state,
      terrain_state_summary: { digest: 'digest-current', revision: 2 },
      feature_context: { featureGeometryDigest: 'feature-digest' }
    )

    assert_equal('generated', result.fetch(:outcome))
    refute_includes(owner.entities.faces, old_face)
    refute_includes(JSON.generate(result), 'boom')
    refute_includes(JSON.generate(result), 'RaisingCdtBackend')
  end

  def test_cdt_feature_geometry_can_accept_full_regeneration_from_dirty_window_plan
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    cdt_backend = RecordingCdtBackend.new(
      status: 'accepted',
      mesh: {
        vertices: [[0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0]],
        triangles: [[0, 1, 2]]
      }
    )

    result = generator_with_cdt(cdt_backend).regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-cdt-feature-window', revision: 2 },
      output_plan: dirty_window_plan(state, digest: 'digest-cdt-feature-window',
                                            window: dirty_window(0, 0, 1, 1)),
      feature_context: { featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal('adaptive_tin', result.dig(:summary, :derivedMesh, :meshType))
    assert_equal(1, cdt_backend.calls)
    refute_includes(owner.entities.faces, old_face)
  end

  def test_strict_cdt_mode_refuses_without_rendering_adaptive_fallback
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    cdt_backend = RecordingCdtBackend.new(status: 'fallback')
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_backend: cdt_backend,
      fallback_on_cdt_failure: false
    )

    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-strict-cdt', revision: 2 },
      output_plan: dirty_window_plan(
        state,
        digest: 'digest-strict-cdt',
        window: dirty_window(0, 0, 1, 1)
      ),
      feature_context: { featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_generation_failed', result.dig(:refusal, :code))
    assert_equal(1, cdt_backend.calls)
    assert_equal('not_accepted', generator.last_cdt_failure_reason)
    assert_empty(owner.entities.faces)
    refute_includes(JSON.generate(result), 'cdt')
    refute_includes(JSON.generate(result), 'fallback')
  end

  def test_cdt_participation_skip_uses_current_output_path_without_calling_cdt_backend
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 }
    )
    cdt_backend = RecordingCdtBackend.new(status: 'accepted')

    result = generator_with_cdt(cdt_backend).regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: dirty_window_plan(state, digest: 'digest-2', window: dirty_window(0, 0, 1, 1)),
      feature_context: {
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'skip' },
        featureSelectionDiagnostics: {
          cdtFallbackTriggers: { patch_relevant_feature_geometry_failed: 1 }
        }
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(0, cdt_backend.calls)
    assert_equal('regular_grid', result.dig(:summary, :derivedMesh, :meshType))
    refute_includes(JSON.generate(result), 'patch_relevant_feature_geometry_failed')
  end

  def test_strict_cdt_mode_refuses_when_cdt_is_ineligible_instead_of_rendering_adaptive
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 }
    )
    original_face_count = owner.entities.faces.length
    cdt_backend = RecordingCdtBackend.new(status: 'accepted')
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_backend: cdt_backend,
      fallback_on_cdt_failure: false
    )

    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: dirty_window_plan(state, digest: 'digest-2', window: dirty_window(0, 0, 1, 1)),
      feature_context: {
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'skip' },
        featureSelectionDiagnostics: {
          cdtFallbackTriggers: { patch_relevant_feature_geometry_failed: 1 }
        }
      }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_generation_failed', result.dig(:refusal, :code))
    assert_equal(0, cdt_backend.calls)
    assert_equal(original_face_count, owner.entities.faces.length)
    refute_includes(JSON.generate(result), 'patch_relevant_feature_geometry_failed')
  end

  def test_dirty_window_cdt_patch_replacement_replaces_only_owned_patch_faces
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = cdt_patch_state(revision: 2)
    patch_id = 'cdt-patch-v1-c0-r0'
    old_patch_face = add_owned_cdt_patch_face(
      owner.entities,
      patch_id: patch_id,
      face_index: 0,
      points: [[0.0, 0.0, 1.0], [16.0, 0.0, 1.0], [16.0, 16.0, 1.0]]
    )
    preserved_neighbor = add_owned_cdt_patch_face(
      owner.entities,
      patch_id: 'cdt-patch-v1-c1-r0',
      face_index: 0,
      border_side: 'west',
      points: [[16.0, 0.0, 1.0], [32.0, 0.0, 1.0], [16.0, 16.0, 1.0]]
    )
    write_cdt_registry(owner, patch_id: patch_id, face_count: 1)
    provider = RecordingPatchReplacementProvider.accepted(patch_id: patch_id, patch_size: 16.0)

    plan = cdt_dirty_window_plan(state, digest: 'digest-2')

    generator = generator_with_patch_provider(provider)
    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: plan,
      feature_context: {
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'eligible' }
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(1, provider.calls)
    refute_includes(owner.entities.faces, old_patch_face)
    assert(owner.entities.faces.any? { |face| face.equal?(preserved_neighbor) })
    assert_equal(3, owner.entities.faces.length)
    replacement_faces = owner.entities.faces.reject { |face| face.equal?(preserved_neighbor) }
    assert(replacement_faces.all? do |face|
      terrain_attribute(face, 'outputKind') == 'cdt_patch_face'
    end)
    assert(replacement_faces.all? do |face|
      terrain_attribute(face, 'cdtPatchId') == patch_id
    end)
    registry = read_cdt_registry(owner)
    patch_record = registry.fetch(:patches).find { |patch| patch.fetch(:patchId) == patch_id }
    assert_equal('new-batch', patch_record.fetch(:replacementBatchId))
    assert_equal(2, patch_record.fetch(:faceCount))
    assert_equal('digest-2', registry.fetch(:stateDigest))
    refute_includes(JSON.generate(replacement_faces.map(&:attributes)), 'patch-a')
    refute_includes(JSON.generate(result), 'local_patch_replacement')
    refute_includes(JSON.generate(result), 'seam')
    assert_cdt_timing_buckets(
      generator,
      :cdt_input_build,
      :retained_boundary_snapshot,
      :solve,
      :topology_validation,
      :ownership_lookup,
      :seam_validation,
      :mutation,
      :registry_write,
      :audit,
      :total
    )
  end

  def test_dirty_window_cdt_patch_replacement_falls_back_without_provider_for_skip
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    identity_generator.generate(owner: owner, state: state,
                                terrain_state_summary: { digest: 'digest-1', revision: 1 })
    provider = RecordingPatchReplacementProvider.accepted(domain_digest: 'patch-a')

    generator = generator_with_patch_provider(provider)
    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: dirty_window_plan(state, digest: 'digest-2', window: dirty_window(0, 0, 1, 1)),
      feature_context: {
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'skip' }
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(0, provider.calls)
    assert_equal('regular_grid', result.dig(:summary, :derivedMesh, :meshType))
  end

  def test_dirty_window_cdt_patch_replacement_falls_back_for_incomplete_result
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = cdt_patch_state(revision: 2)
    patch_id = 'cdt-patch-v1-c0-r0'
    old_patch_face = add_owned_cdt_patch_face(
      owner.entities,
      patch_id: patch_id,
      face_index: 0
    )
    write_cdt_registry(owner, patch_id: patch_id, face_count: 1)
    provider = RecordingPatchReplacementProvider.failed('patch_result_incomplete')

    generator = generator_with_patch_provider(provider)
    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: cdt_dirty_window_plan(state, digest: 'digest-2'),
      feature_context: {
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'eligible' }
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    refute_includes(owner.entities.faces, old_patch_face)
    assert_equal('adaptive_tin', result.dig(:summary, :derivedMesh, :meshType))
    refute_includes(JSON.generate(result), 'patch_result_incomplete')
    assert_cdt_timing_buckets(generator, :fallback_route, :audit, :total)
  end

  def test_dirty_window_cdt_patch_replacement_refuses_duplicate_ownership_without_erasing
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = cdt_patch_state(revision: 2)
    patch_id = 'cdt-patch-v1-c0-r0'
    first = add_owned_cdt_patch_face(owner.entities, patch_id: patch_id, face_index: 0)
    second = add_owned_cdt_patch_face(owner.entities, patch_id: patch_id, face_index: 0)
    write_cdt_registry(owner, patch_id: patch_id, face_count: 2)
    provider = RecordingPatchReplacementProvider.accepted(patch_id: patch_id)

    plan = cdt_dirty_window_plan(state, digest: 'digest-2')

    generator = generator_with_patch_provider(provider)
    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: plan,
      feature_context: {
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'eligible' }
      }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_ownership_invalid', result.dig(:refusal, :code))
    assert_includes(owner.entities.faces, first)
    assert_includes(owner.entities.faces, second)
  end

  def test_dirty_window_cdt_patch_replacement_falls_back_for_seam_mismatch
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = cdt_patch_state(revision: 2)
    patch_id = 'cdt-patch-v1-c0-r0'
    add_owned_cdt_patch_face(owner.entities, patch_id: patch_id, face_index: 0)
    add_owned_cdt_patch_face(
      owner.entities,
      patch_id: 'cdt-patch-v1-c1-r0',
      face_index: 0,
      border_side: 'west',
      points: [[2.0, 0.0, 1.0], [4.0, 0.0, 1.0], [2.0, 2.0, 2.0]]
    )
    write_cdt_registry(owner, patch_id: patch_id, face_count: 1)
    provider = RecordingPatchReplacementProvider.accepted(patch_id: patch_id)

    generator = generator_with_patch_provider(provider)
    result = generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: cdt_dirty_window_plan(state, digest: 'digest-2'),
      feature_context: {
        featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
        cdtParticipation: { status: 'eligible' }
      }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal('adaptive_tin', result.dig(:summary, :derivedMesh, :meshType))
    refute_includes(JSON.generate(result), 'seam_mismatch')
    assert_cdt_timing_buckets(generator, :fallback_route, :audit, :total)
  end

  def test_dirty_window_cdt_patch_replacement_raises_mutation_failure_after_erase_begins
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = cdt_patch_state(revision: 2)
    patch_id = 'cdt-patch-v1-c0-r0'
    old_patch_face = add_owned_cdt_patch_face(
      owner.entities,
      patch_id: patch_id,
      face_index: 0
    )
    write_cdt_registry(owner, patch_id: patch_id, face_count: 1)
    provider = RecordingPatchReplacementProvider.accepted(patch_id: patch_id)
    raise_once_on_next_face_add(owner.entities)

    assert_raises(RuntimeError) do
      generator_with_patch_provider(provider).regenerate(
        owner: owner,
        state: state,
        terrain_state_summary: { digest: 'digest-2', revision: 2 },
        output_plan: cdt_dirty_window_plan(state, digest: 'digest-2'),
        feature_context: {
          featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
          cdtParticipation: { status: 'eligible' }
        }
      )
    end
    refute_includes(
      owner.entities.faces,
      old_patch_face,
      'local fake entities cannot roll back, but the exception must reach the SketchUp operation'
    )
  end

  def test_cdt_neighbor_snapshots_convert_sketchup_internal_points_to_public_meters
    face = FaceWithVertices.new(
      vertices: [
        PointObject.new(20.0, 0.0, 10.0),
        PointObject.new(20.0, 20.0, 10.0),
        PointObject.new(30.0, 20.0, 10.0)
      ]
    )
    face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    face.set_attribute('su_mcp_terrain', 'outputKind', 'cdt_patch_face')
    face.set_attribute('su_mcp_terrain', 'cdtOwnershipSchemaVersion', 1)
    face.set_attribute('su_mcp_terrain', 'cdtPatchId', 'cdt-patch-v1-c1-r0')
    face.set_attribute('su_mcp_terrain', 'cdtReplacementBatchId', 'batch')
    face.set_attribute('su_mcp_terrain', 'cdtPatchFaceIndex', 0)
    face.set_attribute('su_mcp_terrain', 'cdtBorderSide', 'west')
    entities = EntityList.new([face])
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 10.0)
    )

    spans = generator.send(:preserved_cdt_neighbor_spans, entities, ['cdt-patch-v1-c0-r0'])

    assert_equal([[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]], spans.first.fetch(:vertices))
  end

  def test_cdt_neighbor_snapshots_merge_face_fragments_into_ordered_patch_side_span
    faces = [
      FaceWithVertices.new(
        vertices: [
          PointObject.new(20.0, 0.0, 10.0),
          PointObject.new(20.0, 10.0, 11.0),
          PointObject.new(30.0, 10.0, 11.0)
        ]
      ),
      FaceWithVertices.new(
        vertices: [
          PointObject.new(20.0, 10.0, 11.0),
          PointObject.new(20.0, 20.0, 12.0),
          PointObject.new(30.0, 20.0, 12.0)
        ]
      )
    ]
    faces.each_with_index do |face, index|
      mark_cdt_neighbor_face(
        face,
        patch_id: 'cdt-patch-v1-c1-r0',
        side: 'west',
        face_index: index
      )
    end
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 10.0)
    )

    spans = generator.send(
      :preserved_cdt_neighbor_spans,
      EntityList.new(faces),
      ['cdt-patch-v1-c0-r0']
    )

    assert_equal(1, spans.length)
    assert_equal(
      [[2.0, 0.0, 1.0], [2.0, 1.0, 1.1], [2.0, 2.0, 1.2]],
      spans.first.fetch(:vertices)
    )
  end

  def test_cdt_neighbor_snapshots_include_lifecycle_side_endpoints
    face = FaceWithVertices.new(
      vertices: [
        PointObject.new(20.0, 10.0, 11.0),
        PointObject.new(20.0, 20.0, 12.0),
        PointObject.new(30.0, 20.0, 12.0)
      ]
    )
    mark_cdt_neighbor_face(
      face,
      patch_id: 'cdt-patch-v1-c1-r0',
      side: 'west',
      face_index: 0
    )
    generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 10.0)
    )
    state = build_state(
      columns: 5,
      rows: 3,
      elevations: [
        0.0, 0.1, 1.0, 0.3, 0.4,
        0.5, 0.6, 1.1, 0.8, 0.9,
        1.0, 1.1, 1.2, 1.3, 1.4
      ]
    )
    patch_domains = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_cell_size: 2,
      patch_id_prefix: 'cdt-patch'
    ).patch_domains(state.dimensions)

    spans = generator.send(
      :preserved_cdt_neighbor_spans,
      EntityList.new([face]),
      ['cdt-patch-v1-c0-r0'],
      state: state,
      patch_domains: patch_domains
    )

    assert_equal(1, spans.length)
    assert_equal(
      [[2.0, 0.0, 1.0], [2.0, 1.0, 1.1], [2.0, 2.0, 1.2]],
      spans.first.fetch(:vertices)
    )
  end

  def test_cdt_is_not_used_for_dirty_window_partial_regeneration
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 }
    )
    cdt_backend = RecordingCdtBackend.new(status: 'accepted')

    result = generator_with_cdt(cdt_backend).regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: dirty_window_plan(state, digest: 'digest-2', window: dirty_window(0, 0, 0, 0)),
      feature_context: { featureGeometryDigest: 'feature-digest' }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(0, cdt_backend.calls)
  end

  def test_malformed_feature_geometry_does_not_enable_dirty_window_cdt
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_state(columns: 3, rows: 3, revision: 1)
    identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 }
    )
    cdt_backend = RecordingCdtBackend.new(status: 'accepted')

    result = generator_with_cdt(cdt_backend).regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: dirty_window_plan(state, digest: 'digest-2', window: dirty_window(0, 0, 0, 0)),
      feature_context: { featureGeometry: {} }
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(0, cdt_backend.calls)
  end

  def test_v2_adaptive_generation_bootstraps_single_mesh_registry_and_face_ownership
    model = build_semantic_model
    owner = model.active_entities.add_group
    state = build_v2_state(columns: 9, rows: 9, elevations: hill_elevations(9, amplitude: 0.3))
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)

    result = identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 },
      output_plan: adaptive_full_plan(state, 'digest-v2', policy)
    )

    assert_equal('generated', result.fetch(:outcome))
    assert_equal(1, owner.entities.groups.length)
    mesh = owner.entities.groups.first
    assert_equal('adaptive_patch_mesh', terrain_attribute(mesh, 'outputKind'))
    refute(terrain_attribute(mesh, 'adaptivePatchId'))
    assert_equal('digest-v2', terrain_attribute(mesh, 'terrainStateDigest'))
    mesh.entities.faces.each do |face|
      assert_equal('adaptive_patch_face', terrain_attribute(face, 'outputKind'))
      assert(terrain_attribute(face, 'adaptivePatchId'))
      assert(terrain_attribute(face, 'adaptivePatchFaceIndex'))
    end
    assert_instance_of(String, owner.get_attribute('su_mcp_terrain', 'adaptivePatchRegistry'))
    refute_internal_output_fields(result)
  end

  def test_v2_adaptive_patch_planning_reuses_projected_vertices
    state = build_v2_state(columns: 2, rows: 2, elevations: [0.0, 0.1, 0.2, 0.3])
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 1)
    output_plan = Struct.new(
      :adaptive_cells,
      :state_digest,
      :adaptive_patch_policy
    ).new(
      [
        {
          min_column: 0,
          min_row: 0,
          max_column: 1,
          max_row: 1,
          emission_triangles: [
            [[0, 0], [1, 0], [1, 1]],
            [[0, 0], [1, 1], [0, 1]]
          ]
        }
      ],
      'digest-v2',
      policy
    )
    patch = {
      patchId: 'adaptive-patch-v1-c0-r0',
      bounds: {},
      cell_bounds: { min_column: 0, min_row: 0, max_column: 0, max_row: 0 }
    }
    generator = CountingAdaptiveVertexGenerator.new

    planned = generator.send(
      :planned_adaptive_patch_batch,
      state: state,
      output_plan: output_plan,
      patches: [patch]
    )

    assert_equal(2, planned.fetch(:faces).length)
    assert_equal(4, generator.adaptive_vertex_call_count)
  end

  def test_v2_adaptive_patch_face_count_uses_sketchup_entities_enumeration
    model = build_semantic_model
    owner = model.active_entities.add_group
    face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [0, 1, 0])
    host_like_entities = Class.new do
      include Enumerable

      def initialize(entities)
        @entities = entities
      end

      def each(&block)
        @entities.each(&block)
      end
    end.new([face])

    assert_equal([face], identity_generator.send(:entity_faces, host_like_entities))
  end

  def test_v2_adaptive_dirty_window_replaces_only_affected_logical_patch_faces
    model = build_semantic_model
    owner = model.active_entities.add_group
    before_state = build_v2_state(columns: 17, rows: 17, elevations: Array.new(289, 1.0))
    after_state = build_v2_state(
      columns: 17,
      rows: 17,
      elevations: hill_elevations(17, amplitude: 0.2)
    )
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    identity_generator.generate(
      owner: owner,
      state: before_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      output_plan: adaptive_full_plan(before_state, 'digest-1', policy)
    )
    mesh = owner.entities.groups.first
    preserved = mesh.entities.faces.find do |face|
      adaptive_patch_id(face) == 'adaptive-patch-v1-c3-r0'
    end

    identity_generator.regenerate(
      owner: owner,
      state: after_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(after_state, 'digest-2', policy, dirty_window(1, 1, 1, 1))
    )

    assert_equal([mesh], owner.entities.groups)
    assert_includes(mesh.entities.faces, preserved)
    assert(mesh.entities.faces.any? do |face|
      adaptive_patch_id(face) == 'adaptive-patch-v1-c0-r0' &&
        terrain_attribute(face, 'terrainStateDigest') == 'digest-2'
    end)
    assert_equal(mesh.entities.faces.length, terrain_attribute(mesh, 'faceCount'))
    assert_equal(16, adaptive_registry(owner).fetch(:patches).length)
  end

  def test_v2_adaptive_dirty_window_fallback_rebuilds_full_mesh_for_legacy_regular_output
    model = build_semantic_model
    owner = model.active_entities.add_group
    legacy_state = build_state(columns: 17, rows: 17, elevations: Array.new(289, 1.0))
    migrated_state = build_v2_state(
      columns: 17,
      rows: 17,
      elevations: hill_elevations(17, amplitude: 0.2),
      revision: 2
    )
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    identity_generator.generate(
      owner: owner,
      state: legacy_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 }
    )

    result = identity_generator.regenerate(
      owner: owner,
      state: migrated_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(
        migrated_state,
        'digest-2',
        policy,
        dirty_window(1, 1, 1, 1)
      )
    )

    assert_equal('generated', result.fetch(:outcome))
    mesh = owner.entities.groups.first
    assert_equal([mesh], owner.entities.groups)
    assert_equal('adaptive_patch_mesh', terrain_attribute(mesh, 'outputKind'))
    xs = mesh.entities.faces.flat_map { |face| face.points.map { |point| point[0] } }
    ys = mesh.entities.faces.flat_map { |face| face.points.map { |point| point[1] } }
    assert_equal(0.0, xs.min)
    assert_equal(16.0, xs.max)
    assert_equal(0.0, ys.min)
    assert_equal(16.0, ys.max)
    assert_equal(16, adaptive_registry(owner).fetch(:patches).length)
  end

  def test_v2_adaptive_dirty_window_refuses_unsupported_child_inside_mesh_before_erasing
    model = build_semantic_model
    owner = model.active_entities.add_group
    before_state = build_v2_state(columns: 9, rows: 9, elevations: Array.new(81, 1.0))
    after_state = build_v2_state(
      columns: 9,
      rows: 9,
      elevations: hill_elevations(9, amplitude: 0.2)
    )
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    identity_generator.generate(
      owner: owner,
      state: before_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      output_plan: adaptive_full_plan(before_state, 'digest-1', policy)
    )
    mesh = owner.entities.groups.first
    old_faces = mesh.entities.faces.dup
    unsupported = mesh.entities.add_cpoint([0.0, 0.0, 0.0])

    result = identity_generator.regenerate(
      owner: owner,
      state: after_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(after_state, 'digest-2', policy, dirty_window(1, 1, 1, 1))
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_contains_unsupported_entities', result.dig(:refusal, :code))
    old_faces.each { |face| assert_includes(mesh.entities.faces, face) }
    assert_includes(mesh.entities.construction_points, unsupported)
  end

  def test_v2_adaptive_dirty_window_refuses_duplicate_face_index_before_erasing
    model = build_semantic_model
    owner = model.active_entities.add_group
    before_state = build_v2_state(columns: 9, rows: 9, elevations: Array.new(81, 1.0))
    after_state = build_v2_state(
      columns: 9,
      rows: 9,
      elevations: hill_elevations(9, amplitude: 0.2),
      revision: 2
    )
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    identity_generator.generate(
      owner: owner,
      state: before_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      output_plan: adaptive_full_plan(before_state, 'digest-1', policy)
    )
    mesh = owner.entities.groups.first
    patch_faces = mesh.entities.faces.select do |face|
      adaptive_patch_id(face) == 'adaptive-patch-v1-c0-r0'
    end
    patch_faces.fetch(1).set_attribute(
      'su_mcp_terrain',
      'adaptivePatchFaceIndex',
      terrain_attribute(patch_faces.fetch(0), 'adaptivePatchFaceIndex')
    )
    old_faces = mesh.entities.faces.dup

    result = identity_generator.regenerate(
      owner: owner,
      state: after_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(after_state, 'digest-2', policy, dirty_window(1, 1, 1, 1))
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_ownership_invalid', result.dig(:refusal, :code))
    old_faces.each { |face| assert_includes(mesh.entities.faces, face) }
    assert_equal(1, terrain_attribute(mesh, 'terrainStateRevision'))
  end

  def test_v2_adaptive_dirty_window_refuses_registry_face_count_mismatch_before_erasing
    model = build_semantic_model
    owner = model.active_entities.add_group
    before_state = build_v2_state(columns: 9, rows: 9, elevations: Array.new(81, 1.0))
    after_state = build_v2_state(
      columns: 9,
      rows: 9,
      elevations: hill_elevations(9, amplitude: 0.2),
      revision: 2
    )
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    identity_generator.generate(
      owner: owner,
      state: before_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      output_plan: adaptive_full_plan(before_state, 'digest-1', policy)
    )
    registry = adaptive_registry(owner)
    registry.fetch(:patches).find do |patch|
      patch.fetch(:patchId) == 'adaptive-patch-v1-c0-r0'
    end[:faceCount] += 1
    owner.set_attribute('su_mcp_terrain', 'adaptivePatchRegistry', JSON.generate(registry))
    mesh = owner.entities.groups.first
    old_faces = mesh.entities.faces.dup

    result = identity_generator.regenerate(
      owner: owner,
      state: after_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(after_state, 'digest-2', policy, dirty_window(1, 1, 1, 1))
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_ownership_invalid', result.dig(:refusal, :code))
    old_faces.each { |face| assert_includes(mesh.entities.faces, face) }
    assert_equal(1, terrain_attribute(mesh, 'terrainStateRevision'))
  end

  def test_v2_adaptive_repeated_edits_use_newly_emitted_patch_metadata
    model = build_semantic_model
    owner = model.active_entities.add_group
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    first_state = build_v2_state(columns: 9, rows: 9, elevations: Array.new(81, 1.0))
    second_state = build_v2_state(columns: 9, rows: 9,
                                  elevations: hill_elevations(9, amplitude: 0.2),
                                  revision: 2)
    third_state = build_v2_state(columns: 9, rows: 9,
                                 elevations: hill_elevations(9, amplitude: 0.3),
                                 revision: 3)

    identity_generator.generate(
      owner: owner,
      state: first_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      output_plan: adaptive_full_plan(first_state, 'digest-1', policy)
    )
    identity_generator.regenerate(
      owner: owner,
      state: second_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(second_state, 'digest-2', policy, dirty_window(1, 1, 1, 1))
    )
    identity_generator.regenerate(
      owner: owner,
      state: third_state,
      terrain_state_summary: { digest: 'digest-3', revision: 3 },
      output_plan: adaptive_dirty_plan(third_state, 'digest-3', policy, dirty_window(2, 1, 2, 1))
    )

    mesh = owner.entities.groups.first
    rebuilt = mesh.entities.faces.select do |face|
      adaptive_patch_id(face) == 'adaptive-patch-v1-c0-r0'
    end
    refute_empty(rebuilt)
    assert(rebuilt.all? { |face| terrain_attribute(face, 'terrainStateDigest') == 'digest-3' })
    assert_equal(
      rebuilt.length,
      rebuilt.map { |face| terrain_attribute(face, 'adaptivePatchFaceIndex') }.uniq.length
    )
    assert_equal(3, terrain_attribute(mesh, 'terrainStateRevision'))
  end

  def test_v2_adaptive_local_failure_preserves_old_output_until_safe_fallback
    model = build_semantic_model
    owner = model.active_entities.add_group
    owner.entities.add_group
    old_face = owner.entities.add_face([0, 0, 1], [1, 0, 1], [1, 1, 1])
    old_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    state = build_v2_state(columns: 9, rows: 9, elevations: Array.new(81, 1.0))

    result = identity_generator.regenerate(
      owner: owner,
      state: state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(state, 'digest-2', policy, dirty_window(1, 1, 1, 1))
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_includes(owner.entities.faces, old_face)
    refute_includes(JSON.generate(result), 'adaptive-patch-v1')
  end

  def test_v2_adaptive_replacement_does_not_rewrite_unaffected_face_metadata
    model = build_semantic_model
    owner = model.active_entities.add_group
    before_state = build_v2_state(columns: 17, rows: 17, elevations: Array.new(289, 1.0))
    after_state = build_v2_state(columns: 17, rows: 17,
                                 elevations: hill_elevations(17, amplitude: 0.2))
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(patch_cell_size: 4)
    identity_generator.generate(
      owner: owner,
      state: before_state,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      output_plan: adaptive_full_plan(before_state, 'digest-1', policy)
    )
    mesh = owner.entities.groups.first
    preserved_face = mesh.entities.faces.find do |face|
      adaptive_patch_id(face) == 'adaptive-patch-v1-c3-r0'
    end
    preserved_face.set_attribute('su_mcp_terrain', 'sentinelRetainedMetadata', 'unchanged')

    identity_generator.regenerate(
      owner: owner,
      state: after_state,
      terrain_state_summary: { digest: 'digest-2', revision: 2 },
      output_plan: adaptive_dirty_plan(after_state, 'digest-2', policy, dirty_window(1, 1, 1, 1))
    )

    assert_equal('unchanged', terrain_attribute(preserved_face, 'sentinelRetainedMetadata'))
    assert_equal('digest-1', terrain_attribute(preserved_face, 'terrainStateDigest'))
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

  def adaptive_patch_id(face)
    terrain_attribute(face, 'adaptivePatchId')
  end

  def adaptive_registry(owner)
    JSON.parse(
      owner.get_attribute('su_mcp_terrain', 'adaptivePatchRegistry'),
      symbolize_names: true
    )
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

  def assert_no_unsplit_emitted_axis_edges(faces)
    vertices = unique_face_vertices(faces)
    emitted_axis_edges(faces).each do |from, to|
      interior = vertices.find { |point| point_strictly_inside_axis_edge?(point, from, to) }
      refute(interior, "expected emitted edge #{from.inspect}->#{to.inspect} to be split")
    end
  end

  def unique_face_vertices(faces)
    faces.flat_map(&:points).uniq
  end

  def emitted_axis_edges(faces)
    faces.flat_map do |face|
      points = face.points
      points.zip(points.rotate).select do |from, to|
        same_xy_axis?(from, to)
      end
    end
  end

  def same_xy_axis?(from, to)
    from[0] == to[0] || from[1] == to[1]
  end

  def point_strictly_inside_axis_edge?(point, from, to)
    return false if point == from || point == to

    return point[1] == from[1] && strictly_between?(point[0], from[0], to[0]) if from[1] == to[1]

    point[0] == from[0] && strictly_between?(point[1], from[1], to[1])
  end

  def strictly_between?(value, first, second)
    value > [first, second].min && value < [first, second].max
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

  def generator_with_cdt(cdt_backend)
    SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_backend: cdt_backend
    )
  end

  def generator_with_patch_provider(provider)
    SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_patch_replacement_provider: provider
    )
  end

  def assert_cdt_timing_buckets(generator, *expected_buckets)
    buckets = generator.last_cdt_patch_timing.fetch(:buckets)
    expected_buckets.each do |bucket|
      assert(buckets.key?(bucket), "missing #{bucket} timing bucket")
    end
  end

  def add_owned_cdt_patch_face(entities, face_index:, patch_id:, points: nil,
                               border_side: 'east')
    face = entities.add_face(*(points || [[0.0, 0.0, 1.0], [2.0, 0.0, 1.0], [2.0, 2.0, 1.0]]))
    face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    face.set_attribute('su_mcp_terrain', 'outputKind', 'cdt_patch_face')
    face.set_attribute('su_mcp_terrain', 'cdtOwnershipSchemaVersion', 1)
    face.set_attribute('su_mcp_terrain', 'cdtPatchId', patch_id)
    face.set_attribute('su_mcp_terrain', 'cdtReplacementBatchId', 'old-batch')
    face.set_attribute('su_mcp_terrain', 'cdtPatchFaceIndex', face_index)
    face.set_attribute('su_mcp_terrain', 'cdtBorderSide', border_side)
    face.set_attribute('su_mcp_terrain', 'cdtBorderSpanId', "#{border_side}-0")
    face
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

  def raise_once_on_next_face_add(entities)
    original_add_face = entities.method(:add_face)
    raised = false
    entities.define_singleton_method(:add_face) do |*points|
      unless raised
        raised = true
        raise 'replacement emit failed'
      end

      original_add_face.call(*points)
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

  def build_v2_state(columns:, rows:, elevations:, revision: 1)
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
      revision: revision,
      state_id: 'terrain-state-1'
    )
  end

  def mixed_resolution_v2_state
    build_v2_state(
      columns: 6,
      rows: 6,
      elevations: [
        0.0, 0.0, 0.0, 0.05, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.05,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.05, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.1, 0.0
      ]
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

  def adaptive_full_plan(state, digest, policy)
    SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: state,
      terrain_state_summary: { digest: digest, revision: state.revision },
      adaptive_patch_policy: policy
    )
  end

  def adaptive_dirty_plan(state, digest, policy, window, feature_output_policy_diagnostics: nil)
    options = {
      state: state,
      terrain_state_summary: { digest: digest, revision: state.revision },
      window: window,
      adaptive_patch_policy: policy
    }
    if feature_output_policy_diagnostics
      options[:feature_output_policy_diagnostics] = feature_output_policy_diagnostics
    end
    SU_MCP::Terrain::TerrainOutputPlan.dirty_window(**options)
  end

  def canonical_replay_non_interference_rows
    state = build_v2_state(
      columns: 49,
      rows: 49,
      elevations: Array.new(49 * 49) do |index|
        column = index % 49
        row = index / 49
        (Math.sin(column / 5.0) * 0.08) + (Math.cos(row / 6.0) * 0.05)
      end
    )
    [
      {
        row_id: 'target-local-center',
        state: state,
        window: SU_MCP::Terrain::SampleWindow.new(
          min_column: 20,
          min_row: 20,
          max_column: 28,
          max_row: 28
        )
      },
      {
        row_id: 'corridor-diagonal-intersect',
        state: state,
        window: SU_MCP::Terrain::SampleWindow.new(
          min_column: 16,
          min_row: 16,
          max_column: 34,
          max_row: 34
        )
      }
    ]
  end

  def build_feature_output_policy_diagnostics(row)
    window = row.fetch(:window)
    SU_MCP::Terrain::FeatureOutputPolicyDiagnostics.new(
      selection_window: window,
      selected_features: [
        replay_feature('feature-target', 'target_region', 'soft', window),
        replay_feature('feature-corridor', 'linear_corridor', 'firm', window)
      ],
      affected_window: {
        'min' => { 'column' => window.min_column, 'row' => window.min_row },
        'max' => { 'column' => window.max_column, 'row' => window.max_row }
      },
      adaptive_patch_policy: SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(
        patch_cell_size: 16
      )
    )
  end

  def replay_feature(id, kind, strength, window)
    {
      'id' => id,
      'kind' => kind,
      'strengthClass' => strength,
      'affectedWindow' => {
        'min' => { 'column' => window.min_column, 'row' => window.min_row },
        'max' => { 'column' => window.max_column, 'row' => window.max_row }
      }
    }
  end

  def generate_with_plan(state, plan)
    model = build_semantic_model
    owner = model.active_entities.add_group
    result = identity_generator.generate(
      owner: owner,
      state: state,
      terrain_state_summary: {
        digest: plan.state_digest,
        revision: state.revision
      },
      output_plan: plan
    )
    {
      summary: result.fetch(:summary).merge(
        derivedMesh: result.fetch(:summary).fetch(:derivedMesh).reject do |key, _value|
          key == :derivedFromStateDigest
        end
      ),
      faces: owner.entities.faces.map(&:points).sort
    }
  end

  def cdt_patch_state(revision:)
    build_v2_state(
      columns: 50,
      rows: 50,
      elevations: Array.new(2500, 1.0),
      revision: revision
    )
  end

  def cdt_dirty_window_plan(state, digest:)
    adaptive_dirty_plan(
      state,
      digest,
      SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
        conformance_ring: 0,
        patch_id_prefix: 'cdt-patch',
        fingerprint_kind: 'cdt-patch'
      ),
      dirty_window(0, 0, 1, 1)
    )
  end

  def write_cdt_registry(owner, patch_id:, face_count:)
    SU_MCP::Terrain::PatchLifecycle::PatchRegistryStore.new(
      registry_key: SU_MCP::Terrain::TerrainMeshGenerator::ADAPTIVE_PATCH_REGISTRY_KEY
    ).write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: nil,
        stateDigest: 'digest-1',
        stateRevision: 1,
        ownerTransformSignature: nil,
        patches: [
          {
            patchId: patch_id,
            bounds: { minColumn: 0, minRow: 0, maxColumn: 15, maxRow: 15 },
            outputBounds: { minColumn: 0, minRow: 0, maxColumn: 15, maxRow: 15 },
            replacementBatchId: 'old-batch',
            faceCount: face_count,
            status: 'valid'
          }
        ]
      }
    )
  end

  def read_cdt_registry(owner)
    SU_MCP::Terrain::PatchLifecycle::PatchRegistryStore.new(
      registry_key: SU_MCP::Terrain::TerrainMeshGenerator::ADAPTIVE_PATCH_REGISTRY_KEY
    ).read(owner)
  end

  def cdt_patch_ids(owner)
    owner.entities.faces.map { |face| terrain_attribute(face, 'cdtPatchId') }.compact.uniq.sort
  end

  def mark_cdt_neighbor_face(face, patch_id:, side:, face_index:)
    face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    face.set_attribute('su_mcp_terrain', 'outputKind', 'cdt_patch_face')
    face.set_attribute('su_mcp_terrain', 'cdtOwnershipSchemaVersion', 1)
    face.set_attribute('su_mcp_terrain', 'cdtPatchId', patch_id)
    face.set_attribute('su_mcp_terrain', 'cdtReplacementBatchId', 'batch')
    face.set_attribute('su_mcp_terrain', 'cdtPatchFaceIndex', face_index)
    face.set_attribute('su_mcp_terrain', 'cdtBorderSide', side)
  end

  def hill_elevations(size, amplitude:)
    center = size / 2
    Array.new(size * size) do |index|
      column = index % size
      row = index / size
      dx = (column - center).to_f / center
      dy = (row - center).to_f / center
      amplitude * Math.exp(-4 * ((dx * dx) + (dy * dy)))
    end
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

    def internal_to_public_meters(value)
      value.to_f / @multiplier
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

  class CountingEdge < SemanticTestSupport::FakeEdge
    attr_reader :attribute_write_count

    def initialize
      super
      @attribute_write_count = 0
    end

    def set_attribute(dictionary_name, key, value)
      @attribute_write_count += 1 if dictionary_name == 'su_mcp_terrain' &&
                                     key == 'derivedOutput'
      super
    end
  end

  class CountingAdaptiveVertexGenerator < SU_MCP::Terrain::TerrainMeshGenerator
    attr_reader :adaptive_vertex_call_count

    def initialize
      super
      @adaptive_vertex_call_count = 0
    end

    private

    def adaptive_vertex_for_planned_point(state, point)
      @adaptive_vertex_call_count += 1
      super
    end
  end

  class EntityList
    def initialize(entities)
      @entities = entities
    end

    def to_a
      @entities
    end
  end

  class PointObject
    attr_reader :x, :y, :z

    def initialize(x, y, z)
      @x = x
      @y = y
      @z = z
    end
  end

  class VertexObject
    attr_reader :position

    def initialize(position)
      @position = position
    end
  end

  class FaceWithVertices < Sketchup::Face
    attr_reader :vertices

    def initialize(vertices:)
      super()
      @vertices = vertices.map { |point| VertexObject.new(point) }
      @attributes = Hash.new { |hash, key| hash[key] = {} }
    end

    def set_attribute(dictionary, key, value)
      @attributes[dictionary][key] = value
    end

    def get_attribute(dictionary, key, default = nil)
      @attributes.fetch(dictionary, {}).fetch(key, default)
    end
  end

  class RecordingCdtBackend
    attr_reader :calls

    def initialize(status:, mesh: nil, fallback_reason: nil)
      @status = status
      @mesh = mesh
      @fallback_reason = fallback_reason
      @calls = 0
    end

    def build(...)
      @calls += 1
      if @status == 'accepted'
        {
          status: 'accepted',
          mesh: @mesh || { vertices: [], triangles: [] },
          metrics: {}
        }
      else
        {
          status: 'fallback',
          fallbackReason: @fallback_reason,
          metrics: {}
        }
      end
    end
  end

  class PatchLocalRecordingCdtBackend
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def build(state:, **)
      @calls += 1
      x0 = state.origin.fetch('x')
      y0 = state.origin.fetch('y')
      x1 = x0 + ((state.dimensions.fetch('columns') - 1) * state.spacing.fetch('x'))
      y1 = y0 + ((state.dimensions.fetch('rows') - 1) * state.spacing.fetch('y'))
      {
        status: 'accepted',
        mesh: {
          vertices: [
            [x0, y0, 1.0],
            [x1, y0, 1.0],
            [x1, y1, 1.0],
            [x0, y1, 1.0]
          ],
          triangles: [[0, 1, 2], [0, 2, 3]]
        },
        metrics: { maxHeightError: 0.0 }
      }
    end
  end

  class RaisingCdtBackend
    def build(...)
      raise 'boom'
    end
  end

  class RecordingPatchReplacementProvider
    attr_reader :calls, :last_batch_plan

    def self.accepted(patch_id: nil, domain_digest: nil, patch_size: 2.0)
      new(accepted_patch_id: patch_id || domain_digest, patch_size: patch_size)
    end

    def self.failed(reason)
      new(failure_reason: reason)
    end

    def initialize(accepted_patch_id: nil, failure_reason: nil, patch_size: 2.0)
      @accepted_patch_id = accepted_patch_id
      @failure_reason = failure_reason
      @patch_size = patch_size
      @calls = 0
    end

    def build(batch_plan:, **)
      @calls += 1
      @last_batch_plan = batch_plan
      return PatchReplacementResultStub.failed(@failure_reason) if @failure_reason

      patch_ids = batch_plan.replacement_patch_ids
      PatchReplacementResultStub.accepted(
        patch_id: @accepted_patch_id || patch_ids.first,
        replacement_patch_ids: patch_ids,
        replacement_patches: batch_plan.replacement_patches,
        state_digest: batch_plan.terrain_state_summary.fetch(:digest),
        patch_size: @patch_size
      )
    end
  end

  class PatchReplacementResultStub
    attr_reader :status, :mesh, :border_spans, :replacement_patch_ids, :replacement_patches,
                :replacement_batch_id, :stop_reason, :state_digest, :policy_fingerprint,
                :timing

    def self.accepted(patch_id:, replacement_patch_ids:, replacement_patches:,
                      state_digest: 'digest-2', patch_size: 2.0)
      mesh = mesh_for_replacement_patches(replacement_patches, patch_size)
      new(
        status: 'accepted',
        replacement_patch_ids: replacement_patch_ids,
        replacement_patches: replacement_patches,
        stop_reason: nil,
        mesh: mesh,
        border_spans: [
          { side: 'east', spanId: 'east-0', patchId: patch_id,
            fresh: true, vertices: [[patch_size, 0.0, 1.0], [patch_size, patch_size, 1.0]] }
        ],
        replacement_batch_id: 'new-batch',
        state_digest: state_digest,
        policy_fingerprint: 'fingerprint-2',
        timing: { buckets: { topology_validation: 0.0001 } }
      )
    end

    def self.mesh_for_replacement_patches(replacement_patches, patch_size)
      patches = replacement_patches.empty? ? [nil] : replacement_patches
      vertices = []
      triangles = []
      patches.each_with_index do |patch, index|
        bounds = patch_bounds_or_default(patch, patch_size)
        x0 = bounds.fetch(:min_x)
        y0 = bounds.fetch(:min_y)
        x1 = bounds.fetch(:max_x)
        y1 = bounds.fetch(:max_y)
        offset = index * 4
        vertices.push([x0, y0, 1.0], [x1, y0, 1.0], [x1, y1, 1.0], [x0, y1, 1.0])
        triangles.push([offset, offset + 1, offset + 2], [offset, offset + 2, offset + 3])
      end
      { vertices: vertices, triangles: triangles }
    end

    def self.patch_bounds_or_default(patch, patch_size)
      bounds = patch && (patch[:bounds] || patch['bounds'])
      return { min_x: 0.0, min_y: 0.0, max_x: patch_size, max_y: patch_size } unless bounds

      {
        min_x: bounds.fetch(:minColumn) { bounds.fetch('minColumn') }.to_f,
        min_y: bounds.fetch(:minRow) { bounds.fetch('minRow') }.to_f,
        max_x: bounds.fetch(:maxColumn) { bounds.fetch('maxColumn') }.to_f + 1.0,
        max_y: bounds.fetch(:maxRow) { bounds.fetch('maxRow') }.to_f + 1.0
      }
    end

    def self.failed(reason)
      new(
        status: 'failed',
        replacement_patch_ids: [],
        replacement_patches: [],
        stop_reason: reason,
        mesh: { vertices: [], triangles: [] },
        border_spans: [],
        replacement_batch_id: 'failed-batch',
        state_digest: 'digest-2',
        policy_fingerprint: 'fingerprint-2',
        timing: { buckets: { topology_validation: 0.0001 } }
      )
    end

    def initialize(status:, replacement_patch_ids:, replacement_patches:, stop_reason:, mesh:,
                   border_spans:, replacement_batch_id:, state_digest:, policy_fingerprint:,
                   timing:)
      @status = status
      @replacement_patch_ids = replacement_patch_ids
      @replacement_patches = replacement_patches
      @stop_reason = stop_reason
      @mesh = mesh
      @border_spans = border_spans
      @replacement_batch_id = replacement_batch_id
      @state_digest = state_digest
      @policy_fingerprint = policy_fingerprint
      @timing = timing
    end

    def accepted?
      status == 'accepted'
    end
  end
end
# rubocop:enable Metrics/AbcSize
