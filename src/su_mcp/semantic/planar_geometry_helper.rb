# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Shared helpers for simple planar semantic geometry builders.
    module PlanarGeometryHelper
      private

      def add_planar_face(group:, points:, elevation:)
        face = group.entities.add_face(*polygon_points(points, elevation))
        normalize_horizontal_face!(face)
        face
      end

      def polygon_points(points, elevation)
        points.map do |point|
          [point[0].to_f, point[1].to_f, elevation.to_f]
        end
      end

      def normalize_horizontal_face!(face)
        return unless face.respond_to?(:normal) && face.normal.respond_to?(:z)
        return unless face.normal.z.to_f.negative? && face.respond_to?(:reverse!)

        face.reverse!
      end

      def corridor_polygon(points, width)
        half_width = width.to_f / 2.0
        left_side = offset_polyline(points, half_width)
        right_side = offset_polyline(points, -half_width).reverse
        left_side + right_side
      end

      def ellipse_points(center_x:, center_y:, radius_x:, radius_y:, segments: 8)
        angle_step = (Math::PI * 2.0) / segments.to_f
        Array.new(segments) do |index|
          angle = angle_step * index
          [
            center_x + (Math.cos(angle) * radius_x.to_f),
            center_y + (Math.sin(angle) * radius_y.to_f)
          ]
        end
      end

      def square_points(center_x:, center_y:, size:)
        half_size = size.to_f / 2.0
        [
          [center_x - half_size, center_y - half_size],
          [center_x + half_size, center_y - half_size],
          [center_x + half_size, center_y + half_size],
          [center_x - half_size, center_y + half_size]
        ]
      end

      def offset_polyline(points, offset)
        normalized = points.map { |point| [point[0].to_f, point[1].to_f] }
        normalized.each_index.map do |index|
          if index.zero?
            offset_endpoint(
              point: normalized[index],
              direction_start: normalized[index],
              direction_end: normalized[index + 1],
              offset: offset
            )
          elsif index == normalized.length - 1
            offset_endpoint(
              point: normalized[index],
              direction_start: normalized[index - 1],
              direction_end: normalized[index],
              offset: offset
            )
          else
            offset_joint(
              prev_point: normalized[index - 1],
              point: normalized[index],
              next_point: normalized[index + 1],
              offset: offset
            )
          end
        end
      end

      def offset_endpoint(point:, direction_start:, direction_end:, offset:)
        direction = normalize_vector(vector(direction_start, direction_end))
        normal = left_normal(direction)
        [
          point[0] + (normal[0] * offset.to_f),
          point[1] + (normal[1] * offset.to_f)
        ]
      end

      def offset_joint(prev_point:, point:, next_point:, offset:)
        prev_direction = normalize_vector(vector(prev_point, point))
        next_direction = normalize_vector(vector(point, next_point))
        prev_normal = left_normal(prev_direction)
        next_normal = left_normal(next_direction)
        miter = normalize_vector([prev_normal[0] + next_normal[0], prev_normal[1] + next_normal[1]])
        if near_zero_vector?(miter)
          return offset_endpoint(
            point: point,
            direction_start: point,
            direction_end: next_point,
            offset: offset
          )
        end

        denominator = dot_product(miter, next_normal)
        scale = denominator.abs < 1e-6 ? offset.to_f : offset.to_f / denominator
        [
          point[0] + (miter[0] * scale),
          point[1] + (miter[1] * scale)
        ]
      end

      def vector(start_point, end_point)
        [
          end_point[0].to_f - start_point[0].to_f,
          end_point[1].to_f - start_point[1].to_f
        ]
      end

      def normalize_vector(vector)
        length = Math.hypot(vector[0].to_f, vector[1].to_f)
        return [0.0, 0.0] if length.zero?

        [vector[0].to_f / length, vector[1].to_f / length]
      end

      def left_normal(direction)
        [-direction[1].to_f, direction[0].to_f]
      end

      def dot_product(left, right)
        (left[0].to_f * right[0].to_f) + (left[1].to_f * right[1].to_f)
      end

      def near_zero_vector?(vector)
        vector.all? { |value| value.abs < 1e-6 }
      end
    end
  end
end
