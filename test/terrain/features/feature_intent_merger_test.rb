# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_set'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_merger'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class FeatureIntentMergerTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_upsert_replaces_same_semantic_feature_and_retains_overlapping_unrelated_features
    original = state_with_features([target_feature('region-a', priority: 20),
                                    preserve_feature('preserve-a')])
    updated = target_feature('region-a', priority: 40)

    merged = merger.apply(
      state: original,
      delta: {
        'invalidation_window' => updated.fetch('affectedWindow'),
        'upsert_features' => [updated]
      }
    )

    features = merged.feature_intent.fetch('features')
    assert_equal(2, features.length)
    assert_equal(40, features.find { |feature| feature.fetch('id') == updated.fetch('id') }
      .fetch('priority'))
    assert(features.any? { |feature| feature.fetch('kind') == 'preserve_region' })
  end

  def test_exact_retirement_removes_only_targeted_feature_id
    target = target_feature('region-a')
    preserve = preserve_feature('preserve-a')
    original = state_with_features([target, preserve])

    merged = merger.apply(
      state: original,
      delta: { 'retire_feature_ids' => [target.fetch('id')] }
    )

    assert_equal([preserve.fetch('id')], merged.feature_intent.fetch('features').map do |feature|
      feature.fetch('id')
    end)
  end

  def test_overlap_window_never_retires_by_itself
    original = state_with_features([target_feature('region-a'), preserve_feature('preserve-a')])

    merged = merger.apply(
      state: original,
      delta: {
        'invalidation_window' => { 'min' => { 'column' => 0, 'row' => 0 },
                                   'max' => { 'column' => 1, 'row' => 1 } }
      }
    )

    assert_equal(2, merged.feature_intent.fetch('features').length)
  end

  private

  def merger
    @merger ||= SU_MCP::Terrain::FeatureIntentMerger.new
  end

  def state_with_features(features)
    build_state.with_feature_intent(
      {
        'schemaVersion' => 3,
        'revision' => 1,
        'features' => features,
        'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
      }
    )
  end

  def build_state
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 2, 'rows' => 2 },
      elevations: [1.0, 1.0, 1.0, 1.0],
      revision: 1,
      state_id: 'state-1'
    )
  end

  def target_feature(scope, priority: 20)
    feature('target_region', scope, %w[boundary falloff], priority)
  end

  def preserve_feature(scope)
    feature('preserve_region', scope, ['protected'], 80)
  end

  def feature(kind, scope, roles, priority)
    id = "feature:#{kind}:explicit_edit:#{scope}:aaaaaaaaaaaa"
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'roles' => roles,
      'priority' => priority,
      'payload' => { 'semanticScope' => scope },
      'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                            'max' => { 'column' => 1, 'row' => 1 } },
      'provenance' => {
        'originClass' => 'edit_terrain_surface',
        'originOperation' => kind,
        'createdAtRevision' => 1,
        'updatedAtRevision' => 1
      }
    }
  end
end
