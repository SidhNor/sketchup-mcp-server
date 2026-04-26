# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../runtime/tool_response'
require_relative 'asset_exemplar_metadata'
require_relative 'asset_exemplar_serializer'

module SU_MCP
  module StagedAssets
    # Finds approved Asset Exemplars in the active model.
    class AssetExemplarQuery
      DEFAULT_LIMIT = 25
      MAX_LIMIT = 100
      SUPPORTED_FILTER_KEYS = %w[category tags attributes approvalState].freeze

      def initialize(
        adapter: Adapters::ModelAdapter.new,
        metadata: AssetExemplarMetadata.new,
        serializer: AssetExemplarSerializer.new(metadata: metadata)
      )
        @adapter = adapter
        @metadata = metadata
        @serializer = serializer
      end

      def list(params = {})
        filters = normalize_filters(params['filters'])
        return filters if refusal_response?(filters)

        output_options = params['outputOptions'].is_a?(Hash) ? params['outputOptions'] : {}
        assets = filtered_exemplars(filters)
                 .first(limit_from(output_options))
                 .map { |entity| serialize_asset(entity, output_options) }

        ToolResponse.success(count: assets.length, assets: assets)
      end

      private

      attr_reader :adapter, :metadata, :serializer

      def exemplar_entities
        adapter.all_entity_paths_recursive.filter_map do |entry|
          entity = entry.fetch(:entity)
          next unless group_or_component?(entity)
          next if definition_child_path?(entry.fetch(:ancestors))
          next unless metadata.approved_exemplar?(entity)

          entity
        end
      end

      def normalize_filters(raw_filters)
        return {} if raw_filters.nil?
        unless valid_filter_object?(raw_filters)
          return invalid_filter_refusal('filters',
                                        raw_filters)
        end

        unsupported_key = unsupported_filter_key(raw_filters)
        return unsupported_filter_refusal(unsupported_key) if unsupported_key

        shape_refusal = filter_shape_refusal(raw_filters)
        return shape_refusal if shape_refusal

        approval_state = filter_value(raw_filters, 'approvalState') || 'approved'
        unless approved_state?(approval_state)
          return unsupported_approval_state_refusal(approval_state)
        end

        filter_hash(raw_filters, approval_state)
      end

      def filter_hash(raw_filters, approval_state)
        {
          'category' => filter_value(raw_filters, 'category'),
          'tags' => filter_value(raw_filters, 'tags'),
          'attributes' => filter_value(raw_filters, 'attributes'),
          'approvalState' => approval_state
        }.compact
      end

      def filtered_exemplars(filters)
        exemplar_entities.select { |entity| matches_filters?(entity, filters) }
      end

      def serialize_asset(entity, output_options)
        serializer.serialize(entity, include_bounds: include_bounds?(output_options))
      end

      def matches_filters?(entity, filters)
        attributes = metadata.attributes_for(entity)
        matches_category?(attributes, filters['category']) &&
          matches_tags?(attributes, filters['tags']) &&
          matches_asset_attributes?(attributes, filters['attributes'])
      end

      def matches_category?(attributes, category)
        return true if category.nil?

        attributes['assetCategory'] == category.to_s
      end

      def matches_tags?(attributes, tags)
        return true if tags.nil?
        return false unless tags.is_a?(Array)

        required_tags = tags.map(&:to_s)
        asset_tags = Array(attributes['assetTags']).map(&:to_s)
        (required_tags - asset_tags).empty?
      end

      def matches_asset_attributes?(attributes, requested_attributes)
        return true if requested_attributes.nil?
        return false unless requested_attributes.is_a?(Hash)

        asset_attributes = attributes['assetAttributes']
        return false unless asset_attributes.is_a?(Hash)

        requested_attributes.all? do |key, value|
          asset_attributes[key.to_s] == value
        end
      end

      def limit_from(output_options)
        limit = (output_options['limit'] || DEFAULT_LIMIT).to_i
        limit.clamp(1, MAX_LIMIT)
      end

      def include_bounds?(output_options)
        return true unless output_options.key?('includeBounds')

        output_options['includeBounds'] == true
      end

      def definition_child_path?(ancestors)
        ancestors.any?(Sketchup::ComponentInstance)
      end

      def group_or_component?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end

      def refusal_response?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end

      def unsupported_filter_refusal(field)
        ToolResponse.refusal(
          code: 'unsupported_filter',
          message: 'Unsupported staged asset filter.',
          details: { field: "filters.#{field}" }
        )
      end

      def invalid_filter_refusal(field, value)
        ToolResponse.refusal(
          code: 'invalid_filter',
          message: 'Staged asset filter has an invalid shape.',
          details: { field: field, value: value }
        )
      end

      def valid_filter_object?(value)
        value.is_a?(Hash)
      end

      def filter_shape_refusal(filters)
        return invalid_filter_refusal('filters.tags', filter_value(filters, 'tags')) \
          if filter_value(filters, 'tags') && !filter_value(filters, 'tags').is_a?(Array)

        return invalid_filter_refusal('filters.attributes', filter_value(filters, 'attributes')) \
          if filter_value(filters, 'attributes') && !filter_value(filters, 'attributes').is_a?(Hash)

        nil
      end

      def unsupported_filter_key(filters)
        filters.keys.map(&:to_s).find { |key| !SUPPORTED_FILTER_KEYS.include?(key) }
      end

      def filter_value(filters, key)
        filters[key] || filters[key.to_sym]
      end

      def approved_state?(approval_state)
        AssetExemplarMetadata::SUPPORTED_APPROVAL_STATES.include?(approval_state)
      end

      def unsupported_approval_state_refusal(value)
        ToolResponse.refusal(
          code: 'unsupported_approval_state',
          message: 'Only approved Asset Exemplars are discoverable in SAR-01.',
          details: {
            field: 'filters.approvalState',
            value: value,
            allowedValues: AssetExemplarMetadata::SUPPORTED_APPROVAL_STATES
          }
        )
      end
    end
  end
end
