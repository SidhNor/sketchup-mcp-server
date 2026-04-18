# frozen_string_literal: true

module SU_MCP
  # Ruby-owned query validation and exact-match filtering for entity targeting.
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  class TargetingQuery
    SECTION_KEYS = %w[identity attributes metadata].freeze
    IDENTITY_KEYS = %w[sourceElementId persistentId entityId].freeze
    ATTRIBUTE_KEYS = %w[name tag material].freeze
    METADATA_KEYS = %w[managedSceneObject semanticType status state structureCategory].freeze

    def initialize(serializer:)
      @serializer = serializer
    end

    def normalized_target_selector(raw_target_selector)
      raise 'targetSelector is required' unless raw_target_selector.is_a?(Hash)

      unsupported_sections = raw_target_selector.keys.map(&:to_s) - SECTION_KEYS
      unless unsupported_sections.empty?
        raise "Unsupported targetSelector section: #{unsupported_sections.first}"
      end

      selector = {}
      selector['identity'] = normalized_section(
        raw_target_selector['identity'] || raw_target_selector[:identity],
        supported_keys: IDENTITY_KEYS,
        section_name: 'identity'
      )
      selector['attributes'] = normalized_section(
        raw_target_selector['attributes'] || raw_target_selector[:attributes],
        supported_keys: ATTRIBUTE_KEYS,
        section_name: 'attributes'
      )
      selector['metadata'] = normalized_metadata_section(
        raw_target_selector['metadata'] || raw_target_selector[:metadata]
      )

      selector.compact!
      raise 'At least one targetSelector criterion is required' if selector.empty?

      selector
    end

    def filter(entities, target_selector)
      entities.select do |entity|
        matches_identity?(entity, target_selector['identity']) &&
          matches_attributes?(entity, target_selector['attributes']) &&
          matches_metadata?(entity, target_selector['metadata'])
      end
    end

    def resolution_for(matches)
      return 'none' if matches.empty?
      return 'unique' if matches.length == 1

      'ambiguous'
    end

    private

    attr_reader :serializer

    def normalized_section(raw_section, supported_keys:, section_name:)
      return nil if raw_section.nil?
      raise "targetSelector.#{section_name} must be an object" unless raw_section.is_a?(Hash)

      unsupported_keys = raw_section.keys.map(&:to_s) - supported_keys
      unless unsupported_keys.empty?
        raise "Unsupported targetSelector.#{section_name} field: #{unsupported_keys.first}"
      end

      normalized = {}
      raw_section.each do |key, value|
        next if value.nil?

        string_value = value.to_s.strip
        next if string_value.empty?

        normalized[key.to_s] = string_value
      end
      normalized.empty? ? nil : normalized
    end

    def normalized_metadata_section(raw_section)
      return nil if raw_section.nil?
      raise 'targetSelector.metadata must be an object' unless raw_section.is_a?(Hash)

      unsupported_keys = raw_section.keys.map(&:to_s) - METADATA_KEYS
      unless unsupported_keys.empty?
        raise "Unsupported targetSelector.metadata field: #{unsupported_keys.first}"
      end

      normalized = {}
      raw_section.each do |key, value|
        normalized_key = key.to_s
        next if value.nil?

        normalized[normalized_key] =
          if normalized_key == 'managedSceneObject'
            value == true
          else
            string_value = value.to_s.strip
            next if string_value.empty?

            string_value
          end
      end
      normalized.empty? ? nil : normalized
    end

    def matches_identity?(entity, identity_selector)
      return true unless identity_selector

      summary = serializer.serialize_target_match(entity)
      identity_selector.all? { |key, value| summary[key.to_sym] == value }
    end

    def matches_attributes?(entity, attributes_selector)
      return true unless attributes_selector

      summary = serializer.serialize_target_match(entity)
      attributes_selector.all? { |key, value| summary[key.to_sym] == value }
    end

    def matches_metadata?(entity, metadata_selector)
      return true unless metadata_selector

      metadata_summary = serializer.serialize_target_metadata(entity)
      metadata_selector.all? { |key, value| metadata_summary[key.to_sym] == value }
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity
end
