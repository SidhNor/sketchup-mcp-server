# frozen_string_literal: true

require_relative 'attribute_terrain_storage'
require_relative 'terrain_state_serializer'

module SU_MCP
  module Terrain
    # Domain-facing repository seam for loading and saving terrain state payloads.
    class TerrainRepository
      attr_reader :storage, :serializer

      def initialize(storage: AttributeTerrainStorage.new, serializer: TerrainStateSerializer.new)
        @storage = storage
        @serializer = serializer
      end

      def save(owner, state)
        serialized_result = serializer.serialize_with_summary(state)
        serialized = serialized_result.fetch(:payload)
        result = storage.save_payload(owner, serialized)
        return result if result.fetch(:outcome) == 'refused'

        {
          outcome: 'saved',
          state: state,
          summary: serialized_result.fetch(:summary).merge(serializedBytes: serialized.bytesize)
        }
      end

      def load(owner)
        payload_string = storage.load_payload(owner)
        return missing_state if payload_string.nil?

        result = serializer.deserialize(payload_string)
        return result if result.fetch(:outcome) == 'refused'

        state = result.fetch(:state)
        transform_refusal = validate_owner_transform(owner, state)
        return transform_refusal if transform_refusal

        result.merge(
          summary: result.fetch(:summary).merge(serializedBytes: payload_string.bytesize)
        )
      end

      def delete(owner)
        storage.delete_payload(owner)
        { outcome: 'deleted' }
      end

      private

      def missing_state
        {
          outcome: 'absent',
          reason: 'missing_state',
          recoverable: true
        }
      end

      def validate_owner_transform(owner, state)
        stored = state.owner_transform_signature
        current = storage.owner_transform_signature(owner)
        return nil if stored.nil? || current.nil? || stored == current

        refusal(
          code: 'owner_transform_unsupported',
          message: 'Terrain owner transform no longer matches stored owner-local state.',
          details: {
            storedOwnerTransformSignature: stored,
            currentOwnerTransformSignature: current
          }
        )
      end

      def refusal(code:, message:, details: nil)
        refusal_payload = {
          code: code,
          message: message
        }
        refusal_payload[:details] = details if details

        {
          outcome: 'refused',
          recoverable: false,
          refusal: refusal_payload
        }
      end
    end
  end
end
