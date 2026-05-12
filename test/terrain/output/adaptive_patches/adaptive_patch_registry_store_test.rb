# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../support/semantic_test_support'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/' \
                 'adaptive_patch_registry_store'

class AdaptivePatchRegistryStoreTest < Minitest::Test
  include SemanticTestSupport

  def test_write_and_read_registry_keeps_compact_derived_patch_records
    owner = build_semantic_model.active_entities.add_group
    store = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchRegistryStore.new

    store.write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: 'fingerprint-a',
        stateDigest: 'digest-1',
        stateRevision: 1,
        ownerTransformSignature: 'transform-a',
        patches: [patch_record('adaptive-patch-v1-c0-r0')]
      }
    )

    assert_instance_of(String, owner.get_attribute('su_mcp_terrain', 'adaptivePatchRegistry'))
    loaded = store.read(owner)
    assert_equal('valid', loaded.fetch(:status))
    assert_equal(
      ['adaptive-patch-v1-c0-r0'],
      loaded.fetch(:patches).map { |row| row.fetch(:patchId) }
    )
    refute_includes(JSON.generate(loaded), 'adaptiveCells')
    refute_includes(JSON.generate(loaded), 'rawTriangles')
    refute_includes(JSON.generate(loaded), 'vertices')
  end

  def test_readback_invalidates_when_policy_digest_transform_or_face_index_completeness_mismatch
    owner = build_semantic_model.active_entities.add_group
    store = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchRegistryStore.new
    store.write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: 'fingerprint-a',
        stateDigest: 'digest-1',
        stateRevision: 1,
        ownerTransformSignature: 'transform-a',
        patches: [patch_record('adaptive-patch-v1-c0-r0', face_count: 2)]
      }
    )

    result = store.validate_readback(
      owner: owner,
      expected_policy_fingerprint: 'fingerprint-b',
      expected_state_digest: 'digest-1',
      expected_state_revision: 1,
      expected_owner_transform_signature: 'transform-a',
      face_index_counts: { 'adaptive-patch-v1-c0-r0' => 2 }
    )

    assert_equal('invalidated', result.fetch(:status))
    assert_equal('output_policy_fingerprint_mismatch', result.fetch(:reason))
  end

  def test_read_accepts_reload_style_json_registry_payload
    owner = build_semantic_model.active_entities.add_group
    owner.set_attribute(
      'su_mcp_terrain',
      'adaptivePatchRegistry',
      JSON.generate(
        'status' => 'valid',
        'outputPolicyFingerprint' => 'fingerprint-a',
        'stateDigest' => 'digest-1',
        'stateRevision' => 3,
        'ownerTransformSignature' => 'transform-a',
        'patches' => [patch_record('adaptive-patch-v1-c0-r0', face_count: 2)]
      )
    )

    loaded = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchRegistryStore.new.read(owner)

    assert_equal('valid', loaded.fetch(:status))
    assert_equal(3, loaded.fetch(:stateRevision))
    assert_equal(2, loaded.fetch(:patches).first.fetch(:faceCount))
  end

  private

  def patch_record(patch_id, face_count: 0)
    {
      patchId: patch_id,
      bounds: { minColumn: 0, minRow: 0, maxColumn: 15, maxRow: 15 },
      outputBounds: { minColumn: 0, minRow: 0, maxColumn: 15, maxRow: 15 },
      replacementBatchId: 'batch-1',
      faceCount: face_count,
      status: 'valid'
    }
  end
end
