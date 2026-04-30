# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative 'scene_query_serializer'
require_relative 'targeting_query'

module SU_MCP
  # Shared direct-reference resolver extracted under targeting ownership.
  class TargetReferenceResolver
    TARGET_REFERENCE_KEYS = %w[sourceElementId persistentId entityId].freeze

    # Field-aware direct-reference validation failure for command-level refusal mapping.
    class InvalidReference < RuntimeError
      attr_reader :code, :details

      def initialize(code:, message:, details: {})
        @code = code
        @details = details
        super(message)
      end
    end

    def initialize(
      adapter: Adapters::ModelAdapter.new,
      serializer: SceneQuerySerializer.new,
      targeting_query: nil
    )
      @adapter = adapter
      @serializer = serializer
      @targeting_query = targeting_query || TargetingQuery.new(serializer: serializer)
    end

    def resolve(raw_target_reference = nil, field: 'targetReference', **raw_keywords)
      target_reference_input = raw_keywords.empty? ? raw_target_reference : raw_keywords
      target_reference = normalized_target_reference(target_reference_input, field: field)
      matches = lookup_matches(target_reference)

      resolution = targeting_query.resolution_for(matches)
      result = { resolution: resolution }
      result[:entity] = matches.first if resolution == 'unique'
      result
    end

    private

    attr_reader :adapter, :serializer, :targeting_query

    def normalized_target_reference(raw_target_reference, field:)
      target_reference = normalize_values(raw_target_reference)
      if target_reference.empty?
        raise InvalidReference.new(
          code: 'missing_target',
          message: 'Target reference with at least one identifier is required.',
          details: { field: field, allowedFields: TARGET_REFERENCE_KEYS }
        )
      end

      unsupported_keys = target_reference.keys - TARGET_REFERENCE_KEYS
      return target_reference if unsupported_keys.empty?

      unsupported_key = unsupported_keys.first
      raise InvalidReference.new(
        code: 'unsupported_request_field',
        message: "Unsupported target reference criterion: #{unsupported_key}",
        details: {
          field: "#{field}.#{unsupported_key}",
          value: target_reference.fetch(unsupported_key),
          allowedFields: TARGET_REFERENCE_KEYS
        }
      )
    end

    def normalize_values(raw_hash)
      (raw_hash || {}).each_with_object({}) do |(key, value), normalized|
        next if value.nil?

        string_value = value.to_s.strip
        next if string_value.empty?

        normalized[key.to_s] = string_value
      end
    end

    def lookup_matches(target_reference)
      # Native SketchUp identifiers should use model-owned lookup instead of full scene traversal.
      if target_reference.keys == ['entityId'] && adapter.respond_to?(:find_entity_by_id)
        return [adapter.find_entity_by_id(target_reference.fetch('entityId'))].compact
      end

      if target_reference.keys == ['persistentId'] &&
         adapter.respond_to?(:find_entity_by_persistent_id)
        entity = adapter.method(:find_entity_by_persistent_id)
                        .call(target_reference.fetch('persistentId'))
        return [entity].compact
      end

      adapter.all_entities_recursive.select do |entity|
        target_reference_matches?(entity, target_reference)
      end
    end

    def target_reference_matches?(entity, target_reference)
      summary = serializer.serialize_target_match(entity)
      target_reference.all? { |key, value| summary[key.to_sym] == value }
    end
  end
end
