# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Editing
    # Resolves canonical targetReference mutation targets and refuses legacy selector fields.
    class MutationTargetResolver
      def initialize(model_adapter:, target_resolver:, supported_target:)
        @model_adapter = model_adapter
        @target_resolver = target_resolver
        @supported_target = supported_target
      end

      def resolve(params)
        selection = mutation_target_selection(params)
        return selection if refusal_response?(selection)

        resolve_by_reference(selection.fetch(:target_reference))
      rescue TargetReferenceResolver::InvalidReference => e
        ToolResponse.refusal(code: e.code, message: e.message, details: e.details)
      end

      private

      attr_reader :model_adapter, :target_resolver, :supported_target

      def mutation_target_selection(params)
        id = normalized_string(params['id'])
        target_reference = normalized_target_reference(params['targetReference'])
        has_id = !id.nil?
        has_target_reference = !target_reference.empty?

        return unsupported_request_field_refusal('id') if has_id
        return missing_target_refusal unless has_target_reference

        { target_reference: target_reference }
      end

      def resolve_by_reference(target_reference)
        resolution = target_resolver.resolve(target_reference)
        return target_not_found_refusal if resolution[:resolution] == 'none'
        return ambiguous_target_refusal if resolution[:resolution] == 'ambiguous'

        entity = resolution.fetch(:entity)
        return unsupported_target_type_refusal unless supported_target.call(entity)

        {
          model: model_adapter.active_model!,
          entity: entity
        }
      end

      def missing_target_refusal
        ToolResponse.refusal(
          code: 'missing_target',
          message: 'targetReference is required.',
          details: {
            field: 'targetReference',
            allowedFields: TargetReferenceResolver::TARGET_REFERENCE_KEYS
          }
        )
      end

      def unsupported_request_field_refusal(field)
        ToolResponse.refusal(
          code: 'unsupported_request_field',
          message: 'Unsupported request field.',
          details: { field: field, allowedFields: ['targetReference'] }
        )
      end

      def target_not_found_refusal
        ToolResponse.refusal(
          code: 'target_not_found',
          message: 'Target reference resolves to no entity.'
        )
      end

      def ambiguous_target_refusal
        ToolResponse.refusal(
          code: 'ambiguous_target',
          message: 'Target reference resolves ambiguously.'
        )
      end

      def unsupported_target_type_refusal
        ToolResponse.refusal(
          code: 'unsupported_target_type',
          message: 'Target reference must resolve to a supported group or component instance.'
        )
      end

      def refusal_response?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end

      def normalized_string(value)
        string_value = value&.to_s&.strip
        return nil if string_value.nil? || string_value.empty?

        string_value
      end

      def normalized_target_reference(value)
        return {} unless value.is_a?(Hash)

        value.each_with_object({}) do |(key, nested_value), normalized|
          string_value = normalized_string(nested_value)
          normalized[key] = string_value if string_value
        end
      end
    end
  end
end
