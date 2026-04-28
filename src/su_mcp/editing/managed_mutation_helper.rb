# frozen_string_literal: true

require_relative '../semantic/managed_object_metadata'
require_relative '../semantic/serializer'

module SU_MCP
  module Editing
    # Keeps managed-object detection and semantic result shaping
    # out of the generic editing entrypoints.
    class ManagedMutationHelper
      def initialize(
        metadata: Semantic::ManagedObjectMetadata.new,
        serializer: Semantic::Serializer.new
      )
        @metadata = metadata
        @serializer = serializer
      end

      def success_payload(entity)
        {
          entityId: entity.entityID.to_s,
          persistentId: persistent_id_for(entity),
          managedObject: managed_object?(entity) ? serializer.serialize(entity) : nil
        }.compact
      end

      private

      attr_reader :metadata, :serializer

      def managed_object?(entity)
        metadata.managed_object?(entity)
      end

      def persistent_id_for(entity)
        return nil unless entity.respond_to?(:persistent_id)

        entity.method(:persistent_id).call.to_s
      end
    end
  end
end
