# frozen_string_literal: true

module SU_MCP
  module Terrain
    module UI
      # Session-scoped settings for the managed terrain round-brush tools.
      class BrushSettings
        SUPPORTED_TOOLS = %w[target_height local_fairing].freeze
        SUPPORTED_FALLOFFS = %w[none linear smooth].freeze
        POSITIVE_BLEND_FALLOFFS = %w[linear smooth].freeze
        DEFAULT_RADIUS = 2.0
        DEFAULT_BLEND_DISTANCE = 0.0
        DEFAULT_FALLOFF = 'none'
        DEFAULT_FAIRING_STRENGTH = 0.35
        DEFAULT_FAIRING_NEIGHBORHOOD_RADIUS_SAMPLES = 4
        DEFAULT_FAIRING_ITERATIONS = 1
        LOCAL_FAIRING_RADIUS_RANGE = (1..31).freeze
        LOCAL_FAIRING_ITERATIONS_RANGE = (1..8).freeze

        def initialize(values = {})
          @active_tool = 'target_height'
          @shared_values = {
            'radius' => DEFAULT_RADIUS,
            'blendDistance' => DEFAULT_BLEND_DISTANCE,
            'falloff' => DEFAULT_FALLOFF
          }
          @target_height_values = { 'targetElevation' => nil }
          @local_fairing_values = {
            'strength' => DEFAULT_FAIRING_STRENGTH,
            'neighborhoodRadiusSamples' => DEFAULT_FAIRING_NEIGHBORHOOD_RADIUS_SAMPLES,
            'iterations' => DEFAULT_FAIRING_ITERATIONS
          }
          @invalid_setting = nil
          update_values(values || {})
        end

        def activate_tool(tool)
          normalized = tool.to_s
          return unsupported_tool_refusal(normalized) unless SUPPORTED_TOOLS.include?(normalized)

          @active_tool = normalized
          { outcome: 'ready', settings: snapshot }
        end

        def update(values)
          normalized = normalize_values(values || {})
          apply_values(normalized.fetch(:values, empty_values))
          clear_invalid_setting(normalized.fetch(:values, empty_values))
          if refused?(normalized)
            @invalid_setting = normalized.dig(:refusal, :details)
            return without_internal_values(normalized)
          end

          { outcome: 'ready', settings: snapshot }
        end

        def validate
          return invalid_setting_refusal if @invalid_setting
          unless positive_number?(@shared_values['radius'])
            return invalid_settings_refusal('radius')
          end
          return invalid_settings_refusal('blendDistance') unless non_negative_number?(
            @shared_values['blendDistance']
          )

          falloff = @shared_values['falloff']
          unless SUPPORTED_FALLOFFS.include?(falloff)
            return unsupported_falloff_refusal(falloff, SUPPORTED_FALLOFFS)
          end
          if @shared_values['blendDistance'].positive? && falloff == 'none'
            return unsupported_falloff_refusal(
              falloff,
              POSITIVE_BLEND_FALLOFFS,
              code: 'invalid_brush_settings'
            )
          end

          operation_result = validate_active_operation
          return operation_result if refused?(operation_result)

          { outcome: 'ready', settings: snapshot }
        end

        def snapshot
          base = {
            activeTool: @active_tool,
            mode: @active_tool,
            targetElevation: @target_height_values['targetElevation'],
            radius: @shared_values['radius'],
            blendDistance: @shared_values['blendDistance'],
            falloff: @shared_values['falloff'],
            falloffOptions: SUPPORTED_FALLOFFS,
            toolOptions: SUPPORTED_TOOLS,
            localFairing: {
              strength: @local_fairing_values['strength'],
              neighborhoodRadiusSamples: @local_fairing_values['neighborhoodRadiusSamples'],
              iterations: @local_fairing_values['iterations']
            }
          }
          base[:invalidSetting] = @invalid_setting if @invalid_setting
          base
        end

        private

        def update_values(values)
          normalized = normalize_values(values)
          apply_values(normalized.fetch(:values, empty_values))
          return unless refused?(normalized)

          @invalid_setting = normalized.dig(:refusal, :details)
        end

        def apply_values(values_by_bucket)
          @shared_values.merge!(values_by_bucket.fetch(:shared, {}))
          @target_height_values.merge!(values_by_bucket.fetch(:target_height, {}))
          @local_fairing_values.merge!(values_by_bucket.fetch(:local_fairing, {}))
        end

        def empty_values
          { shared: {}, target_height: {}, local_fairing: {} }
        end

        def normalize_values(values)
          requested_tool = requested_tool_for(values)
          return requested_tool if refused?(requested_tool)

          normalized = { shared: {}, target_height: {}, local_fairing: {} }
          refusal = nil
          values.each do |key, value|
            field = key.to_s
            result = normalize_field(normalized, field, value, requested_tool)
            refusal ||= result if refused?(result)
          end
          return refusal.merge(values: normalized) if refusal

          { outcome: 'ready', values: normalized }
        end

        def without_internal_values(result)
          result.reject { |key, _value| key == :values }
        end

        def requested_tool_for(values)
          requested = values.fetch('activeTool', values.fetch(:activeTool, @active_tool)).to_s
          return unsupported_tool_refusal(requested) unless SUPPORTED_TOOLS.include?(requested)

          requested
        end

        def normalize_field(normalized, field, value, requested_tool)
          return activate_tool(value) if field == 'activeTool'

          if field == 'targetElevation'
            return { outcome: 'ready' } if value.nil? && requested_tool != 'target_height'

            return normalize_target_elevation(normalized, field, value)
          end
          return normalize_shared_field(normalized, field, value) if shared_field?(field)
          return normalize_local_fairing_field(normalized, field, value, requested_tool) if
            local_fairing_field?(field)

          { outcome: 'ready' }
        end

        def shared_field?(field)
          %w[radius blendDistance falloff].include?(field)
        end

        def local_fairing_field?(field)
          %w[strength neighborhoodRadiusSamples iterations].include?(field)
        end

        def normalize_shared_field(normalized, field, value)
          return normalize_radius(normalized, field, value) if field == 'radius'
          return normalize_blend_distance(normalized, field, value) if field == 'blendDistance'

          normalize_falloff(normalized, field, value)
        end

        def normalize_local_fairing_field(normalized, field, value, requested_tool)
          return { outcome: 'ready' } if value.nil? && requested_tool != 'local_fairing'
          return normalize_strength(normalized, field, value) if field == 'strength'
          if field == 'neighborhoodRadiusSamples'
            return normalize_integer_range(normalized, field, value, LOCAL_FAIRING_RADIUS_RANGE)
          end

          normalize_integer_range(normalized, field, value, LOCAL_FAIRING_ITERATIONS_RANGE)
        end

        def normalize_target_elevation(normalized, field, value)
          return invalid_settings_refusal(field) unless numeric?(value)

          normalized[:target_height][field] = value.to_f
          { outcome: 'ready' }
        end

        def normalize_radius(normalized, field, value)
          return invalid_settings_refusal(field) unless numeric?(value) && value.to_f.positive?

          normalized[:shared][field] = value.to_f
          { outcome: 'ready' }
        end

        def normalize_blend_distance(normalized, field, value)
          return invalid_settings_refusal(field) unless numeric?(value) && !value.to_f.negative?

          normalized[:shared][field] = value.to_f
          { outcome: 'ready' }
        end

        def normalize_falloff(normalized, field, value)
          falloff = value.to_s
          return unsupported_falloff_refusal(falloff, SUPPORTED_FALLOFFS) unless
            SUPPORTED_FALLOFFS.include?(falloff)

          normalized[:shared][field] = falloff
          { outcome: 'ready' }
        end

        def normalize_strength(normalized, field, value)
          unless numeric?(value) && value.to_f.positive? && value.to_f <= 1.0
            return invalid_settings_refusal(field, allowed_values: '> 0 and <= 1')
          end

          normalized[:local_fairing][field] = value.to_f
          { outcome: 'ready' }
        end

        def normalize_integer_range(normalized, field, value, range)
          unless integer_in_range?(value, range)
            return invalid_settings_refusal(
              field,
              allowed_values: [range.begin, range.end]
            )
          end

          normalized[:local_fairing][field] = value.to_i
          { outcome: 'ready' }
        end

        def numeric?(value)
          value.is_a?(Numeric) && value.finite?
        end

        def positive_number?(value)
          numeric?(value) && value.positive?
        end

        def non_negative_number?(value)
          numeric?(value) && !value.negative?
        end

        def integer_in_range?(value, range)
          value.is_a?(Integer) && range.cover?(value)
        end

        def refused?(result)
          result.is_a?(Hash) && result[:outcome] == 'refused'
        end

        def validate_active_operation
          if @active_tool == 'target_height'
            return missing_field_refusal('targetElevation') if
              @target_height_values['targetElevation'].nil?
          else
            strength = @local_fairing_values['strength']
            unless positive_number?(strength) && strength <= 1.0
              return invalid_settings_refusal('strength', allowed_values: '> 0 and <= 1')
            end
            unless LOCAL_FAIRING_RADIUS_RANGE.cover?(
              @local_fairing_values['neighborhoodRadiusSamples']
            )
              return invalid_settings_refusal(
                'neighborhoodRadiusSamples',
                allowed_values: [LOCAL_FAIRING_RADIUS_RANGE.begin, LOCAL_FAIRING_RADIUS_RANGE.end]
              )
            end
            unless LOCAL_FAIRING_ITERATIONS_RANGE.cover?(@local_fairing_values['iterations'])
              return invalid_settings_refusal(
                'iterations',
                allowed_values: [
                  LOCAL_FAIRING_ITERATIONS_RANGE.begin,
                  LOCAL_FAIRING_ITERATIONS_RANGE.end
                ]
              )
            end
          end

          { outcome: 'ready' }
        end

        def clear_invalid_setting(values)
          return unless @invalid_setting

          changed_fields = values.values.flat_map(&:keys)
          @invalid_setting = nil if changed_fields.include?(@invalid_setting.fetch(:field))
        end

        def invalid_setting_refusal
          refusal(
            code: 'invalid_brush_settings',
            message: 'Managed terrain brush settings are invalid.',
            details: @invalid_setting
          )
        end

        def missing_field_refusal(field)
          refusal(
            code: 'missing_required_field',
            message: "#{field} is required for the managed terrain brush.",
            details: { field: field }
          )
        end

        def invalid_settings_refusal(field, allowed_values: nil)
          details = { field: field }
          details[:allowedValues] = allowed_values if allowed_values
          refusal(
            code: 'invalid_brush_settings',
            message: 'Managed terrain brush settings are invalid.',
            details: details
          )
        end

        def unsupported_tool_refusal(value)
          refusal(
            code: 'unsupported_option',
            message: 'Managed terrain tool is not supported.',
            details: {
              field: 'activeTool',
              value: value,
              allowedValues: SUPPORTED_TOOLS
            }
          )
        end

        def unsupported_falloff_refusal(value, allowed_values, code: 'unsupported_option')
          refusal(
            code: code,
            message: 'Brush falloff is not supported.',
            details: {
              field: 'falloff',
              value: value,
              allowedValues: allowed_values
            }
          )
        end

        def refusal(code:, message:, details:)
          {
            outcome: 'refused',
            refusal: {
              code: code,
              message: message,
              details: details
            }
          }
        end
      end
    end
  end
end
