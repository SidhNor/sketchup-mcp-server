# frozen_string_literal: true

require_relative '../../../../test_helper'

begin
  require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/cdt_lifecycle_ownership'
rescue LoadError
  # Skeleton phase: implementation must introduce lifecycle-owned CDT face metadata helpers.
end

class CdtLifecycleOwnershipContractTest < Minitest::Test
  def test_face_ownership_uses_lifecycle_patch_id_and_registry_fields
    assert(
      defined?(SU_MCP::Terrain::CdtLifecycleOwnership),
      'CdtLifecycleOwnership must exist'
    )

    ownership = SU_MCP::Terrain::CdtLifecycleOwnership.face_ownership(
      patch_id: 'cdt-patch-v1-c0-r0',
      patch_face_index: 0,
      replacement_batch_id: 'cdt-batch-digest-1',
      state_digest: 'digest-1',
      policy_fingerprint: 'fingerprint-1'
    )

    assert_equal(:cdt_patch, ownership.fetch(:kind))
    assert_equal('cdt-patch-v1-c0-r0', ownership.fetch(:patch_id))
    assert_equal(0, ownership.fetch(:patch_face_index))
    refute_includes(JSON.generate(ownership), 'patch_domain_digest')
    refute_includes(JSON.generate(ownership), 'cdtPatchDomainDigest')
  end

  def test_registry_record_is_patch_lifecycle_compatible
    assert(
      defined?(SU_MCP::Terrain::CdtLifecycleOwnership),
      'CdtLifecycleOwnership must exist'
    )

    record = SU_MCP::Terrain::CdtLifecycleOwnership.registry_patch_record(
      patch: {
        patchId: 'cdt-patch-v1-c0-r0',
        bounds: { minColumn: 0, minRow: 0, maxColumn: 15, maxRow: 15 }
      },
      replacement_batch_id: 'cdt-batch-digest-1',
      face_count: 2
    )

    assert_equal('cdt-patch-v1-c0-r0', record.fetch(:patchId))
    assert_equal(2, record.fetch(:faceCount))
    refute_includes(JSON.generate(record), 'patchDomainDigest')
  end
end
