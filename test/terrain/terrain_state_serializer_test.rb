# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/terrain_state_serializer'

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
    assert_equal(1, parsed.fetch('schemaVersion'))
    assert_equal('sha256', parsed.fetch('digestAlgorithm'))
    assert_match(/\A[0-9a-f]{64}\z/, parsed.fetch('digest'))
    assert_equal([10.0, nil, 11.5, 12.0], parsed.fetch('elevations'))
  end

  def test_canonical_digest_is_independent_of_hash_insertion_order
    first = serializer.serialize(build_state(source_summary: { 'b' => 2, 'a' => 1 }))
    second = serializer.serialize(build_state(source_summary: { 'a' => 1, 'b' => 2 }))

    assert_equal(JSON.parse(first).fetch('digest'), JSON.parse(second).fetch('digest'))
    assert_equal(first, second)
  end

  def test_round_trips_through_current_version_migration_harness
    loaded = serializer.deserialize(serializer.serialize(build_state))

    assert_equal('loaded', loaded.fetch(:outcome))
    assert_equal(build_state, loaded.fetch(:state))
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
    tampered['elevations'][0] = 99.0
    assert_refusal('integrity_failed', serializer.deserialize(JSON.generate(tampered)))
  end

  def test_default_migration_harness_refuses_older_schema_without_migrator
    older_schema = JSON.parse(serializer.serialize(build_state))
    older_schema['schemaVersion'] = 0

    assert_refusal('migration_failed', serializer.deserialize(JSON.generate(older_schema)))
  end

  def test_reports_forced_migration_failure
    failing_serializer = SU_MCP::Terrain::TerrainStateSerializer.new(
      migration_harness: ->(_payload) { raise SU_MCP::Terrain::TerrainStateSerializer::MigrationError, 'boom' }
    )

    result = failing_serializer.deserialize(serializer.serialize(build_state))

    assert_refusal('migration_failed', result)
  end

  private

  def serializer
    @serializer ||= SU_MCP::Terrain::TerrainStateSerializer.new
  end

  def build_state(overrides = {})
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

  def assert_refusal(code, result)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.fetch(:refusal).fetch(:code))
    assert_equal(false, result.fetch(:recoverable))
  end
end
