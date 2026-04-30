# frozen_string_literal: true

require_relative 'entity_relocator'
require_relative 'hierarchy_entity_serializer'
require_relative 'managed_object_metadata'
require_relative 'scene_properties'
require_relative '../runtime/tool_response'
require_relative '../scene_query/target_reference_resolver'

module SU_MCP
  # Coordinates the Ruby-owned SEM-07 hierarchy-maintenance slice.
  # rubocop:disable Metrics/ClassLength
  class HierarchyMaintenanceCommands
    CREATE_GROUP_OPERATION_NAME = 'Create Group'
    REPARENT_ENTITIES_OPERATION_NAME = 'Reparent Entities'

    def initialize(
      model: Sketchup.active_model,
      target_resolver: TargetReferenceResolver.new,
      relocator: Semantic::EntityRelocator.new(model: model),
      serializer: Semantic::HierarchyEntitySerializer.new,
      metadata_writer: Semantic::ManagedObjectMetadata.new,
      scene_properties: Semantic::SceneProperties.new
    )
      @model = model
      @target_resolver = target_resolver
      @relocator = relocator
      @serializer = serializer
      @metadata_writer = metadata_writer
      @scene_properties = scene_properties
    end

    def create_group(params)
      validation = validate_create_group_request(params)
      return validation if refusal_response?(validation)

      run_operation(CREATE_GROUP_OPERATION_NAME) do
        perform_group_creation(validation: validation, params: params)
      end
    end

    def reparent_entities(params)
      entities_request = params['entities']
      request_refusal = reparent_request_refusal(entities_request)
      return request_refusal if request_refusal

      parent = resolve_optional_parent(params['parent'])
      return parent if refusal_response?(parent)

      entities = resolve_entities_list(entities_request, field: 'entities')
      return entities if refusal_response?(entities)

      cyclic_refusal = cyclic_reparent_refusal(parent, entities)
      return cyclic_refusal if cyclic_refusal

      run_operation(REPARENT_ENTITIES_OPERATION_NAME) do
        relocated_entities = relocator.relocate(entities: entities, parent: parent)
        cleanup_placeholder(parent) if parent && !relocated_entities.empty?
        reparent_success(parent, relocated_entities)
      end
    end

    private

    attr_reader :model, :target_resolver, :relocator, :serializer, :metadata_writer,
                :scene_properties

    def resolve_optional_parent(raw_parent)
      return nil unless raw_parent

      resolution = target_resolver.resolve(raw_parent)
      refusal = resolution_refusal(resolution, field: 'parent')
      return refusal if refusal

      parent = resolution.fetch(:entity)
      return invalid_parent_type_refusal unless supported_parent?(parent)

      parent
    end

    def resolve_entities_list(raw_entities, field:)
      Array(raw_entities).each_with_index.map do |raw_entity, index|
        resolution = target_resolver.resolve(raw_entity)
        refusal = resolution_refusal(resolution, field: "#{field}[#{index}]")
        return refusal if refusal

        entity = resolution.fetch(:entity)
        unless supported_entity?(entity)
          return unsupported_entity_type_refusal("#{field}[#{index}]")
        end

        entity
      end
    end

    def supported_parent?(entity)
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end

    def supported_entity?(entity)
      supported_parent?(entity)
    end

    def resolution_refusal(resolution, field:)
      case resolution[:resolution]
      when 'unique'
        nil
      when 'none'
        refusal('target_not_found', 'Target reference resolves to no entity.', { field: field })
      when 'ambiguous'
        refusal('ambiguous_target', 'Target reference resolves ambiguously.', { field: field })
      else
        refusal(
          'target_resolution_failed',
          'Target reference resolution returned an unsupported state.',
          { field: field, resolution: resolution[:resolution] }
        )
      end
    end

    def invalid_parent_type_refusal
      refusal(
        'invalid_parent_type',
        'Parent target must resolve to a supported group or component.'
      )
    end

    def unsupported_entity_type_refusal(field)
      refusal(
        'unsupported_entity_type',
        'Entity target must resolve to a supported group or component.',
        { field: field }
      )
    end

    def duplicate_reference_refusal(raw_entities)
      normalized = raw_entities.map do |target|
        target.keys.sort.map { |key| [key.to_s, target[key]] }
      end
      return nil if normalized.uniq.length == normalized.length

      refusal('duplicate_target_reference', 'Duplicate entity target references are not allowed.')
    end

    def missing_entities_refusal(entities_request)
      return nil unless entities_request.nil? || entities_request.empty?

      refusal('missing_entities', 'At least one entity target is required.')
    end

    def reparent_request_refusal(entities_request)
      missing_entities_refusal(entities_request) || duplicate_reference_refusal(entities_request)
    end

    def cyclic_reparent_refusal(parent, entities)
      return nil unless parent
      return nil unless entities.include?(parent) || descendant_of_any?(parent, entities)

      refusal(
        'cyclic_reparent',
        'Requested reparent would create a hierarchy cycle.',
        { field: 'parent' }
      )
    end

    def descendant_of_any?(candidate_parent, entities)
      entities.any? { |entity| descendant?(entity, candidate_parent) }
    end

    def descendant?(entity, candidate_parent)
      child_entities(entity).any? do |child|
        child == candidate_parent || descendant?(child, candidate_parent)
      end
    end

    def child_entities(entity)
      collection = nested_collection_for(entity)
      return [] unless collection

      extract_nested_entities(collection)
    end

    def nested_collection_for(entity)
      return entity.entities if entity.is_a?(Sketchup::Group)
      return entity.definition.entities if entity.is_a?(Sketchup::ComponentInstance)

      nil
    end

    def extract_nested_entities(collection)
      return extract_enumerable_nested_entities(collection) if collection.respond_to?(:grep)

      [].tap do |entities|
        entities.concat(collection.groups) if collection.respond_to?(:groups)
        if collection.respond_to?(:component_instances)
          entities.concat(collection.component_instances)
        end
      end
    end

    def extract_enumerable_nested_entities(collection)
      collection.grep(Sketchup::Group) + collection.grep(Sketchup::ComponentInstance)
    end

    def reparent_success(parent, relocated_entities)
      ToolResponse.success(
        outcome: 'reparented',
        parent: parent ? serializer.serialize(parent) : nil,
        entities: relocated_entities.map { |entity| serializer.serialize(entity) }
      ).compact
    end

    def target_collection_for(parent)
      return model.active_entities unless parent

      if parent.is_a?(Sketchup::ComponentInstance)
        parent.definition.entities
      else
        parent.entities
      end
    end

    def create_empty_group(target_collection, preserve_empty: false)
      group = target_collection.add_group
      preserve_empty_group(group) if preserve_empty
      group
    end

    def perform_group_creation(validation:, params:)
      children = validation.fetch(:children)
      group = create_empty_group(
        target_collection_for(validation.fetch(:parent)),
        preserve_empty: children.empty?
      )
      apply_managed_container_attributes(group, params)
      relocated_children = relocator.relocate(
        entities: children,
        parent: group
      )
      cleanup_placeholder(group) unless relocated_children.empty?
      create_group_success(group, relocated_children)
    end

    def preserve_empty_group(group)
      return group unless group.respond_to?(:entities)

      # SketchUp can discard empty groups in-host, so keep a hidden internal
      # placeholder until semantic children are created or reparented in.
      placeholder = group.entities.add_cpoint(Geom::Point3d.new(0, 0, 0))
      placeholder.hidden = true if placeholder.respond_to?(:hidden=)
      placeholder.set_attribute(
        Semantic::ManagedObjectMetadata::DICTIONARY,
        Semantic::ManagedObjectMetadata::INTERNAL_PLACEHOLDER_KEY,
        true
      )
      group
    end

    def cleanup_placeholder(group)
      return unless group.respond_to?(:entities)

      Semantic::ManagedObjectMetadata.placeholder_entities(group.entities).each(&:erase!)
    end

    def run_operation(name)
      model.start_operation(name, true)
      result = yield
      model.commit_operation
      result
    rescue StandardError
      model.abort_operation if model.respond_to?(:abort_operation)
      raise
    end

    def refusal_response?(result)
      result.is_a?(Hash) && result[:outcome] == 'refused'
    end

    def refusal(code, message, details = nil)
      ToolResponse.refusal(code: code, message: message, details: details)
    end

    def validate_create_group_request(params)
      parent = resolve_optional_parent(params['parent'])
      return parent if refusal_response?(parent)

      children = resolve_entities_list(params['children'] || [], field: 'children')
      return children if refusal_response?(children)

      refusal = managed_container_refusal(params['metadata'])
      return refusal if refusal

      { parent: parent, children: children }
    end

    def create_group_success(group, relocated_children)
      ToolResponse.success(
        outcome: 'created',
        group: serializer.serialize(group),
        children: relocated_children.map { |entity| serializer.serialize(entity) }
      )
    end

    def managed_container_refusal(raw_metadata)
      metadata = normalize_metadata(raw_metadata)
      return nil if metadata.empty?

      unless metadata['sourceElementId']
        return missing_required_field_refusal('metadata.sourceElementId')
      end

      return missing_required_field_refusal('metadata.status') unless metadata['status']

      unsupported_field = (metadata.keys - %w[sourceElementId status]).first
      if unsupported_field
        return unsupported_option_refusal(
          "metadata.#{unsupported_field}",
          metadata[unsupported_field]
        )
      end

      nil
    end

    def normalize_metadata(raw_metadata)
      return {} unless raw_metadata.is_a?(Hash)

      raw_metadata.each_with_object({}) do |(key, value), normalized|
        normalized[key.to_s] = value
      end
    end

    def apply_managed_container_attributes(group, params)
      metadata = normalize_metadata(params['metadata'])
      return group if metadata.empty?

      metadata_writer.write!(
        group,
        'sourceElementId' => metadata.fetch('sourceElementId'),
        'semanticType' => 'grouped_feature',
        'status' => metadata.fetch('status'),
        'state' => 'Created',
        'schemaVersion' => 1
      )
      scene_properties.apply!(model: model, group: group, params: params)
      group
    end

    def missing_required_field_refusal(field)
      refusal(
        'missing_required_field',
        'Required field is missing.',
        { field: field }
      )
    end

    def unsupported_option_refusal(field, value)
      refusal(
        'unsupported_option',
        'Option is not supported for this tool.',
        { field: field, value: value }
      )
    end
  end
  # rubocop:enable Metrics/ClassLength
end
