# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/scene_query_test_support'
require_relative '../src/su_mcp/scene_query_commands'

class SceneQueryCommandsAdapterTest < Minitest::Test
  include SceneQueryTestSupport

  class RecordingAdapter
    attr_reader :calls

    def initialize(model:, top_level_entities:, selected_entities:, entity:, queryable_entities:)
      @model = model
      @top_level_entities = top_level_entities
      @selected_entities = selected_entities
      @entity = entity
      @queryable_entities = queryable_entities
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
  end

  def setup
    @model = build_scene_query_model
    @group = @model.entities.first
    @adapter = RecordingAdapter.new(
      model: @model,
      top_level_entities: @model.entities,
      selected_entities: @model.selection,
      entity: @group,
      queryable_entities: @model.entities
    )
  end

  def test_list_entities_accepts_an_adapter_dependency_and_uses_top_level_lookup
    commands = SU_MCP::SceneQueryCommands.new(adapter: @adapter)

    result = commands.list_entities('limit' => 10)

    assert_equal([101], result[:entities].map { |entity| entity[:id] })
    assert_includes(@adapter.calls, :active_model!)
    assert_includes(@adapter.calls, [:top_level_entities, false])
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

    commands.find_entities('query' => { 'entityId' => '101' })

    assert_includes(@adapter.calls, :queryable_entities)
  end
end
