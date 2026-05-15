# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/feature_output_policy_diagnostics'
require_relative '../../../src/su_mcp/terrain/regions/sample_window'

class FeatureOutputPolicyDiagnosticsTest < Minitest::Test
  def test_serializes_required_traceability_fields_without_host_objects
    diagnostics = build_diagnostics

    payload = diagnostics.to_h
    serialized = JSON.generate(payload)

    assert_equal(1, payload.fetch(:schemaVersion))
    assert_match(/\A[a-f0-9]{64}\z/, payload.fetch(:featureViewDigest))
    assert_equal('adaptive-policy-v1', payload.fetch(:policyFingerprint))
    assert_equal(true, payload.fetch(:diagnosticOnly))
    assert_equal({ hard: 1, firm: 1, soft: 1 }, payload.fetch(:selectedStrengthCounts))
    assert_equal(
      { target_region: 1, linear_corridor: 1, survey_control: 1 },
      payload.fetch(:selectedFeatureKinds)
    )
    assert_equal(
      { mode: 'default_fixed', toleranceMeters: 0.01 },
      payload.fetch(:localTolerancePolicy)
    )
    refute_includes(serialized, 'Sketchup::')
  end

  def test_digest_and_policy_fingerprint_are_stable_for_equivalent_feature_views
    first = build_diagnostics
    second = build_diagnostics

    assert_equal(first.feature_view_digest, second.feature_view_digest)
    assert_equal(first.policy_fingerprint, second.policy_fingerprint)
  end

  def test_intersection_summary_distinguishes_composed_selected_context
    diagnostics = build_diagnostics

    summary = diagnostics.to_h.fetch(:intersectionSummary)

    assert_equal(true, summary.fetch(:hasIntersectingFeatureContext))
    assert_equal(
      [%w[feature-corridor feature-target], %w[feature-survey feature-target]],
      summary.fetch(:intersectingFeaturePairs)
    )
  end

  def test_rejects_non_json_safe_values
    error = assert_raises(ArgumentError) do
      SU_MCP::Terrain::FeatureOutputPolicyDiagnostics.new(
        selection_window: Object.new,
        selected_features: [],
        affected_window: nil,
        adaptive_patch_policy: nil
      )
    end

    assert_match(/JSON-safe/i, error.message)
  end

  private

  def build_diagnostics
    SU_MCP::Terrain::FeatureOutputPolicyDiagnostics.new(
      selection_window: SU_MCP::Terrain::SampleWindow.new(
        min_column: 18,
        min_row: 18,
        max_column: 30,
        max_row: 30
      ),
      selected_features: selected_features,
      affected_window: {
        'min' => { 'column' => 18, 'row' => 18 },
        'max' => { 'column' => 30, 'row' => 30 }
      },
      adaptive_patch_policy: Struct.new(:output_policy_fingerprint).new('adaptive-policy-v1')
    )
  end

  def selected_features
    [
      feature('feature-target', 'target_region', 'soft', bounds(20, 20, 28, 28)),
      feature('feature-corridor', 'linear_corridor', 'firm', bounds(16, 16, 30, 30)),
      feature('feature-survey', 'survey_control', 'hard', bounds(24, 24, 24, 24))
    ]
  end

  def feature(id, kind, strength, bounds)
    {
      'id' => id,
      'kind' => kind,
      'strengthClass' => strength,
      'affectedWindow' => {
        'min' => { 'column' => bounds.fetch(:min_column), 'row' => bounds.fetch(:min_row) },
        'max' => { 'column' => bounds.fetch(:max_column), 'row' => bounds.fetch(:max_row) }
      }
    }
  end

  def bounds(min_column, min_row, max_column, max_row)
    {
      min_column: min_column,
      min_row: min_row,
      max_column: max_column,
      max_row: max_row
    }
  end
end
