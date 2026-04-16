# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/modeling_test_support'
require_relative '../../src/su_mcp/modeling/modeling_support'

class ModelingSupportTest < Minitest::Test
  include ModelingTestSupport

  def setup
    @support = SU_MCP::ModelingSupport.new
  end

  def test_group_or_component_accepts_groups_and_components
    assert_equal(true, @support.send(:group_or_component?, build_group))
    assert_equal(true, @support.send(:group_or_component?, build_component))
    assert_equal(false, @support.send(:group_or_component?, Object.new))
  end

  def test_instance_entities_returns_group_entities
    entities = FakeEntitiesCollection.new(items: [FakeCopyableEntity.new])
    group = build_group(entities: entities)

    assert_same(entities, @support.send(:instance_entities, group))
  end

  def test_instance_entities_returns_component_definition_entities
    entities = FakeEntitiesCollection.new(items: [FakeCopyableEntity.new])
    component = build_component(entities: entities)

    assert_same(entities, @support.send(:instance_entities, component))
  end

  def test_selected_edge_indices_only_accepts_array_inputs
    assert_equal([1, 3], @support.send(:selected_edge_indices, 'edge_indices' => [1, 3]))
    assert_nil(@support.send(:selected_edge_indices, 'edge_indices' => '1,3'))
  end

  def test_filter_edges_by_index_preserves_requested_positions
    edges = [build_edge(0), build_edge(1), build_edge(2)]

    assert_equal([edges[0], edges[2]], @support.send(:filter_edges_by_index, edges, [0, 2]))
  end

  def test_copy_entities_to_target_copies_each_source_entity
    source_entities = [FakeCopyableEntity.new, FakeCopyableEntity.new]
    target_entities = FakeEntitiesCollection.new

    @support.send(:copy_entities_to, source_entities, target_entities)

    assert_equal([target_entities], source_entities[0].copy_targets)
    assert_equal([target_entities], source_entities[1].copy_targets)
  end

  def test_copy_entities_to_rebuilds_uncopyable_edges_as_lines
    edge = build_uncopyable_edge(3)
    target_entities = FakeEntitiesCollection.new

    @support.send(:copy_entities_to, [edge], target_entities)

    assert_equal(1, target_entities.added_lines.length)
    assert_equal(edge.start.position, target_entities.added_lines.first[0])
    assert_equal(edge.end.position, target_entities.added_lines.first[1])
  end
end
