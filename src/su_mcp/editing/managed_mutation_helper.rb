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
          id: entity.entityID,
          managedObject: managed_object?(entity) ? serializer.serialize(entity) : nil
        }
      end

      private

      attr_reader :metadata, :serializer

      def managed_object?(entity)
        metadata.managed_object?(entity)
      end
    end
  end
end
