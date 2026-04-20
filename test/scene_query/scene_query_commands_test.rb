# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/scene_query_commands'

module SceneQueryCommandsAssertions
  def assert_scene_counts(result)
    assert_equal(true, result[:success])
    assert_equal(2, result.dig(:counts, :top_level_entities))
    assert_equal(1, result.dig(:counts, :selected_entities))
    assert_equal(1, result.dig(:counts, :materials))
    assert_equal(1, result.dig(:counts, :layers))
    assert_equal({ 'group' => 1, 'face' => 1 }, result.dig(:counts, :by_type))
  end

  def assert_serialized_group(entity)
    assert_equal(101, entity[:id])
    assert_equal('group', entity[:type])
    assert_equal('Top Group', entity[:name])
    assert_equal('Layer0', entity[:layer])
    assert_equal('Pine', entity[:material])
    assert_equal(1, entity[:children_count])
    assert_equal([0.5, 1.0, 1.5], entity[:origin])
  end
end

class SceneQueryCommandsTest < Minitest::Test
  include SceneQueryTestSupport
  include SceneQueryCommandsAssertions

  def setup
    @commands = SU_MCP::SceneQueryCommands.new
    @model = build_scene_query_model
    Sketchup.active_model_override = @model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_list_resources_uses_top_level_entities_not_active_edit_context
    resources = @commands.list_resources

    assert_equal([101, 102], resources.map { |resource| resource[:id] })
    assert_equal(%w[group face], resources.map { |resource| resource[:type] })
  end

  def test_get_scene_info_reports_top_level_entity_counts_and_serialized_entities
    result = @commands.get_scene_info('entity_limit' => 5)

    assert_scene_counts(result)
    assert_equal([101, 102], result[:entities].map { |entity| entity[:id] })
    assert_equal(1, result.dig(:model, :active_path_depth))
  end

  def test_list_entities_requires_a_scope_selector
    error = assert_raises(RuntimeError) do
      @commands.list_entities('outputOptions' => { 'limit' => 10 })
    end

    assert_equal('scopeSelector is required', error.message)
  end

  def test_list_entities_inventories_top_level_scope_by_default
    result = @commands.list_entities(
      'scopeSelector' => { 'mode' => 'top_level' },
      'outputOptions' => { 'limit' => 10 }
    )

    assert_equal(true, result[:success])
    assert_equal(1, result[:count])
    assert_equal([101], result[:entities].map { |entity| entity[:id] })
  end

  def test_list_entities_supports_selection_scope
    result = @commands.list_entities(
      'scopeSelector' => { 'mode' => 'selection' },
      'outputOptions' => { 'limit' => 10 }
    )

    assert_equal(true, result[:success])
    assert_equal(1, result[:count])
    assert_equal([101], result[:entities].map { |entity| entity[:id] })
  end

  def test_list_entities_supports_children_of_target_scope
    result = @commands.list_entities(
      'scopeSelector' => {
        'mode' => 'children_of_target',
        'targetReference' => { 'entityId' => '101' }
      },
      'outputOptions' => { 'limit' => 10 }
    )

    assert_equal(true, result[:success])
    assert_equal(1, result[:count])
    assert_equal([201], result[:entities].map { |entity| entity[:id] })
  end

  def test_list_entities_hides_internal_managed_container_placeholders
    placeholder = placeholder_entity(entity_id: 301, persistent_id: 3001)
    parent = @model.entities.first
    parent.entities << placeholder

    result = @commands.list_entities(
      'scopeSelector' => {
        'mode' => 'children_of_target',
        'targetReference' => { 'entityId' => '101' }
      },
      'outputOptions' => { 'limit' => 10, 'includeHidden' => true }
    )

    assert_equal(true, result[:success])
    assert_equal(1, result[:count])
    assert_equal([201], result[:entities].map { |entity| entity[:id] })
  end

  def test_list_entities_rejects_unsupported_scope_modes
    error = assert_raises(RuntimeError) do
      @commands.list_entities('scopeSelector' => { 'mode' => 'search_everywhere' })
    end

    assert_equal('Unsupported scopeSelector.mode: search_everywhere', error.message)
  end

  def test_list_entities_requires_target_reference_for_children_scope
    error = assert_raises(RuntimeError) do
      @commands.list_entities('scopeSelector' => { 'mode' => 'children_of_target' })
    end

    assert_equal('scopeSelector.targetReference is required when mode is children_of_target',
                 error.message)
  end

  def test_get_entity_info_uses_model_lookup_and_serializes_group_details
    result = @commands.get_entity_info('id' => '101')

    assert_serialized_group(result[:entity])
  end

  def test_scene_serialization_rounds_geometry_to_model_length_precision
    Sketchup.active_model_override = build_precise_scene_query_model(length_precision: 2)

    scene = @commands.get_scene_info('entity_limit' => 5)
    entity = @commands.get_entity_info('id' => '101')

    assert_equal([-5.33, 0.0, 0.0], scene.dig(:bounds, :min))
    assert_equal([-4.33, 2.0, 3.0], scene.dig(:bounds, :max))
    assert_equal([1.06, 1.0, 1.5], entity.dig(:entity, :origin))
    assert_equal([0.56, 0.0, 0.0], entity.dig(:entity, :bounds, :min))
    assert_equal([1.56, 2.0, 3.0], entity.dig(:entity, :bounds, :max))
  end

  def test_list_entities_includes_hidden_entities_when_requested
    result = @commands.list_entities(
      'scopeSelector' => { 'mode' => 'top_level' },
      'outputOptions' => { 'includeHidden' => true, 'limit' => 10 }
    )

    assert_equal(true, result[:success])
    assert_equal(2, result[:count])
    assert_equal([101, 102], result[:entities].map { |entity| entity[:id] })
  end

  def test_list_entities_clamps_limit_to_at_least_one
    result = @commands.list_entities(
      'scopeSelector' => { 'mode' => 'top_level' },
      'outputOptions' => { 'limit' => 0 }
    )

    assert_equal([101], result[:entities].map { |entity| entity[:id] })
  end

  def test_get_scene_info_requires_an_active_model
    Sketchup.active_model_override = nil

    error = assert_raises(RuntimeError) do
      @commands.get_scene_info
    end

    assert_equal('No active SketchUp model', error.message)
  end

  def test_get_entity_info_requires_a_non_blank_id
    error = assert_raises(RuntimeError) do
      @commands.get_entity_info('id' => '')
    end

    assert_equal('Entity id is required', error.message)
  end

  def test_get_entity_info_raises_when_entity_is_missing
    error = assert_raises(RuntimeError) do
      @commands.get_entity_info('id' => '999')
    end

    assert_equal('Entity not found', error.message)
  end

  private

  def placeholder_entity(entity_id:, persistent_id:)
    SceneQueryTestSupport::FakeGroup.new(
      entity_id: entity_id,
      bounds: SceneQueryTestSupport::FakeBounds.new(
        min: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
        max: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
        center: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
        size: [0.0, 0.0, 0.0]
      ),
      layer: @model.layers.first,
      material: nil,
      details: {
        persistent_id: persistent_id,
        hidden: true,
        attributes: {
          'su_mcp' => {
            SU_MCP::Semantic::ManagedObjectMetadata::INTERNAL_PLACEHOLDER_KEY => true
          }
        }
      }
    )
  end
end
