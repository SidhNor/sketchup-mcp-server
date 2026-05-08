# frozen_string_literal: true

module SU_MCP
  module Terrain
    module UI
      # Session-scoped settings for the first managed terrain target-height brush UI.
      class BrushSettings
        SUPPORTED_FALLOFFS = %w[none linear smooth].freeze
        POSITIVE_BLEND_FALLOFFS = %w[linear smooth].freeze
        DEFAULT_RADIUS = 2.0
        DEFAULT_BLEND_DISTANCE = 0.0
        DEFAULT_FALLOFF = 'none'

        def initialize(values = {})
          @values = {
            'targetElevation' => nil,
            'radius' => DEFAULT_RADIUS,
            'blendDistance' => DEFAULT_BLEND_DISTANCE,
            'falloff' => DEFAULT_FALLOFF
          }
          update_values(values || {})
        end

        def update(values)
          normalized = normalize_values(values || {})
          return normalized if refused?(normalized)

          update_values(normalized.fetch(:values))
          { outcome: 'ready', settings: snapshot }
        end

        def validate
          return invalid_settings_refusal('radius') unless positive_number?(@values['radius'])
          return invalid_settings_refusal('blendDistance') unless non_negative_number?(
            @values['blendDistance']
          )
          return missing_field_refusal('targetElevation') if @values['targetElevation'].nil?

          falloff = @values['falloff']
          unless SUPPORTED_FALLOFFS.include?(falloff)
            return unsupported_falloff_refusal(falloff, SUPPORTED_FALLOFFS)
          end
          if @values['blendDistance'].positive? && falloff == 'none'
            return unsupported_falloff_refusal(
              falloff,
              POSITIVE_BLEND_FALLOFFS,
              code: 'invalid_brush_settings'
            )
          end

          { outcome: 'ready', settings: snapshot }
        end

        def snapshot
          {
            mode: 'target_height',
            targetElevation: @values['targetElevation'],
            radius: @values['radius'],
            blendDistance: @values['blendDistance'],
            falloff: @values['falloff'],
            falloffOptions: SUPPORTED_FALLOFFS
          }
        end

        private

        def update_values(values)
          normalized = normalize_values(values)
          return if refused?(normalized)

          @values.merge!(normalized.fetch(:values))
        end

        def normalize_values(values)
          normalized = {}
          values.each do |key, value|
            field = key.to_s
            case field
            when 'targetElevation', 'radius', 'blendDistance'
              return invalid_settings_refusal(field) unless numeric?(value)

              normalized[field] = value.to_f
            when 'falloff'
              falloff = value.to_s
              return unsupported_falloff_refusal(falloff, SUPPORTED_FALLOFFS) unless
                SUPPORTED_FALLOFFS.include?(falloff)

              normalized[field] = falloff
            end
          end
          { outcome: 'ready', values: normalized }
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

        def refused?(result)
          result.is_a?(Hash) && result[:outcome] == 'refused'
        end

        def missing_field_refusal(field)
          refusal(
            code: 'missing_required_field',
            message: "#{field} is required for the managed terrain brush.",
            details: { field: field }
          )
        end

        def invalid_settings_refusal(field)
          refusal(
            code: 'invalid_brush_settings',
            message: 'Managed terrain brush settings are invalid.',
            details: { field: field }
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
