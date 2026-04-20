# frozen_string_literal: true

require_relative '../scene_query/scene_query_serializer'
require_relative 'managed_object_metadata'

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
        case entity
        when Sketchup::Group
          count_non_placeholder_children(entity.entities)
        when Sketchup::ComponentInstance
          count_non_placeholder_children(entity.definition.entities)
        else
          0
        end
      end

      def count_non_placeholder_children(collection)
        ManagedObjectMetadata
          .collection_entities(collection)
          .count { |entity| !ManagedObjectMetadata.placeholder_entity?(entity) }
      end
    end
  end
end
