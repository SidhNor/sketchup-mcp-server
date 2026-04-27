# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Terrain
    # Validates and normalizes the public edit_terrain_surface request.
    # rubocop:disable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
    class EditTerrainSurfaceRequest
      SUPPORTED_OPERATION_MODES = %w[
        target_height corridor_transition local_fairing survey_point_constraint
      ].freeze
      SUPPORTED_SURVEY_CORRECTION_SCOPES = %w[local regional].freeze
      SUPPORTED_REGION_TYPES = %w[rectangle corridor circle].freeze
      SUPPORTED_BLEND_FALLOFFS = %w[none linear smooth].freeze
      SUPPORTED_SIDE_BLEND_FALLOFFS = %w[none cosine].freeze
      SUPPORTED_PRESERVE_ZONE_TYPES = %w[rectangle circle].freeze
      SUPPORTED_REGION_TYPES_BY_MODE = {
        'target_height' => %w[rectangle circle],
        'corridor_transition' => %w[corridor],
        'local_fairing' => %w[rectangle circle],
        'survey_point_constraint' => %w[rectangle circle]
      }.freeze
      SUPPORTED_PRESERVE_ZONE_TYPES_BY_MODE = {
        'target_height' => %w[rectangle circle],
        'corridor_transition' => %w[rectangle],
        'local_fairing' => %w[rectangle circle],
        'survey_point_constraint' => %w[rectangle circle]
      }.freeze

      LOCAL_FAIRING_RADIUS_RANGE = (1..31).freeze
      LOCAL_FAIRING_ITERATIONS_RANGE = (1..8).freeze

      DEFAULT_BLEND_DISTANCE = 0.0
      DEFAULT_BLEND_FALLOFF = 'none'
      DEFAULT_POSITIVE_BLEND_FALLOFF = 'smooth'
      DEFAULT_SIDE_BLEND_DISTANCE = 0.0
      DEFAULT_SIDE_BLEND_FALLOFF = 'none'
      DEFAULT_POSITIVE_SIDE_BLEND_FALLOFF = 'cosine'
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01
      DEFAULT_SURVEY_POINT_TOLERANCE = 0.01
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
        if operation['mode'] == 'target_height'
          return missing_field_refusal('operation.targetElevation') unless operation.key?(
            'targetElevation'
          )
          return invalid_number_refusal('operation.targetElevation') unless finite_number?(
            operation['targetElevation']
          )
        end
        return local_fairing_operation_refusal if operation['mode'] == 'local_fairing'
        return survey_operation_refusal if operation['mode'] == 'survey_point_constraint'

        nil
      end

      def survey_operation_refusal
        return missing_field_refusal('operation.correctionScope') if blank?(
          operation['correctionScope']
        )
        return nil if SUPPORTED_SURVEY_CORRECTION_SCOPES.include?(operation['correctionScope'])

        unsupported_option_refusal(
          field: 'operation.correctionScope',
          value: operation['correctionScope'],
          allowed_values: SUPPORTED_SURVEY_CORRECTION_SCOPES,
          message: 'Survey correction scope is not supported for edit_terrain_surface.'
        )
      end

      def local_fairing_operation_refusal
        return missing_field_refusal('operation.strength') unless operation.key?('strength')
        return invalid_number_refusal('operation.strength') unless finite_number?(
          operation['strength']
        )

        strength = operation['strength'].to_f
        unless strength.positive? && strength <= 1.0
          return invalid_number_refusal('operation.strength')
        end

        unless operation.key?('neighborhoodRadiusSamples')
          return missing_field_refusal('operation.neighborhoodRadiusSamples')
        end

        radius = operation['neighborhoodRadiusSamples']
        unless radius.is_a?(Integer) && LOCAL_FAIRING_RADIUS_RANGE.cover?(radius)
          return invalid_number_refusal('operation.neighborhoodRadiusSamples')
        end

        return nil unless operation.key?('iterations')

        iterations = operation['iterations']
        return nil if iterations.is_a?(Integer) && LOCAL_FAIRING_ITERATIONS_RANGE.cover?(iterations)

        invalid_number_refusal('operation.iterations')
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
        compatibility_refusal = mode_region_compatibility_refusal
        return compatibility_refusal if compatibility_refusal

        return corridor_region_refusal if operation['mode'] == 'corridor_transition'
        return circle_refusal(region, 'region') if region['type'] == 'circle'

        bounds_refusal(region['bounds'], 'region.bounds') || blend_refusal
      end

      def mode_region_compatibility_refusal
        allowed = SUPPORTED_REGION_TYPES_BY_MODE.fetch(operation['mode'], SUPPORTED_REGION_TYPES)
        return nil if allowed.include?(region['type'])

        unsupported_option_refusal(
          field: 'region.type',
          value: region['type'],
          allowed_values: allowed,
          message: 'Region type is not supported for this edit operation mode.'
        )
      end

      def corridor_region_refusal
        control_refusal('region.startControl', region['startControl']) ||
          control_refusal('region.endControl', region['endControl']) ||
          corridor_width_refusal ||
          corridor_side_blend_refusal ||
          coincident_corridor_refusal
      end

      def control_refusal(field, control)
        return missing_field_refusal(field) unless control.is_a?(Hash)

        point = control['point']
        return invalid_shape_refusal("#{field}.point") unless point.is_a?(Hash)

        %w[x y].each do |axis|
          return invalid_number_refusal("#{field}.point.#{axis}") unless finite_number?(point[axis])
        end
        return invalid_number_refusal("#{field}.elevation") unless finite_number?(
          control['elevation']
        )

        nil
      end

      def corridor_width_refusal
        width = region['width']
        return missing_field_refusal('region.width') unless region.key?('width')
        return invalid_number_refusal('region.width') unless finite_number?(width)
        return invalid_number_refusal('region.width') unless width.to_f.positive?

        nil
      end

      def corridor_side_blend_refusal
        side_blend = region.fetch('sideBlend', {})
        return invalid_shape_refusal('region.sideBlend') unless side_blend.is_a?(Hash)

        distance = side_blend.fetch('distance', DEFAULT_SIDE_BLEND_DISTANCE)
        return invalid_number_refusal('region.sideBlend.distance') unless finite_number?(distance)
        return invalid_number_refusal('region.sideBlend.distance') if distance.to_f.negative?

        falloff = normalized_side_blend_falloff(side_blend, distance)
        unless SUPPORTED_SIDE_BLEND_FALLOFFS.include?(falloff)
          return unsupported_option_refusal(
            field: 'region.sideBlend.falloff',
            value: falloff,
            allowed_values: SUPPORTED_SIDE_BLEND_FALLOFFS,
            message: 'Side-blend falloff is not supported for corridor_transition.'
          )
        end
        return invalid_shape_refusal('region.sideBlend.falloff') if distance.to_f.positive? &&
                                                                    falloff == 'none'

        nil
      end

      def coincident_corridor_refusal
        start_point = region.dig('startControl', 'point')
        end_point = region.dig('endControl', 'point')
        return nil unless start_point == end_point

        refusal(
          code: 'invalid_corridor_geometry',
          message: 'Corridor transition controls do not define supported geometry.',
          details: {
            field: 'region',
            reason: 'start and end controls must not be coincident'
          }
        )
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

      def circle_refusal(circle, field)
        return missing_field_refusal("#{field}.center") unless circle.key?('center')
        return invalid_shape_refusal("#{field}.center") unless circle['center'].is_a?(Hash)

        %w[x y].each do |axis|
          return invalid_number_refusal("#{field}.center.#{axis}") unless finite_number?(
            circle.dig('center', axis)
          )
        end

        return missing_field_refusal("#{field}.radius") unless circle.key?('radius')
        return invalid_number_refusal("#{field}.radius") unless finite_number?(circle['radius'])
        return invalid_number_refusal("#{field}.radius") unless circle['radius'].to_f.positive?

        nil
      end

      def constraints_refusal
        return invalid_shape_refusal('constraints') unless constraints.is_a?(Hash)

        survey_result = survey_points_refusal
        return survey_result if survey_result

        fixed_controls_result = fixed_controls_refusal
        return fixed_controls_result if fixed_controls_result

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
          compatibility_result = preserve_zone_compatibility_refusal(zone, index)
          return compatibility_result if compatibility_result

          field = "constraints.preserveZones[#{index}]"
          shape_result = if zone['type'] == 'circle'
                           circle_refusal(zone, field)
                         else
                           bounds_refusal(zone['bounds'], "#{field}.bounds")
                         end
          return shape_result if shape_result
        end
        nil
      end

      def survey_points_refusal
        return nil unless operation['mode'] == 'survey_point_constraint'
        return missing_field_refusal('constraints.surveyPoints') unless constraints.key?(
          'surveyPoints'
        )

        survey_points = constraints['surveyPoints']
        return invalid_shape_refusal('constraints.surveyPoints') unless survey_points.is_a?(Array)
        return missing_field_refusal('constraints.surveyPoints') if survey_points.empty?

        survey_points.each_with_index do |point_constraint, index|
          unless point_constraint.is_a?(Hash)
            return invalid_shape_refusal("constraints.surveyPoints[#{index}]")
          end

          point = point_constraint['point']
          unless point.is_a?(Hash)
            return invalid_shape_refusal("constraints.surveyPoints[#{index}].point")
          end

          %w[x y z].each do |axis|
            unless finite_number?(point[axis])
              return invalid_number_refusal("constraints.surveyPoints[#{index}].point.#{axis}")
            end
          end
          if point_constraint.key?('tolerance') &&
             (!finite_number?(point_constraint['tolerance']) ||
              point_constraint['tolerance'].to_f.negative?)
            return invalid_number_refusal("constraints.surveyPoints[#{index}].tolerance")
          end
          if point_constraint.key?('id') && !json_safe_scalar?(point_constraint['id'])
            return invalid_shape_refusal("constraints.surveyPoints[#{index}].id")
          end
        end
        nil
      end

      def preserve_zone_compatibility_refusal(zone, index)
        allowed = SUPPORTED_PRESERVE_ZONE_TYPES_BY_MODE.fetch(
          operation['mode'],
          SUPPORTED_PRESERVE_ZONE_TYPES
        )
        return nil if allowed.include?(zone['type'])

        unsupported_option_refusal(
          field: "constraints.preserveZones[#{index}].type",
          value: zone['type'],
          allowed_values: allowed,
          message: 'Preserve zone type is not supported for this edit operation mode.'
        )
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
        normalized['operation'] = normalized_operation
        normalized['constraints'] = normalized_constraints
        normalized['region'] = normalized_region
        normalized['outputOptions'] = normalized_output_options
        normalized
      end

      def normalized_operation
        normalized = deep_dup(operation)
        if normalized['mode'] == 'local_fairing'
          normalized['strength'] = normalized.fetch('strength').to_f
          normalized['iterations'] = normalized.fetch('iterations', 1)
        end
        normalized
      end

      def normalized_region
        normalized = deep_dup(region)
        return normalized_corridor_region(normalized) if normalized['type'] == 'corridor'

        blend = normalized.fetch('blend', {})
        distance = blend.fetch('distance', DEFAULT_BLEND_DISTANCE).to_f
        falloff = blend.fetch('falloff', nil)
        falloff ||= distance.positive? ? DEFAULT_POSITIVE_BLEND_FALLOFF : DEFAULT_BLEND_FALLOFF
        normalized['blend'] = blend.merge('distance' => distance, 'falloff' => falloff)
        normalized
      end

      def normalized_corridor_region(normalized)
        side_blend = normalized.fetch('sideBlend', {})
        distance = side_blend.fetch('distance', DEFAULT_SIDE_BLEND_DISTANCE).to_f
        falloff = normalized_side_blend_falloff(side_blend, distance)
        normalized['sideBlend'] = side_blend.merge('distance' => distance, 'falloff' => falloff)
        normalized
      end

      def normalized_side_blend_falloff(side_blend, distance)
        falloff = side_blend.fetch('falloff', nil)
        return falloff if falloff
        return DEFAULT_POSITIVE_SIDE_BLEND_FALLOFF if distance.to_f.positive?

        DEFAULT_SIDE_BLEND_FALLOFF
      end

      def normalized_constraints
        normalized = deep_dup(constraints)
        fixed_controls = normalized.fetch('fixedControls', [])
        normalized['fixedControls'] = fixed_controls.map do |control|
          control.merge(
            'tolerance' => control.fetch('tolerance', DEFAULT_FIXED_CONTROL_TOLERANCE).to_f
          )
        end
        survey_points = normalized.fetch('surveyPoints', [])
        normalized['surveyPoints'] = survey_points.map do |point_constraint|
          point_constraint.merge(
            'tolerance' => point_constraint.fetch(
              'tolerance',
              DEFAULT_SURVEY_POINT_TOLERANCE
            ).to_f
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

      def json_safe_scalar?(value)
        value.nil? || value.is_a?(String) || value.is_a?(Numeric) ||
          boolean?(value)
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
