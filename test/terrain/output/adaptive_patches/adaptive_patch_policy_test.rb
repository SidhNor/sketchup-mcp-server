# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_policy'

class AdaptivePatchPolicyTest < Minitest::Test
  def test_stable_patch_identity_uses_owner_local_output_cell_lattice
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(
      patch_cell_size: 16,
      conformance_ring: 1
    )

    assert_equal('adaptive-patch-v1-c0-r0', policy.patch_id_for(column: 0, row: 0))
    assert_equal('adaptive-patch-v1-c1-r0', policy.patch_id_for(column: 16, row: 0))
    assert_equal('adaptive-patch-v1-c1-r1', policy.patch_id_for(column: 31, row: 31))
  end

  def test_output_policy_fingerprint_is_deterministic_and_contract_sensitive
    first = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(
      patch_cell_size: 16,
      conformance_ring: 1,
      hard_patch_boundaries: true,
      adaptive_metadata_schema_version: 1
    )
    equivalent = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(
      adaptive_metadata_schema_version: 1,
      hard_patch_boundaries: true,
      conformance_ring: 1,
      patch_cell_size: 16
    )
    changed = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(
      patch_cell_size: 32,
      conformance_ring: 1,
      hard_patch_boundaries: true,
      adaptive_metadata_schema_version: 1
    )

    assert_equal(first.output_policy_fingerprint, equivalent.output_policy_fingerprint)
    refute_equal(first.output_policy_fingerprint, changed.output_policy_fingerprint)
    assert_match(/\A[0-9a-f]{64}\z/, first.output_policy_fingerprint)
  end

  def test_candidate_matrix_reports_patch_size_in_cells_and_meters
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(
      candidate_patch_cell_sizes: [8, 16, 32],
      spacing: { 'x' => 0.5, 'y' => 1.0 }
    )

    assert_equal(
      [
        { patchCellSize: 8, physicalSizeMeters: { x: 4.0, y: 8.0 } },
        { patchCellSize: 16, physicalSizeMeters: { x: 8.0, y: 16.0 } },
        { patchCellSize: 32, physicalSizeMeters: { x: 16.0, y: 32.0 } }
      ],
      policy.candidate_matrix
    )
  end
end
