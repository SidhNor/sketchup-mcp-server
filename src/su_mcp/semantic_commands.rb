# frozen_string_literal: true

require_relative 'semantic/builder_registry'
require_relative 'semantic/managed_object_metadata'
require_relative 'semantic/pad_builder'
require_relative 'semantic/request_normalizer'
require_relative 'semantic/request_validator'
require_relative 'semantic/serializer'
require_relative 'semantic/structure_builder'
require_relative 'semantic/target_resolver'

module SU_MCP
  # Coordinates the Ruby-owned SEM-01 semantic creation slice.
  # rubocop:disable Metrics/ClassLength
  class SemanticCommands
    OPERATION_NAME = 'Create Site Element'
    METADATA_OPERATION_NAME = 'Set Entity Metadata'
    SCHEMA_VERSION = 1

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      model: Sketchup.active_model,
      registry: Semantic::BuilderRegistry.new,
      validator: Semantic::RequestValidator.new,
      request_normalizer: Semantic::RequestNormalizer.new,
      metadata_writer: Semantic::ManagedObjectMetadata.new,
      serializer: Semantic::Serializer.new,
      target_resolver: Semantic::TargetResolver.new
    )
      @model = model
      @registry = registry
      @validator = validator
      @request_normalizer = request_normalizer
      @metadata_writer = metadata_writer
      @serializer = serializer
      @target_resolver = target_resolver
    end
    # rubocop:enable Metrics/ParameterLists

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_site_element(params)
      refusal = validator.refusal_for(params)
      return refusal if refusal

      # Normalize only validated requests so meter semantics stay at the Ruby boundary.
      normalized_params = request_normalizer.normalize_create_site_element_params(params)
      builder = registry.builder_for(params.fetch('elementType'))
      model.start_operation(OPERATION_NAME, true)
      entity = builder.build(model: model, params: normalized_params)
      metadata_writer.write!(entity, metadata_attributes(normalized_params))
      result = {
        success: true,
        outcome: 'created',
        managedObject: serializer.serialize(entity)
      }
      model.commit_operation
      result
    rescue StandardError
      model.abort_operation if model.respond_to?(:abort_operation)
      raise
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # rubocop:disable Naming/AccessorMethodName
    def set_entity_metadata(params)
      refusal = missing_metadata_change_refusal(params)
      return refusal if refusal

      resolution = target_resolver.resolve(params.fetch('target'))
      refusal = refusal_for_resolution(resolution)
      return refusal if refusal

      apply_metadata_update(resolution.fetch(:entity), params)
    end
    # rubocop:enable Naming/AccessorMethodName

    private

    attr_reader :model, :registry, :validator, :request_normalizer, :metadata_writer, :serializer,
                :target_resolver

    def refusal_for_resolution(resolution)
      return target_not_found_refusal if resolution[:resolution] == 'none'
      return ambiguous_target_refusal if resolution[:resolution] == 'ambiguous'

      nil
    end

    # rubocop:disable Metrics/MethodLength
    def apply_metadata_update(entity, params)
      operation_started = false
      prepared_update = metadata_writer.prepare_update(entity, **metadata_mutation_params(params))
      refusal = metadata_update_refusal(prepared_update)
      return refusal if refusal

      model.start_operation(METADATA_OPERATION_NAME, true)
      operation_started = true
      metadata_writer.apply_prepared_update(entity, prepared_update)
      result = {
        success: true,
        outcome: 'updated',
        managedObject: serializer.serialize(entity)
      }
      model.commit_operation
      result
    rescue StandardError
      model.abort_operation if operation_started && model.respond_to?(:abort_operation)
      raise
    end
    # rubocop:enable Metrics/MethodLength

    def missing_metadata_change_refusal(params)
      set_attributes = params.fetch('set', {})
      clear_attributes = params.fetch('clear', [])
      return nil unless set_attributes.empty? && clear_attributes.empty?

      refusal('missing_metadata_change', 'At least one metadata change is required.')
    end

    def metadata_mutation_params(params)
      {
        set: params.fetch('set', {}),
        clear: params.fetch('clear', [])
      }
    end

    def metadata_update_refusal(prepared_update)
      return nil unless prepared_update[:outcome] == 'refused'

      { success: true, outcome: 'refused', refusal: prepared_update[:refusal] }
    end

    def target_not_found_refusal
      refusal('target_not_found', 'Target reference resolves to no entity.')
    end

    def ambiguous_target_refusal
      refusal('ambiguous_target', 'Target reference resolves ambiguously.')
    end

    def refusal(code, message, details = nil)
      response = {
        success: true,
        outcome: 'refused',
        refusal: {
          code: code,
          message: message
        }
      }
      response[:refusal][:details] = details if details
      response
    end

    def metadata_attributes(params)
      public_params = public_params_for_metadata(params)

      {
        'sourceElementId' => public_params.fetch('sourceElementId'),
        'semanticType' => public_params.fetch('elementType'),
        'status' => public_params.fetch('status'),
        'state' => 'Created',
        'schemaVersion' => SCHEMA_VERSION
      }.tap do |attributes|
        attributes.merge!(type_specific_metadata_attributes(public_params))
      end
    end

    def public_params_for_metadata(params)
      # Metadata stays in public meter units even though builders consume internal lengths.
      params.fetch('__public_params__', params)
    end

    def type_specific_metadata_attributes(params)
      case params['elementType']
      when 'structure'
        structure_metadata_attributes(params)
      when 'path'
        path_metadata_attributes(params)
      when 'retaining_edge'
        retaining_edge_metadata_attributes(params)
      when 'planting_mass'
        planting_mass_metadata_attributes(params)
      when 'tree_proxy'
        tree_proxy_metadata_attributes(params)
      else
        {}
      end
    end

    def structure_metadata_attributes(params)
      return {} unless params['structureCategory']

      { 'structureCategory' => params['structureCategory'] }
    end

    def path_metadata_attributes(params)
      payload = params.fetch('path', {})
      attributes = { 'width' => payload['width'] }
      attributes['thickness'] = payload['thickness'] if payload.key?('thickness')
      attributes
    end

    def retaining_edge_metadata_attributes(params)
      payload = params.fetch('retaining_edge', {})
      {
        'height' => payload['height'],
        'thickness' => payload['thickness']
      }
    end

    def planting_mass_metadata_attributes(params)
      payload = params.fetch('planting_mass', {})
      attributes = { 'averageHeight' => payload['averageHeight'] }
      if payload.key?('plantingCategory')
        attributes['plantingCategory'] = payload['plantingCategory']
      end
      attributes
    end

    def tree_proxy_metadata_attributes(params)
      payload = params.fetch('tree_proxy', {})
      attributes = {
        'height' => payload['height'],
        'canopyDiameterX' => payload['canopyDiameterX'],
        'canopyDiameterY' => payload.fetch('canopyDiameterY', payload['canopyDiameterX']),
        'trunkDiameter' => payload['trunkDiameter']
      }
      attributes['speciesHint'] = payload['speciesHint'] if payload.key?('speciesHint')
      attributes
    end
  end
  # rubocop:enable Metrics/ClassLength
end
