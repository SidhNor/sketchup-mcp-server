# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_grid_policy'

class PatchGridPolicyTest < Minitest::Test
  def test_stable_patch_identity_can_use_non_adaptive_prefix
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_cell_size: 16,
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )

    assert_equal('cdt-patch-v1-c0-r0', policy.patch_id_for(column: 0, row: 0))
    assert_equal('cdt-patch-v1-c1-r1', policy.patch_id_for(column: 31, row: 31))
  end

  def test_fingerprint_is_sensitive_to_patch_kind
    adaptive = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_id_prefix: 'adaptive-patch',
      fingerprint_kind: 'adaptive-patch'
    )
    cdt = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )

    refute_equal(adaptive.output_policy_fingerprint, cdt.output_policy_fingerprint)
  end
end
