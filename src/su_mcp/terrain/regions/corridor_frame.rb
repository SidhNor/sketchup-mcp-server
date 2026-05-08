# frozen_string_literal: true

module SU_MCP
  module Terrain
    # SketchUp-free oriented corridor math for transition terrain edits.
    class CorridorFrame
      # Keeps exact endpoint samples on adopted fractional grids inside the corridor.
      PARAMETER_TOLERANCE = 1e-9

      attr_reader :start_control, :end_control, :width, :side_blend, :length

      def initialize(start_control:, end_control:, width:, side_blend:)
        @start_control = normalize_control(start_control, 'startControl')
        @end_control = normalize_control(end_control, 'endControl')
        @width = normalize_positive_number(width, 'width')
        @side_blend = normalize_side_blend(side_blend)
        assign_vectors
      end

      def longitudinal_parameter(point)
        coordinate = normalize_point(point, 'point')
        dx = coordinate.fetch('x') - start_point.fetch('x')
        dy = coordinate.fetch('y') - start_point.fetch('y')
        ((dx * @direction_x) + (dy * @direction_y)) / length
      end

      def signed_lateral_distance(point)
        coordinate = normalize_point(point, 'point')
        dx = coordinate.fetch('x') - start_point.fetch('x')
        dy = coordinate.fetch('y') - start_point.fetch('y')
        (dx * @perpendicular_x) + (dy * @perpendicular_y)
      end

      def weight_at(point)
        return 0.0 if outside_corridor_length?(point)

        lateral = signed_lateral_distance(point).abs
        half_width = width / 2.0
        return 1.0 if lateral <= half_width

        side_blend_weight(lateral - half_width)
      end

      def outer_bounds(expand_by:)
        expansion = normalize_expansion(expand_by)
        points = outer_corner_points

        {
          'minX' => coordinate_values(points, 'x').min - expansion.fetch('x'),
          'minY' => coordinate_values(points, 'y').min - expansion.fetch('y'),
          'maxX' => coordinate_values(points, 'x').max + expansion.fetch('x'),
          'maxY' => coordinate_values(points, 'y').max + expansion.fetch('y')
        }
      end

      private

      def outside_corridor_length?(point)
        parameter = longitudinal_parameter(point)
        parameter < -PARAMETER_TOLERANCE || parameter > (1.0 + PARAMETER_TOLERANCE)
      end

      def side_blend_weight(shoulder_distance)
        blend_distance = side_blend.fetch('distance')
        return 0.0 unless blend_distance.positive?
        return 0.0 if shoulder_distance > blend_distance
        return 0.0 if side_blend.fetch('falloff') == 'none'

        0.5 * (1.0 + Math.cos(Math::PI * (shoulder_distance / blend_distance)))
      end

      def outer_corner_points
        extent = (width / 2.0) + side_blend.fetch('distance')
        [start_point, end_point].flat_map do |point|
          [
            offset_point(point, extent),
            offset_point(point, -extent)
          ]
        end
      end

      def coordinate_values(points, axis)
        points.map { |point| point.fetch(axis) }
      end

      def assign_vectors
        components = axis_components
        @length = components.fetch(:length)
        raise ArgumentError, 'corridor endpoints must not be coincident' unless length.positive?

        @direction_x = components.fetch(:dx) / length
        @direction_y = components.fetch(:dy) / length
        @perpendicular_x = -@direction_y
        @perpendicular_y = @direction_x
      end

      def axis_components
        dx = end_point.fetch('x') - start_point.fetch('x')
        dy = end_point.fetch('y') - start_point.fetch('y')
        { dx: dx, dy: dy, length: Math.sqrt((dx * dx) + (dy * dy)) }
      end

      def offset_point(point, distance)
        {
          'x' => point.fetch('x') + (@perpendicular_x * distance),
          'y' => point.fetch('y') + (@perpendicular_y * distance)
        }
      end

      def start_point
        start_control.fetch('point')
      end

      def end_point
        end_control.fetch('point')
      end

      def normalize_control(value, field)
        hash = normalize_hash(value, field)
        {
          'point' => normalize_point(hash.fetch('point'), "#{field}.point"),
          'elevation' => normalize_number(hash.fetch('elevation'), "#{field}.elevation")
        }
      rescue KeyError => e
        raise ArgumentError, "#{field}.#{e.key} is required"
      end

      def normalize_point(value, field)
        hash = normalize_hash(value, field)
        {
          'x' => normalize_number(hash.fetch('x'), "#{field}.x"),
          'y' => normalize_number(hash.fetch('y'), "#{field}.y")
        }
      rescue KeyError => e
        raise ArgumentError, "#{field}.#{e.key} is required"
      end

      def normalize_side_blend(value)
        hash = normalize_hash(value || {}, 'sideBlend')
        distance = normalize_number(hash.fetch('distance', 0.0), 'sideBlend.distance')
        raise ArgumentError, 'sideBlend.distance must not be negative' if distance.negative?

        falloff = hash.fetch('falloff', distance.positive? ? 'cosine' : 'none').to_s
        unless %w[none cosine].include?(falloff)
          raise ArgumentError, 'sideBlend.falloff is unsupported'
        end

        { 'distance' => distance, 'falloff' => falloff }
      end

      def normalize_expansion(value)
        hash = normalize_hash(value, 'expand_by')
        {
          'x' => normalize_non_negative_number(hash.fetch('x'), 'expand_by.x'),
          'y' => normalize_non_negative_number(hash.fetch('y'), 'expand_by.y')
        }
      end

      def normalize_hash(value, field)
        raise ArgumentError, "#{field} must be a hash" unless value.is_a?(Hash)

        value.transform_keys(&:to_s)
      end

      def normalize_positive_number(value, field)
        number = normalize_number(value, field)
        raise ArgumentError, "#{field} must be positive" unless number.positive?

        number
      end

      def normalize_non_negative_number(value, field)
        number = normalize_number(value, field)
        raise ArgumentError, "#{field} must not be negative" if number.negative?

        number
      end

      def normalize_number(value, field)
        raise ArgumentError, "#{field} must be numeric" unless value.is_a?(Numeric)
        raise ArgumentError, "#{field} must be finite" unless value.finite?

        value.to_f
      end
    end
  end
end
