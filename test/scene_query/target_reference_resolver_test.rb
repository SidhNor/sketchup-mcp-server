# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/target_reference_resolver'

class TargetReferenceResolverTest < Minitest::Test
  include SceneQueryTestSupport

  def setup
    Sketchup.active_model_override = build_metadata_target_model
    @resolver = SU_MCP::TargetReferenceResolver.new
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_resolves_nested_managed_object_by_source_element_id
    result = @resolver.resolve('sourceElementId' => 'garden-shed-001')

    assert_equal('unique', result[:resolution])
    assert_equal(702, result.fetch(:entity).entityID)
  end

  def test_resolves_nested_managed_object_by_entity_id
    result = @resolver.resolve('entityId' => '702')

    assert_equal('unique', result[:resolution])
    assert_equal(7002, result.fetch(:entity).persistent_id)
  end

  def test_returns_none_when_no_entity_matches
    result = @resolver.resolve('sourceElementId' => 'missing-element-001')

    assert_equal('none', result[:resolution])
    refute_includes(result.keys, :entity)
  end

  def test_returns_ambiguous_when_multiple_entities_match
    result = @resolver.resolve('sourceElementId' => 'duplicate-managed-001')

    assert_equal('ambiguous', result[:resolution])
    refute_includes(result.keys, :entity)
  end

  private

  def build_metadata_target_model
    layer = FakeLayer.new('Structures')
    material = FakeMaterial.new('Timber')

    nested_managed = build_scene_query_group(
      entity_id: 702,
      origin_x: 12,
      layer: layer,
      material: material,
      details: {
        name: 'Garden Shed',
        persistent_id: 7002,
        entities: [],
        attributes: { 'su_mcp' => { 'sourceElementId' => 'garden-shed-001' } }
      }
    )
    duplicate_one = build_scene_query_group(
      entity_id: 703,
      origin_x: 16,
      layer: layer,
      material: material,
      details: {
        name: 'Duplicate A',
        persistent_id: 7003,
        entities: [],
        attributes: { 'su_mcp' => { 'sourceElementId' => 'duplicate-managed-001' } }
      }
    )
    duplicate_two = build_scene_query_group(
      entity_id: 704,
      origin_x: 20,
      layer: layer,
      material: material,
      details: {
        name: 'Duplicate B',
        persistent_id: 7004,
        entities: [],
        attributes: { 'su_mcp' => { 'sourceElementId' => 'duplicate-managed-001' } }
      }
    )
    parent_group = build_scene_query_group(
      entity_id: 701,
      origin_x: 10,
      layer: layer,
      material: material,
      details: {
        name: 'Organization Group',
        persistent_id: 7001,
        entities: [nested_managed, duplicate_one]
      }
    )

    FakeModel.new(
      state: {
        entities: [parent_group, duplicate_two],
        active_entities: [],
        selection: [],
        materials: [material],
        layers: [layer],
        bounds: build_bounds(origin_x: -5)
      },
      details: { options: default_options }
    )
  end
end
