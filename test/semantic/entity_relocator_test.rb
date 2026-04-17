# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/semantic/entity_relocator'

class EntityRelocatorTest < Minitest::Test
  include SemanticTestSupport
  include SceneQueryTestSupport

  def setup
    @model = build_semantic_model
    @layer = @model.layers.first
    @material = @model.materials.to_a.first
    @relocator = SU_MCP::Semantic::EntityRelocator.new
  end

  def test_relocates_supported_group_entities_into_target_parent
    child_group = build_sample_surface_group(
      entity_id: 101,
      persistent_id: 1001,
      name: 'Tree Wrapper',
      layer: @layer,
      material: @material,
      child_faces: [],
      source_element_id: 'tree-001'
    )
    target_parent = @model.active_entities.add_group

    result = @relocator.relocate(entities: [child_group], parent: target_parent)

    assert_equal(1, result.length)
    assert_equal('tree-001', result.first.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_relocates_supported_component_entities_into_target_parent
    child_component = build_sample_surface_component(
      entity_id: 201,
      persistent_id: 2001,
      name: 'House Extension',
      definition_name: 'House Extension Definition',
      layer: @layer,
      material: @material,
      child_faces: [],
      source_element_id: 'house-extension-001'
    )
    target_parent = @model.active_entities.add_group

    result = @relocator.relocate(entities: [child_component], parent: target_parent)

    assert_equal(1, result.length)
    assert_equal('house-extension-001', result.first.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_preserves_wrapper_properties_when_relocation_recreates_wrapper
    child_group = build_sample_surface_group(
      entity_id: 301,
      persistent_id: 3001,
      name: 'Retained Wrapper',
      layer: @layer,
      material: @material,
      child_faces: [],
      source_element_id: 'wrapper-001'
    )
    target_parent = @model.active_entities.add_group

    result = @relocator.relocate(entities: [child_group], parent: target_parent)

    assert_equal('Retained Wrapper', result.first.name)
    assert_equal(@layer.name, result.first.layer.name)
    assert_equal(@material.display_name, result.first.material.display_name)
  end

  # rubocop:disable Metrics/MethodLength
  def test_returns_relocated_entities_in_input_order
    first = build_sample_surface_group(
      entity_id: 401,
      persistent_id: 4001,
      name: 'First Wrapper',
      layer: @layer,
      material: @material,
      child_faces: [],
      source_element_id: 'first-001'
    )
    second = build_sample_surface_component(
      entity_id: 402,
      persistent_id: 4002,
      name: 'Second Wrapper',
      definition_name: 'Second Definition',
      layer: @layer,
      material: @material,
      child_faces: [],
      source_element_id: 'second-001'
    )
    target_parent = @model.active_entities.add_group

    result = @relocator.relocate(entities: [first, second], parent: target_parent)

    assert_equal(
      %w[first-001 second-001],
      result.map { |entity| entity.get_attribute('su_mcp', 'sourceElementId') }
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_preserves_source_element_id_when_runtime_ids_refresh
    child_group = build_sample_surface_group(
      entity_id: 501,
      persistent_id: 5001,
      name: 'Refresh Wrapper',
      layer: @layer,
      material: @material,
      child_faces: [],
      source_element_id: 'refresh-001'
    )
    target_parent = @model.active_entities.add_group

    result = @relocator.relocate(entities: [child_group], parent: target_parent)

    assert_equal('refresh-001', result.first.get_attribute('su_mcp', 'sourceElementId'))
    refute_nil(result.first.entityID)
    refute_nil(result.first.persistent_id)
  end

  # rubocop:disable Metrics/AbcSize
  def test_preserves_nested_group_contents_when_relocating_group_wrappers
    child_group = @model.active_entities.add_group
    child_group.set_attribute('su_mcp', 'sourceElementId', 'nested-wrapper-001')
    nested_group = child_group.entities.add_group
    nested_group.set_attribute('su_mcp', 'sourceElementId', 'nested-child-001')
    child_group.entities.add_face(
      [0.0, 0.0, 0.0],
      [1.0, 0.0, 0.0],
      [1.0, 1.0, 0.0]
    )
    target_parent = @model.active_entities.add_group

    result = @relocator.relocate(entities: [child_group], parent: target_parent)

    relocated_group = result.first
    assert_equal('nested-wrapper-001', relocated_group.get_attribute('su_mcp', 'sourceElementId'))
    assert_equal(1, relocated_group.entities.groups.length)
    assert_equal(1, relocated_group.entities.faces.length)
    assert_equal(
      'nested-child-001',
      relocated_group.entities.groups.first.get_attribute('su_mcp', 'sourceElementId')
    )
  end
  # rubocop:enable Metrics/AbcSize
end
