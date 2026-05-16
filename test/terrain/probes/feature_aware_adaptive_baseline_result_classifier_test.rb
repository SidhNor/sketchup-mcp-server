# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/' \
                 'feature_aware_adaptive_baseline_result_classifier'

class FeatureAwareAdaptiveBaselineResultClassifierTest < Minitest::Test
  def test_classifies_feature_policy_rows_as_policy_applied_without_overclaiming_quality
    row = classify(
      current_row(
        face_count: 108,
        seconds: 0.09,
        density_hits: 12,
        fallback_counts: { 'unsupportedFeatureGeometry' => 1 },
        quality_status: 'captured'
      )
    )

    assert_equal('policy_applied', row.fetch('verdict'))
    assert_includes(row.fetch('verdictReason'), 'feature policy applied')
    assert_includes(row.fetch('verdictReason'), 'unsupportedFeatureGeometry=1')
    assert_equal(8, row.fetch('comparison').fetch('faceCountDelta'))
  end

  def test_classifies_baseline_equivalent_rows_as_neutral
    row = classify(current_row)

    assert_equal('neutral', row.fetch('verdict'))
  end

  def test_classifies_policy_rows_without_quality_capture_as_neutral
    row = classify(current_row(density_hits: 12))

    assert_equal('neutral', row.fetch('verdict'))
  end

  def test_classifies_refused_missing_policy_and_slow_rows
    assert_equal('failed', classify(current_row(outcome: 'refused')).fetch('verdict'))
    assert_equal('failed', classify(current_row(policy: nil)).fetch('verdict'))
    assert_equal(
      'regressed',
      classify(current_row(seconds: 0.13, density_hits: 1)).fetch('verdict')
    )
  end

  def test_normalizes_patch_scope_field_names_for_replay_and_result_rows
    row = classify(
      current_row(density_hits: 1, quality_status: 'captured').tap do |current|
        current['affectedPatchScope'] = current.delete('patchScope')
      end
    )

    assert_equal('policy_applied', row.fetch('verdict'))
    refute(row.fetch('comparison').fetch('patchScopeChanged'))
  end

  private

  def classify(row)
    document = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineResultClassifier.annotate(
      baseline_document: { 'rows' => [baseline_row] },
      current_document: { 'rows' => [row] }
    )
    document.fetch('rows').first
  end

  def baseline_row
    current_row(policy: nil)
  end

  def current_row(
    face_count: 100,
    seconds: 0.1,
    outcome: 'edited',
    density_hits: 0,
    fallback_counts: {},
    policy: :default,
    quality_status: nil
  )
    {
      'rowId' => 'feature-row',
      'seconds' => seconds,
      'outcome' => outcome,
      'faceCount' => face_count,
      'dirtyWindow' => { 'columns' => 9, 'rows' => 9 },
      'patchScope' => { 'affectedPatchCount' => 1, 'replacementPatchCount' => 9 },
      'adaptivePolicySummary' => policy_summary(policy, density_hits, fallback_counts),
      'featureQualitySummary' => quality_summary(quality_status)
    }.compact
  end

  def policy_summary(policy, density_hits, fallback_counts)
    return nil if policy.nil?

    {
      'policyFingerprint' => 'policy',
      'densityHitCount' => density_hits,
      'hardProtectedToleranceHitCount' => 0,
      'fallbackCounts' => fallback_counts
    }
  end

  def quality_summary(status)
    return nil unless status

    { 'status' => status }
  end
end
