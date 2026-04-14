# frozen_string_literal: true

require_relative '../scene_query_serializer'
require_relative 'managed_object_metadata'

module SU_MCP
  module Semantic
    # Normalizes a SEM-01 Managed Scene Object into a JSON-safe payload.
    class Serializer
      def initialize(bounds_serializer: SceneQuerySerializer.new)
        @bounds_serializer = bounds_serializer
      end

      def serialize(entity)
        {
          **identity_attributes(entity),
          **presentation_attributes(entity),
          bounds: semantic_bounds(entity)
        }.compact
      end

      private

      def identity_attributes(entity)
        {
          sourceElementId: attribute(entity, 'sourceElementId'),
          persistentId: persistent_id_for(entity),
          entityId: stringify(entity.entityID),
          semanticType: attribute(entity, 'semanticType'),
          status: attribute(entity, 'status'),
          state: attribute(entity, 'state'),
          structureCategory: attribute(entity, 'structureCategory')
        }
      end

      def presentation_attributes(entity)
        {
          name: entity_name(entity),
          tag: layer_name(entity),
          material: material_name(entity)
        }
      end

      def attribute(entity, key)
        entity.get_attribute(ManagedObjectMetadata::DICTIONARY, key)
      end

      def stringify(value)
        value&.to_s
      end

      def persistent_id_for(entity)
        return nil unless entity.respond_to?(:persistent_id)

        # rubocop:disable SketchupSuggestions/Compatibility
        stringify(entity.persistent_id)
        # rubocop:enable SketchupSuggestions/Compatibility
      end

      def entity_name(entity)
        return nil unless entity.respond_to?(:name)

        name = entity.name.to_s
        name.empty? ? nil : name
      end

      def layer_name(entity)
        return nil unless entity.respond_to?(:layer) && entity.layer

        entity.layer.name
      end

      def material_name(entity)
        return nil unless entity.respond_to?(:material) && entity.material

        material = entity.material
        return material.display_name if material.respond_to?(:display_name)
        return material.name if material.respond_to?(:name)

        material.to_s
      end

      def semantic_bounds(entity)
        bounds = @bounds_serializer.bounds_to_h(entity.bounds)
        return nil unless bounds

        {
          min: bounds[:min],
          max: bounds[:max]
        }
      end
    end
  end
end
