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
      return create_site_element_v2(normalized_params) if params['contractVersion'] == 2

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

    def create_site_element_v2(params)
      case params.dig('lifecycle', 'mode')
      when 'adopt_existing'
        create_site_element_v2_adopt(params)
      when 'replace_preserve_identity'
        create_site_element_v2_replace(params)
      else
        create_site_element_v2_new(params)
      end
    end

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

    def resolve_v2_target_entity(target, section:)
      resolution = target_resolver.resolve(target)
      refusal_response = v2_resolution_refusal(resolution, section)
      return refusal_response if refusal_response

      resolution.fetch(:entity)
    end

    def refusal_response?(result)
      result.is_a?(Hash) && result[:outcome] == 'refused'
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

    def v2_metadata_attributes(params, state:, source_element_id: nil)
      public_params = params.fetch('__public_params__', params)
      metadata = public_params.fetch('metadata', {})

      {
        'sourceElementId' => source_element_id || metadata.fetch('sourceElementId'),
        'semanticType' => params.fetch('elementType'),
        'status' => metadata.fetch('status'),
        'state' => state,
        'schemaVersion' => SCHEMA_VERSION
      }.tap do |attributes|
        attributes.merge!(v2_type_specific_metadata_attributes(public_params))
      end
    end

    def replacement_metadata_attributes(previous_entity, params)
      previous_attributes = metadata_writer.attributes_for(previous_entity)
      source_element_id = previous_attributes.fetch('sourceElementId')

      v2_metadata_attributes(
        params,
        state: 'Replaced',
        source_element_id: source_element_id
      )
    end

    def public_params_for_metadata(params)
      # Metadata stays in public meter units even though builders consume internal lengths.
      params.fetch('__public_params__', params)
    end

    def v2_type_specific_metadata_attributes(params)
      case params['elementType']
      when 'structure'
        v2_structure_metadata_attributes(params)
      when 'path'
        v2_path_metadata_attributes(params)
      else
        {}
      end
    end

    def v2_structure_metadata_attributes(params)
      category = params.dig('definition', 'structureCategory')
      return {} unless category

      { 'structureCategory' => category }
    end

    def v2_path_metadata_attributes(params)
      definition = params.fetch('definition', {})
      attributes = { 'width' => definition['width'] }
      attributes['thickness'] = definition['thickness'] if definition.key?('thickness')
      attributes
    end

    def builder_params_for_v2(
      params,
      hosting_entity: nil,
      parent_entity: nil,
      lifecycle_target: nil
    )
      public_params = params.fetch('__public_params__', params)

      {
        'elementType' => params.fetch('elementType'),
        '__public_params__' => public_params,
        'hosting' => resolved_section(params['hosting'], 'resolved_target', hosting_entity),
        'placement' => resolved_section(params['placement'], 'resolved_parent', parent_entity),
        'lifecycle' => resolved_section(params['lifecycle'], 'resolved_target', lifecycle_target)
      }.tap do |builder_params|
        builder_params.merge!(v2_builder_payload(params))
        metadata = params.fetch('metadata', {})
        if metadata.key?('sourceElementId')
          builder_params['sourceElementId'] = metadata['sourceElementId']
        end
        builder_params['status'] = metadata['status'] if metadata.key?('status')
      end
    end

    def resolved_section(section, key, resolved_entity)
      return section unless section.is_a?(Hash) && resolved_entity

      section.merge(key => resolved_entity)
    end

    def v2_builder_payload(params)
      case params['elementType']
      when 'path'
        path_builder_payload(params)
      when 'structure'
        structure_builder_payload(params)
      else
        {}
      end
    end

    def path_builder_payload(params)
      definition = params.fetch('definition')
      path_payload = {
        'centerline' => definition['centerline'],
        'width' => definition['width']
      }
      path_payload['thickness'] = definition['thickness'] if definition.key?('thickness')
      path_payload['elevation'] = definition['elevation'] if definition.key?('elevation')

      { 'path' => path_payload }
    end

    def structure_builder_payload(params)
      definition = params.fetch('definition')
      payload = {
        'structureCategory' => definition['structureCategory']
      }
      payload['footprint'] = definition['footprint'] if definition.key?('footprint')
      payload['elevation'] = definition['elevation'] if definition.key?('elevation')
      payload['height'] = definition['height'] if definition.key?('height')
      payload
    end

    def create_site_element_v2_adopt(params)
      entity = resolve_v2_target_entity(params.dig('lifecycle', 'target'), section: 'lifecycle')
      return entity if refusal_response?(entity)

      run_v2_operation do
        metadata_writer.write!(entity, v2_metadata_attributes(params, state: 'Adopted'))
        success_result('adopted', entity)
      end
    end

    def create_site_element_v2_replace(params)
      previous_entity = resolve_v2_target_entity(
        params.dig('lifecycle', 'target'),
        section: 'lifecycle'
      )
      return previous_entity if refusal_response?(previous_entity)

      parent_entity = resolve_v2_parent_entity(params)
      return parent_entity if refusal_response?(parent_entity)

      run_v2_operation do
        entity = build_v2_entity(
          params,
          lifecycle_target: previous_entity,
          parent_entity: parent_entity
        )
        replacement_result(entity, previous_entity, params)
      end
    end

    def create_site_element_v2_new(params)
      hosting_entity = resolve_v2_hosting_entity(params)
      return hosting_entity if refusal_response?(hosting_entity)

      parent_entity = resolve_v2_parent_entity(params)
      return parent_entity if refusal_response?(parent_entity)

      run_v2_operation do
        entity = build_v2_entity(
          params,
          hosting_entity: hosting_entity,
          parent_entity: parent_entity
        )
        metadata_writer.write!(entity, v2_metadata_attributes(params, state: 'Created'))
        success_result('created', entity)
      end
    end

    def build_v2_entity(params, hosting_entity: nil, parent_entity: nil, lifecycle_target: nil)
      builder = registry.builder_for(params.fetch('elementType'))
      builder.build(
        model: model,
        params: builder_params_for_v2(
          params,
          hosting_entity: hosting_entity,
          parent_entity: parent_entity,
          lifecycle_target: lifecycle_target
        )
      )
    end

    def replacement_result(entity, previous_entity, params)
      metadata_writer.write!(entity, replacement_metadata_attributes(previous_entity, params))
      success_result('replaced', entity)
    end

    def v2_resolution_refusal(resolution, section)
      case resolution[:resolution]
      when 'none'
        refusal('target_not_found', 'Target reference resolves to no entity.', { section: section })
      when 'ambiguous'
        refusal('ambiguous_target', 'Target reference resolves ambiguously.', { section: section })
      end
    end

    def resolve_v2_hosting_entity(params)
      return nil unless params.dig('hosting', 'target').is_a?(Hash)

      resolve_v2_target_entity(params.dig('hosting', 'target'), section: 'hosting')
    end

    def resolve_v2_parent_entity(params)
      return nil unless params.dig('placement', 'mode') == 'parented'

      resolve_v2_target_entity(params.dig('placement', 'parent'), section: 'placement')
    end

    def run_v2_operation
      model.start_operation(OPERATION_NAME, true)
      result = yield
      model.commit_operation
      result
    rescue StandardError
      model.abort_operation if model.respond_to?(:abort_operation)
      raise
    end

    def success_result(outcome, entity)
      {
        success: true,
        outcome: outcome,
        managedObject: serializer.serialize(entity)
      }
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
