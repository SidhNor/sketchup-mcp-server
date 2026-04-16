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
    assert_equal(1101, result[:id])
  end

  def test_boolean_difference_rebuilds_edge_geometry_when_source_entities_lack_copy
    target_entities = FakeEntitiesCollection.new(items: [build_uncopyable_edge(0)])
    tool_entities = FakeEntitiesCollection.new(items: [build_uncopyable_edge(1)])
    target = build_group(entity_id: 101, entities: target_entities)
    tool = build_group(entity_id: 202, entities: tool_entities)
    active_entities = FakeEntitiesCollection.new
    @model = build_model(entities: [target, tool], active_entities: active_entities)

    result = @commands.boolean_operation(
      'operation' => 'difference',
      'target_id' => '101',
      'tool_id' => '202'
    )

    assert_equal(true, result[:success])
    assert_equal(1, active_entities.added_groups.first.entities.added_lines.length)
    assert_equal(1, active_entities.added_groups[1].entities.added_lines.length)
  end

  def test_chamfer_edges_cleans_up_result_group_when_edge_processing_fails
    edge = build_edge(0)
    face = Struct.new(:edges).new([edge])
    edge.define_singleton_method(:faces) { [face, face] }
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

  # rubocop:disable Metrics/MethodLength
  def test_chamfer_edges_snapshots_face_points_before_adding_new_faces
    first_edge = build_copyable_chamfer_edge(30)
    second_edge = build_copyable_chamfer_edge(40)
    second_edge_original_faces = second_edge.faces
    broken_face = Struct.new(:edges).new([second_edge])
    mutation_state = { mutating: false }

    second_edge.define_singleton_method(:faces) do
      mutation_state[:mutating] ? [broken_face, broken_face] : second_edge_original_faces
    end

    active_entities = MutatingChamferEntities.new do
      mutation_state[:mutating] = true
    end
    entity = build_group(
      entity_id: 101,
      entities: FakeEntitiesCollection.new(items: [first_edge, second_edge])
    )
    @model = build_model(entities: [entity], active_entities: active_entities)

    result = @commands.chamfer_edges(
      'entity_id' => '101',
      'distance' => 2.0
    )

    assert_equal(true, result[:success])
    assert_equal(2, active_entities.added_groups.first.entities.added_faces.length)
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize
  def test_chamfer_points_for_builds_a_planar_quad_from_the_two_adjacent_faces
    edge = build_chamferable_edge
    points = @commands.send(:chamfer_points_for, edge, edge.faces, 2.0)

    assert_equal(4, points.length)
    assert_equal(0.0, points[0].z)
    assert_equal(0.0, points[1].z)
    assert_equal(2.0, points[2].z)
    assert_equal(2.0, points[3].z)
    assert_equal(2.0, points[0].y)
    assert_equal(2.0, points[1].y)
    assert_equal(0.0, points[2].y)
    assert_equal(0.0, points[3].y)
  end
  # rubocop:enable Metrics/AbcSize

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

  private

  class MutatingChamferEntities < FakeEntitiesCollection
    def initialize(&on_add_face)
      super()
      @on_add_face = on_add_face
    end

    def add_face(*points)
      @on_add_face&.call
      super
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def build_copyable_chamfer_edge(index)
    start_vertex = FakeVertex.new(SceneQueryTestSupport::FakePoint.new(index.to_f, 0.0, 0.0))
    end_vertex = FakeVertex.new(SceneQueryTestSupport::FakePoint.new(index.to_f + 10.0, 0.0, 0.0))
    edge = build_edge(index)
    edge.define_singleton_method(:start) { start_vertex }
    edge.define_singleton_method(:end) { end_vertex }
    edge.define_singleton_method(:vertices) { [start_vertex, end_vertex] }

    face1_start = build_connected_edge(
      start_vertex,
      SceneQueryTestSupport::FakePoint.new(index.to_f, 10.0, 0.0)
    )
    face1_end = build_connected_edge(
      end_vertex,
      SceneQueryTestSupport::FakePoint.new(index.to_f + 10.0, 10.0, 0.0)
    )
    face2_start = build_connected_edge(
      start_vertex,
      SceneQueryTestSupport::FakePoint.new(index.to_f, 0.0, 10.0)
    )
    face2_end = build_connected_edge(
      end_vertex,
      SceneQueryTestSupport::FakePoint.new(index.to_f + 10.0, 0.0, 10.0)
    )

    face1 = Struct.new(:edges).new([edge, face1_start, face1_end])
    face2 = Struct.new(:edges).new([edge, face2_start, face2_end])

    edge.define_singleton_method(:faces) { [face1, face2] }
    start_vertex.edges = [edge, face1_start, face2_start]
    end_vertex.edges = [edge, face1_end, face2_end]
    edge
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
