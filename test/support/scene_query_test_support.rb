# frozen_string_literal: true

module SceneQueryTestSupport
  class FakeOptionsProvider
    def initialize(values)
      @values = values
    end

    def [](key)
      @values[key]
    end
  end

  class FakeOptionsManager
    def initialize(providers)
      @providers = providers
    end

    def [](key)
      @providers[key]
    end
  end

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

    def write_image(options)
      @write_image_calls << options
      true
    end
  end

  class FakeTransformation
    attr_reader :origin

    def initialize(origin, translation: nil)
      @origin = origin
      @translation = translation || [0.0, 0.0, 0.0]
    end

    def apply(x_value, y_value, z_value)
      [
        x_value + @translation[0],
        y_value + @translation[1],
        z_value + @translation[2]
      ]
    end

    def inverse_apply(x_value, y_value, z_value)
      [
        x_value - @translation[0],
        y_value - @translation[1],
        z_value - @translation[2]
      ]
    end
  end

  module FakeEntityBehavior
    attr_reader :entity_id, :bounds, :layer, :material, :name, :persistent_id, :details

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
      @details = details
      @attributes = details.fetch(:attributes, {})
    end

    def hidden?
      @hidden
    end

    def locked?
      @locked
    end

    define_method(:entityID) { entity_id }

    def material=(material)
      @material = material
    end

    def get_attribute(dictionary_name, key, default = nil)
      dictionary = @attributes[dictionary_name]
      return default unless dictionary.is_a?(Hash)

      dictionary.fetch(key, default)
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

  class FakeComponentDefinition
    attr_reader :name, :entities

    def initialize(name:, entities:)
      @name = name
      @entities = entities
    end
  end

  class FakeComponentInstance < Sketchup::ComponentInstance
    include FakeEntityBehavior

    attr_reader :definition, :transformation, :transformations

    def initialize(entity_id:, bounds:, layer:, material:, details: {})
      super
      @definition = details.fetch(:definition)
      @transformation = details.fetch(:transformation, FakeTransformation.new(bounds.center))
      @transformations = []
    end

    def transform!(transformation)
      @transformations << transformation
    end
  end

  class FakeFace < Sketchup::Face
    include FakeEntityBehavior
  end

  class FakeEdge < Sketchup::Edge
    include FakeEntityBehavior
  end

  class FakeModel
    attr_reader :entities, :active_entities, :selection, :materials, :layers, :bounds, :title,
                :path, :active_path, :active_view, :saved_paths, :export_calls, :options

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
      @options = details.fetch(:options)
      @saved_paths = []
      @export_calls = []
    end

    def find_entity_by_id(id)
      (@entities + @active_entities).find { |entity| entity.entityID == id }
    end

    def save(path)
      @saved_paths << path
      true
    end

    def export(path, options)
      @export_calls << [path, options]
      true
    end
  end

  def build_scene_query_model
    layer = FakeLayer.new('Layer0')
    material = FakeMaterial.new('Pine')
    state = build_scene_query_state(layer: layer, material: material)
    FakeModel.new(
      state: state,
      details: { active_path: [:editing], options: default_options }
    )
  end

  def build_precise_scene_query_model(length_precision: 2)
    layer = FakeLayer.new('Layer0')
    material = FakeMaterial.new('Pine')
    state = build_scene_query_state(
      layer: layer,
      material: material,
      group_origin_x: 0.5555,
      hidden_face_origin_x: 10.4444,
      nested_face_origin_x: 20.6666,
      model_bounds_origin_x: -5.3333
    )
    FakeModel.new(
      state: state,
      details: {
        active_path: [:editing],
        options: decimal_options(length_precision: length_precision)
      }
    )
  end

  def build_scene_query_state(layer:, material:, group_origin_x: 0, hidden_face_origin_x: 10,
                              nested_face_origin_x: 20, model_bounds_origin_x: -5)
    top_level_group = build_scene_query_group(
      entity_id: 101,
      origin_x: group_origin_x,
      layer: layer,
      material: material
    )

    {
      entities: [
        top_level_group,
        build_hidden_face(layer: layer, material: material, origin_x: hidden_face_origin_x)
      ],
      active_entities: [
        build_nested_face(layer: layer, material: material, origin_x: nested_face_origin_x)
      ],
      selection: [top_level_group],
      materials: [material],
      layers: [layer],
      bounds: build_bounds(origin_x: model_bounds_origin_x)
    }
  end

  def build_mutation_model(entity_id: 301, material_name: 'Pine')
    layer = FakeLayer.new('Layer0')
    material = FakeMaterial.new(material_name)
    entity = build_scene_query_group(entity_id: entity_id, origin_x: 0, layer: layer,
                                     material: material)

    FakeModel.new(
      state: mutation_model_state(entity: entity, layer: layer, material: material),
      details: { options: default_options }
    )
  end

  def build_find_entities_model
    trees = FakeLayer.new('Trees')
    hardscape = FakeLayer.new('Hardscape')
    bark = FakeMaterial.new('Bark')
    leaf = FakeMaterial.new('Leaf')
    concrete = FakeMaterial.new('Concrete')
    mulch = FakeMaterial.new('Mulch')

    entities = [
      build_scene_query_group(
        entity_id: 101,
        origin_x: 0,
        layer: trees,
        material: bark,
        details: {
          name: 'Retained Oak',
          persistent_id: 1001,
          attributes: { 'su_mcp' => { 'sourceElementId' => 'tree-001' } }
        }
      ),
      build_scene_query_group(
        entity_id: 102,
        origin_x: 5,
        layer: trees,
        material: leaf,
        details: {
          name: 'Retained Maple',
          persistent_id: 1002
        }
      ),
      build_scene_query_face(
        entity_id: 103,
        origin_x: 10,
        layer: hardscape,
        material: concrete,
        details: {
          name: 'Driveway',
          persistent_id: 1003
        }
      ),
      build_scene_query_group(
        entity_id: 104,
        origin_x: 15,
        layer: trees,
        material: mulch,
        details: {
          name: 'Retained Oak',
          persistent_id: 1004
        }
      )
    ]

    FakeModel.new(
      state: {
        entities: entities,
        active_entities: [],
        selection: [],
        materials: [bark, leaf, concrete, mulch],
        layers: [trees, hardscape],
        bounds: build_bounds(origin_x: -5)
      },
      details: { options: default_options }
    )
  end

  # This custom fixture overlay is needed because the existing scene-query support
  # only models broad inspection entities. Explicit surface interrogation needs
  # test-owned sampleable faces, nested faces, stacked candidates, and occluders.
  # Reusing the existing fakes directly would not let the skeleton suite express
  # face/group/component sampling or ambiguity scenarios credibly.
  def build_sample_surface_z_model
    terrain = FakeLayer.new('Terrain')
    structures = FakeLayer.new('Structures')
    soil = FakeMaterial.new('Soil')
    concrete = FakeMaterial.new('Concrete')
    steel = FakeMaterial.new('Steel')

    visible_face_target = build_sample_surface_face(
      entity_id: 401,
      persistent_id: 4001,
      source_element_id: 'surface-face-001',
      name: 'Visible Face Target',
      layer: terrain,
      material: soil,
      x_range: [0.0, 10.0],
      y_range: [0.0, 10.0],
      z_value: 2.5
    )

    group_target = build_sample_surface_group(
      entity_id: 402,
      persistent_id: 4002,
      source_element_id: 'surface-group-001',
      name: 'Grouped Surface Target',
      layer: terrain,
      material: soil,
      child_faces: [
        build_sample_surface_face(
          entity_id: 421,
          persistent_id: 4201,
          name: 'Grouped Face',
          layer: terrain,
          material: soil,
          x_range: [0.0, 10.0],
          y_range: [0.0, 10.0],
          z_value: 3.5
        )
      ],
      transformation: FakeTransformation.new(
        FakePoint.new(20.0, 0.0, 0.0),
        translation: [20.0, 0.0, 0.0]
      )
    )

    component_target = build_sample_surface_component(
      entity_id: 403,
      persistent_id: 4003,
      source_element_id: 'surface-component-001',
      name: 'Component Surface Target',
      definition_name: 'Surface Component',
      layer: terrain,
      material: concrete,
      child_faces: [
        build_sample_surface_face(
          entity_id: 431,
          persistent_id: 4301,
          name: 'Component Face',
          layer: terrain,
          material: concrete,
          x_range: [0.0, 10.0],
          y_range: [0.0, 10.0],
          z_value: 4.25
        )
      ],
      transformation: FakeTransformation.new(
        FakePoint.new(40.0, 0.0, 0.0),
        translation: [40.0, 0.0, 0.0]
      )
    )

    ambiguous_target = build_sample_surface_group(
      entity_id: 404,
      persistent_id: 4004,
      source_element_id: 'surface-ambiguous-001',
      name: 'Ambiguous Surface Target',
      layer: structures,
      material: steel,
      child_faces: [
        build_sample_surface_face(
          entity_id: 441,
          persistent_id: 4401,
          name: 'Lower Deck',
          layer: structures,
          material: steel,
          x_range: [60.0, 70.0],
          y_range: [0.0, 10.0],
          z_value: 5.0
        ),
        build_sample_surface_face(
          entity_id: 442,
          persistent_id: 4402,
          name: 'Upper Deck',
          layer: structures,
          material: steel,
          x_range: [60.0, 70.0],
          y_range: [0.0, 10.0],
          z_value: 7.0
        )
      ]
    )

    clustered_target = build_sample_surface_group(
      entity_id: 405,
      persistent_id: 4005,
      source_element_id: 'surface-clustered-001',
      name: 'Clustered Surface Target',
      layer: terrain,
      material: soil,
      child_faces: [
        build_sample_surface_face(
          entity_id: 451,
          persistent_id: 4501,
          name: 'Clustered Lower',
          layer: terrain,
          material: soil,
          x_range: [80.0, 90.0],
          y_range: [0.0, 10.0],
          z_value: 8.0
        ),
        build_sample_surface_face(
          entity_id: 452,
          persistent_id: 4502,
          name: 'Clustered Upper',
          layer: terrain,
          material: soil,
          x_range: [80.0, 90.0],
          y_range: [0.0, 10.0],
          z_value: 8.0004
        )
      ]
    )

    occluded_target = build_sample_surface_face(
      entity_id: 406,
      persistent_id: 4006,
      source_element_id: 'surface-occluded-001',
      name: 'Occluded Surface Target',
      layer: terrain,
      material: soil,
      x_range: [100.0, 110.0],
      y_range: [0.0, 10.0],
      z_value: 1.5
    )

    occluder = build_sample_surface_face(
      entity_id: 407,
      persistent_id: 4007,
      source_element_id: 'surface-occluder-001',
      name: 'Occluding Face',
      layer: structures,
      material: steel,
      x_range: [100.0, 110.0],
      y_range: [0.0, 10.0],
      z_value: 9.0
    )

    empty_group_target = build_sample_surface_group(
      entity_id: 408,
      persistent_id: 4008,
      source_element_id: 'surface-empty-001',
      name: 'Empty Group Target',
      layer: terrain,
      material: soil,
      child_faces: []
    )

    unsupported_edge_target = build_sample_surface_edge(
      entity_id: 409,
      persistent_id: 4009,
      source_element_id: 'surface-edge-001',
      name: 'Unsupported Edge Target',
      layer: terrain,
      material: soil,
      x_range: [120.0, 130.0],
      y_range: [0.0, 0.0],
      z_value: 0.0
    )

    sloped_face_target = build_sample_surface_face(
      entity_id: 410,
      persistent_id: 4010,
      source_element_id: 'surface-sloped-001',
      name: 'Sloped Face Target',
      layer: terrain,
      material: soil,
      x_range: [140.0, 150.0],
      y_range: [0.0, 10.0],
      z_value: 1.0,
      slope_x: 0.5
    )

    FakeModel.new(
      state: {
        entities: [
          visible_face_target,
          group_target,
          component_target,
          ambiguous_target,
          clustered_target,
          occluded_target,
          occluder,
          empty_group_target,
          unsupported_edge_target,
          sloped_face_target
        ],
        active_entities: [],
        selection: [],
        materials: [soil, concrete, steel],
        layers: [terrain, structures],
        bounds: build_bounds(origin_x: -10)
      },
      details: { options: default_options }
    )
  end

  def build_scene_query_group(entity_id:, origin_x:, layer:, material:, details: {})
    FakeGroup.new(
      entity_id: entity_id,
      bounds: build_bounds(origin_x: origin_x),
      layer: layer,
      material: material,
      details: { name: 'Top Group', persistent_id: 1001, entities: [Object.new] }.merge(details)
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

  def build_scene_query_component(entity_id:, origin_x:, layer:, material:, details: {})
    definition = details.fetch(:definition) do
      FakeComponentDefinition.new(name: details.fetch(:definition_name, 'Component Definition'),
                                  entities: details.fetch(:entities, []))
    end

    FakeComponentInstance.new(
      entity_id: entity_id,
      bounds: build_bounds(origin_x: origin_x),
      layer: layer,
      material: material,
      details: details.merge(definition: definition)
    )
  end

  def build_hidden_face(layer:, material:, origin_x: 10)
    build_scene_query_face(entity_id: 102, origin_x: origin_x, layer: layer, material: material,
                           details: { hidden: true, name: 'Hidden Face', persistent_id: 1002 })
  end

  def build_nested_face(layer:, material:, origin_x: 20)
    build_scene_query_face(entity_id: 201, origin_x: origin_x, layer: layer, material: material,
                           details: { name: 'Nested Face', persistent_id: 2001 })
  end

  # rubocop:disable Metrics/ParameterLists
  def build_sample_surface_face(entity_id:, persistent_id:, name:, layer:, material:, x_range:,
                                y_range:, z_value:, source_element_id: nil, hidden: false,
                                slope_x: 0.0, slope_y: 0.0)
    FakeFace.new(
      entity_id: entity_id,
      bounds: build_sample_surface_bounds(x_range: x_range, y_range: y_range, z_value: z_value),
      layer: layer,
      material: material,
      details: {
        hidden: hidden,
        name: name,
        persistent_id: persistent_id,
        attributes: sample_surface_attributes(source_element_id),
        sample_surface: {
          x_range: x_range,
          y_range: y_range,
          z: z_value,
          slope_x: slope_x,
          slope_y: slope_y
        }
      }
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def build_sample_surface_group(entity_id:, persistent_id:, name:, layer:, material:, child_faces:,
                                 source_element_id: nil, transformation: nil)
    FakeGroup.new(
      entity_id: entity_id,
      bounds: build_bounds(origin_x: child_faces.empty? ? 0 : child_faces.first.bounds.min.x),
      layer: layer,
      material: material,
      details: {
        name: name,
        persistent_id: persistent_id,
        attributes: sample_surface_attributes(source_element_id),
        entities: child_faces,
        transformation: transformation
      }
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def build_sample_surface_component(
    entity_id:,
    persistent_id:,
    name:,
    definition_name:,
    layer:,
    material:,
    child_faces:,
    source_element_id: nil,
    transformation: nil
  )
    definition = FakeComponentDefinition.new(name: definition_name, entities: child_faces)
    build_scene_query_component(
      entity_id: entity_id,
      origin_x: child_faces.empty? ? 0 : child_faces.first.bounds.min.x,
      layer: layer,
      material: material,
      details: {
        name: name,
        persistent_id: persistent_id,
        attributes: sample_surface_attributes(source_element_id),
        definition_name: definition_name,
        definition: definition,
        transformation: transformation
      }
    )
  end
  # rubocop:enable Metrics/ParameterLists

  # rubocop:disable Metrics/ParameterLists
  def build_sample_surface_edge(entity_id:, persistent_id:, name:, layer:, material:, x_range:,
                                y_range:, z_value:, source_element_id: nil)
    FakeEdge.new(
      entity_id: entity_id,
      bounds: build_sample_surface_bounds(x_range: x_range, y_range: y_range, z_value: z_value),
      layer: layer,
      material: material,
      details: {
        name: name,
        persistent_id: persistent_id,
        attributes: sample_surface_attributes(source_element_id)
      }
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def build_sample_surface_bounds(x_range:, y_range:, z_value:)
    min = FakePoint.new(x_range.first, y_range.first, z_value)
    max = FakePoint.new(x_range.last, y_range.last, z_value)
    center = FakePoint.new(
      (x_range.first + x_range.last) / 2.0,
      (y_range.first + y_range.last) / 2.0,
      z_value
    )
    FakeBounds.new(
      min: min,
      max: max,
      center: center,
      size: [x_range.last - x_range.first, y_range.last - y_range.first, 0.0]
    )
  end

  def sample_surface_attributes(source_element_id)
    return {} if source_element_id.nil?

    { 'su_mcp' => { 'sourceElementId' => source_element_id } }
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

  def default_options
    decimal_options(length_precision: 3)
  end

  def decimal_options(length_precision:)
    FakeOptionsManager.new(
      'UnitsOptions' => FakeOptionsProvider.new(
        'LengthFormat' => Length::Decimal,
        'LengthPrecision' => length_precision
      )
    )
  end
end
