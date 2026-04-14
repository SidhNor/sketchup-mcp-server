# frozen_string_literal: true

module SceneQueryTestSupport
  class FakePoint
    attr_reader :axis_x, :axis_y, :axis_z

    def initialize(axis_x, axis_y, axis_z)
      @axis_x = axis_x
      @axis_y = axis_y
      @axis_z = axis_z
    end

    alias x axis_x
    alias y axis_y
    alias z axis_z
  end

  class FakeBounds
    attr_reader :min, :max, :center, :width, :height, :depth

    def initialize(min:, max:, center:, size:)
      @min = min
      @max = max
      @center = center
      @width, @height, @depth = size
    end

    def valid?
      true
    end
  end

  class FakeLayer
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  class FakeMaterial
    attr_reader :display_name
    attr_accessor :color

    def initialize(display_name)
      @display_name = display_name
    end

    def name
      @display_name
    end
  end

  class FakeMaterialCollection
    def initialize(materials = [])
      @materials = materials.dup
    end

    def [](name)
      @materials.find { |material| material.display_name == name || material.name == name }
    end

    def add(name)
      material = FakeMaterial.new(name)
      @materials << material
      material
    end

    def length
      @materials.length
    end

    def to_a
      @materials.dup
    end
  end

  class FakeView
    attr_reader :write_image_calls

    def initialize
      @write_image_calls = []
    end

    # rubocop:disable Naming/PredicateMethod
    def write_image(options)
      @write_image_calls << options
      true
    end
    # rubocop:enable Naming/PredicateMethod
  end

  class FakeTransformation
    attr_reader :origin

    def initialize(origin)
      @origin = origin
    end
  end

  module FakeEntityBehavior
    attr_reader :entity_id, :bounds, :layer, :material, :name, :persistent_id

    def initialize(entity_id:, bounds:, layer:, material:, details: {})
      super()
      @entity_id = entity_id
      @bounds = bounds
      @layer = layer
      @material = material
      @hidden = details.fetch(:hidden, false)
      @locked = details.fetch(:locked, false)
      @name = details.fetch(:name, '')
      @persistent_id = details[:persistent_id]
    end

    def hidden?
      @hidden
    end

    def locked?
      @locked
    end

    # rubocop:disable Naming/MethodName
    define_method(:entityID) { entity_id }
    # rubocop:enable Naming/MethodName

    def material=(material)
      @material = material
    end
  end

  class FakeGroup < Sketchup::Group
    include FakeEntityBehavior

    attr_reader :entities, :transformation, :transformations

    def initialize(entity_id:, bounds:, layer:, material:, details: {})
      super
      @entities = details.fetch(:entities, [])
      @transformation = details.fetch(:transformation, FakeTransformation.new(bounds.center))
      @transformations = []
      @erased = false
    end

    def erase!
      @erased = true
    end

    def erased?
      @erased
    end

    def transform!(transformation)
      @transformations << transformation
    end
  end

  class FakeFace < Sketchup::Face
    include FakeEntityBehavior
  end

  class FakeModel
    attr_reader :entities, :active_entities, :selection, :materials, :layers, :bounds, :title,
                :path, :active_path, :active_view, :saved_paths, :export_calls

    # rubocop:disable Metrics/MethodLength
    def initialize(state:, details: {})
      @entities = state.fetch(:entities)
      @active_entities = state.fetch(:active_entities)
      @selection = state.fetch(:selection)
      @materials = state.fetch(:materials)
      @layers = state.fetch(:layers)
      @bounds = state.fetch(:bounds)
      @title = details.fetch(:title, 'Test Model')
      @path = details.fetch(:path, '/tmp/test_model.skp')
      @active_path = details[:active_path]
      @active_view = details.fetch(:active_view, FakeView.new)
      @saved_paths = []
      @export_calls = []
    end
    # rubocop:enable Metrics/MethodLength

    def find_entity_by_id(id)
      (@entities + @active_entities).find { |entity| entity.entityID == id }
    end

    # rubocop:disable Naming/PredicateMethod
    def save(path)
      @saved_paths << path
      true
    end

    def export(path, options)
      @export_calls << [path, options]
      true
    end
    # rubocop:enable Naming/PredicateMethod
  end

  def build_scene_query_model
    layer = FakeLayer.new('Layer0')
    material = FakeMaterial.new('Pine')
    state = build_scene_query_state(layer: layer, material: material)
    FakeModel.new(state: state, details: { active_path: [:editing] })
  end

  def build_scene_query_state(layer:, material:)
    top_level_group = build_scene_query_group(entity_id: 101, origin_x: 0, layer: layer,
                                              material: material)

    {
      entities: [top_level_group, build_hidden_face(layer: layer, material: material)],
      active_entities: [build_nested_face(layer: layer, material: material)],
      selection: [top_level_group],
      materials: [material],
      layers: [layer],
      bounds: build_bounds(origin_x: -5)
    }
  end

  def build_mutation_model(entity_id: 301, material_name: 'Pine')
    layer = FakeLayer.new('Layer0')
    material = FakeMaterial.new(material_name)
    entity = build_scene_query_group(entity_id: entity_id, origin_x: 0, layer: layer,
                                     material: material)

    FakeModel.new(state: mutation_model_state(entity: entity, layer: layer, material: material))
  end

  def build_scene_query_group(entity_id:, origin_x:, layer:, material:)
    FakeGroup.new(
      entity_id: entity_id,
      bounds: build_bounds(origin_x: origin_x),
      layer: layer,
      material: material,
      details: { name: 'Top Group', persistent_id: 1001, entities: [Object.new] }
    )
  end

  def build_scene_query_face(entity_id:, origin_x:, layer:, material:, details:)
    FakeFace.new(
      entity_id: entity_id,
      bounds: build_bounds(origin_x: origin_x),
      layer: layer,
      material: material,
      details: details
    )
  end

  def build_hidden_face(layer:, material:)
    build_scene_query_face(entity_id: 102, origin_x: 10, layer: layer, material: material,
                           details: { hidden: true, name: 'Hidden Face', persistent_id: 1002 })
  end

  def build_nested_face(layer:, material:)
    build_scene_query_face(entity_id: 201, origin_x: 20, layer: layer, material: material,
                           details: { name: 'Nested Face', persistent_id: 2001 })
  end

  def build_bounds(origin_x:)
    min = FakePoint.new(origin_x, 0, 0)
    max = FakePoint.new(origin_x + 1, 2, 3)
    center = FakePoint.new(origin_x + 0.5, 1.0, 1.5)
    FakeBounds.new(min: min, max: max, center: center, size: [1, 2, 3])
  end

  def mutation_model_state(entity:, layer:, material:)
    {
      entities: [entity],
      active_entities: [],
      selection: [entity],
      materials: FakeMaterialCollection.new([material]),
      layers: [layer],
      bounds: build_bounds(origin_x: -5)
    }
  end
end
