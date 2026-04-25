# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Payload-oriented attribute storage for terrain state.
    class AttributeTerrainStorage
      DICTIONARY = 'su_mcp_terrain'
      PAYLOAD_KEY = 'statePayload'
      MAX_SERIALIZED_BYTES = 8 * 1024 * 1024

      def initialize(max_serialized_bytes: MAX_SERIALIZED_BYTES)
        @max_serialized_bytes = max_serialized_bytes
      end

      def load_payload(owner)
        return nil unless owner.respond_to?(:get_attribute)

        owner.get_attribute(DICTIONARY, PAYLOAD_KEY)
      end

      def save_payload(owner, payload_string)
        serialized_bytes = payload_string.bytesize
        if serialized_bytes > max_serialized_bytes
          return payload_too_large_refusal(serialized_bytes)
        end

        owner.set_attribute(DICTIONARY, PAYLOAD_KEY, payload_string)
        {
          outcome: 'saved',
          serialized_bytes: serialized_bytes
        }
      rescue StandardError => e
        refusal(
          code: 'write_failed',
          message: 'Terrain state payload could not be written.',
          details: { error: e.message }
        )
      end

      def delete_payload(owner)
        return nil unless owner.respond_to?(:delete_attribute)

        owner.delete_attribute(DICTIONARY, PAYLOAD_KEY)
      end

      def owner_transform_signature(owner)
        return owner.transform_signature if owner.respond_to?(:transform_signature)
        return nil unless owner.respond_to?(:transformation)

        stable_transformation_signature(owner.transformation)
      end

      private

      attr_reader :max_serialized_bytes

      def stable_transformation_signature(transformation)
        return nil unless transformation.respond_to?(:to_a)

        values = transformation.to_a
        return nil unless values.respond_to?(:map)

        "matrix:#{values.map { |value| format('%.12g', value.to_f) }.join(',')}"
      rescue StandardError
        nil
      end

      def payload_too_large_refusal(serialized_bytes)
        refusal(
          code: 'payload_too_large',
          message: 'Terrain state payload exceeds the configured storage limit.',
          details: {
            serializedBytes: serialized_bytes,
            maxSerializedBytes: max_serialized_bytes
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
