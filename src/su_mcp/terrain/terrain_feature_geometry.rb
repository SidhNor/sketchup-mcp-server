# frozen_string_literal: true

require 'digest'
require 'json'

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Backend-neutral MTA-23 feature geometry for validation-only output candidates.
    class TerrainFeatureGeometry
      COLLECTION_KEYS = %w[
        outputAnchorCandidates protectedRegions pressureRegions referenceSegments affectedWindows
        tolerances
      ].freeze
      OPTIONAL_KEYS = %w[failureCategory limitations].freeze
      SORT_KEYS = %w[id featureId role strength primitive source].freeze

      attr_reader :failure_category, :limitations

      def initialize(values = nil, **keywords)
        payload = FeatureIntentSet.stringify_keys((values || {}).merge(keywords))
        unknown = payload.keys - COLLECTION_KEYS - OPTIONAL_KEYS
        if unknown.any?
          raise ArgumentError,
                "Unknown terrain feature geometry field: #{unknown.first}"
        end

        COLLECTION_KEYS.each do |key|
          instance_variable_set("@#{snake_key(key)}", normalize_array(payload.fetch(key, [])))
        end
        @failure_category = payload.fetch('failureCategory', 'none')
        @limitations = normalize_array(payload.fetch('limitations', []))
        assert_json_safe!(primitive_payload)
      end

      def to_h
        primitive_payload.merge(
          'featureGeometryDigest' => feature_geometry_digest,
          'referenceGeometryDigest' => reference_geometry_digest
        )
      end

      def feature_geometry_digest
        Digest::SHA256.hexdigest(FeatureIntentSet.canonical_json(primitive_payload))
      end

      def reference_geometry_digest
        Digest::SHA256.hexdigest(
          FeatureIntentSet.canonical_json('referenceSegments' => reference_segments)
        )
      end

      def self.snake_key(value)
        value.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      def self.sort_key_for(item)
        return item unless item.is_a?(Hash)

        SORT_KEYS.map { |key| item[key] || '' } + [FeatureIntentSet.canonical_json(item)]
      end

      COLLECTION_KEYS.each do |key|
        define_method(snake_key(key)) do
          instance_variable_get("@#{snake_key(key)}")
        end
      end

      private_class_method :snake_key

      private

      def snake_key(value)
        self.class.send(:snake_key, value)
      end

      def primitive_payload
        COLLECTION_KEYS.to_h { |key| [key, public_send(snake_key(key))] }
      end

      def normalize_array(value)
        normalized = Array(value).map do |item|
          normalize_value(item)
        end
        normalized.sort_by { |item| self.class.sort_key_for(item) }
      end

      def normalize_value(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), memo|
            memo[key.to_s] = normalize_value(nested)
          end
        when Array
          value.map { |nested| normalize_value(nested) }
        when Numeric
          unless value.finite?
            raise ArgumentError,
                  'terrain feature geometry numeric values must be finite'
          end

          value
        else
          value
        end
      end

      def assert_json_safe!(value)
        JSON.parse(JSON.generate(value))
      rescue JSON::GeneratorError, TypeError
        raise ArgumentError, 'terrain feature geometry must be JSON-safe'
      end
    end
  end
end
