# frozen_string_literal: true

require 'sketchup'
require_relative 'component_geometry_builder'
require_relative 'material_resolver'

module SU_MCP
  # Grouped command surface for SocketServer-owned editing and export operations.
  class EditingCommands
    def initialize(model_adapter:, logger: nil, active_model_provider: nil, geometry_builder: nil,
                   material_resolver: nil)
      @model_adapter = model_adapter
      @logger = logger
      @active_model_provider = active_model_provider
      @geometry_builder = geometry_builder || ComponentGeometryBuilder.new(logger: logger)
      @material_resolver = material_resolver || MaterialResolver.new
    end

    def create_component(params)
      log("Creating component with params: #{params.inspect}")
      model = active_model!
      entities = model.active_entities

      position = params['position'] || [0, 0, 0]
      dimensions = params['dimensions'] || [1, 1, 1]

      group = entities.add_group
      geometry_builder.build(
        group: group,
        type: params['type'],
        position: position,
        dimensions: dimensions
      )

      { id: group.entityID, success: true }
    end

    def delete_component(params)
      entity = model_adapter.find_entity!(params['id'])
      entity.erase!
      { success: true }
    end

    def transform_component(params)
      entity = model_adapter.find_entity!(params['id'])

      apply_translation(entity, params['position']) if params['position']
      apply_rotation(entity, params['rotation']) if params['rotation']
      apply_scale(entity, params['scale']) if params['scale']

      { success: true, id: entity.entityID }
    end

    def export_scene(params)
      model_adapter.export_scene(
        format: params['format'],
        width: params['width'],
        height: params['height']
      )
    end

    def apply_material(params)
      model = model_adapter.active_model!
      entity = model_adapter.find_entity!(params['id'])
      material = material_resolver.resolve(model: model, material_name: params['material'])
      apply_material_to_entity(entity, material)

      { success: true, id: entity.entityID }
    end

    private

    attr_reader :model_adapter, :logger, :active_model_provider, :geometry_builder,
                :material_resolver

    def active_model!
      return active_model_provider.call if active_model_provider.respond_to?(:call)

      Sketchup.active_model
    end

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
