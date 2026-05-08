# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/mta23_hosted_sidecar_probe'

class Mta23HostedSidecarProbeTest < Minitest::Test
  def test_probe_payload_names_sidecar_and_records_required_hosted_evidence_fields
    probe = SU_MCP::Terrain::Mta23HostedSidecarProbe.new(
      timestamp: '20260506-120000',
      model_bounds: { min: [0.0, 0.0, 0.0], max: [10.0, 10.0, 3.0] }
    )

    payload = probe.payload_for(candidate_row: { caseId: 'created_flat_corridor_mta21' },
                                mesh: { vertices: [[0.0, 0.0, 0.0]], triangles: [] })

    assert_equal('MTA23-CANDIDATE-20260506-120000', payload.fetch(:sidecarName))
    assert_operator(payload.dig(:placementOffset, 0), :>, 10.0)
    %i[
      beforeTopLevelEntityIds afterTopLevelEntityIds generatedFaceCount generatedVertexCount
      topologyChecks profileChecks timing undoStatus saveCopyStatus saveReopenStatus
      candidateOnlyMetadata
    ].each { |field| assert_includes(payload.fetch(:evidence).keys, field) }
  end

  def test_report_downgrades_productionization_when_save_reopen_was_skipped
    report = SU_MCP::Terrain::Mta23HostedSidecarProbe.hosted_report(
      evidence: { saveReopenStatus: 'skipped' },
      requested_recommendation: 'productionize_adaptive_candidate_later'
    )

    assert_equal('pursue_constrained_delaunay_or_cdt_follow_up', report.fetch(:recommendation))
    assert_includes(report.fetch(:validationGaps), 'save/reopen validation gap')
  end
end
