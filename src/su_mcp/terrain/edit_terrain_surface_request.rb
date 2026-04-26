# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Terrain
    # Validates and normalizes the public edit_terrain_surface request.
    # rubocop:disable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
    class EditTerrainSurfaceRequest
      SUPPORTED_OPERATION_MODES = %w[target_height].freeze
      SUPPORTED_REGION_TYPES = %w[rectangle].freeze
      SUPPORTED_BLEND_FALLOFFS = %w[none linear smooth].freeze
      SUPPORTED_PRESERVE_ZONE_TYPES = %w[rectangle].freeze

      DEFAULT_BLEND_DISTANCE = 0.0
      DEFAULT_BLEND_FALLOFF = 'none'
      DEFAULT_POSITIVE_BLEND_FALLOFF = 'smooth'
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01
      DEFAULT_INCLUDE_SAMPLE_EVIDENCE = false
      DEFAULT_SAMPLE_EVIDENCE_LIMIT = 20
      MAX_SAMPLE_EVIDENCE_LIMIT = 100

      def initialize(params)
        @params = self.class.stringify_keys(params || {})
      end

      def validate
        first_refusal || ready_result
      end

      def self.stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), normalized|
            normalized[key.to_s] = stringify_keys(nested)
          end
        when Array
          value.map { |nested| stringify_keys(nested) }
        else
          value
        end
      end

      private

      attr_reader :params

      def first_refusal
        root_section_refusal ||
          operation_refusal ||
          region_refusal ||
          constraints_refusal ||
          output_options_refusal
      end

      def root_section_refusal
        return missing_field_refusal('targetReference') unless target_reference.is_a?(Hash)
        return missing_field_refusal('operation') unless operation.is_a?(Hash)
        return missing_field_refusal('region') unless region.is_a?(Hash)
        return missing_field_refusal('targetReference') if target_reference.empty?

        unsupported_target_key = target_reference.keys.find do |key|
          !%w[sourceElementId persistentId entityId].include?(key)
        end
        return nil unless unsupported_target_key

        unsupported_option_refusal(
          field: "targetReference.#{unsupported_target_key}",
          value: unsupported_target_key,
          allowed_values: %w[sourceElementId persistentId entityId],
          message: 'Target reference field is not supported for edit_terrain_surface.'
        )
      end

      def operation_refusal
        return missing_field_refusal('operation.mode') if blank?(operation['mode'])
        unless SUPPORTED_OPERATION_MODES.include?(operation['mode'])
          return unsupported_option_refusal(
            field: 'operation.mode',
            value: operation['mode'],
            allowed_values: SUPPORTED_OPERATION_MODES,
            message: 'Operation mode is not supported for edit_terrain_surface.'
          )
        end
        return invalid_number_refusal('operation.targetElevation') unless finite_number?(
          operation['targetElevation']
        )

        fixed_controls_refusal
      end

      def fixed_controls_refusal
        fixed_controls = constraints.fetch('fixedControls', [])
        return invalid_shape_refusal('constraints.fixedControls') unless fixed_controls.is_a?(Array)

        fixed_controls.each_with_index do |control, index|
          unless control.is_a?(Hash)
            return invalid_shape_refusal("constraints.fixedControls[#{index}]")
          end

          point = control['point']
          unless point.is_a?(Hash)
            return invalid_shape_refusal("constraints.fixedControls[#{index}].point")
          end

          %w[x y].each do |axis|
            unless finite_number?(point[axis])
              return invalid_number_refusal("constraints.fixedControls[#{index}].point.#{axis}")
            end
          end
          if control.key?('elevation') && !finite_number?(control['elevation'])
            return invalid_number_refusal("constraints.fixedControls[#{index}].elevation")
          end
          if control.key?('tolerance') && (!finite_number?(control['tolerance']) ||
              control['tolerance'].to_f.negative?)
            return invalid_number_refusal("constraints.fixedControls[#{index}].tolerance")
          end
        end
        nil
      end

      def region_refusal
        return missing_field_refusal('region.type') if blank?(region['type'])
        unless SUPPORTED_REGION_TYPES.include?(region['type'])
          return unsupported_option_refusal(
            field: 'region.type',
            value: region['type'],
            allowed_values: SUPPORTED_REGION_TYPES,
            message: 'Region type is not supported for edit_terrain_surface.'
          )
        end

        bounds_refusal(region['bounds'], 'region.bounds') || blend_refusal
      end

      def blend_refusal
        blend = region.fetch('blend', {})
        return invalid_shape_refusal('region.blend') unless blend.is_a?(Hash)

        distance = blend.fetch('distance', DEFAULT_BLEND_DISTANCE)
        return invalid_number_refusal('region.blend.distance') unless finite_number?(distance)
        return invalid_number_refusal('region.blend.distance') if distance.to_f.negative?

        falloff = blend.fetch('falloff', nil)
        falloff ||= distance.to_f.positive? ? DEFAULT_POSITIVE_BLEND_FALLOFF : DEFAULT_BLEND_FALLOFF
        return nil if SUPPORTED_BLEND_FALLOFFS.include?(falloff)

        unsupported_option_refusal(
          field: 'region.blend.falloff',
          value: falloff,
          allowed_values: SUPPORTED_BLEND_FALLOFFS,
          message: 'Blend falloff is not supported for edit_terrain_surface.'
        )
      end

      def constraints_refusal
        return invalid_shape_refusal('constraints') unless constraints.is_a?(Hash)

        preserve_zones = constraints.fetch('preserveZones', [])
        return invalid_shape_refusal('constraints.preserveZones') unless preserve_zones.is_a?(Array)

        preserve_zones.each_with_index do |zone, index|
          unless zone.is_a?(Hash)
            return invalid_shape_refusal("constraints.preserveZones[#{index}]")
          end
          unless SUPPORTED_PRESERVE_ZONE_TYPES.include?(zone['type'])
            return unsupported_option_refusal(
              field: "constraints.preserveZones[#{index}].type",
              value: zone['type'],
              allowed_values: SUPPORTED_PRESERVE_ZONE_TYPES,
              message: 'Preserve zone type is not supported for edit_terrain_surface.'
            )
          end
          bounds_result = bounds_refusal(
            zone['bounds'],
            "constraints.preserveZones[#{index}].bounds"
          )
          return bounds_result if bounds_result
        end
        nil
      end

      def output_options_refusal
        return invalid_shape_refusal('outputOptions') unless output_options.is_a?(Hash)
        if output_options.key?('includeSampleEvidence') &&
           !boolean?(output_options['includeSampleEvidence'])
          return invalid_shape_refusal('outputOptions.includeSampleEvidence')
        end

        limit = output_options.fetch('sampleEvidenceLimit', DEFAULT_SAMPLE_EVIDENCE_LIMIT)
        unless limit.is_a?(Integer)
          return invalid_number_refusal('outputOptions.sampleEvidenceLimit')
        end
        unless limit.between?(0, MAX_SAMPLE_EVIDENCE_LIMIT)
          return invalid_number_refusal('outputOptions.sampleEvidenceLimit')
        end

        nil
      end

      def bounds_refusal(bounds, field)
        return invalid_shape_refusal(field) unless bounds.is_a?(Hash)

        %w[minX minY maxX maxY].each do |key|
          return invalid_number_refusal("#{field}.#{key}") unless finite_number?(bounds[key])
        end
        return nil if bounds.fetch('minX') <= bounds.fetch('maxX') &&
                      bounds.fetch('minY') <= bounds.fetch('maxY')

        invalid_shape_refusal(field)
      end

      def ready_result
        normalized = normalized_params
        {
          outcome: 'ready',
          operation_mode: normalized.dig('operation', 'mode'),
          region_type: normalized.dig('region', 'type'),
          params: normalized
        }
      end

      def normalized_params
        normalized = deep_dup(params)
        normalized['constraints'] = normalized_constraints
        normalized['region'] = normalized_region
        normalized['outputOptions'] = normalized_output_options
        normalized
      end

      def normalized_region
        normalized = deep_dup(region)
        blend = normalized.fetch('blend', {})
        distance = blend.fetch('distance', DEFAULT_BLEND_DISTANCE).to_f
        falloff = blend.fetch('falloff', nil)
        falloff ||= distance.positive? ? DEFAULT_POSITIVE_BLEND_FALLOFF : DEFAULT_BLEND_FALLOFF
        normalized['blend'] = blend.merge('distance' => distance, 'falloff' => falloff)
        normalized
      end

      def normalized_constraints
        normalized = deep_dup(constraints)
        fixed_controls = normalized.fetch('fixedControls', [])
        normalized['fixedControls'] = fixed_controls.map do |control|
          control.merge(
            'tolerance' => control.fetch('tolerance', DEFAULT_FIXED_CONTROL_TOLERANCE).to_f
          )
        end
        normalized['preserveZones'] = normalized.fetch('preserveZones', [])
        normalized
      end

      def normalized_output_options
        {
          'includeSampleEvidence' => output_options.fetch(
            'includeSampleEvidence',
            DEFAULT_INCLUDE_SAMPLE_EVIDENCE
          ),
          'sampleEvidenceLimit' => output_options.fetch(
            'sampleEvidenceLimit',
            DEFAULT_SAMPLE_EVIDENCE_LIMIT
          )
        }
      end

      def deep_dup(value)
        self.class.stringify_keys(value)
      end

      def target_reference
        params['targetReference']
      end

      def operation
        params.fetch('operation', {})
      end

      def region
        params.fetch('region', {})
      end

      def constraints
        params.fetch('constraints', {})
      end

      def output_options
        params.fetch('outputOptions', {})
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end

      def finite_number?(value)
        value.is_a?(Numeric) && value.finite?
      end

      def boolean?(value)
        [true, false].include?(value)
      end

      def missing_field_refusal(field)
        refusal(
          code: 'missing_required_field',
          message: "#{field} is required.",
          details: { field: field }
        )
      end

      def invalid_shape_refusal(field)
        refusal(
          code: 'invalid_edit_request',
          message: 'edit_terrain_surface request shape is invalid.',
          details: { field: field }
        )
      end

      def invalid_number_refusal(field)
        refusal(
          code: 'invalid_edit_request',
          message: 'edit_terrain_surface numeric field is invalid.',
          details: { field: field }
        )
      end

      def unsupported_option_refusal(field:, value:, allowed_values:, message:)
        refusal(
          code: 'unsupported_option',
          message: message,
          details: {
            field: field,
            value: value,
            allowedValues: allowed_values
          }
        )
      end

      def refusal(code:, message:, details:)
        ToolResponse.refusal(code: code, message: message, details: details)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity
  end
end
