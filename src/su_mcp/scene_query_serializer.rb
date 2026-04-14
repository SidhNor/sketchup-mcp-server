# frozen_string_literal: true

module SU_MCP
  SCENE_QUERY_TYPE_KEYS = {
    Sketchup::ComponentInstance => 'componentinstance',
    Sketchup::Group => 'group',
    Sketchup::Face => 'face',
    Sketchup::Edge => 'edge',
    Sketchup::Vertex => 'vertex',
    Sketchup::Text => 'text',
    Sketchup::Dimension => 'dimension'
  }.freeze

  # Normalizes SketchUp entities and bounds into bridge-safe hashes.
  # rubocop:disable Metrics/ClassLength
  class SceneQuerySerializer
    def bounds_to_h(bounds)
      return nil unless bounds&.valid?

      {
        min: point_to_a(bounds.min),
        max: point_to_a(bounds.max),
        center: point_to_a(bounds.center),
        size: [safe_float(bounds.width), safe_float(bounds.height), safe_float(bounds.depth)]
      }
    end

    def serialize_entity(entity)
      data = base_entity_data(entity)
      data.merge!(instance_details(entity)) if group_or_component?(entity)
      data.compact
    end

    def entity_type_counts(entities)
      entities.each_with_object(Hash.new(0)) do |entity, counts|
        counts[entity_type_key(entity)] += 1
      end
    end

    def entity_type_key(entity)
      SCENE_QUERY_TYPE_KEYS.each do |klass, key|
        return key if entity.is_a?(klass)
      end

      entity.class.name.split('::').last.downcase
    end

    private

    def base_entity_data(entity)
      {
        id: entity.entityID,
        persistent_id: persistent_id_for(entity),
        type: entity_type_key(entity),
        name: entity_name(entity),
        layer: layer_name(entity), material: material_name_for(entity),
        hidden: value_if_supported(entity, :hidden?),
        locked: value_if_supported(entity, :locked?),
        bounds: bounds_to_h(entity.bounds)
      }
    end

    def safe_float(value)
      return value unless value.respond_to?(:to_f)

      rounded_float(value.to_f)
    end

    def point_to_a(point)
      return nil unless point

      [safe_float(point.x), safe_float(point.y), safe_float(point.z)]
    end

    def rounded_float(value)
      precision = configured_length_precision
      return value unless precision

      value.round(precision)
    end

    def configured_length_precision
      model = Sketchup.active_model
      return nil unless model.respond_to?(:options)

      units = model.options['UnitsOptions']
      return nil unless units

      precision = units['LengthPrecision']
      precision.is_a?(Numeric) ? precision.to_i : nil
    rescue StandardError
      nil
    end

    def entity_name(entity)
      name = entity.respond_to?(:name) ? entity.name.to_s : ''
      return name unless name.empty?

      return component_definition_name(entity) if entity.is_a?(Sketchup::ComponentInstance)

      entity_type_label(entity)
    end

    def component_definition_name(entity)
      definition_name = entity.definition&.name.to_s
      definition_name.empty? ? entity_type_label(entity) : definition_name
    end

    def layer_name(entity)
      entity.respond_to?(:layer) && entity.layer ? entity.layer.name : nil
    end

    def material_name_for(entity)
      return nil unless entity.respond_to?(:material)

      material = entity.material
      return nil unless material
      return material.display_name if material.respond_to?(:display_name)
      return material.name if material.respond_to?(:name)

      material.to_s
    end

    def value_if_supported(entity, method_name)
      entity.respond_to?(method_name) ? entity.public_send(method_name) : nil
    end

    def instance_details(entity)
      details = {
        definition_name: component_instance_definition_name(entity),
        children_count: entity_children_count(entity)
      }
      if entity.respond_to?(:transformation)
        details[:origin] = point_to_a(entity.transformation.origin)
      end
      details
    end

    def component_instance_definition_name(entity)
      entity.is_a?(Sketchup::ComponentInstance) ? entity.definition&.name : nil
    end

    def entity_children_count(entity)
      return entity.entities.length if entity.is_a?(Sketchup::Group)
      return entity.definition.entities.length if entity.is_a?(Sketchup::ComponentInstance)

      0
    end

    def entity_type_label(entity)
      entity_type_key(entity).capitalize
    end

    def persistent_id_for(entity)
      return nil unless entity.respond_to?(:persistent_id)

      # rubocop:disable SketchupSuggestions/Compatibility
      entity.persistent_id
      # rubocop:enable SketchupSuggestions/Compatibility
    end

    def group_or_component?(entity)
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
