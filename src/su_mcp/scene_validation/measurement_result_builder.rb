# frozen_string_literal: true

module SU_MCP
  # Builds JSON-safe measurement payload fragments with public unit conversion.
  class MeasurementResultBuilder
    INCH_TO_METER = 0.0254
    SQUARE_INCH_TO_SQUARE_METER = INCH_TO_METER * INCH_TO_METER

    def measured(mode, kind, value:, unit:, evidence:)
      {
        outcome: 'measured',
        measurement: {
          mode: mode,
          kind: kind,
          value: value,
          unit: unit,
          evidence: evidence
        }
      }
    end

    def unavailable(mode, kind, reason)
      {
        outcome: 'unavailable',
        measurement: {
          mode: mode,
          kind: kind,
          reason: reason
        }
      }
    end

    def bounds_value(bounds)
      {
        min: point_hash(bounds.min),
        max: point_hash(bounds.max),
        center: point_hash(bounds.center),
        size: bounds_size(bounds)
      }
    end

    def bounds_evidence(bounds)
      {
        bounds: {
          min: point_hash(bounds.min),
          max: point_hash(bounds.max),
          center: point_hash(bounds.center)
        }
      }
    end

    def point_hash(point)
      {
        x: meters(point.x),
        y: meters(point.y),
        z: meters(point.z)
      }
    end

    def meters(value)
      rounded(value.to_f * INCH_TO_METER)
    end

    def square_meters(value)
      rounded(value.to_f * SQUARE_INCH_TO_SQUARE_METER)
    end

    def horizontal_bounds_area(bounds)
      square_meters(axis_extent(bounds, :x) * axis_extent(bounds, :y))
    end

    private

    def bounds_size(bounds)
      {
        x: meters(axis_extent(bounds, :x)),
        y: meters(axis_extent(bounds, :y)),
        z: meters(axis_extent(bounds, :z))
      }
    end

    def axis_extent(bounds, axis)
      bounds.max.public_send(axis) - bounds.min.public_send(axis)
    end

    def rounded(value)
      value.round(6)
    end
  end
end
