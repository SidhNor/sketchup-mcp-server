# frozen_string_literal: true

require_relative '../scene_query/scene_query_serializer'
require_relative 'asset_exemplar_metadata'

module SU_MCP
  module StagedAssets
    # Serializes approved Asset Exemplars into JSON-safe public summaries.
    class AssetExemplarSerializer
      def initialize(metadata: AssetExemplarMetadata.new,
                     scene_serializer: SceneQuerySerializer.new)
        @metadata = metadata
        @scene_serializer = scene_serializer
      end

      def serialize(entity, include_bounds: true)
        attributes = metadata.attributes_for(entity)
        summary = scene_serializer.serialize_target_match(entity)
        serialized = asset_summary(attributes, summary)
        serialized[:bounds] = scene_serializer.bounds_to_h(entity.bounds) if include_bounds
        serialized.compact
      end

      private

      attr_reader :metadata, :scene_serializer

      def asset_summary(attributes, summary)
        {
          sourceElementId: attributes.fetch('sourceElementId'),
          persistentId: summary[:persistentId],
          entityId: summary[:entityId],
          type: summary[:type],
          displayName: attributes.fetch('assetDisplayName'),
          category: attributes.fetch('assetCategory'),
          approvalState: attributes.fetch('approvalState'),
          tags: Array(attributes.fetch('assetTags')),
          metadata: metadata_summary(attributes)
        }
      end

      def metadata_summary(attributes)
        {
          assetRole: attributes.fetch('assetRole'),
          stagingMode: attributes.fetch('stagingMode'),
          schemaVersion: attributes.fetch('assetExemplarSchemaVersion'),
          attributes: attributes.fetch('assetAttributes', {})
        }
      end
    end
  end
end
