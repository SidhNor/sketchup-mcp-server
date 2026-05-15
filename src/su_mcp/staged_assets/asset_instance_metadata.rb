# frozen_string_literal: true

require_relative 'asset_exemplar_metadata'

module SU_MCP
  module StagedAssets
    # Owns Asset Instance metadata written during staged-asset instantiation.
    class AssetInstanceMetadata
      SCHEMA_VERSION = 1
      EXEMPLAR_FIELDS = %w[
        assetExemplar
        assetExemplarSchemaVersion
        approvalState
        stagingMode
      ].freeze

      def prepare_instance(metadata:, source_attributes:)
        source_element_id = normalized_string(metadata_value(metadata, 'sourceElementId'))
        return missing_metadata_refusal if source_element_id.empty?

        {
          outcome: 'ready',
          attributes: instance_attributes(
            source_element_id: source_element_id,
            source_asset_element_id: source_attributes.fetch('sourceElementId')
          ),
          clear: EXEMPLAR_FIELDS
        }
      end

      def apply_prepared_instance(entity, prepared_instance)
        prepared_instance.fetch(:clear).each do |key|
          entity.delete_attribute(AssetExemplarMetadata::DICTIONARY, key)
        end
        prepared_instance.fetch(:attributes).each do |key, value|
          entity.set_attribute(AssetExemplarMetadata::DICTIONARY, key, value)
        end

        { outcome: 'applied' }
      end

      private

      def instance_attributes(source_element_id:, source_asset_element_id:)
        {
          'managedSceneObject' => true,
          'semanticType' => 'asset_instance',
          'assetRole' => 'instance',
          'assetInstanceSchemaVersion' => SCHEMA_VERSION,
          'sourceElementId' => source_element_id,
          'sourceAssetElementId' => source_asset_element_id
        }
      end

      def metadata_value(metadata, key)
        return nil unless metadata.is_a?(Hash)

        metadata[key] || metadata[key.to_sym]
      end

      def normalized_string(value)
        value.to_s.strip
      end

      def missing_metadata_refusal
        {
          outcome: 'refused',
          refusal: {
            code: 'missing_required_metadata',
            message: 'Created Asset Instance metadata.sourceElementId is required.',
            details: { field: 'metadata.sourceElementId' }
          }
        }
      end
    end
  end
end
