# frozen_string_literal: true

require_relative '../../test_helper'
require 'digest'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_set'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/storage/terrain_state_serializer'

class TerrainStateSerializerTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_serializes_v1_schema_with_digest
    serialized = serializer.serialize(build_state)
    parsed = JSON.parse(serialized)

    assert_equal('heightmap_grid', parsed.fetch('payloadKind'))
    assert_equal(3, parsed.fetch('schemaVersion'))
    assert_equal('sha256', parsed.fetch('digestAlgorithm'))
    assert_equal(SU_MCP::Terrain::FeatureIntentSet.default_h, parsed.fetch('featureIntent'))
    assert_match(/\A[0-9a-f]{64}\z/, parsed.fetch('digest'))
    assert_equal([10.0, nil, 11.5, 12.0], parsed.fetch('tiles').first.fetch('elevations'))
  end

  def test_canonical_digest_is_independent_of_hash_insertion_order
    first = serializer.serialize(build_state(source_summary: { 'b' => 2, 'a' => 1 }))
    second = serializer.serialize(build_state(source_summary: { 'a' => 1, 'b' => 2 }))

    assert_equal(JSON.parse(first).fetch('digest'), JSON.parse(second).fetch('digest'))
    assert_equal(first, second)
  end

  def test_round_trips_through_current_version_dispatch
    loaded = serializer.deserialize(serializer.serialize(build_state))

    assert_equal('loaded', loaded.fetch(:outcome))
    assert_equal(build_state, loaded.fetch(:state))
  end

  def test_migrates_v1_heightmap_payload_to_v3_without_upsampling
    v1_payload = serialized_v1_payload

    loaded = serializer.deserialize(JSON.generate(v1_payload))

    assert_equal('loaded', loaded.fetch(:outcome))
    assert_instance_of(SU_MCP::Terrain::TiledHeightmapState, loaded.fetch(:state))
    assert_equal('heightmap_grid', loaded.fetch(:state).payload_kind)
    assert_equal(3, loaded.fetch(:state).schema_version)
    assert_equal(SU_MCP::Terrain::FeatureIntentSet.default_h, loaded.fetch(:state).feature_intent)
    assert_equal(build_v1_state.elevations, loaded.fetch(:state).elevations)
    assert_equal(build_v1_state.spacing, loaded.fetch(:state).spacing)
  end

  def test_migrates_v2_tiled_payload_to_v3_with_empty_feature_intent
    v2_payload = JSON.parse(serializer.serialize(build_state))
    v2_payload.delete('featureIntent')
    v2_payload['schemaVersion'] = 2
    v2_payload['digest'] = Digest::SHA256.hexdigest(canonical_json(
                                                      v2_payload.reject do |key, _value|
                                                        %w[digest digestAlgorithm].include?(key)
                                                      end
                                                    ))

    loaded = serializer.deserialize(JSON.generate(v2_payload))

    assert_equal('loaded', loaded.fetch(:outcome))
    assert_equal(3, loaded.fetch(:state).schema_version)
    assert_equal(SU_MCP::Terrain::FeatureIntentSet.default_h, loaded.fetch(:state).feature_intent)
  end

  def test_deserializes_legacy_v3_feature_intent_with_effective_defaults
    payload = JSON.parse(serializer.serialize(build_state(feature_intent: legacy_feature_intent)))

    loaded = serializer.deserialize(JSON.generate(payload))

    feature_intent = loaded.fetch(:state).feature_intent
    feature = feature_intent.fetch('features').first
    assert_equal('active', feature.dig('lifecycle', 'status'))
    assert_equal('soft', feature.fetch('strengthClass'))
    assert_equal(feature.fetch('affectedWindow'), feature.fetch('relevanceWindow'))
    assert_match(/\A[a-f0-9]{64}\z/, feature_intent.dig('effectiveIndex', 'sourceDigest'))
    assert_equal(
      ['feature:target_region:explicit_edit:region-a:aaaaaaaaaaaa'],
      feature_intent.dig('effectiveIndex', 'activeIdsByStrength', 'soft')
    )
  end

  def test_digest_participates_in_feature_intent_ordering
    first = serializer.serialize(build_state(feature_intent: feature_intent(%w[b a])))
    second = serializer.serialize(build_state(feature_intent: feature_intent(%w[a b])))

    assert_equal(JSON.parse(first).fetch('digest'), JSON.parse(second).fetch('digest'))
    assert_equal(first, second)
  end

  def test_refuses_corrupt_json_and_malformed_valid_json
    assert_refusal('corrupt_payload', serializer.deserialize('{not-json'))

    invalid_json = JSON.generate('not an object')
    assert_refusal('invalid_payload', serializer.deserialize(invalid_json))
  end

  def test_refuses_unsupported_version_and_digest_mismatch
    unsupported = JSON.parse(serializer.serialize(build_state))
    unsupported['schemaVersion'] = 99
    assert_refusal('unsupported_version', serializer.deserialize(JSON.generate(unsupported)))

    tampered = JSON.parse(serializer.serialize(build_state))
    tampered['tiles'][0]['elevations'][0] = 99.0
    assert_refusal('integrity_failed', serializer.deserialize(JSON.generate(tampered)))
  end

  def test_default_migration_harness_refuses_older_schema_without_migrator
    older_schema = JSON.parse(serializer.serialize(build_state))
    older_schema['schemaVersion'] = 0

    assert_refusal('integrity_failed', serializer.deserialize(JSON.generate(older_schema)))
  end

  def test_reports_forced_migration_failure
    failing_serializer = SU_MCP::Terrain::TerrainStateSerializer.new(
      migration_harness: ->(_payload) { raise SU_MCP::Terrain::TerrainStateSerializer::MigrationError, 'boom' }
    )

    result = failing_serializer.deserialize(JSON.generate(serialized_v1_payload))

    assert_refusal('migration_failed', result)
  end

  private

  def serializer
    @serializer ||= SU_MCP::Terrain::TerrainStateSerializer.new
  end

  def build_state(overrides = {})
    SU_MCP::Terrain::TiledHeightmapState.new(
      {
        basis: BASIS,
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: { 'columns' => 2, 'rows' => 2 },
        elevations: [10.0, nil, 11.5, 12.0],
        revision: 1,
        state_id: 'terrain-state-1',
        source_summary: nil,
        constraint_refs: [],
        owner_transform_signature: 'transform-a',
        feature_intent: overrides.delete(:feature_intent) || SU_MCP::Terrain::FeatureIntentSet.default_h
      }.merge(overrides)
    )
  end

  def feature_intent(scopes)
    {
      'schemaVersion' => 3,
      'revision' => 1,
      'effectiveRevision' => 1,
      'features' => scopes.map do |scope|
        {
          'id' => "feature:target_region:explicit_edit:#{scope}:aaaaaaaaaaaa",
          'kind' => 'target_region',
          'sourceMode' => 'explicit_edit',
          'semanticScope' => scope,
          'strengthClass' => 'soft',
          'roles' => ['boundary'],
          'priority' => 30,
          'payload' => { 'semanticScope' => scope },
          'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                                'max' => { 'column' => 1, 'row' => 1 } },
          'relevanceWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                                 'max' => { 'column' => 1, 'row' => 1 } },
          'lifecycle' => {
            'status' => 'active',
            'supersededBy' => nil,
            'updatedAtRevision' => 1
          },
          'provenance' => {
            'originClass' => 'edit_terrain_surface',
            'originOperation' => 'target_height',
            'createdAtRevision' => 1,
            'updatedAtRevision' => 1
          }
        }
      end,
      'effectiveIndex' => {
        'effectiveRevision' => 1,
        'sourceDigest' => 'a' * 64,
        'activeIdsByStrength' => {
          'hard' => [],
          'firm' => [],
          'soft' => scopes.map do |scope|
            "feature:target_region:explicit_edit:#{scope}:aaaaaaaaaaaa"
          end.sort
        },
        'countsByStatus' => {
          'active' => scopes.length,
          'superseded' => 0,
          'deprecated' => 0,
          'retired' => 0
        },
        'countsByStrength' => { 'hard' => 0, 'firm' => 0, 'soft' => scopes.length }
      },
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    }
  end

  def legacy_feature_intent
    {
      'schemaVersion' => 3,
      'revision' => 1,
      'features' => [
        {
          'id' => 'feature:target_region:explicit_edit:region-a:aaaaaaaaaaaa',
          'kind' => 'target_region',
          'sourceMode' => 'explicit_edit',
          'roles' => ['boundary'],
          'priority' => 30,
          'payload' => { 'semanticScope' => 'region-a' },
          'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                                'max' => { 'column' => 1, 'row' => 1 } },
          'provenance' => {
            'originClass' => 'edit_terrain_surface',
            'originOperation' => 'target_height',
            'createdAtRevision' => 1,
            'updatedAtRevision' => 1
          }
        }
      ],
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    }
  end

  def build_v1_state(overrides = {})
    SU_MCP::Terrain::HeightmapState.new(
      {
        basis: BASIS,
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: { 'columns' => 2, 'rows' => 2 },
        elevations: [10.0, nil, 11.5, 12.0],
        revision: 1,
        state_id: 'terrain-state-1',
        source_summary: nil,
        constraint_refs: [],
        owner_transform_signature: 'transform-a'
      }.merge(overrides)
    )
  end

  def serialized_v1_payload
    payload = build_v1_state.to_h.merge('digestAlgorithm' => 'sha256')
    payload['digest'] = Digest::SHA256.hexdigest(canonical_json(
                                                   payload.reject do |key, _value|
                                                     %w[digest digestAlgorithm].include?(key)
                                                   end
                                                 ))
    payload
  end

  def canonical_json(value)
    JSON.generate(canonical_value(value))
  end

  def canonical_value(value)
    case value
    when Hash
      value.keys.map(&:to_s).sort.to_h { |key| [key, canonical_value(value.fetch(key))] }
    when Array
      value.map { |nested| canonical_value(nested) }
    else
      value
    end
  end

  def assert_refusal(code, result)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.fetch(:refusal).fetch(:code))
    assert_equal(false, result.fetch(:recoverable))
  end
end
