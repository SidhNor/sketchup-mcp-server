# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../scene_query_serializer'
require_relative '../targeting_query'

module SU_MCP
  module Semantic
    # Resolves compact target references to one entity without exposing query semantics publicly.
    class TargetResolver
      TARGET_REFERENCE_KEYS = %w[sourceElementId persistentId entityId].freeze

      def initialize(
        adapter: Adapters::ModelAdapter.new,
        serializer: SceneQuerySerializer.new,
        targeting_query: nil
      )
        @adapter = adapter
        @targeting_query = targeting_query || TargetingQuery.new(serializer: serializer)
      end

      def resolve(raw_target)
        query = normalized_target(raw_target)
        matches = targeting_query.filter(adapter.all_entities_recursive, query)
        resolution = targeting_query.resolution_for(matches)

        result = { resolution: resolution }
        result[:entity] = matches.first if resolution == 'unique'
        result
      end

      private

      attr_reader :adapter, :targeting_query

      def normalized_target(raw_target)
        query = targeting_query.normalized_query(raw_target)
        unsupported_keys = query.keys - TARGET_REFERENCE_KEYS
        return query if unsupported_keys.empty?

        raise "Unsupported target reference criterion: #{unsupported_keys.first}"
      end
    end
  end
end
