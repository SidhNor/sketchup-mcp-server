# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/attribute_terrain_storage'

class AttributeTerrainStorageTest < Minitest::Test
  def test_writes_payload_under_terrain_namespace_not_su_mcp
    owner = TerrainOwnerDouble.new
    storage = SU_MCP::Terrain::AttributeTerrainStorage.new

    result = storage.save_payload(owner, 'payload-json')

    assert_equal({ outcome: 'saved', serialized_bytes: 12 }, result)
    assert_equal('payload-json', owner.get_attribute('su_mcp_terrain', 'statePayload'))
    assert_nil(owner.get_attribute('su_mcp', 'statePayload'))
    refute_includes(owner.attributes.fetch('su_mcp', {}), 'payload-json')
  end

  def test_reads_and_deletes_payload_without_exposing_attribute_handles
    owner = TerrainOwnerDouble.new
    storage = SU_MCP::Terrain::AttributeTerrainStorage.new
    storage.save_payload(owner, 'payload-json')

    assert_equal('payload-json', storage.load_payload(owner))
    storage.delete_payload(owner)
    assert_nil(storage.load_payload(owner))
  end

  def test_reports_write_failure_as_json_safe_refusal
    owner = TerrainOwnerDouble.new(write_error: RuntimeError.new('disk full'))
    result = SU_MCP::Terrain::AttributeTerrainStorage.new.save_payload(owner, 'payload-json')

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('write_failed', result.fetch(:refusal).fetch(:code))
    assert_equal(false, result.fetch(:recoverable))
  end

  def test_owner_transform_signature_uses_stable_matrix_values
    owner = TerrainOwnerDouble.new(transformation: UnstableTransformation.new)
    storage = SU_MCP::Terrain::AttributeTerrainStorage.new

    first = storage.owner_transform_signature(owner)
    second = storage.owner_transform_signature(owner)

    assert_equal(first, second)
    assert_equal('matrix:1,0,0,0,0,1,0,0,0,0,1,0,2,3,4,1', first)
  end

  class TerrainOwnerDouble
    attr_reader :attributes, :transformation

    def initialize(write_error: nil, transformation: nil)
      @write_error = write_error
      @transformation = transformation
      @attributes = Hash.new { |hash, key| hash[key] = {} }
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

  class UnstableTransformation
    def to_a
      [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        2.0, 3.0, 4.0, 1.0
      ]
    end
  end
end
