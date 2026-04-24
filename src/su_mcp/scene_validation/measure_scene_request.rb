# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  # Normalizes and validates the public measure_scene request shape.
  # rubocop:disable Metrics/ClassLength
  class MeasureSceneRequest
    MODE_KINDS = {
      'bounds' => ['world_bounds'],
      'height' => ['bounds_z'],
      'distance' => ['bounds_center_to_bounds_center'],
      'area' => %w[surface horizontal_bounds],
      'terrain_profile' => ['elevation_summary']
    }.freeze
    TARGET_REFERENCE_KEYS = %w[sourceElementId persistentId entityId].freeze
    TERRAIN_ONLY_FIELDS = %w[sampling samplingPolicy].freeze
    TERRAIN_SAMPLING_TYPES = ['profile'].freeze

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

      terrain_profile? ? terrain_profile_refusal : generic_mode_refusal
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

    def terrain_profile?
      mode == 'terrain_profile'
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

    def sampling_params
      params['sampling']
    end

    def sampling_policy_params
      params['samplingPolicy']
    end

    def sample_surface_params
      sampling = sampling_params.dup
      policy = sampling_policy_params.is_a?(Hash) ? sampling_policy_params : {}
      result = {
        'target' => reference('target'),
        'sampling' => sampling
      }
      result['visibleOnly'] = policy['visibleOnly'] if policy.key?('visibleOnly')
      result['ignoreTargets'] = policy['ignoreTargets'] if policy.key?('ignoreTargets')
      result
    end

    private

    attr_reader :params

    def reference_fields
      distance? ? %w[from to] : ['target']
    end

    def generic_mode_refusal
      terrain_field_refusal || output_options_refusal
    end

    def terrain_field_refusal
      field = TERRAIN_ONLY_FIELDS.find { |candidate| params.key?(candidate) }
      return nil unless field

      ToolResponse.refusal(
        code: 'unsupported_request_field',
        message: "#{field} is only supported for terrain_profile/elevation_summary.",
        details: { field: field }
      )
    end

    def terrain_profile_refusal
      sampling_refusal ||
        sampling_policy_refusal ||
        output_options_refusal
    end

    def sampling_refusal
      sampling = params['sampling']
      return missing_field_refusal('sampling') unless sampling.is_a?(Hash)

      type = sampling['type'] || sampling[:type]
      return missing_field_refusal('sampling.type') if blank_value?(type)
      return unsupported_sampling_type_refusal(type) unless type == 'profile'

      profile_path_refusal(sampling) ||
        profile_spacing_refusal(sampling)
    end

    def profile_path_refusal(sampling)
      path = sampling['path'] || sampling[:path]
      return missing_field_refusal('sampling.path') if Array(path).empty?

      nil
    end

    def profile_spacing_refusal(sampling)
      sample_count = sampling['sampleCount'] || sampling[:sampleCount]
      interval_meters = sampling['intervalMeters'] || sampling[:intervalMeters]
      if sample_count.nil? && interval_meters.nil?
        return missing_field_refusal('sampling.sampleCount|sampling.intervalMeters')
      end

      return nil if sample_count.nil? || interval_meters.nil?

      ToolResponse.refusal(
        code: 'mutually_exclusive_fields',
        message: 'Provide either sampling.sampleCount or sampling.intervalMeters, not both.',
        details: { fields: %w[sampling.sampleCount sampling.intervalMeters] }
      )
    end

    def unsupported_sampling_type_refusal(value)
      ToolResponse.refusal(
        code: 'unsupported_sampling_type',
        message: 'Terrain profile measurements support profile sampling only.',
        details: {
          field: 'sampling.type',
          value: value,
          allowedValues: TERRAIN_SAMPLING_TYPES
        }
      )
    end

    def sampling_policy_refusal
      policy = params['samplingPolicy']
      return nil if policy.nil?
      unless policy.is_a?(Hash)
        return invalid_request_refusal('samplingPolicy must be an object', field: 'samplingPolicy')
      end

      unsupported = policy.keys.map(&:to_s) - %w[visibleOnly ignoreTargets]
      unless unsupported.empty?
        return ToolResponse.refusal(
          code: 'unsupported_request_field',
          message: "Unsupported samplingPolicy field: #{unsupported.first}",
          details: { field: "samplingPolicy.#{unsupported.first}" }
        )
      end

      visible_only_refusal(policy) || ignore_targets_refusal(policy)
    end

    def visible_only_refusal(policy)
      value = policy['visibleOnly']
      return nil if value == true || value == false || value.nil?

      invalid_request_refusal(
        'samplingPolicy.visibleOnly must be boolean',
        field: 'samplingPolicy.visibleOnly'
      )
    end

    def ignore_targets_refusal(policy)
      ignore_targets = policy['ignoreTargets']
      return nil if ignore_targets.nil?
      unless ignore_targets.is_a?(Array)
        return invalid_request_refusal(
          'samplingPolicy.ignoreTargets must be an array',
          field: 'samplingPolicy.ignoreTargets'
        )
      end

      ignore_targets.each_with_index do |target, index|
        reference_refusal = reference_shape_refusal("samplingPolicy.ignoreTargets.#{index}", target)
        return reference_refusal if reference_refusal
      end
      nil
    end

    def blank_value?(value)
      value.nil? || value.to_s.strip.empty?
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

    def invalid_request_refusal(message, field: nil)
      details = field ? { field: field } : nil
      ToolResponse.refusal(code: 'invalid_request', message: message, details: details)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
