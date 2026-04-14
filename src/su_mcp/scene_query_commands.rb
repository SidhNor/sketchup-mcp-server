# frozen_string_literal: true

require_relative 'scene_query_serializer'

module SU_MCP
  # Read-oriented SketchUp command behavior and entity serialization helpers.
  class SceneQueryCommands
    def initialize(logger: nil)
      @logger = logger
      @serializer = SceneQuerySerializer.new
    end

    def list_resources
      model = Sketchup.active_model
      return [] unless model

      top_level_entities(model).map do |entity|
        {
          id: entity.entityID,
          type: serializer.entity_type_key(entity)
        }
      end
    end

    def get_scene_info(params = {})
      model = active_model!
      entities = top_level_entities(model)

      {
        success: true,
        model: model_summary(model),
        counts: scene_counts(model, entities),
        bounds: serializer.bounds_to_h(model.bounds),
        entities: serialize_entities(entities.first(limit_from(params, 'entity_limit', 25)))
      }
    end

    def list_entities(params = {})
      model = active_model!
      entities = filtered_entities(
        top_level_entities(model),
        include_hidden: params['include_hidden'] == true
      )

      {
        success: true,
        count: entities.length,
        entities: serialize_entities(entities.first(limit_from(params, 'limit', 100)))
      }
    end

    def get_entity_info(params)
      {
        success: true,
        entity: serializer.serialize_entity(find_entity(params))
      }
    end

    def selection_info
      model = active_model!
      selection = model.selection

      log "Getting selection, count: #{selection.length}"

      selected_entities = serialize_entities(selection)
      { success: true, count: selected_entities.length, entities: selected_entities }
    end

    private

    attr_reader :serializer

    def active_model!
      model = Sketchup.active_model
      raise 'No active SketchUp model' unless model

      model
    end

    def find_entity(params)
      id_str = params['id'].to_s.delete('"')
      raise 'Entity id is required' if id_str.empty?

      entity = active_model!.find_entity_by_id(id_str.to_i)
      raise 'Entity not found' unless entity

      entity
    end

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

    def filtered_entities(entities, include_hidden:)
      return entities if include_hidden

      entities.reject do |entity|
        entity.respond_to?(:hidden?) && entity.hidden?
      end
    end

    def limit_from(params, key, default)
      limit = (params[key] || default).to_i
      [limit, 1].max
    end

    def log(message)
      @logger&.call(message)
    end

    # These bridge-facing read commands intentionally report top-level model content,
    # not the active edit context, to preserve the existing Python/Ruby contract.
    # rubocop:disable SketchupSuggestions/ModelEntities
    def top_level_entities(model)
      model.entities.to_a
    end
    # rubocop:enable SketchupSuggestions/ModelEntities
  end
end
