# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/' \
                 'patch_cdt_replacement_provider'

class PatchCdtReplacementProviderTest < Minitest::Test
  include PatchCdtTestSupport

  def test_build_adapts_mta32_patch_proof_without_exposing_debug_mesh
    proof_runner = RecordingProofRunner.new(proof_result: accepted_proof_result)

    result = SU_MCP::Terrain::PatchCdtReplacementProvider.new(
      proof_runner: proof_runner
    ).build(
      state: state,
      feature_geometry: patch_feature_geometry,
      output_plan: dirty_output_plan(state: state, window: patch_window_for_provider),
      terrain_state_summary: { digest: 'digest-1' },
      feature_context: {}
    )

    assert_equal(1, proof_runner.calls)
    assert(result.accepted?)
    refute_includes(JSON.generate(result.to_h), 'debugMesh')
    refute_includes(JSON.generate(result.to_h), 'proofType')
    assert_equal(patch_feature_geometry.feature_geometry_digest, result.feature_digest)
  end

  private

  def state
    @state ||= patch_state(columns: 3, rows: 3)
  end

  def patch_window_for_provider
    SU_MCP::Terrain::SampleWindow.new(
      min_column: 0,
      min_row: 0,
      max_column: 1,
      max_row: 1
    )
  end

  def accepted_proof_result
    {
      status: 'accepted',
      proofType: 'patch_local_incremental_residual_cdt_proof',
      patchDomain: {
        ownerLocalBounds: { minX: 0.0, minY: 0.0, maxX: 2.0, maxY: 2.0 },
        sourceDimensions: { columns: 3, rows: 3 }
      },
      topology: { passed: true },
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

  class RecordingProofRunner
    attr_reader :calls

    def initialize(proof_result:)
      @proof_result = proof_result
      @calls = 0
    end

    def run(**)
      @calls += 1
      @proof_result
    end
  end
end
