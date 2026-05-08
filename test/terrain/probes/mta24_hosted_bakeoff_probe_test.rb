# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/mta24_hosted_bakeoff_probe'

class Mta24HostedBakeoffProbeTest < Minitest::Test
  def test_payload_names_three_sidecars_and_records_required_evidence_fields
    payload = probe.payload_for(
      case_id: 'created_flat_corridor_mta21',
      family: 'mta22_created',
      rows: sidecar_rows
    )

    assert_equal('created_flat_corridor_mta21', payload.fetch(:caseId))
    assert_equal('mta22_created', payload.fetch(:family))
    assert_equal(%i[current adaptive cdt], payload.fetch(:sidecars).keys)
    assert(payload.fetch(:sidecars).values.all? do |sidecar|
      sidecar.fetch(:sidecarName).start_with?('MTA24-')
    end)
    %i[
      beforeTopLevelEntityIds afterTopLevelEntityIds generatedFaceCount generatedVertexCount
      topologyChecks profileChecks timing undoStatus saveCopyStatus saveReopenStatus
      sourceDenseFaceCount cdtFaceCount denseRatio selectedPointCount sourceDimensions
      maxHeightError sourceGroup placementOffsets validationMetadata
    ].each { |field| assert_includes(payload.fetch(:evidence).keys, field) }
    assert_equal(8, payload.dig(:evidence, :sourceDenseFaceCount))
    assert_equal(1, payload.dig(:evidence, :cdtFaceCount))
    assert_equal(0.125, payload.dig(:evidence, :denseRatio))
    assert_equal(4, payload.dig(:evidence, :selectedPointCount))
  end

  def test_payload_carries_required_family_matrix_and_joint_visual_status
    payload = probe.payload_for(case_id: 'case', family: 'high_relief', rows: sidecar_rows)

    required = SU_MCP::Terrain::Mta24HostedBakeoffProbe::REQUIRED_FAMILIES
    assert_equal(required, payload.fetch(:familyCoverage).keys)
    assert_equal('not_run', payload.fetch(:jointVisualValidationStatus))
    assert_equal(%w[current adaptive cdt], payload.dig(:familyCoverage, 'high_relief', :backends))
  end

  def test_report_downgrades_when_required_family_or_joint_visual_validation_is_missing
    report = SU_MCP::Terrain::Mta24HostedBakeoffProbe.hosted_report(
      evidence: {
        familyCoverage: { 'mta22_created' => { status: 'passed' } },
        jointVisualValidationStatus: 'not_run'
      },
      requested_recommendation: 'productionize_cdt_later'
    )

    assert_equal('hosted_validation_required', report.fetch(:recommendation))
    assert_includes(report.fetch(:validationGaps), 'required hosted family coverage gap')
    assert_includes(report.fetch(:validationGaps), 'joint live visual validation gap')
  end

  private

  def probe
    @probe ||= SU_MCP::Terrain::Mta24HostedBakeoffProbe.new(
      timestamp: '20260507-120000',
      model_bounds: { min: [0.0, 0.0, 0.0], max: [10.0, 10.0, 3.0] }
    )
  end

  def sidecar_rows
    {
      current: { backend: 'mta21_current_adaptive', mesh: mesh },
      adaptive: { backend: 'mta23_intent_aware_adaptive_grid_prototype', mesh: mesh },
      cdt: {
        backend: 'mta24_constrained_delaunay_cdt_prototype',
        mesh: mesh,
        selectedPointCount: 4,
        sourceDimensions: { 'columns' => 3, 'rows' => 3 },
        sourceGroup: 'MTA23-CURRENT-VS-MTA23-BAKEOFF-20260507-091137',
        metrics: {
          denseEquivalentFaceCount: 8,
          denseRatio: 0.125,
          maxHeightError: 0.01
        }
      }
    }
  end

  def mesh
    { vertices: [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]],
      triangles: [[0, 1, 2]] }
  end
end
