# frozen_string_literal: true

require_relative '../scene_query/scene_query_serializer'
require_relative 'asset_exemplar_serializer'

module SU_MCP
  module StagedAssets
    # Serializes created Asset Instances and source lineage evidence.
    class AssetInstanceSerializer
      def initialize(
        scene_serializer: SceneQuerySerializer.new,
        source_serializer: AssetExemplarSerializer.new(scene_serializer: scene_serializer)
      )
        @scene_serializer = scene_serializer
        @source_serializer = source_serializer
      end

      def serialize(instance, source_entity:, placement:, include_bounds: true)
        result = {
          instance: instance_summary(instance),
          sourceAsset: source_serializer.serialize(source_entity, include_bounds: false),
          lineage: lineage_summary(instance),
          placement: placement_summary(placement)
        }
        result[:bounds] = scene_serializer.bounds_to_h(instance.bounds) if include_bounds
        result.compact
      end

      private

      attr_reader :scene_serializer, :source_serializer

      def instance_summary(instance)
        summary = scene_serializer.serialize_target_match(instance)
        {
          sourceElementId: summary[:sourceElementId],
          persistentId: summary[:persistentId],
          entityId: summary[:entityId],
          type: summary[:type],
          semanticType: attribute_value(instance, 'semanticType'),
          assetRole: attribute_value(instance, 'assetRole')
        }.compact
      end

      def lineage_summary(instance)
        {
          sourceAssetElementId: attribute_value(instance, 'sourceAssetElementId')
        }.compact
      end

      def placement_summary(placement)
        {
          position: placement.fetch(:position),
          scale: placement.fetch(:scale)
        }
      end

      def attribute_value(entity, key)
        value = entity.get_attribute('su_mcp', key)
        return nil if value.to_s.empty?

        value
      end
    end
  end
end
