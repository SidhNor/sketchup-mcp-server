# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/effective_feature_view'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_set'
require_relative '../../../src/su_mcp/terrain/regions/sample_window'

class EffectiveFeatureViewTest < Minitest::Test
  def test_rejects_stale_effective_index_before_selection
    intent = feature_intent([
                              feature('hard-a', 'fixed_control', 'hard', status: 'active',
                                                                         window: output_window)
                            ]).merge(
                              'effectiveIndex' => SU_MCP::Terrain::FeatureIntentSet.default_h
                                .fetch('effectiveIndex')
                                .merge('sourceDigest' => '0' * 64)
                            )

    error = assert_raises(SU_MCP::Terrain::EffectiveFeatureView::StaleIndexError) do
      SU_MCP::Terrain::EffectiveFeatureView.new(intent).selection(window: output_window)
    end

    assert_equal('feature_effective_index_invalid', error.category)
  end

  def test_rejects_effective_index_bucket_drift_even_when_digest_matches
    intent = feature_intent([
                              feature('hard-a', 'fixed_control', 'hard', status: 'active',
                                                                         window: output_window)
                            ])
    intent['effectiveIndex'] = intent.fetch('effectiveIndex').merge(
      'activeIdsByStrength' => { 'hard' => [], 'firm' => [], 'soft' => [] }
    )

    assert_raises(SU_MCP::Terrain::EffectiveFeatureView::StaleIndexError) do
      SU_MCP::Terrain::EffectiveFeatureView.new(intent).selection(window: output_window)
    end
  end

  def test_selects_hard_features_globally_and_bounds_firm_soft_by_relevance
    hard = feature('hard-a', 'fixed_control', 'hard',
                   status: 'active', window: far_window)
    firm = feature('firm-a', 'linear_corridor', 'firm',
                   status: 'active', window: output_window)
    soft = feature('soft-a', 'target_region', 'soft',
                   status: 'active', window: far_window)
    retired = feature('old-soft', 'target_region', 'soft',
                      status: 'retired', window: output_window)

    selection = SU_MCP::Terrain::EffectiveFeatureView.new(
      feature_intent([soft, hard, retired, firm])
    ).selection(window: output_window)

    assert_equal(%w[firm-a hard-a], selection.fetch(:features).map { |item| item.fetch('id') })
    assert_equal(
      {
        active: 3,
        included: 2,
        excludedByStatus: 1,
        excludedByRelevance: 1,
        includedByStrength: { hard: 1, firm: 1, soft: 0 }
      },
      selection.fetch(:diagnostics)
    )
  end

  def test_bounds_firm_soft_when_selection_window_is_sample_window
    hard = feature('hard-a', 'fixed_control', 'hard',
                   status: 'active', window: far_window)
    firm = feature('firm-a', 'linear_corridor', 'firm',
                   status: 'active', window: output_window)
    soft = feature('soft-a', 'target_region', 'soft',
                   status: 'active', window: far_window)

    selection = SU_MCP::Terrain::EffectiveFeatureView.new(
      feature_intent([soft, hard, firm])
    ).selection(window: output_sample_window)

    assert_equal(%w[firm-a hard-a], selection.fetch(:features).map { |item| item.fetch('id') })
    assert_equal(
      {
        active: 3,
        included: 2,
        excludedByStatus: 0,
        excludedByRelevance: 1,
        includedByStrength: { hard: 1, firm: 1, soft: 0 }
      },
      selection.fetch(:diagnostics)
    )
  end

  private

  def feature_intent(features)
    SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 9,
      'features' => features,
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    ).to_h
  end

  def feature(id, kind, strength, status:, window:)
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'semanticScope' => id,
      'strengthClass' => strength,
      'roles' => roles_for(kind),
      'priority' => 1,
      'payload' => { 'semanticScope' => id },
      'affectedWindow' => window,
      'relevanceWindow' => window,
      'lifecycle' => {
        'status' => status,
        'supersededBy' => nil,
        'updatedAtRevision' => 9
      },
      'provenance' => {
        'originClass' => 'test',
        'originOperation' => kind,
        'createdAtRevision' => 9,
        'updatedAtRevision' => 9
      }
    }
  end

  def roles_for(kind)
    return ['control'] if kind == 'fixed_control'
    return ['centerline'] if kind == 'linear_corridor'

    ['support']
  end

  def output_window
    { 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 2, 'row' => 2 } }
  end

  def output_sample_window
    SU_MCP::Terrain::SampleWindow.new(
      min_column: 0,
      min_row: 0,
      max_column: 2,
      max_row: 2
    )
  end

  def far_window
    { 'min' => { 'column' => 10, 'row' => 10 }, 'max' => { 'column' => 12, 'row' => 12 } }
  end
end
