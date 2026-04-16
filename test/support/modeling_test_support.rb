# frozen_string_literal: true

require_relative 'scene_query_test_support'

# The existing scene-query and semantic helpers model read-only traversal and
# basic mutation, but they do not cover the copy, validity, edge, and collection
# operations needed to lead the solid-modeling and joinery extraction credibly.
# This overlay keeps those extra mechanics test-owned and intentionally narrow.
module ModelingTestSupport
  include SceneQueryTestSupport

  class FakeVector
    attr_reader :x, :y, :z

    def initialize(x_value, y_value, z_value)
      @x = x_value
      @y = y_value
      @z = z_value
    end

    def normalize!
      self
    end

    def reverse
      self.class.new(-x, -y, -z)
    end
  end

  class FakeVertex
    attr_reader :position
    attr_accessor :edges

    def initialize(position)
      @position = position
      @edges = []
    end
  end

  class FakeCopyableEntity
    attr_reader :copy_targets

    def initialize
      @copy_targets = []
    end

    def copy(target)
      @copy_targets << target
      self
    end
  end

  class FakeFace
    attr_reader :pushpull_calls

    def initialize
      @pushpull_calls = []
    end

    def pushpull(distance)
      @pushpull_calls << distance
    end
  end

  class FakeEntitiesCollection
    attr_reader :items, :added_groups, :added_faces, :added_lines, :subtract_calls,
                :outer_shell_calls, :intersect_calls, :added_instances

    def initialize(items: [])
      @items = items.dup
      @added_groups = []
      @added_faces = []
      @added_lines = []
      @subtract_calls = []
      @outer_shell_calls = 0
      @intersect_calls = []
      @added_instances = []
    end

    def each(&block)
      items.each(&block)
    end

    def grep(klass)
      items.grep(klass)
    end

    def add_group
      group = FakeGroup.new(entities: self.class.new)
      @added_groups << group
      @items << group
      group
    end

    def add_face(*points)
      face = FakeFace.new
      @added_faces << { points: points, face: face }
      @items << face
      face
    end

    def add_line(start_point, end_point)
      @added_lines << [start_point, end_point]
    end

    def subtract(other_entities)
      @subtract_calls << other_entities
    end

    def outer_shell
      @outer_shell_calls += 1
      true
    end

    def intersect_with(*args)
      @intersect_calls << args
      true
    end

    def add_instance(parent, transformation)
      @added_instances << [parent, transformation]
    end
  end

  class FakeDefinition
    attr_reader :entities

    def initialize(entities:)
      @entities = entities
    end
  end

  class FakeGroup < Sketchup::Group
    attr_reader :entities, :transformation, :copy_count, :transformations, :bounds

    def initialize(entity_id: 101, entities: FakeEntitiesCollection.new, bounds: nil,
                   transformation: nil)
      super()
      @entity_id = entity_id
      @entities = entities
      @bounds = bounds || default_bounds
      @transformation = transformation || SceneQueryTestSupport::FakeTransformation.new(@bounds.center)
      @copy_count = 0
      @transformations = []
      @erased = false
    end

    def entityID
      @entity_id
    end

    def copy
      @copy_count += 1
      self.class.new(
        entity_id: @entity_id,
        entities: @entities,
        bounds: @bounds,
        transformation: @transformation
      )
    end

    def erase!
      @erased = true
    end

    def transform!(transformation)
      @transformations << transformation
    end

    def erased?
      @erased
    end

    def valid?
      !@erased
    end

    private

    def default_bounds
      SceneQueryTestSupport::FakeBounds.new(
        min: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
        max: SceneQueryTestSupport::FakePoint.new(2.0, 2.0, 2.0),
        center: SceneQueryTestSupport::FakePoint.new(1.0, 1.0, 1.0),
        size: [2.0, 2.0, 2.0]
      )
    end
  end

  class FakeComponentInstance < Sketchup::ComponentInstance
    attr_reader :definition, :transformation, :transformations, :bounds

    def initialize(definition:, entity_id: 202, bounds: nil, transformation: nil)
      super()
      @entity_id = entity_id
      @definition = definition
      @bounds = bounds || default_bounds
      @transformation = transformation || SceneQueryTestSupport::FakeTransformation.new(@bounds.center)
      @transformations = []
      @erased = false
    end

    def entityID
      @entity_id
    end

    def copy
      self.class.new(
        definition: @definition,
        entity_id: @entity_id,
        bounds: @bounds,
        transformation: @transformation
      )
    end

    def erase!
      @erased = true
    end

    def transform!(transformation)
      @transformations << transformation
    end

    def valid?
      !@erased
    end

    private

    def default_bounds
      SceneQueryTestSupport::FakeBounds.new(
        min: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
        max: SceneQueryTestSupport::FakePoint.new(2.0, 2.0, 2.0),
        center: SceneQueryTestSupport::FakePoint.new(1.0, 1.0, 1.0),
        size: [2.0, 2.0, 2.0]
      )
    end
  end

  class FakeModel
    attr_reader :active_entities

    def initialize(entities: [], active_entities: FakeEntitiesCollection.new)
      @entities = entities
      @active_entities = active_entities
    end

    def find_entity_by_id(id)
      @entities.find { |entity| entity.entityID == id }
    end
  end

  def build_edge(index)
    start_vertex = FakeVertex.new(SceneQueryTestSupport::FakePoint.new(index.to_f, 0.0, 0.0))
    end_vertex = FakeVertex.new(SceneQueryTestSupport::FakePoint.new(index.to_f + 1.0, 0.0, 0.0))
    edge = SceneQueryTestSupport::FakeEdge.new(
      entity_id: 500 + index,
      bounds: SceneQueryTestSupport::FakeBounds.new(
        min: SceneQueryTestSupport::FakePoint.new(index.to_f, 0.0, 0.0),
        max: SceneQueryTestSupport::FakePoint.new(index.to_f + 1.0, 0.0, 0.0),
        center: SceneQueryTestSupport::FakePoint.new(index.to_f + 0.5, 0.0, 0.0),
        size: [1.0, 0.0, 0.0]
      ),
      layer: SceneQueryTestSupport::FakeLayer.new('Layer0'),
      material: SceneQueryTestSupport::FakeMaterial.new('Steel'),
      details: {}
    )
    edge.define_singleton_method(:start) { start_vertex }
    edge.define_singleton_method(:end) { end_vertex }
    edge.define_singleton_method(:vertices) { [start_vertex, end_vertex] }
    edge.define_singleton_method(:faces) { [] }
    edge.define_singleton_method(:copy) do |target|
      target.items << self
      self
    end
    edge
  end

  def build_group(entity_id: 101, entities: FakeEntitiesCollection.new)
    FakeGroup.new(entity_id: entity_id, entities: entities)
  end

  def build_component(entity_id: 202, entities: FakeEntitiesCollection.new)
    FakeComponentInstance.new(
      entity_id: entity_id,
      definition: FakeDefinition.new(entities: entities)
    )
  end

  def build_model(entities: [], active_entities: FakeEntitiesCollection.new)
    FakeModel.new(entities: entities, active_entities: active_entities)
  end

  def build_bounds(min:, max:)
    SceneQueryTestSupport::FakeBounds.new(
      min: SceneQueryTestSupport::FakePoint.new(*min),
      max: SceneQueryTestSupport::FakePoint.new(*max),
      center: SceneQueryTestSupport::FakePoint.new(
        (min[0] + max[0]) / 2.0,
        (min[1] + max[1]) / 2.0,
        (min[2] + max[2]) / 2.0
      ),
      size: [max[0] - min[0], max[1] - min[1], max[2] - min[2]]
    )
  end
end
