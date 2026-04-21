# frozen_string_literal: true

require_relative 'builder_registry'
require_relative 'builder_refusal'
require_relative 'destination_resolver'
require_relative 'managed_object_metadata'
require_relative 'pad_builder'
require_relative 'request_normalizer'
require_relative 'request_validator'
require_relative '../runtime/tool_response'
require_relative '../scene_query/target_reference_resolver'
require_relative 'serializer'
require_relative 'structure_builder'

module SU_MCP
  # Coordinates the Ruby-owned SEM-01 semantic creation slice.
  # rubocop:disable Metrics/ClassLength
  class SemanticCommands
    OPERATION_NAME = 'Create Site Element'
    METADATA_OPERATION_NAME = 'Set Entity Metadata'
    SCHEMA_VERSION = 1
    SUPPORTED_HOSTING_MODES = {
      'path' => ['surface_drape'],
      'pad' => ['surface_snap'],
      'retaining_edge' => ['edge_clamp']
    }.freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      model: Sketchup.active_model,
      registry: Semantic::BuilderRegistry.new,
      validator: Semantic::RequestValidator.new,
      request_normalizer: Semantic::RequestNormalizer.new,
      metadata_writer: Semantic::ManagedObjectMetadata.new,
      serializer: Semantic::Serializer.new,
      target_resolver: TargetReferenceResolver.new,
      destination_resolver: Semantic::DestinationResolver.new(model: model)
    )
      @model = model
      @registry = registry
      @validator = validator
      @request_normalizer = request_normalizer
      @metadata_writer = metadata_writer
      @serializer = serializer
      @target_resolver = target_resolver
      @destination_resolver = destination_resolver
    end
    # rubocop:enable Metrics/ParameterLists

    def create_site_element(params)
      refusal = validator.refusal_for(params)
      return refusal if refusal

      # Normalize only validated requests so meter semantics stay at the Ruby boundary.
      normalized_params = request_normalizer.normalize_create_site_element_params(params)
      create_site_element_v2(normalized_params, public_params: params)
    rescue Semantic::BuilderRefusal => e
      ToolResponse.refusal(code: e.code, message: e.message, details: e.details)
    end

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
                :target_resolver, :destination_resolver

    def create_site_element_v2(params, public_params:)
      case params.dig('lifecycle', 'mode')
      when 'adopt_existing'
        create_site_element_v2_adopt(params, public_params: public_params)
      when 'replace_preserve_identity'
        create_site_element_v2_replace(params, public_params: public_params)
      else
        create_site_element_v2_new(params, public_params: public_params)
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
      result = ToolResponse.success(
        outcome: 'updated',
        managedObject: serializer.serialize(entity)
      )
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

      ToolResponse.refusal_result(prepared_update[:refusal])
    end

    def target_not_found_refusal
      refusal('target_not_found', 'Target reference resolves to no entity.')
    end

    def ambiguous_target_refusal
      refusal('ambiguous_target', 'Target reference resolves ambiguously.')
    end

    def refusal(code, message, details = nil)
      ToolResponse.refusal(code: code, message: message, details: details)
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

    def metadata_attributes(public_params, state:, source_element_id: nil)
      metadata = public_params.fetch('metadata', {})

      {
        'sourceElementId' => source_element_id || metadata.fetch('sourceElementId'),
        'semanticType' => public_params.fetch('elementType'),
        'status' => metadata.fetch('status'),
        'state' => state,
        'schemaVersion' => SCHEMA_VERSION
      }.tap do |attributes|
        attributes.merge!(type_specific_metadata_attributes(public_params))
      end
    end

    def replacement_metadata_attributes(previous_entity, params)
      previous_attributes = metadata_writer.attributes_for(previous_entity)
      source_element_id = previous_attributes.fetch('sourceElementId')

      metadata_attributes(
        params,
        state: 'Replaced',
        source_element_id: source_element_id
      )
    end

    def builder_params_for_v2(
      params,
      hosting_entity: nil,
      parent_entity: nil,
      lifecycle_target: nil
    )
      {
        'elementType' => params.fetch('elementType'),
        'hosting' => resolved_section(params['hosting'], 'resolved_target', hosting_entity),
        'placement' => resolved_section(params['placement'], 'resolved_parent', parent_entity),
        'lifecycle' => resolved_section(params['lifecycle'], 'resolved_target', lifecycle_target)
      }.tap do |builder_params|
        builder_params.merge!(v2_builder_payload(params))
      end
    end

    def resolved_section(section, key, resolved_entity)
      return section unless section.is_a?(Hash) && resolved_entity

      section.merge(key => resolved_entity)
    end

    def v2_builder_payload(params)
      case params['elementType']
      when 'pad', 'structure', 'path', 'retaining_edge', 'planting_mass', 'tree_proxy'
        migrated_builder_payload(params)
      else
        {}
      end
    end

    def migrated_builder_payload(params)
      payload = { 'definition' => params.fetch('definition') }
      payload['sceneProperties'] = params['sceneProperties'] if params.key?('sceneProperties')
      payload['representation'] = params['representation'] if params.key?('representation')
      payload
    end

    def create_site_element_v2_adopt(params, public_params:)
      entity = resolve_v2_target_entity(params.dig('lifecycle', 'target'), section: 'lifecycle')
      return entity if refusal_response?(entity)

      run_v2_operation do
        metadata_writer.write!(entity, metadata_attributes(public_params, state: 'Adopted'))
        success_result('adopted', entity)
      end
    end

    def create_site_element_v2_replace(params, public_params:)
      previous_entity = resolve_v2_target_entity(
        params.dig('lifecycle', 'target'),
        section: 'lifecycle'
      )
      return previous_entity if refusal_response?(previous_entity)

      replacement_context = resolve_v2_replace_context(params, previous_entity)
      return replacement_context if refusal_response?(replacement_context)

      run_v2_replace_operation(params, public_params, previous_entity, replacement_context)
    end

    def create_site_element_v2_new(params, public_params:)
      creation_context = resolve_v2_new_context(params)
      return creation_context if refusal_response?(creation_context)

      run_v2_operation do
        entity = build_v2_entity(
          params,
          hosting_entity: creation_context[:hosting_entity],
          parent_entity: creation_context[:parent_entity],
          destination: creation_context.fetch(:destination)
        )
        cleanup_placeholder(creation_context[:parent_entity]) if creation_context[:parent_entity]
        metadata_writer.write!(entity, metadata_attributes(public_params, state: 'Created'))
        success_result('created', entity)
      end
    end

    def build_v2_entity(
      params,
      hosting_entity: nil,
      parent_entity: nil,
      lifecycle_target: nil,
      destination: model.active_entities
    )
      builder = registry.builder_for(params.fetch('elementType'))
      builder.build(
        model: model,
        destination: destination,
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
      previous_entity.erase!
      success_result('replaced', entity)
    rescue StandardError
      cleanup_entity(entity)
      raise
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

    def resolve_v2_explicit_parent_entity(params)
      return nil unless params.dig('placement', 'mode') == 'parented'
      return nil unless params.dig('placement', 'parent').is_a?(Hash)

      resolve_v2_target_entity(params.dig('placement', 'parent'), section: 'placement')
    end

    def resolve_v2_new_context(params)
      hosting_entity = resolve_v2_hosting_entity(params)
      return hosting_entity if refusal_response?(hosting_entity)

      parent_entity = resolve_v2_explicit_parent_entity(params)
      return parent_entity if refusal_response?(parent_entity)

      hosting_refusal = unsupported_hosting_refusal(params)
      return hosting_refusal if hosting_refusal

      destination = resolve_v2_create_destination(parent_entity)
      return destination if refusal_response?(destination)

      {
        hosting_entity: hosting_entity,
        parent_entity: parent_entity,
        destination: destination.fetch(:destination)
      }
    end

    def run_v2_replace_operation(params, public_params, previous_entity, replacement_context)
      run_v2_operation do
        entity = build_v2_entity(
          params,
          lifecycle_target: previous_entity,
          parent_entity: replacement_context[:parent_entity],
          destination: replacement_context.fetch(:destination)
        )
        replacement_result(entity, previous_entity, public_params)
      end
    end

    def resolve_v2_replace_context(params, previous_entity)
      replace_target_refusal = replacement_target_refusal(previous_entity)
      return replace_target_refusal if replace_target_refusal

      parent_entity = resolve_v2_explicit_parent_entity(params)
      return parent_entity if refusal_response?(parent_entity)

      destination = resolve_v2_replace_destination(
        previous_entity: previous_entity,
        explicit_parent_entity: parent_entity
      )
      return destination if refusal_response?(destination)

      {
        parent_entity: parent_entity,
        destination: destination.fetch(:destination)
      }
    end

    def resolve_v2_create_destination(parent_entity)
      destination_resolver.resolve_for_create(parent_entity: parent_entity)
    end

    def resolve_v2_replace_destination(previous_entity:, explicit_parent_entity:)
      destination_resolver.resolve_for_replace(
        previous_entity: previous_entity,
        explicit_parent: explicit_parent_entity
      )
    end

    def unsupported_hosting_refusal(params)
      hosting_mode = params.dig('hosting', 'mode').to_s
      return nil if hosting_mode.empty? || hosting_mode == 'none'

      supported_modes = SUPPORTED_HOSTING_MODES.fetch(params.fetch('elementType'), [])
      return nil if supported_modes.include?(hosting_mode)

      refusal(
        'unsupported_hosting_mode',
        'Hosting mode is not supported for this semantic element type.',
        { section: 'hosting', mode: hosting_mode, elementType: params.fetch('elementType') }
      )
    end

    def replacement_target_refusal(entity)
      return locked_replace_target_refusal if entity.respond_to?(:locked?) && entity.locked?
      return locked_replace_target_refusal unless entity.respond_to?(:erase!)

      nil
    end

    def locked_replace_target_refusal
      refusal(
        'invalid_replace_target',
        'Lifecycle target cannot be safely replaced in the current SketchUp context.',
        { section: 'lifecycle' }
      )
    end

    def cleanup_entity(entity)
      return unless entity.respond_to?(:erase!)
      return if entity.respond_to?(:erased?) && entity.erased?

      entity.erase!
    rescue StandardError
      nil
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

    def cleanup_placeholder(parent_entity)
      return unless parent_entity.respond_to?(:entities)

      Semantic::ManagedObjectMetadata.placeholder_entities(parent_entity.entities).each(&:erase!)
    end

    def success_result(outcome, entity)
      ToolResponse.success(
        outcome: outcome,
        managedObject: serializer.serialize(entity)
      )
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
      category = params.dig('definition', 'structureCategory')
      return {} unless category

      { 'structureCategory' => category }
    end

    def path_metadata_attributes(params)
      payload = params.fetch('definition', {})
      attributes = { 'width' => payload['width'] }
      attributes['thickness'] = payload['thickness'] if payload.key?('thickness')
      attributes
    end

    def retaining_edge_metadata_attributes(params)
      payload = params.fetch('definition', {})
      {
        'height' => payload['height'],
        'thickness' => payload['thickness']
      }
    end

    def planting_mass_metadata_attributes(params)
      payload = params.fetch('definition', {})
      attributes = { 'averageHeight' => payload['averageHeight'] }
      if payload.key?('plantingCategory')
        attributes['plantingCategory'] = payload['plantingCategory']
      end
      attributes
    end

    def tree_proxy_metadata_attributes(params)
      payload = params.fetch('definition', {})
      canopy_diameter_y = payload['canopyDiameterY'] || payload['canopyDiameterX']
      attributes = {
        'height' => payload['height'],
        'canopyDiameterX' => payload['canopyDiameterX'],
        'canopyDiameterY' => canopy_diameter_y,
        'trunkDiameter' => payload['trunkDiameter']
      }
      attributes['speciesHint'] = payload['speciesHint'] if payload.key?('speciesHint')
      attributes
    end
  end
  # rubocop:enable Metrics/ClassLength
end
