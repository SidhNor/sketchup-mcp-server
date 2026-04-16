# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/modeling_test_support'
require_relative '../src/su_mcp/modeling_support'
require_relative '../src/su_mcp/solid_modeling_commands'

class SolidModelingCommandsTest < Minitest::Test
  include ModelingTestSupport

  class RecordingSupport < SU_MCP::ModelingSupport
    attr_reader :calls

    def initialize
      super
      @calls = []
    end

    def group_or_component?(entity)
      @calls << [:group_or_component?, entity]
      !entity.is_a?(Object) || entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end
  end

  def setup
    @support = RecordingSupport.new
    @model = build_model
    @commands = SU_MCP::SolidModelingCommands.new(
      model_provider: -> { @model },
      logger: nil,
      support: @support
    )
  end

  def test_boolean_operation_rejects_invalid_operation_names
    error = assert_raises(RuntimeError) do
      @commands.boolean_operation(
        'operation' => 'slice',
        'target_id' => '101',
        'tool_id' => '202'
      )
    end

    assert_match(/Invalid boolean operation/, error.message)
  end

  def test_boolean_operation_rejects_missing_target_or_tool_entities
    @model = build_model(entities: [build_group(entity_id: 101)])

    error = assert_raises(RuntimeError) do
      @commands.boolean_operation(
        'operation' => 'union',
        'target_id' => '101',
        'tool_id' => '999'
      )
    end

    assert_equal('Entity not found: tool', error.message)
  end

  def test_boolean_operation_rejects_unsupported_entity_types
    unsupported = Object.new
    @model = build_model(entities: [unsupported, build_group(entity_id: 202)])
    # rubocop:disable Naming/MethodName
    unsupported.define_singleton_method(:entityID) { 101 }
    # rubocop:enable Naming/MethodName

    error = assert_raises(RuntimeError) do
      @commands.boolean_operation(
        'operation' => 'union',
        'target_id' => '101',
        'tool_id' => '202'
      )
    end

    assert_equal('Boolean operations require groups or component instances', error.message)
  end

  def test_boolean_operation_routes_union_through_shared_copy_helpers
    target_entities = FakeEntitiesCollection.new(items: [FakeCopyableEntity.new])
    tool_entities = FakeEntitiesCollection.new(items: [FakeCopyableEntity.new])
    target = build_group(entity_id: 101, entities: target_entities)
    tool = build_group(entity_id: 202, entities: tool_entities)
    active_entities = FakeEntitiesCollection.new
    @model = build_model(entities: [target, tool], active_entities: active_entities)

    result = @commands.boolean_operation(
      'operation' => 'union',
      'target_id' => '101',
      'tool_id' => '202'
    )

    assert_equal(true, result[:success])
    assert_equal(active_entities.added_groups.first.entityID, result[:id])
  end

  def test_chamfer_edges_cleans_up_result_group_when_edge_processing_fails
    edge = build_edge(0)
    edge.define_singleton_method(:faces) { [Object.new, Object.new] }
    entity = build_group(entity_id: 101, entities: FakeEntitiesCollection.new(items: [edge]))
    @model = build_model(entities: [entity], active_entities: FakeEntitiesCollection.new)

    error = assert_raises(StandardError) do
      @commands.chamfer_edges(
        'entity_id' => '101',
        'distance' => 0.5,
        'edge_indices' => [0]
      )
    end

    assert_match(/connected edge/i, error.message)
  end

  def test_fillet_edges_filters_result_edges_by_selected_indices
    edges = [build_edge(0), build_edge(1), build_edge(2)]
    edges.each { |edge| edge.define_singleton_method(:faces) { [Object.new, Object.new] } }
    entity = build_group(entity_id: 101, entities: FakeEntitiesCollection.new(items: edges))
    @model = build_model(entities: [entity], active_entities: FakeEntitiesCollection.new)

    result = @commands.fillet_edges(
      'entity_id' => '101',
      'radius' => 0.5,
      'segments' => 4,
      'edge_indices' => [1]
    )

    assert_equal(true, result[:success])
  end
end
