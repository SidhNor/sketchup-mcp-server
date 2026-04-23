# frozen_string_literal: true

require_relative '../runtime/tool_response'
require_relative 'request_shape_contract'

module SU_MCP
  module Semantic
    # Owns structural recovery or refusal for malformed create-site-element request shapes.
    class RequestShapeRecovery
      CANONICAL_TOP_LEVEL_SECTIONS = RequestShapeContract::CANONICAL_TOP_LEVEL_SECTIONS
      ALLOWED_DEFINITION_FIELDS_BY_TYPE = RequestShapeContract::ALLOWED_DEFINITION_FIELDS_BY_TYPE

      def recover_create_site_element_params(params)
        wrapped = wrapped_payload(params)
        return recover_unwrapped_payload(wrapped) if wrapped

        recover_unwrapped_payload(params)
      end

      private

      def recover_unwrapped_payload(params)
        refusal = misnested_definition_leaf_refusal(params)
        return refusal if refusal

        recovered = recover_top_level_definition_leafs(params)
        return recovered if recovered

        deep_copy(params)
      end

      def wrapped_payload(params)
        return unless params.is_a?(Hash)
        return unless params.keys == ['definition']

        wrapped = params['definition']
        return unless wrapped.is_a?(Hash)

        wrapped
      end

      def recover_top_level_definition_leafs(params)
        return unless params.is_a?(Hash)
        return if params['definition'].is_a?(Hash)

        element_type = params['elementType'].to_s
        allowed_fields = ALLOWED_DEFINITION_FIELDS_BY_TYPE.fetch(element_type, [])
        return if allowed_fields.empty?

        definition_leafs = params.slice(*allowed_fields)
        return if definition_leafs.empty?
        return unless canonical_non_definition_sections_present?(params)

        recovered = deep_copy(params)
        recovered['definition'] = definition_leafs
        definition_leafs.each_key { |key| recovered.delete(key) }
        recovered
      end

      # rubocop:disable Metrics/MethodLength
      def misnested_definition_leaf_refusal(params)
        return unless params.is_a?(Hash)
        return unless params['definition'].is_a?(Hash)

        misnested_fields = top_level_definition_leaf_fields(params)
        return if misnested_fields.empty?

        ToolResponse.refusal(
          code: 'malformed_request_shape',
          message: 'Request shape is malformed for semantic site creation.',
          details: {
            elementType: params['elementType'],
            expectedTopLevelSections: CANONICAL_TOP_LEVEL_SECTIONS,
            misnestedFields: misnested_fields,
            allowedDefinitionFields: ALLOWED_DEFINITION_FIELDS_BY_TYPE.fetch(
              params['elementType'].to_s,
              []
            ),
            suggestedCorrection: 'Keep geometry leaf fields inside definition.'
          }
        )
      end
      # rubocop:enable Metrics/MethodLength

      def canonical_non_definition_sections_present?(params)
        (CANONICAL_TOP_LEVEL_SECTIONS - ['definition']).all? { |section| params.key?(section) }
      end

      def top_level_definition_leaf_fields(params)
        params.keys.reject do |key|
          CANONICAL_TOP_LEVEL_SECTIONS.include?(key) || !all_definition_fields.include?(key)
        end
      end

      def all_definition_fields
        @all_definition_fields ||= ALLOWED_DEFINITION_FIELDS_BY_TYPE.values.flatten.uniq
      end

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end
    end
  end
end
