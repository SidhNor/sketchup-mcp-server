# frozen_string_literal: true

require 'sketchup'
require_relative 'managed_mutation_helper'
require_relative 'material_resolver'
require_relative 'mutation_target_resolver'
require_relative '../semantic/length_converter'
require_relative '../runtime/tool_response'
require_relative '../scene_query/scene_query_serializer'
require_relative '../scene_query/target_reference_resolver'

module SU_MCP
  # Grouped command surface for generic editing operations.
  # rubocop:disable Metrics/ClassLength
  class EditingCommands
    DELETE_OPERATION_NAME = 'Delete Entities'
    TRANSFORM_OPERATION_NAME = 'Transform Entities'
    SET_MATERIAL_OPERATION_NAME = 'Set Entity Material'

    # rubocop:disable Metrics/ParameterLists
    def initialize(model_adapter:, logger: nil, material_resolver: nil, serializer: nil,
                   target_resolver: nil, managed_mutation_helper: nil, length_converter: nil)
      @model_adapter = model_adapter
      @logger = logger
      @material_resolver = material_resolver || MaterialResolver.new
      @serializer = serializer || SceneQuerySerializer.new
      @target_resolver = target_resolver || TargetReferenceResolver.new(
        adapter: model_adapter,
        serializer: @serializer
      )
      @managed_mutation_helper = managed_mutation_helper || Editing::ManagedMutationHelper.new
      @mutation_target_resolver = Editing::MutationTargetResolver.new(
        model_adapter: model_adapter,
        target_resolver: @target_resolver,
        supported_target: method(:supported_mutation_target?)
      )
      @length_converter = length_converter || Semantic::LengthConverter.new
    end
    # rubocop:enable Metrics/ParameterLists

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
      mutation_target = resolve_mutation_target(params)
      return mutation_target if refusal_response?(mutation_target)

      run_mutation_operation(mutation_target.fetch(:model), TRANSFORM_OPERATION_NAME) do
        entity = mutation_target.fetch(:entity)
        apply_translation(entity, params['position']) if params['position']
        apply_rotation(entity, params['rotation']) if params['rotation']
        apply_scale(entity, params['scale']) if params['scale']

        ToolResponse.success(
          outcome: 'transformed',
          **managed_mutation_helper.success_payload(entity)
        )
      end
    end

    def apply_material(params)
      mutation_target = resolve_mutation_target(params)
      return mutation_target if refusal_response?(mutation_target)

      run_mutation_operation(mutation_target.fetch(:model), SET_MATERIAL_OPERATION_NAME) do
        entity = mutation_target.fetch(:entity)
        material = material_resolver.resolve(
          model: mutation_target.fetch(:model),
          material_name: params['material']
        )
        apply_material_to_entity(entity, material)

        ToolResponse.success(
          outcome: 'material_applied',
          **managed_mutation_helper.success_payload(entity)
        )
      end
    end

    private

    attr_reader :model_adapter, :logger, :material_resolver, :serializer, :target_resolver,
                :managed_mutation_helper, :mutation_target_resolver, :length_converter

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

    def supported_mutation_target?(entity)
      supported_delete_target?(entity)
    end

    def run_delete_operation(&block)
      model = model_adapter.active_model!
      run_mutation_operation(model, DELETE_OPERATION_NAME, &block)
    end

    def run_mutation_operation(model, operation_name)
      operation_started = false
      if model.respond_to?(:start_operation)
        model.start_operation(operation_name, true)
        operation_started = true
      end

      result = yield
      model.commit_operation if operation_started && model.respond_to?(:commit_operation)
      result
    rescue StandardError
      model.abort_operation if operation_started && model.respond_to?(:abort_operation)
      raise
    end

    def resolve_mutation_target(params)
      mutation_target_resolver.resolve(params)
    end

    def refusal_response?(result)
      result.is_a?(Hash) && result[:outcome] == 'refused'
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
        Geom::Point3d.new(*internal_position(position))
      )
      entity.transform!(transformation)
    end

    def internal_position(position)
      Array(position).first(3).map do |value|
        length_converter.public_meters_to_internal(value)
      end
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
  # rubocop:enable Metrics/ClassLength
end
