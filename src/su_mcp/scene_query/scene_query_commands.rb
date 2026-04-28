# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../runtime/tool_response'
require_relative 'sample_surface_query'
require_relative 'scene_query_serializer'
require_relative 'scope_resolver'
require_relative 'target_reference_resolver'
require_relative 'targeting_query'

module SU_MCP
  # Read-oriented SketchUp command behavior and entity serialization helpers.
  class SceneQueryCommands
    def initialize(logger: nil, adapter: nil, serializer: nil, scope_resolver: nil,
                   target_reference_resolver: nil)
      @logger = logger
      @adapter = adapter || Adapters::ModelAdapter.new
      @serializer = serializer || SceneQuerySerializer.new
      @targeting_query = TargetingQuery.new(serializer: @serializer)
      @target_reference_resolver =
        target_reference_resolver || TargetReferenceResolver.new(
          adapter: @adapter,
          serializer: @serializer,
          targeting_query: @targeting_query
        )
      @scope_resolver = scope_resolver || ScopeResolver.new(
        adapter: @adapter,
        target_resolver: @target_reference_resolver
      )
      @sample_surface_query = SampleSurfaceQuery.new(serializer: @serializer)
    end

    def list_resources
      adapter.top_level_entities(include_hidden: true).map do |entity|
        {
          entityId: entity.entityID.to_s,
          type: serializer.entity_type_key(entity)
        }
      end
    rescue RuntimeError => e
      return [] if e.message == 'No active SketchUp model'

      raise
    end

    def get_scene_info(params = {})
      model = adapter.active_model!
      entities = adapter.top_level_entities(include_hidden: true)

      {
        success: true,
        model: model_summary(model),
        counts: scene_counts(model, entities),
        bounds: serializer.bounds_to_h(model.bounds),
        entities: serialize_entities(entities.first(limit_from(params, 'entity_limit', 25)))
      }
    end

    def list_entities(params = {})
      adapter.active_model!
      scope = scope_resolver.resolve(
        scope_selector: params['scopeSelector'],
        output_options: params['outputOptions']
      )
      entities = visible_entities(scope.fetch(:entities))
      limited_entities = entities.first(scope.fetch(:limit))

      {
        success: true,
        count: entities.length,
        entities: serialize_entities(limited_entities)
      }
    end

    def get_entity_info(params)
      return unsupported_request_field_refusal('id') if params.key?('id') || params.key?(:id)
      return missing_target_refusal('targetReference') unless params['targetReference'].is_a?(Hash)

      resolution = target_reference_resolver.resolve(params.fetch('targetReference'))
      unless resolution[:resolution] == 'unique'
        return invalid_target_reference_refusal('targetReference')
      end

      {
        success: true,
        entity: serializer.serialize_entity(resolution.fetch(:entity))
      }
    rescue TargetReferenceResolver::InvalidReference => e
      target_reference_error_refusal(e)
    end

    def find_entities(params)
      adapter.active_model!
      target_selector = targeting_query.normalized_target_selector(params['targetSelector'])
      matches = targeting_query.filter(adapter.all_entities_recursive, target_selector)

      {
        success: true,
        resolution: targeting_query.resolution_for(matches),
        matches: matches.map { |entity| serializer.serialize_target_match(entity) }
      }
    end

    def sample_surface_z(params)
      adapter.active_model!
      sample_surface_query.execute(
        entities: adapter.all_entities_recursive,
        entity_entries: adapter.all_entity_paths_recursive,
        scene_entities: adapter.queryable_entities,
        params: params
      )
    end

    def selection_info
      adapter.active_model!
      selection = visible_entities(adapter.selected_entities)

      log "Getting selection, count: #{selection.length}"

      selected_entities = serialize_entities(selection)
      { success: true, count: selected_entities.length, entities: selected_entities }
    end

    private

    attr_reader :adapter, :serializer, :targeting_query, :target_reference_resolver,
                :scope_resolver, :sample_surface_query

    def model_summary(model)
      {
        title: model.title,
        path: model.path,
        activePathDepth: model.active_path ? model.active_path.length : 0
      }
    end

    def scene_counts(model, entities)
      {
        topLevelEntities: entities.length,
        selectedEntities: model.selection.length,
        materials: model.materials.length,
        layers: model.layers.length,
        byType: serializer.entity_type_counts(entities)
      }
    end

    def serialize_entities(entities)
      entities.map { |entity| serializer.serialize_entity(entity) }
    end

    def visible_entities(entities)
      entities.select { |entity| serializer.public_surface_entity?(entity) }
    end

    def limit_from(params, key, default)
      limit = (params[key] || default).to_i
      [limit, 1].max
    end

    def log(message)
      @logger&.call(message)
    end

    def unsupported_request_field_refusal(field)
      ToolResponse.refusal(
        code: 'unsupported_request_field',
        message: 'Unsupported request field.',
        details: { field: field, allowedFields: ['targetReference'] }
      )
    end

    def missing_target_refusal(field)
      ToolResponse.refusal(
        code: 'missing_target',
        message: 'targetReference is required.',
        details: {
          field: field,
          allowedFields: TargetReferenceResolver::TARGET_REFERENCE_KEYS
        }
      )
    end

    def invalid_target_reference_refusal(field)
      ToolResponse.refusal(
        code: 'invalid_target_reference',
        message: 'Target reference must resolve to one entity.',
        details: { field: field }
      )
    end

    def target_reference_error_refusal(error)
      code = error.code == 'missing_target' ? 'missing_target' : error.code
      ToolResponse.refusal(
        code: code,
        message: error.message,
        details: error.details
      )
    end
  end
end
