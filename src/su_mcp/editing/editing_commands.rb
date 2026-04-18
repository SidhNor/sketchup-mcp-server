# frozen_string_literal: true

require 'sketchup'
require_relative 'material_resolver'
require_relative '../runtime/tool_response'
require_relative '../scene_query/scene_query_serializer'
require_relative '../scene_query/target_reference_resolver'

module SU_MCP
  # Grouped command surface for generic editing operations.
  class EditingCommands
    DELETE_OPERATION_NAME = 'Delete Entities'

    def initialize(model_adapter:, logger: nil, material_resolver: nil, serializer: nil,
                   target_resolver: nil)
      @model_adapter = model_adapter
      @logger = logger
      @material_resolver = material_resolver || MaterialResolver.new
      @serializer = serializer || SceneQuerySerializer.new
      @target_resolver = target_resolver || TargetReferenceResolver.new(
        adapter: model_adapter,
        serializer: @serializer
      )
    end

    # rubocop:disable Metrics/MethodLength
    def delete_entities(params)
      validate_delete_entities_params!(params)

      resolution = target_resolver.resolve(params.fetch('targetReference'))
      return target_not_found_refusal if resolution[:resolution] == 'none'
      return ambiguous_target_refusal if resolution[:resolution] == 'ambiguous'

      entity = resolution.fetch(:entity)
      return unsupported_target_type_refusal unless supported_delete_target?(entity)

      deleted_summary = serializer.serialize_target_match(entity)
      run_delete_operation do
        entity.erase!
        ToolResponse.success(
          outcome: 'deleted',
          operation: {
            name: DELETE_OPERATION_NAME,
            targetKind: serializer.entity_type_key(entity)
          },
          affectedEntities: {
            deleted: [deleted_summary]
          }
        )
      end
    end
    # rubocop:enable Metrics/MethodLength

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

    attr_reader :model_adapter, :logger, :material_resolver, :serializer, :target_resolver

    def validate_delete_entities_params!(params)
      ambiguity_policy = params.dig('constraints', 'ambiguityPolicy')
      if ambiguity_policy && ambiguity_policy != 'fail'
        raise "Unsupported ambiguityPolicy: #{ambiguity_policy}"
      end

      response_format = params.dig('outputOptions', 'responseFormat')
      return if response_format.nil? || response_format == 'concise'

      raise "Unsupported responseFormat: #{response_format}"
    end

    def supported_delete_target?(entity)
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end

    def run_delete_operation
      model = model_adapter.active_model!
      operation_started = false
      if model.respond_to?(:start_operation)
        model.start_operation(DELETE_OPERATION_NAME, true)
        operation_started = true
      end

      result = yield
      model.commit_operation if operation_started && model.respond_to?(:commit_operation)
      result
    rescue StandardError
      model.abort_operation if operation_started && model.respond_to?(:abort_operation)
      raise
    end

    def target_not_found_refusal
      ToolResponse.refusal(
        code: 'target_not_found',
        message: 'Target reference resolves to no entity.'
      )
    end

    def ambiguous_target_refusal
      ToolResponse.refusal(
        code: 'ambiguous_target',
        message: 'Target reference resolves ambiguously.'
      )
    end

    def unsupported_target_type_refusal
      ToolResponse.refusal(
        code: 'unsupported_target_type',
        message: 'Target reference must resolve to a supported group or component instance.'
      )
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
