# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../support/semantic_test_support'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_traversal'

class AdaptivePatchTraversalTest < Minitest::Test
  include SemanticTestSupport

  def test_affected_face_lookup_uses_logical_patch_ids_inside_single_mesh
    owner = build_semantic_model.active_entities.add_group
    mesh = adaptive_mesh(owner)
    affected = patch_face(mesh, 'adaptive-patch-v1-c0-r0')
    preserved = patch_face(mesh, 'adaptive-patch-v1-c1-r0')
    unrelated_face = mesh.entities.add_face([20, 0, 0], [21, 0, 0], [21, 1, 0])
    unrelated_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)

    result = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchTraversal
             .new
             .affected_faces(mesh.entities, ['adaptive-patch-v1-c0-r0'])

    assert_equal([affected], result)
    refute_includes(result, preserved)
    refute_includes(result, unrelated_face)
  end

  def test_adaptive_mesh_lookup_ignores_legacy_patch_containers
    owner = build_semantic_model.active_entities.add_group
    legacy = patch_container(owner, 'adaptive-patch-v1-c0-r0')
    mesh = adaptive_mesh(owner)

    result = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchTraversal.new.adaptive_mesh(
      owner.entities
    )

    assert_equal(mesh, result)
    refute_equal(legacy, result)
  end

  def test_affected_container_lookup_uses_registry_patch_ids_without_flat_all_output_selection
    owner = build_semantic_model.active_entities.add_group
    affected = patch_container(owner, 'adaptive-patch-v1-c0-r0')
    preserved = patch_container(owner, 'adaptive-patch-v1-c1-r0')
    unrelated_face = owner.entities.add_face([20, 0, 0], [21, 0, 0], [21, 1, 0])
    unrelated_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)

    result = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchTraversal
             .new
             .affected_containers(owner.entities, ['adaptive-patch-v1-c0-r0'])

    assert_equal([affected], result)
    refute_includes(result, preserved)
    refute_includes(result, unrelated_face)
  end

  def test_integrity_traversal_scans_nested_faces_only_inside_target_containers
    owner = build_semantic_model.active_entities.add_group
    affected = patch_container(owner, 'adaptive-patch-v1-c0-r0')
    affected.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    preserved = patch_container(owner, 'adaptive-patch-v1-c1-r0')
    preserved.entities.add_face([10, 0, 0], [11, 0, 0], [11, 1, 0])

    result = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchTraversal
             .new
             .faces_for_integrity([affected])

    assert_equal(1, result.length)
    refute_includes(result, preserved.entities.faces.first)
  end

  private

  def patch_container(owner, patch_id)
    group = owner.entities.add_group
    group.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    group.set_attribute('su_mcp_terrain', 'outputKind', 'adaptive_patch_container')
    group.set_attribute('su_mcp_terrain', 'adaptivePatchId', patch_id)
    group
  end

  def adaptive_mesh(owner)
    group = owner.entities.add_group
    group.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    group.set_attribute('su_mcp_terrain', 'outputKind', 'adaptive_patch_mesh')
    group
  end

  def patch_face(mesh, patch_id)
    face = mesh.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    face.set_attribute('su_mcp_terrain', 'outputKind', 'adaptive_patch_face')
    face.set_attribute('su_mcp_terrain', 'adaptivePatchId', patch_id)
    face
  end
end
