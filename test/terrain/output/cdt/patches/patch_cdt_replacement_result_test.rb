# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_replacement_result'

class PatchCdtReplacementResultTest < Minitest::Test
  include PatchCdtTestSupport

  def test_adapts_accepted_patch_proof_into_json_safe_replacement_contract
    result = SU_MCP::Terrain::PatchCdtReplacementResult.from_proof(
      proof_result: accepted_proof_result,
      feature_geometry: patch_feature_geometry,
      replacement_batch_id: 'batch-1',
      timing: { mta32PatchSolveSeconds: 0.01, seamValidationSeconds: 0.0 }
    )

    assert_equal('accepted', result.status)
    assert_equal('batch-1', result.replacement_batch_id)
    assert_equal(4, result.border_spans.length)
    assert_equal(%w[east north south west], result_border_sides(result))
    assert_equal(patch_feature_geometry.feature_geometry_digest, result.feature_digest)
    assert_equal(0.01, result.timing.fetch(:mta32PatchSolveSeconds))
    assert_includes(result.timing.keys, :ownershipSnapshotSeconds)

    serialized = JSON.generate(result.to_h)
    refute_includes(serialized, 'debugMesh')
    refute_includes(serialized, 'proofType')
    assert_json_safe(result.to_h)
  end

  def test_rejects_incomplete_mesh_before_it_can_drive_mutation
    proof = accepted_proof_result.merge(debugMesh: { vertices: [[1.0, 1.0, 0.0]], triangles: [] })

    result = SU_MCP::Terrain::PatchCdtReplacementResult.from_proof(
      proof_result: proof,
      feature_geometry: patch_feature_geometry
    )

    assert_equal('failed', result.status)
    assert_equal('patch_result_incomplete', result.stop_reason)
    assert_empty(result.mesh.fetch(:triangles))
  end

  def test_rejects_out_of_domain_vertices
    proof = accepted_proof_result
    proof = proof.merge(
      debugMesh: proof.fetch(:debugMesh).merge(
        vertices: proof.fetch(:debugMesh).fetch(:vertices) + [[99.0, 99.0, 0.0]],
        triangles: proof.fetch(:debugMesh).fetch(:triangles) + [[0, 1, 4]]
      )
    )

    result = SU_MCP::Terrain::PatchCdtReplacementResult.from_proof(
      proof_result: proof,
      feature_geometry: patch_feature_geometry
    )

    assert_equal('failed', result.status)
    assert_equal('topology_invalid', result.stop_reason)
  end

  def test_timing_keeps_default_buckets_and_allows_overrides
    result = SU_MCP::Terrain::PatchCdtReplacementResult.from_proof(
      proof_result: accepted_proof_result,
      feature_geometry: patch_feature_geometry,
      timing: { ownershipSnapshotSeconds: 0.02, mutationSeconds: 0.03 }
    )

    assert_equal(
      SU_MCP::Terrain::PatchCdtReplacementResult::DEFAULT_TIMING.keys.sort,
      result.timing.keys.sort
    )
    assert_equal(0.02, result.timing.fetch(:ownershipSnapshotSeconds))
    assert_equal(0.03, result.timing.fetch(:mutationSeconds))
    assert_equal(0.0, result.timing.fetch(:mta33SelectionSeconds))
  end

  private

  def result_border_sides(result)
    result.border_spans.map { |span| span.fetch(:side) }.sort
  end

  def accepted_proof_result
    {
      status: 'accepted',
      proofType: 'patch_local_incremental_residual_cdt_proof',
      patchDomain: {
        ownerLocalBounds: { minX: 0.0, minY: 0.0, maxX: 2.0, maxY: 2.0 },
        sampleBounds: { minColumn: 0, minRow: 0, maxColumn: 2, maxRow: 2 },
        sourceDimensions: { columns: 3, rows: 3 },
        marginSamples: 0,
        patchSampleCount: 9
      },
      topology: { passed: true, areaCoverageRatio: 1.0 },
      residualQuality: { maxHeightError: 0.0 },
      debugMesh: {
        vertices: [
          [0.0, 0.0, 0.0],
          [2.0, 0.0, 0.0],
          [2.0, 2.0, 0.0],
          [0.0, 2.0, 0.0]
        ],
        triangles: [[0, 1, 2], [0, 2, 3]]
      }
    }
  end
end
