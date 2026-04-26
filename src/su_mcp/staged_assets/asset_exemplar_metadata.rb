# frozen_string_literal: true

module SU_MCP
  module StagedAssets
    # Owns the Asset Exemplar metadata contract for staged-asset reuse.
    # rubocop:disable Metrics/ClassLength
    class AssetExemplarMetadata
      DICTIONARY = 'su_mcp'
      SCHEMA_VERSION = 1
      SUPPORTED_APPROVAL_STATES = %w[approved].freeze
      SUPPORTED_STAGING_MODES = %w[metadata_only].freeze
      REQUIRED_ATTRIBUTE_KEYS = %w[
        assetExemplar
        assetExemplarSchemaVersion
        assetRole
        approvalState
        sourceElementId
        assetCategory
        assetDisplayName
        assetTags
        assetAttributes
        stagingMode
      ].freeze

      def approved_exemplar?(entity)
        attributes = attributes_for(entity)
        return false unless REQUIRED_ATTRIBUTE_KEYS.all? { |key| present?(attributes[key]) }

        attributes['assetExemplar'] == true &&
          attributes['assetExemplarSchemaVersion'] == SCHEMA_VERSION &&
          attributes['assetRole'] == 'exemplar' &&
          attributes['approvalState'] == 'approved' &&
          attributes['stagingMode'] == 'metadata_only'
      end

      def attributes_for(entity)
        return entity.attributes.fetch(DICTIONARY, {}).dup if entity.respond_to?(:attributes)

        if entity.respond_to?(:attribute_dictionary)
          dictionary = entity.attribute_dictionary(DICTIONARY,
                                                   false)
        end
        return {} unless dictionary

        {}.tap do |attributes|
          dictionary.each_pair { |key, value| attributes[key.to_s] = value }
        end
      end

      def prepare_curation(_entity, metadata:, approval:, staging:)
        normalized_metadata = normalize_hash(metadata)
        approval_state = normalize_string(approval_value(approval))
        staging_mode = normalize_string(staging_value(staging))

        option_refusal = finite_option_validation(approval_state, staging_mode)
        return option_refusal if option_refusal

        missing_field = required_metadata_field(normalized_metadata)
        return missing_metadata_refusal(missing_field) if missing_field

        {
          outcome: 'ready',
          attributes: exemplar_attributes(
            metadata: normalized_metadata,
            approval_state: approval_state,
            staging_mode: staging_mode
          )
        }
      end

      def apply_prepared_curation(entity, prepared_curation)
        prepared_curation.fetch(:attributes).each do |key, value|
          entity.set_attribute(DICTIONARY, key, value)
        end

        { outcome: 'curated' }
      end

      private

      def finite_option_validation(approval_state, staging_mode)
        unless supported_approval_state?(approval_state)
          return approval_state_refusal(approval_state)
        end
        return staging_mode_refusal(staging_mode) unless supported_staging_mode?(staging_mode)

        nil
      end

      def supported_approval_state?(approval_state)
        SUPPORTED_APPROVAL_STATES.include?(approval_state)
      end

      def supported_staging_mode?(staging_mode)
        SUPPORTED_STAGING_MODES.include?(staging_mode)
      end

      def approval_state_refusal(value)
        finite_option_refusal(
          code: 'unsupported_approval_state',
          message: 'Only approved Asset Exemplars are supported in SAR-01.',
          field: 'approval.state',
          value: value,
          allowed_values: SUPPORTED_APPROVAL_STATES
        )
      end

      def staging_mode_refusal(value)
        finite_option_refusal(
          code: 'unsupported_staging_mode',
          message: 'Only metadata-only staging is supported in SAR-01.',
          field: 'staging.mode',
          value: value,
          allowed_values: SUPPORTED_STAGING_MODES
        )
      end

      def exemplar_attributes(metadata:, approval_state:, staging_mode:)
        {
          'assetExemplar' => true,
          'assetExemplarSchemaVersion' => SCHEMA_VERSION,
          'assetRole' => 'exemplar',
          'approvalState' => approval_state,
          'sourceElementId' => metadata.fetch('sourceElementId'),
          'assetCategory' => metadata.fetch('category'),
          'assetDisplayName' => metadata.fetch('displayName'),
          'assetTags' => normalize_tags(metadata['tags']),
          'assetAttributes' => normalize_asset_attributes(metadata['attributes']),
          'stagingMode' => staging_mode
        }
      end

      def required_metadata_field(metadata)
        {
          'metadata.sourceElementId' => metadata['sourceElementId'],
          'metadata.category' => metadata['category'],
          'metadata.displayName' => metadata['displayName']
        }.find { |_field, value| !present?(value) }&.first
      end

      def missing_metadata_refusal(field)
        {
          outcome: 'refused',
          refusal: {
            code: 'missing_required_metadata',
            message: 'Required Asset Exemplar metadata is missing.',
            details: { field: field }
          }
        }
      end

      def finite_option_refusal(code:, message:, field:, value:, allowed_values:)
        {
          outcome: 'refused',
          refusal: {
            code: code,
            message: message,
            details: {
              field: field,
              value: value,
              allowedValues: allowed_values
            }
          }
        }
      end

      def approval_value(approval)
        return nil unless approval.is_a?(Hash)

        approval['state'] || approval[:state]
      end

      def staging_value(staging)
        return nil unless staging.is_a?(Hash)

        staging['mode'] || staging[:mode]
      end

      def normalize_hash(value)
        return {} unless value.is_a?(Hash)

        value.each_with_object({}) do |(key, nested_value), normalized|
          normalized[key.to_s] = nested_value
        end
      end

      def normalize_tags(value)
        Array(value).filter_map do |tag|
          normalized = normalize_string(tag)
          normalized unless normalized.empty?
        end
      end

      def normalize_asset_attributes(value)
        return {} unless value.is_a?(Hash)

        value.each_with_object({}) do |(key, nested_value), normalized|
          normalized_value = normalize_json_value(nested_value)
          normalized[key.to_s] = normalized_value unless normalized_value.nil?
        end
      end

      def normalize_json_value(value)
        return value if scalar_json_value?(value)
        return normalize_json_array(value) if value.is_a?(Array)
        return normalize_asset_attributes(value) if value.is_a?(Hash)

        nil
      end

      def normalize_json_array(values)
        values.filter_map { |value| normalize_json_value(value) }
      end

      def scalar_json_value?(value)
        value.is_a?(String) ||
          value.is_a?(Numeric) ||
          value == true ||
          value == false
      end

      def normalize_string(value)
        value.to_s.strip
      end

      def present?(value)
        return false if value.nil?
        return !value.empty? if value.respond_to?(:empty?)

        true
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
