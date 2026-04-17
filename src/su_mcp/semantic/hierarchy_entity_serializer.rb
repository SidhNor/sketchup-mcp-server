# frozen_string_literal: true

require_relative '../scene_query/scene_query_serializer'

module SU_MCP
  module Semantic
    # Serializes hierarchy-maintenance entities into a JSON-safe summary.
    class HierarchyEntitySerializer
      def initialize(scene_query_serializer: SceneQuerySerializer.new)
        @scene_query_serializer = scene_query_serializer
      end

      def serialize(entity)
        scene_query_serializer
          .serialize_target_match(entity)
          .merge(childrenCount: children_count(entity))
      end

      private

      attr_reader :scene_query_serializer

      def children_count(entity)
        return entity.entities.length if entity.is_a?(Sketchup::Group)
        return entity.definition.entities.length if entity.is_a?(Sketchup::ComponentInstance)

        0
      end
    end
  end
end
