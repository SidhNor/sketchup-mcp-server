# frozen_string_literal: true

require_relative 'entity_relocator'
require_relative 'hierarchy_entity_serializer'
require_relative 'target_resolver'

module SU_MCP
  # Coordinates the Ruby-owned SEM-07 hierarchy-maintenance slice.
  # rubocop:disable Metrics/ClassLength
  class HierarchyMaintenanceCommands
    CREATE_GROUP_OPERATION_NAME = 'Create Group'
    REPARENT_ENTITIES_OPERATION_NAME = 'Reparent Entities'

    def initialize(
      model: Sketchup.active_model,
      target_resolver: Semantic::TargetResolver.new,
      relocator: Semantic::EntityRelocator.new(model: model),
      serializer: Semantic::HierarchyEntitySerializer.new
    )
      @model = model
      @target_resolver = target_resolver
      @relocator = relocator
      @serializer = serializer
    end

    def create_group(params)
      parent = resolve_optional_parent(params['parent'])
      return parent if refusal_response?(parent)

      children = resolve_entities_list(params['children'] || [], field: 'children')
      return children if refusal_response?(children)

      run_operation(CREATE_GROUP_OPERATION_NAME) do
        group = target_collection_for(parent).add_group
        relocated_children = relocator.relocate(entities: children, parent: group)

        {
          success: true,
          outcome: 'created',
          group: serializer.serialize(group),
          children: relocated_children.map { |entity| serializer.serialize(entity) }
        }
      end
    end

    def reparent_entities(params)
      entities_request = params['entities']
      missing_entities_refusal = missing_entities_refusal(entities_request)
      return missing_entities_refusal if missing_entities_refusal

      duplicate_refusal = duplicate_reference_refusal(entities_request)
      return duplicate_refusal if duplicate_refusal

      parent = resolve_optional_parent(params['parent'])
      return parent if refusal_response?(parent)

      entities = resolve_entities_list(entities_request, field: 'entities')
      return entities if refusal_response?(entities)

      cyclic_refusal = cyclic_reparent_refusal(parent, entities)
      return cyclic_refusal if cyclic_refusal

      run_operation(REPARENT_ENTITIES_OPERATION_NAME) do
        relocated_entities = relocator.relocate(entities: entities, parent: parent)
        reparent_success(parent, relocated_entities)
      end
    end

    private

    attr_reader :model, :target_resolver, :relocator, :serializer

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
      when 'none'
        refusal('target_not_found', 'Target reference resolves to no entity.', { field: field })
      when 'ambiguous'
        refusal('ambiguous_target', 'Target reference resolves ambiguously.', { field: field })
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
      {
        success: true,
        outcome: 'reparented',
        parent: parent ? serializer.serialize(parent) : nil,
        entities: relocated_entities.map { |entity| serializer.serialize(entity) }
      }.compact
    end

    def target_collection_for(parent)
      return model.active_entities unless parent

      if parent.is_a?(Sketchup::ComponentInstance)
        parent.definition.entities
      else
        parent.entities
      end
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
  end
  # rubocop:enable Metrics/ClassLength
end
