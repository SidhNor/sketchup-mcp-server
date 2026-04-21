# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Extracted geometry and numeric validation mechanics for semantic requests.
    class GeometryValidator
      def invalid_polygon?(footprint)
        normalized = normalize_polygon(footprint)
        return true if normalized.nil?
        return true if normalized.length < 3 || normalized.uniq.length < 3

        consecutive_duplicate_points?(normalized) ||
          self_intersecting_polygon?(normalized) ||
          polygon_area(normalized).zero?
      end

      def invalid_polyline?(points)
        normalized = normalize_polyline(points)
        return true if normalized.nil?
        return true if consecutive_duplicate_points?(normalized)

        normalized.uniq.length < 2
      end

      def invalid_positive_number?(value)
        !finite_numeric?(value) || value.to_f <= 0
      end

      def finite_numeric?(value)
        value.is_a?(Numeric) && value.finite?
      end

      private

      def normalize_polygon(footprint)
        return nil unless footprint.is_a?(Array)

        points = footprint.map { |point| normalize_xy_point(point) }
        return nil if points.any?(&:nil?)

        remove_repeated_closing_point(points)
      end

      def normalize_polyline(points)
        return nil unless points.is_a?(Array)

        normalized = points.map { |point| normalize_xy_point(point) }
        return nil if normalized.any?(&:nil?)

        normalized
      end

      def normalize_xy_point(point)
        values = Array(point).first(2)
        return nil unless values.length == 2
        return nil unless values.all? { |value| finite_numeric?(value) }

        values.map(&:to_f)
      end

      def remove_repeated_closing_point(points)
        return points unless points.length > 1 && points.first == points.last

        points[0...-1]
      end

      def consecutive_duplicate_points?(points)
        points.each_cons(2).any? { |left, right| left == right }
      end

      def polygon_area(points)
        wrapped_points = points + [points.first]
        area_sum = wrapped_points.each_cons(2).sum do |(x1, y1), (x2, y2)|
          (x1 * y2) - (x2 * y1)
        end

        (area_sum / 2.0).abs
      end

      def self_intersecting_polygon?(points)
        edges(points).each_with_index.any? do |first_edge, first_index|
          edges(points).each_with_index.any? do |second_edge, second_index|
            next false if first_index >= second_index
            next false if adjacent_edges?(points.length, first_index, second_index)

            segments_intersect?(first_edge, second_edge)
          end
        end
      end

      def edges(points)
        wrapped_points = points + [points.first]
        wrapped_points.each_cons(2).to_a
      end

      def adjacent_edges?(point_count, first_index, second_index)
        second_index == first_index + 1 || (first_index.zero? && second_index == point_count - 1)
      end

      def segments_intersect?(first_edge, second_edge)
        first_start, first_end = first_edge
        second_start, second_end = second_edge

        first_orientation_start = orientation(first_start, first_end, second_start)
        first_orientation_end = orientation(first_start, first_end, second_end)
        second_orientation_start = orientation(second_start, second_end, first_start)
        second_orientation_end = orientation(second_start, second_end, first_end)

        return true if first_orientation_start != first_orientation_end &&
                       second_orientation_start != second_orientation_end
        return on_segment?(first_start, second_start, first_end) if first_orientation_start.zero?
        return on_segment?(first_start, second_end, first_end) if first_orientation_end.zero?
        return on_segment?(second_start, first_start, second_end) if second_orientation_start.zero?
        return on_segment?(second_start, first_end, second_end) if second_orientation_end.zero?

        false
      end

      def orientation(point_a, point_b, point_c)
        value = ((point_b[1] - point_a[1]) * (point_c[0] - point_b[0])) -
                ((point_b[0] - point_a[0]) * (point_c[1] - point_b[1]))
        return 0 if value.zero?

        value.positive? ? 1 : -1
      end

      def on_segment?(point_a, point_b, point_c)
        point_b[0].between?([point_a[0], point_c[0]].min, [point_a[0], point_c[0]].max) &&
          point_b[1].between?([point_a[1], point_c[1]].min, [point_a[1], point_c[1]].max)
      end
    end
  end
end
