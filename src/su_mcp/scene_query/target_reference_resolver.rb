# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative 'scene_query_serializer'
require_relative 'targeting_query'

module SU_MCP
  # Shared direct-reference resolver extracted under targeting ownership.
  class TargetReferenceResolver
    TARGET_REFERENCE_KEYS = %w[sourceElementId persistentId entityId].freeze

    def initialize(
      adapter: Adapters::ModelAdapter.new,
      serializer: SceneQuerySerializer.new,
      targeting_query: nil
    )
      @adapter = adapter
      @serializer = serializer
      @targeting_query = targeting_query || TargetingQuery.new(serializer: serializer)
    end

    def resolve(raw_target_reference)
      target_reference = normalized_target_reference(raw_target_reference)
      matches = adapter.all_entities_recursive.select do |entity|
        target_reference_matches?(entity, target_reference)
      end

      resolution = targeting_query.resolution_for(matches)
      result = { resolution: resolution }
      result[:entity] = matches.first if resolution == 'unique'
      result
    end

    private

    attr_reader :adapter, :serializer, :targeting_query

    def normalized_target_reference(raw_target_reference)
      target_reference = normalize_values(raw_target_reference)
      raise 'Target reference with at least one identifier is required' if target_reference.empty?

      unsupported_keys = target_reference.keys - TARGET_REFERENCE_KEYS
      return target_reference if unsupported_keys.empty?

      raise "Unsupported target reference criterion: #{unsupported_keys.first}"
    end

    def normalize_values(raw_hash)
      (raw_hash || {}).each_with_object({}) do |(key, value), normalized|
        next if value.nil?

        string_value = value.to_s.strip
        next if string_value.empty?

        normalized[key.to_s] = string_value
      end
    end

    def target_reference_matches?(entity, target_reference)
      summary = serializer.serialize_target_match(entity)
      target_reference.all? { |key, value| summary[key.to_sym] == value }
    end
  end
end
