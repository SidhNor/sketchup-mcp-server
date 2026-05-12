# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../support/semantic_test_support'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_registry_store'

class PatchRegistryStoreTest < Minitest::Test
  include SemanticTestSupport

  def test_registry_key_is_configurable_for_cdt_or_adaptive_owners
    owner = build_semantic_model.active_entities.add_group
    store = SU_MCP::Terrain::PatchLifecycle::PatchRegistryStore.new(
      registry_key: 'cdtPatchRegistry'
    )

    store.write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: 'fingerprint-a',
        stateDigest: 'digest-1',
        stateRevision: 1,
        patches: [{ patchId: 'cdt-patch-v1-c0-r0', faceCount: 2 }]
      }
    )

    assert_instance_of(String, owner.get_attribute('su_mcp_terrain', 'cdtPatchRegistry'))
    assert_equal(
      ['cdt-patch-v1-c0-r0'],
      store.read(owner).fetch(:patches).map { |patch| patch.fetch(:patchId) }
    )
  end
end
