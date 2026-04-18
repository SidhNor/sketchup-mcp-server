# frozen_string_literal: true

require_relative 'target_reference_resolver'

module SU_MCP
  # Resolves explicit scene inventory scopes into entity collections.
  class ScopeResolver
    SUPPORTED_SCOPE_MODES = %w[top_level selection children_of_target].freeze
    SUPPORTED_SCOPE_SELECTOR_KEYS = %w[mode targetReference].freeze
    SUPPORTED_OUTPUT_OPTIONS_KEYS = %w[limit includeHidden].freeze

    def initialize(adapter:, target_resolver: nil)
      @adapter = adapter
      @target_resolver = target_resolver || TargetReferenceResolver.new(adapter: adapter)
    end

    # rubocop:disable Metrics/MethodLength
    def resolve(scope_selector:, output_options: nil)
      selector = normalized_scope_selector(scope_selector)
      include_hidden = include_hidden?(output_options)
      entities = case selector.fetch('mode')
                 when 'top_level'
                   adapter.top_level_entities(include_hidden: include_hidden)
                 when 'selection'
                   filtered_entities(adapter.selected_entities, include_hidden: include_hidden)
                 when 'children_of_target'
                   resolve_children_scope(
                     selector.fetch('targetReference'),
                     include_hidden: include_hidden
                   )
                 end

      {
        entities: entities,
        limit: limit_from(output_options)
      }
    end
    # rubocop:enable Metrics/MethodLength

    private

    attr_reader :adapter, :target_resolver

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
    def normalized_scope_selector(raw_scope_selector)
      raise 'scopeSelector is required' unless raw_scope_selector.is_a?(Hash)

      unsupported_keys = raw_scope_selector.keys.map(&:to_s) - SUPPORTED_SCOPE_SELECTOR_KEYS
      unless unsupported_keys.empty?
        raise "Unsupported scopeSelector field: #{unsupported_keys.first}"
      end

      mode = raw_scope_selector['mode'] || raw_scope_selector[:mode]
      mode = mode.to_s.strip
      raise 'scopeSelector.mode is required' if mode.empty?
      raise "Unsupported scopeSelector.mode: #{mode}" unless SUPPORTED_SCOPE_MODES.include?(mode)

      selector = { 'mode' => mode }
      if mode == 'children_of_target'
        target_reference = raw_scope_selector['targetReference'] ||
                           raw_scope_selector[:targetReference]
        unless target_reference.is_a?(Hash)
          raise 'scopeSelector.targetReference is required when mode is children_of_target'
        end

        selector['targetReference'] = target_reference
      end
      selector
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

    def filtered_entities(entities, include_hidden:)
      return Array(entities) if include_hidden

      Array(entities).reject { |entity| entity.respond_to?(:hidden?) && entity.hidden? }
    end

    def resolve_children_scope(target_reference, include_hidden:)
      resolution = target_resolver.resolve(target_reference)
      if resolution[:resolution] == 'none'
        raise 'scopeSelector.targetReference resolves to no entity'
      end
      if resolution[:resolution] == 'ambiguous'
        raise 'scopeSelector.targetReference resolves ambiguously'
      end

      filtered_entities(
        child_entities_for(resolution.fetch(:entity)),
        include_hidden: include_hidden
      )
    end

    def child_entities_for(entity)
      if entity.is_a?(Sketchup::Group)
        Array(entity.entities)
      elsif entity.is_a?(Sketchup::ComponentInstance)
        Array(entity.definition.entities)
      else
        raise 'scopeSelector.targetReference must resolve to a group or component instance'
      end
    end

    def include_hidden?(raw_output_options)
      output_options = normalize_output_options(raw_output_options)
      output_options['includeHidden'] == true
    end

    def limit_from(raw_output_options)
      output_options = normalize_output_options(raw_output_options)
      limit = (output_options['limit'] || 100).to_i
      [limit, 1].max
    end

    def normalize_output_options(raw_output_options)
      return {} if raw_output_options.nil?
      raise 'outputOptions must be an object' unless raw_output_options.is_a?(Hash)

      unsupported_keys = raw_output_options.keys.map(&:to_s) - SUPPORTED_OUTPUT_OPTIONS_KEYS
      unless unsupported_keys.empty?
        raise "Unsupported outputOptions field: #{unsupported_keys.first}"
      end

      raw_output_options.each_with_object({}) do |(key, value), normalized|
        normalized[key.to_s] = value
      end
    end
  end
end
