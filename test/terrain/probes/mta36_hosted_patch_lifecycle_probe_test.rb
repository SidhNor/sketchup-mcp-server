# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/mta36_hosted_patch_lifecycle_probe'

class Mta36HostedPatchLifecycleProbeTest < Minitest::Test
  def test_probe_matrix_requires_command_path_timing_reload_undo_and_visual_rows
    probe = SU_MCP::Terrain::Mta36HostedPatchLifecycleProbe.new(timestamp: '20260511-120000')

    payload = probe.payload_for(
      case_id: 'medium-interior-repeat',
      terrain_extent_meters: { x: 45.0, y: 84.0 },
      spacing_meters: { x: 0.65, y: 0.65 },
      patch_cell_size: 16
    )

    assert_equal('medium-interior-repeat', payload.fetch(:caseId))
    assert_equal('command_path', payload.fetch(:executionMode))
    %i[
      commandPrep dirtyWindowMapping adaptivePlanning conformance registryLookup
      ownershipFaceLookup mutation registryWrites audit total
    ].each { |bucket| assert_includes(payload.fetch(:timingBuckets).keys, bucket) }
    %i[
      repeatedSamePatchEdit repeatedAdjacentPatchEdit preservedNeighbors noDeleteFallback
      intersectingMultiModeEdits singleMeshTopology undo reloadReadback visualInspection
      performanceComparison
    ].each { |field| assert_includes(payload.fetch(:acceptanceRows).keys, field) }
  end

  def test_hosted_report_records_blocker_when_speedup_gate_is_not_met_above_responsiveness_floor
    report = SU_MCP::Terrain::Mta36HostedPatchLifecycleProbe.hosted_report(
      evidence: {
        fullAdaptiveTotalMs: 850,
        localAdaptiveTotalMs: 650,
        visualInspection: 'passed',
        reloadReadback: 'passed',
        undo: 'passed'
      }
    )

    assert_equal('performance_blocked', report.fetch(:status))
    assert_includes(report.fetch(:blockers), 'local adaptive replacement missed speedup gate')
  end
end
