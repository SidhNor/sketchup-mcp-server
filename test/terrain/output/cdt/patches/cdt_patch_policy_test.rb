# frozen_string_literal: true

require_relative '../../../../test_helper'

begin
  require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/cdt_patch_policy'
rescue LoadError
  # Skeleton phase: implementation must introduce the CDT PatchLifecycle adapter.
end

class CdtPatchPolicyTest < Minitest::Test
  def test_cdt_policy_is_a_patch_lifecycle_adapter_without_new_identity_rules
    assert(defined?(SU_MCP::Terrain::CdtPatchPolicy), 'CdtPatchPolicy must exist')

    policy = SU_MCP::Terrain::CdtPatchPolicy.new

    assert_kind_of(SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy, policy)
    assert_equal(0, policy.conformance_ring)
    assert_equal('cdt-patch-v1-c0-r0', policy.patch_id_for(column: 0, row: 0))
    assert_equal('cdt-patch', policy.fingerprint_kind)
  end
end
