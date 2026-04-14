# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

require_relative 'test_helper'
require_relative 'support/semantic_test_support'
require_relative '../src/su_mcp/semantic/managed_object_metadata'
require_relative '../src/su_mcp/semantic/serializer'

class SemanticSerializerTest < Minitest::Test
  include SemanticTestSupport

  def test_serializes_wrapper_group_into_a_managed_object_payload
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    serializer = SU_MCP::Semantic::Serializer.new

    metadata.write!(
      entity,
      'sourceElementId' => 'terrace-001',
      'semanticType' => 'pad',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )

    payload = serializer.serialize(entity)

    assert_equal('terrace-001', payload[:sourceElementId])
    assert_equal('pad', payload[:semanticType])
    assert_equal('proposed', payload[:status])
    assert_equal('Created', payload[:state])
    assert_equal(entity.entityID.to_s, payload[:entityId])
    assert_equal(entity.persistent_id.to_s, payload[:persistentId])
    assert(payload[:bounds])
  end
end
# rubocop:enable Metrics/AbcSize
