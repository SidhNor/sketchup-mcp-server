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

  def test_exact_retirement_marks_only_targeted_feature_retired
    target = target_feature('region-a')
    preserve = preserve_feature('preserve-a')
    original = state_with_features([target, preserve])

    merged = merger.apply(
      state: original,
      delta: { 'retire_feature_ids' => [target.fetch('id')] }
    )

    features = merged.feature_intent.fetch('features')
    retired = features.find { |feature| feature.fetch('id') == target.fetch('id') }
    active = features.find { |feature| feature.fetch('id') == preserve.fetch('id') }

    assert_equal(2, features.length)
    assert_equal('retired', retired.dig('lifecycle', 'status'))
    assert_equal('active', active.dig('lifecycle', 'status'))
    assert_equal(1, merged.feature_intent.dig('effectiveIndex', 'countsByStatus', 'retired'))
    assert_equal([preserve.fetch('id')],
                 merged.feature_intent.dig('effectiveIndex', 'activeIdsByStrength', 'hard'))
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
    assert(merged.feature_intent.fetch('features').all? do |feature|
      feature.dig('lifecycle', 'status') == 'active'
    end)
  end

  def test_same_scope_soft_feature_upsert_supersedes_previous_active_feature
    original_target = target_feature('region-a', suffix: 'aaaaaaaaaaaa')
    replacement_target = target_feature('region-a', suffix: 'bbbbbbbbbbbb', priority: 40)
    original = state_with_features([original_target, preserve_feature('preserve-a')])

    merged = merger.apply(
      state: original,
      delta: { 'upsert_features' => [replacement_target] }
    )

    old_feature = merged.feature_intent.fetch('features').find do |feature|
      feature.fetch('id') == original_target.fetch('id')
    end
    new_feature = merged.feature_intent.fetch('features').find do |feature|
      feature.fetch('id') == replacement_target.fetch('id')
    end

    assert_equal('superseded', old_feature.dig('lifecycle', 'status'))
    assert_equal(replacement_target.fetch('id'), old_feature.dig('lifecycle', 'supersededBy'))
    assert_equal('active', new_feature.dig('lifecycle', 'status'))
    assert_equal([replacement_target.fetch('id')],
                 merged.feature_intent.dig('effectiveIndex', 'activeIdsByStrength', 'soft'))
  end

  def test_same_scope_corridor_upsert_supersedes_previous_active_corridor
    original_corridor = corridor_feature('corridor-a', suffix: 'aaaaaaaaaaaa')
    replacement_corridor = corridor_feature('corridor-a', suffix: 'bbbbbbbbbbbb')
    original = state_with_features([original_corridor])

    merged = merger.apply(
      state: original,
      delta: { 'upsert_features' => [replacement_corridor] }
    )

    assert_equal(
      'superseded',
      status_for(merged, original_corridor.fetch('id'))
    )
    assert_equal(
      [replacement_corridor.fetch('id')],
      merged.feature_intent.dig('effectiveIndex', 'activeIdsByStrength', 'firm')
    )
  end

  def test_same_scope_preserve_region_requires_exact_id_or_explicit_retirement
    original_preserve = preserve_feature('preserve-a', suffix: 'aaaaaaaaaaaa')
    overlapping_preserve = preserve_feature('preserve-a', suffix: 'bbbbbbbbbbbb')
    original = state_with_features([original_preserve])

    merged = merger.apply(
      state: original,
      delta: { 'upsert_features' => [overlapping_preserve] }
    )

    assert_equal('active', status_for(merged, original_preserve.fetch('id')))
    assert_equal('active', status_for(merged, overlapping_preserve.fetch('id')))
    assert_equal(
      [original_preserve.fetch('id'), overlapping_preserve.fetch('id')].sort,
      merged.feature_intent.dig('effectiveIndex', 'activeIdsByStrength', 'hard')
    )
  end

  def test_same_scope_fixed_control_relocation_requires_exact_id_or_explicit_retirement
    original_control = fixed_feature('fixed-a', suffix: 'aaaaaaaaaaaa')
    relocated_control = fixed_feature('fixed-a', suffix: 'bbbbbbbbbbbb')
    original = state_with_features([original_control])

    merged = merger.apply(
      state: original,
      delta: { 'upsert_features' => [relocated_control] }
    )

    assert_equal('active', status_for(merged, original_control.fetch('id')))
    assert_equal('active', status_for(merged, relocated_control.fetch('id')))
    assert_equal(
      [original_control.fetch('id'), relocated_control.fetch('id')].sort,
      merged.feature_intent.dig('effectiveIndex', 'activeIdsByStrength', 'hard')
    )
  end

  def test_same_id_upsert_replaces_payload_without_creating_superseded_copy
    original = target_feature('region-a', suffix: 'aaaaaaaaaaaa', priority: 20)
    replacement = target_feature('region-a', suffix: 'aaaaaaaaaaaa', priority: 45)
    state = state_with_features([original])

    merged = merger.apply(state: state, delta: { 'upsert_features' => [replacement] })
    features = merged.feature_intent.fetch('features')

    assert_equal(1, features.length)
    assert_equal(45, features.first.fetch('priority'))
    assert_equal('active', features.first.dig('lifecycle', 'status'))
    assert_equal(1, merged.feature_intent.dig('effectiveIndex', 'countsByStatus', 'active'))
  end

  def test_same_kind_different_scope_does_not_supersede_by_overlap
    original_target = target_feature('region-a', suffix: 'aaaaaaaaaaaa')
    separate_target = target_feature('region-b', suffix: 'bbbbbbbbbbbb')
    state = state_with_features([original_target])

    merged = merger.apply(state: state, delta: { 'upsert_features' => [separate_target] })

    assert_equal('active', status_for(merged, original_target.fetch('id')))
    assert_equal('active', status_for(merged, separate_target.fetch('id')))
    assert_equal(
      [original_target.fetch('id'), separate_target.fetch('id')].sort,
      merged.feature_intent.dig('effectiveIndex', 'activeIdsByStrength', 'soft')
    )
  end

  def test_same_scope_planar_survey_and_fairing_features_supersede_by_kind
    {
      'planar_region' => %w[boundary support],
      'survey_control' => %w[control support],
      'fairing_region' => ['support']
    }.each do |kind, roles|
      original = feature(kind, "#{kind}-scope", roles, 30, suffix: 'aaaaaaaaaaaa')
      replacement = feature(kind, "#{kind}-scope", roles, 40, suffix: 'bbbbbbbbbbbb')

      merged = merger.apply(
        state: state_with_features([original]),
        delta: { 'upsert_features' => [replacement] }
      )

      assert_equal('superseded', status_for(merged, original.fetch('id')), kind)
      assert_equal('active', status_for(merged, replacement.fetch('id')), kind)
    end
  end

  def test_retired_feature_is_not_resuperseded_by_later_same_scope_upsert
    original = target_feature('region-a', suffix: 'aaaaaaaaaaaa')
    replacement = target_feature('region-a', suffix: 'bbbbbbbbbbbb')
    retired_state = merger.apply(
      state: state_with_features([original]),
      delta: { 'retire_feature_ids' => [original.fetch('id')] }
    )

    merged = merger.apply(state: retired_state, delta: { 'upsert_features' => [replacement] })

    assert_equal('retired', status_for(merged, original.fetch('id')))
    assert_nil(feature_for(merged, original.fetch('id')).dig('lifecycle', 'supersededBy'))
    assert_equal('active', status_for(merged, replacement.fetch('id')))
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

  def target_feature(scope, priority: 20, suffix: 'aaaaaaaaaaaa')
    feature('target_region', scope, %w[boundary falloff], priority, suffix: suffix)
  end

  def corridor_feature(scope, suffix: 'aaaaaaaaaaaa')
    feature('linear_corridor', scope, %w[centerline side_transition], 70, suffix: suffix)
  end

  def preserve_feature(scope, suffix: 'aaaaaaaaaaaa')
    feature('preserve_region', scope, ['protected'], 80, suffix: suffix)
  end

  def fixed_feature(scope, suffix: 'aaaaaaaaaaaa')
    feature('fixed_control', scope, ['control'], 90, suffix: suffix)
  end

  def feature(kind, scope, roles, priority, suffix: 'aaaaaaaaaaaa')
    id = "feature:#{kind}:explicit_edit:#{scope}:#{suffix}"
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'semanticScope' => scope,
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

  def status_for(state, feature_id)
    feature_for(state, feature_id).dig('lifecycle', 'status')
  end

  def feature_for(state, feature_id)
    state.feature_intent.fetch('features').find do |feature|
      feature.fetch('id') == feature_id
    end
  end
end
