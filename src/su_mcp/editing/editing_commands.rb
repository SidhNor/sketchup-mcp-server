# frozen_string_literal: true

require 'sketchup'
require_relative 'material_resolver'

module SU_MCP
  # Grouped command surface for generic editing operations.
  class EditingCommands
    def initialize(model_adapter:, logger: nil, material_resolver: nil)
      @model_adapter = model_adapter
      @logger = logger
      @material_resolver = material_resolver || MaterialResolver.new
    end

    def delete_component(params)
      entity = model_adapter.find_entity!(params['id'])
      entity.erase!
      { success: true }
    end

    def transform_entities(params)
      entity = model_adapter.find_entity!(params['id'])

      apply_translation(entity, params['position']) if params['position']
      apply_rotation(entity, params['rotation']) if params['rotation']
      apply_scale(entity, params['scale']) if params['scale']

      { success: true, id: entity.entityID }
    end

    def apply_material(params)
      model = model_adapter.active_model!
      entity = model_adapter.find_entity!(params['id'])
      material = material_resolver.resolve(model: model, material_name: params['material'])
      apply_material_to_entity(entity, material)

      { success: true, id: entity.entityID }
    end

    private

    attr_reader :model_adapter, :logger, :material_resolver

    def apply_translation(entity, position)
      transformation = Geom::Transformation.translation(
        Geom::Point3d.new(position[0], position[1], position[2])
      )
      entity.transform!(transformation)
    end

    def apply_rotation(entity, rotation)
      rotations = [
        [rotation[0], Geom::Vector3d.new(1, 0, 0)],
        [rotation[1], Geom::Vector3d.new(0, 1, 0)],
        [rotation[2], Geom::Vector3d.new(0, 0, 1)]
      ]

      rotations.each do |degrees, axis|
        next if degrees.zero?

        entity.transform!(
          Geom::Transformation.rotation(entity.bounds.center, axis, degrees * Math::PI / 180)
        )
      end
    end

    def apply_scale(entity, scale)
      entity.transform!(
        Geom::Transformation.scaling(entity.bounds.center, scale[0], scale[1], scale[2])
      )
    end

    def apply_material_to_entity(entity, material)
      if entity.respond_to?(:material=)
        entity.material = material
        return
      end

      entities = instance_entities(entity)
      entities.grep(Sketchup::Face).each { |face| face.material = material }
    end

    def instance_entities(entity)
      return entity.entities if entity.is_a?(Sketchup::Group)
      return entity.definition.entities if entity.is_a?(Sketchup::ComponentInstance)

      []
    end

    def log(message)
      logger&.call(message)
    end
  end
end
