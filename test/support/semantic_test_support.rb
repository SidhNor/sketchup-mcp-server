# frozen_string_literal: true

# rubocop:disable Style/OptionalBooleanParameter

require_relative 'scene_query_test_support'

# The existing scene-query fixtures are read-oriented and do not model the
# writable SketchUp surface needed for semantic creation. This overlay keeps the
# extra seam test-owned and limited to operations, wrapper groups, attribute
# writes, face creation, and pushpull recording.
module SemanticTestSupport
  class IdSequence
    def initialize(entity_id: 1_000, persistent_id: 5_000)
      @next_entity_id = entity_id
      @next_persistent_id = persistent_id
    end

    def next_entity_id
      value = @next_entity_id
      @next_entity_id += 1
      value
    end

    def next_persistent_id
      value = @next_persistent_id
      @next_persistent_id += 1
      value
    end
  end

  class FakeEntitiesCollection
    attr_reader :groups, :faces

    def initialize(id_sequence:, layer:, material:)
      @id_sequence = id_sequence
      @layer = layer
      @material = material
      @groups = []
      @faces = []
    end

    def add_group
      group = FakeGroup.new(
        entity_id: @id_sequence.next_entity_id,
        persistent_id: @id_sequence.next_persistent_id,
        layer: @layer,
        material: @material,
        id_sequence: @id_sequence
      )
      @groups << group
      group
    end

    def add_face(*points)
      face = FakeFace.new(
        entity_id: @id_sequence.next_entity_id,
        persistent_id: @id_sequence.next_persistent_id,
        layer: @layer,
        material: @material,
        points: points
      )
      @faces << face
      face
    end
  end

  class FakeGroup < Sketchup::Group
    attr_accessor :name, :layer, :material, :bounds
    attr_reader :entities, :attributes, :persistent_id

    def initialize(entity_id:, persistent_id:, layer:, material:, id_sequence:)
      super()
      @entity_id = entity_id
      @persistent_id = persistent_id
      @layer = layer
      @material = material
      @name = ''
      @bounds = build_bounds
      @attributes = Hash.new { |hash, key| hash[key] = {} }
      @entities = FakeEntitiesCollection.new(
        id_sequence: id_sequence,
        layer: layer,
        material: material
      )
    end

    def entityID
      @entity_id
    end

    def set_attribute(dictionary_name, key, value)
      @attributes[dictionary_name][key] = value
    end

    def get_attribute(dictionary_name, key, default = nil)
      @attributes.fetch(dictionary_name, {}).fetch(key, default)
    end

    private

    def build_bounds(min: [0.0, 0.0, 0.0], max: [1.0, 1.0, 1.0])
      SceneQueryTestSupport::FakeBounds.new(
        min: point(min),
        max: point(max),
        center: point([
                        (min[0] + max[0]) / 2.0,
                        (min[1] + max[1]) / 2.0,
                        (min[2] + max[2]) / 2.0
                      ]),
        size: [max[0] - min[0], max[1] - min[1], max[2] - min[2]]
      )
    end

    def point(coords)
      SceneQueryTestSupport::FakePoint.new(coords[0], coords[1], coords[2])
    end
  end

  class FakeFace < Sketchup::Face
    attr_accessor :material, :bounds
    attr_reader :pushpull_calls, :points, :layer, :persistent_id

    def initialize(entity_id:, persistent_id:, layer:, material:, points:)
      super()
      @entity_id = entity_id
      @persistent_id = persistent_id
      @layer = layer
      @material = material
      @points = points
      @normal_z = polygon_signed_area(points).negative? ? -1.0 : 1.0
      @pushpull_calls = []
      @bounds = build_bounds(points)
    end

    def entityID
      @entity_id
    end

    def pushpull(distance)
      @pushpull_calls << distance
      distance
    end

    def normal
      Struct.new(:z).new(@normal_z)
    end

    def reverse!
      @normal_z *= -1.0
    end

    private

    def build_bounds(points)
      xyz_points = points.map { |point| point.is_a?(Array) ? point : [point.x, point.y, point.z] }
      xs = xyz_points.map { |point| point[0].to_f }
      ys = xyz_points.map { |point| point[1].to_f }
      zs = xyz_points.map { |point| point[2].to_f }
      min = [xs.min || 0.0, ys.min || 0.0, zs.min || 0.0]
      max = [xs.max || 0.0, ys.max || 0.0, zs.max || 0.0]

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

    def polygon_signed_area(points)
      wrapped_points = points + [points.first]
      wrapped_points.each_cons(2).sum do |(x1, y1, _z1), (x2, y2, _z2)|
        (x1.to_f * y2.to_f) - (x2.to_f * y1.to_f)
      end / 2.0
    end
  end

  class FakeModel
    attr_reader :active_entities, :materials, :layers, :options, :operations

    def initialize(
      active_entities: nil,
      materials: nil,
      layers: nil,
      options: nil
    )
      @id_sequence = IdSequence.new
      @layers = layers || [SceneQueryTestSupport::FakeLayer.new('Layer0')]
      @materials = materials || SceneQueryTestSupport::FakeMaterialCollection.new([
                                                                                    SceneQueryTestSupport::FakeMaterial.new('Default')
                                                                                  ])
      @options = options || default_options
      default_material = @materials.to_a.first || SceneQueryTestSupport::FakeMaterial.new('Default')
      @active_entities = active_entities || FakeEntitiesCollection.new(
        id_sequence: @id_sequence,
        layer: @layers.first,
        material: default_material
      )
      @operations = []
    end

    def start_operation(name, disable_ui = true)
      @operations << [:start_operation, name, disable_ui]
    end

    def commit_operation
      @operations << [:commit_operation]
    end

    def abort_operation
      @operations << [:abort_operation]
    end

    private

    def default_options
      SceneQueryTestSupport::FakeOptionsManager.new(
        'UnitsOptions' => SceneQueryTestSupport::FakeOptionsProvider.new(
          'LengthFormat' => Length::Decimal,
          'LengthPrecision' => 3
        )
      )
    end
  end

  def build_semantic_model
    FakeModel.new
  end
end
# rubocop:enable Style/OptionalBooleanParameter
