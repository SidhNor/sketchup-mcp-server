# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  # Normalizes and validates the public measure_scene request shape.
  class MeasureSceneRequest
    MODE_KINDS = {
      'bounds' => ['world_bounds'],
      'height' => ['bounds_z'],
      'distance' => ['bounds_center_to_bounds_center'],
      'area' => %w[surface horizontal_bounds]
    }.freeze
    TARGET_REFERENCE_KEYS = %w[sourceElementId persistentId entityId].freeze

    def initialize(params)
      @params = params
    end

    def refusal
      return invalid_request_refusal('request must be an object') unless params.is_a?(Hash)
      return unsupported_mode_refusal unless MODE_KINDS.key?(mode)
      return unsupported_kind_refusal unless MODE_KINDS.fetch(mode).include?(kind)

      reference_fields.each do |field|
        field_refusal = refusal_for_reference_field(field)
        return field_refusal if field_refusal
      end

      output_options_refusal
    end

    def mode
      params['mode'].to_s
    end

    def kind
      params['kind'].to_s
    end

    def distance?
      mode == 'distance'
    end

    def reference(field)
      params.fetch(field)
    end

    def include_evidence?
      options = params['outputOptions']
      options.is_a?(Hash) && options['includeEvidence'] == true
    end

    def compact_reference(field)
      reference(field).each_with_object({}) do |(key, value), result|
        string_key = key.to_s
        next unless TARGET_REFERENCE_KEYS.include?(string_key)
        next if value.to_s.strip.empty?

        result[string_key.to_sym] = value.to_s
      end
    end

    private

    attr_reader :params

    def reference_fields
      distance? ? %w[from to] : ['target']
    end

    def refusal_for_reference_field(field)
      return missing_field_refusal(field) unless params.key?(field)

      reference_refusal = reference_shape_refusal(field, params[field])
      return reference_refusal if reference_refusal

      missing_field_refusal(field) unless reference_present?(params[field])
    end

    def reference_shape_refusal(field, reference)
      return invalid_request_refusal("#{field} must be an object") unless reference.is_a?(Hash)

      unsupported = reference.keys.map(&:to_s) - TARGET_REFERENCE_KEYS
      return nil if unsupported.empty?

      ToolResponse.refusal(
        code: 'unsupported_reference_field',
        message: "Unsupported #{field} reference field: #{unsupported.first}",
        details: {
          field: "#{field}.#{unsupported.first}",
          allowedValues: TARGET_REFERENCE_KEYS
        }
      )
    end

    def reference_present?(reference)
      reference.is_a?(Hash) && reference.any? do |key, value|
        TARGET_REFERENCE_KEYS.include?(key.to_s) && !value.to_s.strip.empty?
      end
    end

    def output_options_refusal
      output_options = params['outputOptions']
      return nil if output_options.nil?

      unless output_options.is_a?(Hash)
        return invalid_request_refusal('outputOptions must be an object')
      end

      unsupported_output_options_refusal(output_options) ||
        include_evidence_refusal(output_options)
    end

    def unsupported_output_options_refusal(output_options)
      unsupported = output_options.keys.map(&:to_s) - ['includeEvidence']
      return nil if unsupported.empty?

      ToolResponse.refusal(
        code: 'unsupported_request_field',
        message: "Unsupported outputOptions field: #{unsupported.first}",
        details: { field: "outputOptions.#{unsupported.first}" }
      )
    end

    def include_evidence_refusal(output_options)
      value = output_options['includeEvidence']
      return nil if value == true || value == false || value.nil?

      ToolResponse.refusal(
        code: 'invalid_request',
        message: 'outputOptions.includeEvidence must be boolean',
        details: { field: 'outputOptions.includeEvidence' }
      )
    end

    def unsupported_mode_refusal
      ToolResponse.refusal(
        code: 'unsupported_mode',
        message: 'Measurement mode is not supported.',
        details: {
          field: 'mode',
          value: mode,
          allowedValues: MODE_KINDS.keys
        }
      )
    end

    def unsupported_kind_refusal
      ToolResponse.refusal(
        code: 'unsupported_kind',
        message: 'Measurement kind is not supported for this mode.',
        details: {
          field: 'kind',
          mode: mode,
          value: kind,
          allowedValues: MODE_KINDS.fetch(mode, [])
        }
      )
    end

    def missing_field_refusal(field)
      ToolResponse.refusal(
        code: 'missing_required_field',
        message: "Missing required field: #{field}",
        details: { field: field }
      )
    end

    def invalid_request_refusal(message)
      ToolResponse.refusal(code: 'invalid_request', message: message)
    end
  end
end
