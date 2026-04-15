# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Converts public meter values to SketchUp internal lengths and back.
    class LengthConverter
      METERS_TO_INTERNAL = 39.37007874015748
      ROUNDING_PRECISION = 9

      def public_meters_to_internal(value)
        return nil if value.nil?

        value.to_f * METERS_TO_INTERNAL
      end

      def internal_to_public_meters(value)
        return nil if value.nil?

        (value.to_f / METERS_TO_INTERNAL).round(ROUNDING_PRECISION)
      end
    end
  end
end
