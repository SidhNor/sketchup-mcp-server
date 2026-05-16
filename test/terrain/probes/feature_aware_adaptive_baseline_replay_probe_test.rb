# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_replay'

class FeatureAwareAdaptiveBaselineReplayProbeTest < Minitest::Test
  def test_probe_exposes_required_evidence_table_columns_and_generic_timing_buckets
    replay = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.validate_document(
      minimal_document
    )

    template = replay.evidence_row_template

    %i[
      rowId sequenceId replaySpec commandKind sourceElementId featureContextClass accepted
      verdict outcome stateRevision featureViewDigest policyFingerprint featureContext dirtyWindow
      adaptivePolicySummary affectedPatchScope faceCount vertexCount meshType
      simplificationTolerance
      maxSimplificationError renderingSummary featureQualitySummary harnessQualitySeconds
      timingBuckets
    ].each { |field| assert_includes(template.keys, field) }
    %i[
      commandOutputPlanning featureSelectionDiagnostics dirtyWindowMapping adaptivePlanning
      mutation total
    ].each { |bucket| assert_includes(template.fetch(:timingBuckets).keys, bucket) }
  end

  def test_hosted_report_marks_unexpected_refusals_as_evidence_failures
    report = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.hosted_report(
      evidence: {
        rows: [
          { rowId: 'target-local-center', accepted: false, verdict: 'refused' }
        ],
        environment: { sketchUpVersion: '26.1.189', extensionVersion: '1.7.0' }
      }
    )

    assert_equal('failed', report.fetch(:status))
    assert_includes(report.fetch(:blockers), 'target-local-center refused unexpectedly')
  end

  private

  def minimal_document
    {
      'schemaVersion' => 1,
      'corpusId' => 'feature-aware-adaptive-baseline',
      'units' => 'meters',
      'terrain' => {
        'sourceElementId' => 'feature-aware-baseline-terrain',
        'dimensions' => { 'columns' => 49, 'rows' => 49 },
        'spacingMeters' => { 'x' => 0.5, 'y' => 0.5 },
        'placement' => { 'origin' => { 'x' => 320.0, 'y' => 0.0, 'z' => 0.0 } },
        'elevationRecipe' => { 'kind' => 'deterministic_wave_v1' },
        'createTerrainSurface' => {
          'metadata' => { 'sourceElementId' => 'feature-aware-baseline-terrain' },
          'lifecycle' => { 'mode' => 'create' }
        }
      },
      'sequences' => [
        {
          'sequenceId' => 'create-and-local-edit',
          'rows' => [
            {
              'rowId' => 'create-baseline',
              'commandKind' => 'create',
              'expectedStatus' => 'accepted',
              'terrainPosition' => { 'x' => 320.0, 'y' => 0.0, 'z' => 0.0 },
              'featureContextClass' => 'none',
              'publicCommandPayload' => {
                'metadata' => { 'sourceElementId' => 'feature-aware-baseline-terrain' },
                'lifecycle' => { 'mode' => 'create' }
              }
            }
          ]
        }
      ]
    }
  end
end
