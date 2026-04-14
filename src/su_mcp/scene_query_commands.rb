# frozen_string_literal: true

require_relative 'adapters/model_adapter'
require_relative 'scene_query_serializer'

module SU_MCP
  # Read-oriented SketchUp command behavior and entity serialization helpers.
  class SceneQueryCommands
    def initialize(logger: nil, adapter: nil, serializer: nil)
      @logger = logger
      @adapter = adapter || Adapters::ModelAdapter.new
      @serializer = serializer || SceneQuerySerializer.new
    end

    def list_resources
      adapter.top_level_entities(include_hidden: true).map do |entity|
        {
          id: entity.entityID,
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
      entities = adapter.top_level_entities(include_hidden: params['include_hidden'] == true)

      {
        success: true,
        count: entities.length,
        entities: serialize_entities(entities.first(limit_from(params, 'limit', 100)))
      }
    end

    def get_entity_info(params)
      {
        success: true,
        entity: serializer.serialize_entity(adapter.find_entity!(params['id']))
      }
    end

    def selection_info
      adapter.active_model!
      selection = adapter.selected_entities

      log "Getting selection, count: #{selection.length}"

      selected_entities = serialize_entities(selection)
      { success: true, count: selected_entities.length, entities: selected_entities }
    end

    private

    attr_reader :adapter, :serializer

    def model_summary(model)
      {
        title: model.title,
        path: model.path,
        active_path_depth: model.active_path ? model.active_path.length : 0
      }
    end

    def scene_counts(model, entities)
      {
        top_level_entities: entities.length,
        selected_entities: model.selection.length,
        materials: model.materials.length,
        layers: model.layers.length,
        by_type: serializer.entity_type_counts(entities)
      }
    end

    def serialize_entities(entities)
      entities.map { |entity| serializer.serialize_entity(entity) }
    end

    def limit_from(params, key, default)
      limit = (params[key] || default).to_i
      [limit, 1].max
    end

    def log(message)
      @logger&.call(message)
    end
  end
end
