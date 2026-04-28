# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/scene_query_commands'

class SceneQueryCommandsAdapterTest < Minitest::Test
  include SceneQueryTestSupport

  class RecordingAdapter
    attr_reader :calls

    def initialize(
      model:,
      top_level_entities:,
      selected_entities:,
      entity:,
      queryable_entities:,
      all_entities_recursive:,
      all_entity_paths_recursive:
    )
      @model = model
      @top_level_entities = top_level_entities
      @selected_entities = selected_entities
      @entity = entity
      @queryable_entities = queryable_entities
      @all_entities_recursive = all_entities_recursive
      @all_entity_paths_recursive = all_entity_paths_recursive
      @calls = []
    end

    def active_model!
      @calls << :active_model!
      @model
    end

    def top_level_entities(include_hidden: false)
      @calls << [:top_level_entities, include_hidden]
      include_hidden ? @top_level_entities : @top_level_entities.reject(&:hidden?)
    end

    def selected_entities
      @calls << :selected_entities
      @selected_entities
    end

    def find_entity!(id)
      @calls << [:find_entity!, id]
      @entity
    end

    def queryable_entities
      @calls << :queryable_entities
      @queryable_entities
    end

    def all_entities_recursive
      @calls << :all_entities_recursive
      @all_entities_recursive
    end

    def all_entity_paths_recursive
      @calls << :all_entity_paths_recursive
      @all_entity_paths_recursive
    end
  end

  def setup
    @model = build_scene_query_model
    @group = @model.entities.first
    @adapter = RecordingAdapter.new(
      model: @model,
      top_level_entities: @model.entities,
      selected_entities: @model.selection,
      entity: @group,
      queryable_entities: @model.entities,
      all_entities_recursive: @model.entities + @group.entities,
      all_entity_paths_recursive: (@model.entities + @group.entities).map do |entity|
        { entity: entity, ancestors: [] }
      end
    )
  end

  def test_list_entities_accepts_an_adapter_dependency_and_uses_top_level_lookup
    commands = SU_MCP::SceneQueryCommands.new(adapter: @adapter)

    result = commands.list_entities(
      'scopeSelector' => { 'mode' => 'top_level' },
      'outputOptions' => { 'limit' => 10 }
    )

    assert_equal([101], result[:entities].map { |entity| entity[:id] })
    assert_includes(@adapter.calls, :active_model!)
    assert_includes(@adapter.calls, [:top_level_entities, false])
  end

  def test_list_entities_uses_adapter_owned_selection_lookup_for_selection_scope
    commands = SU_MCP::SceneQueryCommands.new(adapter: @adapter)

    result = commands.list_entities('scopeSelector' => { 'mode' => 'selection' })

    assert_equal([101], result[:entities].map { |entity| entity[:id] })
    assert_includes(@adapter.calls, :selected_entities)
  end

  def test_selection_info_uses_adapter_owned_selection_lookup
    commands = SU_MCP::SceneQueryCommands.new(adapter: @adapter)

    result = commands.selection_info

    assert_equal([101], result[:entities].map { |entity| entity[:id] })
    assert_includes(@adapter.calls, :selected_entities)
  end

  def test_get_entity_info_delegates_entity_resolution_to_the_adapter
    commands = SU_MCP::SceneQueryCommands.new(adapter: @adapter)

    result = commands.get_entity_info('id' => '"101"')

    assert_equal(101, result.dig(:entity, :id))
    assert_includes(@adapter.calls, [:find_entity!, '"101"'])
  end

  def test_find_entities_uses_adapter_owned_entity_enumeration
    commands = SU_MCP::SceneQueryCommands.new(adapter: @adapter)

    commands.find_entities('targetSelector' => { 'identity' => { 'entityId' => '101' } })

    assert_includes(@adapter.calls, :all_entities_recursive)
  end

  def test_sample_surface_z_uses_recursive_entities_for_nested_targets
    commands = SU_MCP::SceneQueryCommands.new(adapter: @adapter)

    commands.sample_surface_z(
      'target' => { 'entityId' => '101' },
      'sampling' => {
        'type' => 'points',
        'points' => [{ 'x' => 0.0, 'y' => 0.0 }]
      }
    )

    assert_includes(@adapter.calls, :all_entities_recursive)
    assert_includes(@adapter.calls, :all_entity_paths_recursive)
    assert_includes(@adapter.calls, :queryable_entities)
  end
end
