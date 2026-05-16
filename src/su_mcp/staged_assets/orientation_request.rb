# frozen_string_literal: true

module SU_MCP
  module StagedAssets
    # Normalizes SAR-05 placement orientation input before model mutation.
    class OrientationRequest
      SUPPORTED_MODES = %w[upright surface_aligned].freeze

      def normalize(raw_orientation)
        return ready(default_orientation) if raw_orientation.nil?
        return invalid_orientation_refusal(raw_orientation) unless raw_orientation.is_a?(Hash)

        mode = normalized_mode(raw_orientation)
        return mode if refused?(mode)

        yaw = normalized_yaw(raw_orientation)
        return yaw if refused?(yaw)

        surface_reference = hash_value(raw_orientation, 'surfaceReference')
        if surface_reference_missing?(mode, surface_reference)
          return missing_surface_reference_refusal
        end

        ready(
          mode: mode,
          yawDegrees: yaw&.to_f,
          sourceHeadingPreserved: yaw.nil?,
          surfaceReference: surface_reference,
          explicit: true
        )
      end

      private

      def default_orientation
        {
          mode: 'upright',
          yawDegrees: nil,
          sourceHeadingPreserved: true,
          surfaceReference: nil,
          explicit: false
        }
      end

      def ready(orientation)
        { outcome: 'ready', orientation: orientation }
      end

      def normalized_mode(raw_orientation)
        mode = hash_value(raw_orientation, 'mode')
        return missing_mode_refusal if blank?(mode)

        mode = mode.to_s
        return unsupported_mode_refusal(mode) unless SUPPORTED_MODES.include?(mode)

        mode
      end

      def normalized_yaw(raw_orientation)
        yaw = hash_value(raw_orientation, 'yawDegrees')
        return yaw if yaw.nil? || finite_number?(yaw)

        invalid_yaw_refusal(yaw)
      end

      def hash_value(hash, key)
        return hash[key] if hash.key?(key)

        hash[key.to_sym]
      end

      def surface_reference_missing?(mode, surface_reference)
        mode == 'surface_aligned' && !surface_reference.is_a?(Hash)
      end

      def refused?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end

      def finite_number?(value)
        value.is_a?(Numeric) && value.finite?
      end

      def invalid_orientation_refusal(value)
        refusal(
          code: 'invalid_orientation',
          message: 'placement.orientation must be an object when provided.',
          details: { field: 'placement.orientation', value: value }
        )
      end

      def missing_mode_refusal
        refusal(
          code: 'missing_orientation_mode',
          message: 'placement.orientation.mode is required when orientation is provided.',
          details: {
            field: 'placement.orientation.mode',
            allowedValues: SUPPORTED_MODES
          }
        )
      end

      def unsupported_mode_refusal(value)
        refusal(
          code: 'unsupported_orientation_mode',
          message: 'placement.orientation.mode must be upright or surface_aligned.',
          details: {
            field: 'placement.orientation.mode',
            value: value,
            allowedValues: SUPPORTED_MODES
          }
        )
      end

      def invalid_yaw_refusal(value)
        refusal(
          code: 'invalid_orientation_yaw',
          message: 'placement.orientation.yawDegrees must be a finite number when provided.',
          details: {
            field: 'placement.orientation.yawDegrees',
            value: value,
            bounds: 'finite_number'
          }
        )
      end

      def missing_surface_reference_refusal
        refusal(
          code: 'missing_surface_reference',
          message: 'surface_aligned orientation requires placement.orientation.surfaceReference.',
          details: { field: 'placement.orientation.surfaceReference' }
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
