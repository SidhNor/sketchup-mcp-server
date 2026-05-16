# frozen_string_literal: true

module SU_MCP
  module StagedAssets
    # Builds orientation-aware transform matrices without touching SketchUp entities.
    class AssetOrientationTransformBuilder
      IDENTITY_MATRIX = [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
      ].freeze

      def build(source_transform:, origin:, orientation:)
        source_matrix = matrix_for(source_transform)
        frame_matrix = oriented_matrix(source_matrix, orientation)
        frame_matrix[12] = origin.x
        frame_matrix[13] = origin.y
        frame_matrix[14] = origin.z
        frame_matrix[15] = 1.0

        { matrix: frame_matrix, evidence: orientation_evidence(orientation) }
      end

      def build_sketchup_transform(source_transform:, origin:, orientation:)
        result = build(
          source_transform: source_transform,
          origin: origin,
          orientation: orientation
        )
        transform = Geom::Transformation.new(result.fetch(:matrix))
        return transform if usable_transform?(transform)

        nil
      rescue ArgumentError, TypeError
        nil
      end

      private

      def matrix_for(source_transform)
        values = source_transform.to_a if source_transform.respond_to?(:to_a)
        return values.map(&:to_f) if values.is_a?(Array) && values.length == 16

        IDENTITY_MATRIX.dup
      end

      def oriented_matrix(source_matrix, orientation)
        if orientation[:mode] == 'surface_aligned'
          return surface_aligned_matrix(source_matrix, orientation)
        end
        if orientation[:yawDegrees].nil? && !orientation.fetch(:explicit, true)
          return source_matrix.dup
        end

        upright_matrix(source_matrix, orientation)
      end

      def upright_matrix(source_matrix, orientation)
        heading = orientation[:yawDegrees] || source_heading_degrees(source_matrix)
        apply_axis_scales(
          yaw_matrix(heading.to_f),
          source_axis_lengths(source_matrix)
        )
      end

      def surface_aligned_matrix(source_matrix, orientation)
        frame = orientation.fetch(:surfaceFrame)
        aligned = multiply_axes(
          model_up_to_surface_up_matrix(frame.fetch(:up_axis)),
          source_matrix
        )
        return aligned if orientation[:yawDegrees].nil?

        yaw_delta = orientation.fetch(:yawDegrees).to_f - source_heading_degrees(source_matrix)
        multiply_axes(rotation_around_axis(frame.fetch(:up_axis), yaw_delta), aligned)
      end

      def axes_to_matrix(x_axis, y_axis, z_axis)
        [
          x_axis[0], x_axis[1], x_axis[2], 0.0,
          y_axis[0], y_axis[1], y_axis[2], 0.0,
          z_axis[0], z_axis[1], z_axis[2], 0.0,
          0.0, 0.0, 0.0, 1.0
        ].map(&:to_f)
      end

      def yaw_matrix(degrees)
        radians = degrees * Math::PI / 180.0
        cos = Math.cos(radians)
        sin = Math.sin(radians)
        [
          cos, sin, 0.0, 0.0,
          -sin, cos, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0
        ]
      end

      def rotation_around_axis(axis, degrees)
        x_axis, y_axis, z_axis = normalize(axis)
        cos, sin, one_minus_cos = rotation_terms(degrees)

        rotation_matrix_from_terms(x_axis, y_axis, z_axis, cos, sin, one_minus_cos)
      end

      def model_up_to_surface_up_matrix(up_axis)
        normalized_up = normalize(up_axis)
        axis = cross([0.0, 0.0, 1.0], normalized_up)
        axis_length = magnitude(axis)
        return IDENTITY_MATRIX.dup if axis_length <= Float::EPSILON

        dot = normalized_up[2].clamp(-1.0, 1.0)
        angle_degrees = Math.atan2(axis_length, dot) * 180.0 / Math::PI
        rotation_around_axis(axis, angle_degrees)
      end

      def rotation_terms(degrees)
        radians = degrees * Math::PI / 180.0
        cos = Math.cos(radians)
        [cos, Math.sin(radians), 1.0 - cos]
      end

      def rotation_matrix_from_terms(x_axis, y_axis, z_axis, cos, sin, one_minus_cos)
        rotation_x_axis(x_axis, y_axis, z_axis, cos, sin, one_minus_cos) +
          rotation_y_axis(x_axis, y_axis, z_axis, cos, sin, one_minus_cos) +
          rotation_z_axis(x_axis, y_axis, z_axis, cos, sin, one_minus_cos) +
          [0.0, 0.0, 0.0, 1.0]
      end

      def rotation_x_axis(x_axis, y_axis, z_axis, cos, sin, one_minus_cos)
        [
          cos + (x_axis * x_axis * one_minus_cos),
          (x_axis * y_axis * one_minus_cos) + (z_axis * sin),
          (x_axis * z_axis * one_minus_cos) - (y_axis * sin),
          0.0
        ]
      end

      def rotation_y_axis(x_axis, y_axis, z_axis, cos, sin, one_minus_cos)
        [
          (y_axis * x_axis * one_minus_cos) - (z_axis * sin),
          cos + (y_axis * y_axis * one_minus_cos),
          (y_axis * z_axis * one_minus_cos) + (x_axis * sin),
          0.0
        ]
      end

      def rotation_z_axis(x_axis, y_axis, z_axis, cos, sin, one_minus_cos)
        [
          (z_axis * x_axis * one_minus_cos) + (y_axis * sin),
          (z_axis * y_axis * one_minus_cos) - (x_axis * sin),
          cos + (z_axis * z_axis * one_minus_cos),
          0.0
        ]
      end

      def multiply_axes(left, right)
        result = IDENTITY_MATRIX.dup
        3.times do |row|
          3.times do |column|
            result[(column * 4) + row] =
              (left[row] * right[column * 4]) +
              (left[4 + row] * right[(column * 4) + 1]) +
              (left[8 + row] * right[(column * 4) + 2])
          end
        end
        result
      end

      def source_heading_degrees(source_matrix)
        x_axis = source_matrix.first(3)
        return 0.0 if Math.sqrt((x_axis[0]**2) + (x_axis[1]**2)) <= Float::EPSILON

        Math.atan2(x_axis[1], x_axis[0]) * 180.0 / Math::PI
      end

      def source_axis_lengths(source_matrix)
        [0, 4, 8].map do |start_index|
          axis = source_matrix[start_index, 3]
          length = Math.sqrt(axis.sum { |component| component * component })
          length.zero? ? 1.0 : length
        end
      end

      def apply_axis_scales(matrix, scales)
        matrix.dup.tap do |scaled|
          [0, 4, 8].each_with_index do |start_index, scale_index|
            3.times do |offset|
              scaled[start_index + offset] *= scales.fetch(scale_index)
            end
          end
        end
      end

      def normalize(vector)
        magnitude = Math.sqrt(vector.sum { |component| component.to_f * component.to_f })
        return [0.0, 0.0, 1.0] if magnitude.zero?

        vector.map { |component| component.to_f / magnitude }
      end

      def magnitude(vector)
        Math.sqrt(vector.sum { |component| component.to_f * component.to_f })
      end

      def cross(first, second)
        [
          (first[1] * second[2]) - (first[2] * second[1]),
          (first[2] * second[0]) - (first[0] * second[2]),
          (first[0] * second[1]) - (first[1] * second[0])
        ]
      end

      def usable_transform?(transform)
        return false unless transform
        return true unless transform.respond_to?(:origin)

        origin = transform.origin
        origin.respond_to?(:x) && !origin.x.nil?
      end

      def orientation_evidence(orientation)
        evidence = {
          mode: orientation.fetch(:mode),
          yawDegrees: orientation[:yawDegrees],
          sourceHeadingPreserved: orientation.fetch(:sourceHeadingPreserved)
        }
        if orientation[:mode] == 'surface_aligned'
          evidence[:surface] = orientation.fetch(:surfaceFrame).fetch(:evidence)
        end
        evidence
      end
    end
  end
end
