# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/terrain_state_serializer'
require_relative '../../src/su_mcp/terrain/attribute_terrain_storage'
require_relative '../../src/su_mcp/terrain/terrain_repository'

class TerrainRepositoryTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_save_and_load_round_trip_without_raw_storage_handles
    owner = TerrainOwnerDouble.new(transform_signature: 'transform-a')
    repository = SU_MCP::Terrain::TerrainRepository.new

    saved = repository.save(owner, build_state)
    loaded = repository.load(owner)

    assert_equal('saved', saved.fetch(:outcome))
    assert_equal('loaded', loaded.fetch(:outcome))
    assert_equal(build_state, loaded.fetch(:state))
    assert_kind_of(Integer, loaded.fetch(:summary).fetch(:serializedBytes))
    refute_includes(loaded.keys, :storage)
    refute_includes(loaded.keys, :attribute_dictionary)
  end

  def test_missing_state_is_recoverable_absence
    result = SU_MCP::Terrain::TerrainRepository.new.load(TerrainOwnerDouble.new)

    assert_equal('absent', result.fetch(:outcome))
    assert_equal('missing_state', result.fetch(:reason))
    assert_equal(true, result.fetch(:recoverable))
  end

  def test_repository_refusals_are_terminal_for_unsafe_payloads
    owner = TerrainOwnerDouble.new
    repository = SU_MCP::Terrain::TerrainRepository.new
    repository.storage.save_payload(owner, '{bad-json')

    result = repository.load(owner)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('corrupt_payload', result.fetch(:refusal).fetch(:code))
    assert_equal(false, result.fetch(:recoverable))
  end

  def test_oversized_payload_refuses_before_write
    owner = TerrainOwnerDouble.new
    repository = SU_MCP::Terrain::TerrainRepository.new(
      storage: SU_MCP::Terrain::AttributeTerrainStorage.new(max_serialized_bytes: 10)
    )

    result = repository.save(owner, build_state)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('payload_too_large', result.fetch(:refusal).fetch(:code))
    assert_nil(owner.get_attribute('su_mcp_terrain', 'statePayload'))
  end

  def test_representative_512_grid_payload_is_under_default_threshold
    elevations = Array.new(512 * 512, 1.25)
    state = build_state(
      dimensions: { 'columns' => 512, 'rows' => 512 },
      elevations: elevations
    )

    result = SU_MCP::Terrain::TerrainRepository.new.save(TerrainOwnerDouble.new, state)

    assert_equal('saved', result.fetch(:outcome))
    assert_operator(result.fetch(:summary).fetch(:serializedBytes), :<, SU_MCP::Terrain::AttributeTerrainStorage::MAX_SERIALIZED_BYTES)
  end

  def test_owner_transform_mismatch_refuses_on_load
    owner = TerrainOwnerDouble.new(transform_signature: 'transform-a')
    repository = SU_MCP::Terrain::TerrainRepository.new
    repository.save(owner, build_state)
    owner.transform_signature = 'transform-b'

    result = repository.load(owner)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('owner_transform_unsupported', result.fetch(:refusal).fetch(:code))
  end

  def test_owner_transform_matrix_signature_does_not_false_mismatch_on_load
    owner = TerrainOwnerDouble.new(transformation: MatrixTransformation.new([2.0, 3.0, 4.0]))
    repository = SU_MCP::Terrain::TerrainRepository.new
    signature = repository.storage.owner_transform_signature(owner)
    state = build_state(owner_transform_signature: signature)

    repository.save(owner, state)
    result = repository.load(owner)

    assert_equal('loaded', result.fetch(:outcome))
  end

  def test_write_failure_is_returned_as_repository_refusal
    result = SU_MCP::Terrain::TerrainRepository.new.save(
      TerrainOwnerDouble.new(write_error: RuntimeError.new('nope')),
      build_state
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('write_failed', result.fetch(:refusal).fetch(:code))
  end

  class TerrainOwnerDouble
    attr_accessor :transform_signature
    attr_reader :attributes, :transformation

    def initialize(transform_signature: nil, write_error: nil, transformation: nil)
      @write_error = write_error
      @attributes = Hash.new { |hash, key| hash[key] = {} }
      @transform_signature = transform_signature
      @transformation = transformation
    end

    def set_attribute(dictionary, key, value)
      raise @write_error if @write_error

      attributes[dictionary][key] = value
    end

    def get_attribute(dictionary, key, default = nil)
      attributes.fetch(dictionary, {}).fetch(key, default)
    end

    def delete_attribute(dictionary, key = nil)
      return attributes.delete(dictionary) if key.nil?

      attributes.fetch(dictionary, {}).delete(key)
    end
  end

  class MatrixTransformation
    def initialize(translation)
      @translation = translation
    end

    def to_a
      [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        @translation[0], @translation[1], @translation[2], 1.0
      ]
    end
  end

  private

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
end
