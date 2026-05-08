# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_set'

class FeatureIntentSetTest < Minitest::Test
  def test_default_feature_intent_payload_is_json_safe_and_schema_v3_ready
    payload = SU_MCP::Terrain::FeatureIntentSet.default_h

    assert_equal(3, payload.fetch('schemaVersion'))
    assert_equal(0, payload.fetch('revision'))
    assert_equal(0, payload.fetch('effectiveRevision'))
    assert_equal([], payload.fetch('features'))
    assert_equal(
      {
        'effectiveRevision' => 0,
        'activeIdsByStrength' => { 'hard' => [], 'firm' => [], 'soft' => [] },
        'countsByStatus' => {
          'active' => 0,
          'superseded' => 0,
          'deprecated' => 0,
          'retired' => 0
        },
        'countsByStrength' => { 'hard' => 0, 'firm' => 0, 'soft' => 0 }
      },
      payload.fetch('effectiveIndex').reject { |key, _value| key == 'sourceDigest' }
    )
    assert_match(/\A[a-f0-9]{64}\z/, payload.dig('effectiveIndex', 'sourceDigest'))
    assert_equal('grid_relative_v1', payload.dig('generation', 'pointificationPolicy'))
    refute_includes(JSON.generate(payload), 'Sketchup::')
  end

  def test_semantic_id_is_stable_for_reordered_payload_keys_and_revision_changes
    first = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'target_region',
      source_mode: 'explicit_edit',
      semantic_scope: 'region-a',
      payload: { 'bounds' => { 'maxX' => 3.0, 'minX' => 1.0 }, 'revision' => 1 }
    )
    second = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'target_region',
      source_mode: 'explicit_edit',
      semantic_scope: 'region-a',
      payload: { 'revision' => 99, 'bounds' => { 'minX' => 1.0, 'maxX' => 3.0 } }
    )

    assert_equal(first, second)
    assert_match(/\Afeature:target_region:explicit_edit:region-a:[0-9a-f]{12}\z/, first)
  end

  def test_semantic_id_normalizes_owner_local_numbers_to_six_decimal_places
    first = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'fixed_control',
      source_mode: 'explicit_edit',
      semantic_scope: 'fixed-a',
      payload: { 'point' => { 'x' => 1.1234564, 'y' => 2.0 } }
    )
    second = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'fixed_control',
      source_mode: 'explicit_edit',
      semantic_scope: 'fixed-a',
      payload: { 'point' => { 'x' => 1.12345649, 'y' => 2.0 } }
    )

    assert_equal(first, second)
  end

  def test_semantic_id_changes_for_material_geometry_changes
    first = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'target_region',
      source_mode: 'explicit_edit',
      semantic_scope: 'region-a',
      payload: { 'center' => { 'x' => 1.0, 'y' => 2.0 }, 'radius' => 3.0 }
    )
    second = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'target_region',
      source_mode: 'explicit_edit',
      semantic_scope: 'region-a',
      payload: { 'center' => { 'x' => 1.0, 'y' => 2.0 }, 'radius' => 4.0 }
    )

    refute_equal(first, second)
  end

  def test_semantic_id_excludes_transformed_owner_and_sketchup_identity_fields
    first = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'fixed_control',
      source_mode: 'explicit_edit',
      semantic_scope: 'fixed-a',
      payload: identity_payload.merge('ownerTransformSignature' => 'transform-a',
                                      'entityId' => 123)
    )
    second = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'fixed_control',
      source_mode: 'explicit_edit',
      semantic_scope: 'fixed-a',
      payload: identity_payload.merge('ownerTransformSignature' => 'transform-b',
                                      'entityId' => 456)
    )

    assert_equal(first, second)
  end

  def test_semantic_id_uses_user_control_id_for_off_grid_non_square_control_scope
    first = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'survey_control',
      source_mode: 'explicit_edit',
      semantic_scope: 'survey:control-7',
      payload: {
        'id' => 'control-7',
        'point' => { 'x' => 1.25, 'y' => 2.75, 'z' => 10.0 },
        'spacing' => { 'x' => 2.0, 'y' => 3.0 }
      }
    )
    second = SU_MCP::Terrain::FeatureIntentSet.semantic_id_for(
      kind: 'survey_control',
      source_mode: 'explicit_edit',
      semantic_scope: 'survey:control-8',
      payload: {
        'id' => 'control-8',
        'point' => { 'x' => 1.25, 'y' => 2.75, 'z' => 10.0 },
        'spacing' => { 'x' => 2.0, 'y' => 3.0 }
      }
    )

    refute_equal(first, second)
  end

  def test_normalizes_features_into_canonical_id_order
    set = SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 5,
      'features' => [feature('feature:target_region:explicit_edit:b:bbbbbbbbbbbb'),
                     feature('feature:target_region:explicit_edit:a:aaaaaaaaaaaa')],
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    )

    assert_equal(
      %w[feature:target_region:explicit_edit:a:aaaaaaaaaaaa
         feature:target_region:explicit_edit:b:bbbbbbbbbbbb],
      set.to_h.fetch('features').map { |candidate| candidate.fetch('id') }
    )
  end

  def test_legacy_feature_normalizes_effective_fields_without_losing_identity
    set = SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 5,
      'features' => [
        feature('feature:target_region:explicit_edit:region-a:aaaaaaaaaaaa').merge(
          'payload' => { 'semanticScope' => 'region-a' }
        )
      ],
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    )

    normalized = set.to_h.fetch('features').first
    assert_equal('region-a', normalized.fetch('semanticScope'))
    assert_equal('soft', normalized.fetch('strengthClass'))
    assert_equal(normalized.fetch('affectedWindow'), normalized.fetch('relevanceWindow'))
    assert_equal('active', normalized.dig('lifecycle', 'status'))
    assert_nil(normalized.dig('lifecycle', 'supersededBy'))
    assert_equal(5, normalized.dig('lifecycle', 'updatedAtRevision'))
  end

  def test_preserves_supplied_lifecycle_relevance_and_effective_index
    payload = {
      'schemaVersion' => 3,
      'revision' => 7,
      'effectiveRevision' => 3,
      'features' => [
        feature('feature:linear_corridor:explicit_edit:corridor-a:bbbbbbbbbbbb').merge(
          'semanticScope' => 'corridor-a',
          'strengthClass' => 'firm',
          'relevanceWindow' => { 'min' => { 'column' => 2, 'row' => 2 },
                                 'max' => { 'column' => 3, 'row' => 3 } },
          'lifecycle' => {
            'status' => 'superseded',
            'supersededBy' => 'feature:linear_corridor:explicit_edit:corridor-a:cccccccccccc',
            'updatedAtRevision' => 7
          }
        )
      ],
      'effectiveIndex' => {
        'effectiveRevision' => 3,
        'sourceDigest' => 'a' * 64,
        'activeIdsByStrength' => { 'hard' => [], 'firm' => [], 'soft' => [] },
        'countsByStatus' => {
          'active' => 0,
          'superseded' => 1,
          'deprecated' => 0,
          'retired' => 0
        },
        'countsByStrength' => { 'hard' => 0, 'firm' => 0, 'soft' => 0 }
      },
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    }

    normalized = SU_MCP::Terrain::FeatureIntentSet.new(payload).to_h

    assert_equal(3, normalized.fetch('effectiveRevision'))
    assert_equal(payload.fetch('effectiveIndex'), normalized.fetch('effectiveIndex'))
    assert_equal('superseded', normalized.dig('features', 0, 'lifecycle', 'status'))
    assert_equal('corridor-a', normalized.dig('features', 0, 'semanticScope'))
  end

  def test_effective_index_digest_ignores_provenance_revision_churn
    feature_payload = feature('feature:target_region:explicit_edit:region-a:aaaaaaaaaaaa')
    first = SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 7,
      'features' => [feature_payload],
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    ).to_h
    second = SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 8,
      'features' => [
        feature_payload.merge(
          'provenance' => feature_payload.fetch('provenance').merge(
            'updatedAtRevision' => 99
          )
        )
      ],
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    ).to_h

    assert_equal(
      first.dig('effectiveIndex', 'sourceDigest'),
      second.dig('effectiveIndex', 'sourceDigest')
    )
  end

  def test_effective_index_digest_changes_when_query_driving_lifecycle_changes
    feature_payload = feature('feature:target_region:explicit_edit:region-a:aaaaaaaaaaaa')
    active = SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 7,
      'features' => [feature_payload],
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    ).to_h
    retired = SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 7,
      'features' => [
        feature_payload.merge(
          'lifecycle' => {
            'status' => 'retired',
            'supersededBy' => nil,
            'updatedAtRevision' => 99
          }
        )
      ],
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    ).to_h

    refute_equal(
      active.dig('effectiveIndex', 'sourceDigest'),
      retired.dig('effectiveIndex', 'sourceDigest')
    )
    assert_equal([], retired.dig('effectiveIndex', 'activeIdsByStrength', 'soft'))
  end

  def test_rejects_unknown_feature_kind_and_role
    assert_raises(ArgumentError) do
      SU_MCP::Terrain::FeatureIntentSet.new(
        'features' => [feature('feature:bad:explicit_edit:x:aaaaaaaaaaaa').merge('kind' => 'bad')]
      )
    end

    assert_raises(ArgumentError) do
      SU_MCP::Terrain::FeatureIntentSet.new(
        'features' => [
          feature('feature:target_region:explicit_edit:x:aaaaaaaaaaaa').merge(
            'roles' => ['unknown_role']
          )
        ]
      )
    end
  end

  def test_rejects_unknown_lifecycle_status_and_strength_class
    assert_raises(ArgumentError) do
      SU_MCP::Terrain::FeatureIntentSet.new(
        'features' => [
          feature('feature:target_region:explicit_edit:x:aaaaaaaaaaaa').merge(
            'lifecycle' => { 'status' => 'zombie' }
          )
        ]
      )
    end

    assert_raises(ArgumentError) do
      SU_MCP::Terrain::FeatureIntentSet.new(
        'features' => [
          feature('feature:target_region:explicit_edit:x:aaaaaaaaaaaa').merge(
            'strengthClass' => 'medium-ish'
          )
        ]
      )
    end
  end

  private

  def identity_payload
    {
      'id' => 'fixed-1',
      'point' => { 'x' => 1.25, 'y' => 2.75 },
      'spacing' => { 'x' => 2.0, 'y' => 3.0 }
    }
  end

  def feature(id)
    {
      'id' => id,
      'kind' => 'target_region',
      'sourceMode' => 'explicit_edit',
      'roles' => ['boundary'],
      'priority' => 30,
      'payload' => { 'region' => { 'type' => 'rectangle' } },
      'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                            'max' => { 'column' => 1, 'row' => 1 } },
      'provenance' => {
        'originClass' => 'edit_terrain_surface',
        'originOperation' => 'target_height',
        'createdAtRevision' => 2,
        'updatedAtRevision' => 2
      }
    }
  end
end
