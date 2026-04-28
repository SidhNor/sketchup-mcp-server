# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/managed_object_metadata'
require_relative '../../src/su_mcp/semantic/serializer'

class SemanticSerializerTest < Minitest::Test
  include SemanticTestSupport

  METERS_TO_INTERNAL = 39.37007874015748

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

  def test_serializes_type_specific_semantic_fields_when_present
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    serializer = SU_MCP::Semantic::Serializer.new

    metadata.write!(
      entity,
      'sourceElementId' => 'main-walk-001',
      'semanticType' => 'path',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'width' => 1.6,
      'thickness' => 0.1
    )

    payload = serializer.serialize(entity)

    assert_equal(1.6, payload[:width])
    assert_equal(0.1, payload[:thickness])
  end

  def test_serializes_semantic_bounds_back_to_public_meters
    entity = build_semantic_model.active_entities.add_group
    entity.bounds = planting_mass_bounds_in_internal_units
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    serializer = SU_MCP::Semantic::Serializer.new

    metadata.write!(
      entity,
      'sourceElementId' => 'hedge-001',
      'semanticType' => 'planting_mass',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )

    payload = serializer.serialize(entity)

    assert_equal([0.0, 0.0, 0.0], payload.dig(:bounds, :min))
    assert_equal([4.0, 2.0, 1.8], payload.dig(:bounds, :max))
  end

  private

  def planting_mass_bounds_in_internal_units
    SceneQueryTestSupport::FakeBounds.new(
      min: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
      max: SceneQueryTestSupport::FakePoint.new(
        4.0 * METERS_TO_INTERNAL,
        2.0 * METERS_TO_INTERNAL,
        1.8 * METERS_TO_INTERNAL
      ),
      center: SceneQueryTestSupport::FakePoint.new(
        2.0 * METERS_TO_INTERNAL,
        1.0 * METERS_TO_INTERNAL,
        0.9 * METERS_TO_INTERNAL
      ),
      size: [
        4.0 * METERS_TO_INTERNAL,
        2.0 * METERS_TO_INTERNAL,
        1.8 * METERS_TO_INTERNAL
      ]
    )
  end
end
