# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../support/semantic_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_debug_mesh_renderer'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_local_cdt_proof'

class PatchDebugMeshRendererTest < Minitest::Test
  include PatchCdtTestSupport
  include SemanticTestSupport

  def test_renders_opt_in_debug_mesh_as_named_debug_group
    evidence = debug_mesh_evidence
    model = build_semantic_model

    result = SU_MCP::Terrain::PatchDebugMeshRenderer.new.render(
      model: model,
      evidence: evidence,
      source_element_id: 'mta32-test-proof-mesh'
    )

    group = model.active_entities.groups.fetch(0)
    assert_equal('rendered', result.fetch(:status))
    assert_equal('MTA-32 Patch CDT Proof Mesh', group.name)
    assert_equal(true, group.get_attribute('su_mcp', 'debugOnly'))
    assert_equal('mta32-test-proof-mesh', group.get_attribute('su_mcp', 'sourceElementId'))
    assert_equal('mta32-test-proof-mesh', result.fetch(:sourceElementId))
    assert_equal(evidence.dig(:debugMesh, :triangles).length, group.entities.faces.length)
    assert_equal(evidence.dig(:debugMesh, :triangles).length, result.fetch(:faceCount))
  end

  private

  def debug_mesh_evidence
    state = rough_state(columns: 9, rows: 9)
    SU_MCP::Terrain::PatchLocalCdtProof.new.run(
      state: state,
      feature_geometry: empty_feature_geometry,
      output_plan: dirty_output_plan(state: state),
      base_tolerance: 0.05,
      max_point_budget: 96,
      max_face_budget: 192,
      max_runtime_budget: 2.0,
      include_debug_mesh: true
    )
  end
end
