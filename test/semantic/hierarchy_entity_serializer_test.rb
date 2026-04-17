# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/semantic/hierarchy_entity_serializer'

class HierarchyEntitySerializerTest < Minitest::Test
  include SceneQueryTestSupport

  def setup
    @layer = SceneQueryTestSupport::FakeLayer.new('Layer0')
    @material = SceneQueryTestSupport::FakeMaterial.new('Pine')
    @serializer = SU_MCP::Semantic::HierarchyEntitySerializer.new
  end

  # rubocop:disable Metrics/MethodLength
  def test_serializes_managed_group_summary_with_children_count
    group = build_scene_query_group(
      entity_id: 101,
      origin_x: 0.0,
      layer: @layer,
      material: @material,
      details: {
        name: 'Managed Group',
        persistent_id: 1001,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'group-001' } },
        entities: [Object.new, Object.new]
      }
    )

    assert_equal(
      {
        sourceElementId: 'group-001',
        persistentId: '1001',
        entityId: '101',
        type: 'group',
        name: 'Managed Group',
        tag: 'Layer0',
        material: 'Pine',
        childrenCount: 2
      },
      @serializer.serialize(group)
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_serializes_unmanaged_component_summary_without_source_element_id
    component = build_scene_query_component(
      entity_id: 201,
      origin_x: 0.0,
      layer: @layer,
      material: @material,
      details: {
        name: 'Loose Component',
        persistent_id: 2001,
        definition_name: 'Tree Proxy Definition',
        entities: [Object.new]
      }
    )

    summary = @serializer.serialize(component)

    refute(summary.key?(:sourceElementId))
    assert_equal(1, summary[:childrenCount])
    assert_equal('componentinstance', summary[:type])
  end
end
