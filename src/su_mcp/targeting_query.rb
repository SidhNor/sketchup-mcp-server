# frozen_string_literal: true

module SU_MCP
  # Ruby-owned query validation and exact-match filtering for entity targeting.
  class TargetingQuery
    SUPPORTED_KEYS = %w[sourceElementId persistentId entityId name tag material].freeze

    def initialize(serializer:)
      @serializer = serializer
    end

    def normalized_query(raw_query)
      query = normalize_values(raw_query)
      raise 'At least one query criterion is required' if query.empty?

      unsupported_keys = query.keys - SUPPORTED_KEYS
      return query if unsupported_keys.empty?

      raise "Unsupported query criterion: #{unsupported_keys.first}"
    end

    def filter(entities, query)
      entities.select do |entity|
        summary = @serializer.serialize_target_match(entity)
        query.all? { |key, value| summary[key.to_sym] == value }
      end
    end

    def resolution_for(matches)
      return 'none' if matches.empty?
      return 'unique' if matches.length == 1

      'ambiguous'
    end

    private

    def normalize_values(raw_query)
      (raw_query || {}).each_with_object({}) do |(key, value), normalized|
        next if value.nil?

        string_value = value.to_s.strip
        next if string_value.empty?

        normalized[key.to_s] = string_value
      end
    end
  end
end
