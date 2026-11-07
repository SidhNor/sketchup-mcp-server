# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/adapters/entity_path_index'

class EntityPathIndexTest < Minitest::Test
  # Minimal model graph with the parent/definition/instance links SketchUp exposes.
  module FakeNode
    attr_accessor :parent
    attr_reader :entity_id

    # Matches the SketchUp API name.
    def entityID # rubocop:disable Naming/MethodName
      entity_id
    end

    def init_node(id)
      @entity_id = id
    end
  end

  class FakeModel < Sketchup::Model
    attr_reader :entities, :definitions

    def initialize
      super
      @entities = []
      @definitions = []
    end
  end

  class FakeDefinition < Sketchup::ComponentDefinition
    attr_reader :entities, :instances

    def initialize(name)
      super()
      @name = name
      @entities = []
      @instances = []
    end

    def add(entity)
      entity.parent = self
      @entities << entity
      entity
    end
  end

  class FakeFace < Sketchup::Face
    include FakeNode

    def initialize(id)
      super()
      init_node(id)
    end
  end

  class FakeGroup < Sketchup::Group
    include FakeNode

    attr_reader :definition

    def initialize(id, definition)
      super()
      init_node(id)
      @definition = definition
      definition.instances << self
    end

    def entities
      definition.entities
    end
  end

  class FakeInstance < Sketchup::ComponentInstance
    include FakeNode

    attr_reader :definition

    def initialize(id, definition)
      super()
      init_node(id)
      @definition = definition
      definition.instances << self
    end
  end

  class FakeImage < Sketchup::Image
    include FakeNode

    def initialize(id, definition)
      super()
      init_node(id)
      definition.instances << self
    end
  end

  def setup
    @model = FakeModel.new
    build_definitions
    build_scene
    @index = SU_MCP::Adapters::EntityPathIndex.new(@model)
  end

  def test_entries_matching_returns_the_same_entries_as_the_full_walk
    predicates = [
      ->(_entity) { true },
      ->(entity) { entity.is_a?(Sketchup::Face) },
      ->(entity) { entity.equal?(@nested_face) },
      ->(entity) { entity.equal?(@root_instance) }
    ]

    predicates.each do |predicate|
      expected = @index.select { |entry| predicate.call(entry.fetch(:entity)) }

      assert_equal(signature(expected), signature(@index.entries_matching(&predicate)))
    end
  end

  def test_entities_in_shared_definitions_appear_once_per_placed_copy
    entries = @index.entries_matching { |entity| entity.equal?(@nested_face) }

    # Once through the instance inside the group, once through the root instance.
    assert_equal([[1, 3, 6], [4, 6]], entries.map { |entry| ids(entry[:ancestors]) }.sort)
  end

  def test_each_unique_entity_is_tested_once
    tested = Hash.new(0)
    @index.entries_matching { |entity| tested[entity.entityID] += 1 }

    assert_equal([1], tested.values.uniq)
  end

  def test_image_and_unplaced_definitions_are_not_reachable
    entries = @index.entries_matching do |entity|
      entity.equal?(@image_face) || entity.equal?(@orphan_face)
    end

    assert_empty(entries)
  end

  def test_each_outside_components_skips_contents_of_component_instances
    outside = @index.each_outside_components.to_a
    expected = @index.select do |entry|
      entry[:entity].is_a?(Sketchup::Group) || entry[:entity].is_a?(Sketchup::ComponentInstance)
    end
    expected = expected.reject { |entry| entry[:ancestors].any?(Sketchup::ComponentInstance) }

    assert_equal(signature(expected), signature(outside))
    assert_equal([1, 3, 4], outside.map { |entry| entry[:entity].entityID })
  end

  def test_falls_back_to_the_full_walk_when_definitions_are_unavailable
    model = Struct.new(:entities).new(@model.entities)
    index = SU_MCP::Adapters::EntityPathIndex.new(model)

    entries = index.entries_matching { |entity| entity.equal?(@nested_face) }

    assert_equal([[1, 3, 6], [4, 6]], entries.map { |entry| ids(entry[:ancestors]) })
  end

  private

  def build_definitions
    @group_definition = FakeDefinition.new('group')
    @component = FakeDefinition.new('component')
    @nested = FakeDefinition.new('nested')
    @image_definition = FakeDefinition.new('image')
    @orphan = FakeDefinition.new('orphan')
    @model.definitions.push(@group_definition, @component, @nested, @image_definition, @orphan)
  end

  # Root: group 1 (face 2, instance 3), instance 4, image 8. Both component
  # instances (3 and 4) contain face 5 and nested instance 6 (face 7).
  def build_scene
    @group = add_root(FakeGroup.new(1, @group_definition))
    @group_definition.add(FakeFace.new(2))
    @group_definition.add(FakeInstance.new(3, @component))
    @root_instance = add_root(FakeInstance.new(4, @component))
    @component.add(FakeFace.new(5))
    @component.add(FakeInstance.new(6, @nested))
    @nested_face = @nested.add(FakeFace.new(7))
    add_root(FakeImage.new(8, @image_definition))
    @image_face = @image_definition.add(FakeFace.new(9))
    @orphan_face = @orphan.add(FakeFace.new(10))
  end

  def add_root(entity)
    entity.parent = @model
    @model.entities << entity
    entity
  end

  def ids(entities)
    entities.map(&:entityID)
  end

  def signature(entries)
    entries.map { |entry| [entry[:entity].entityID, ids(entry[:ancestors])] }.sort
  end
end
