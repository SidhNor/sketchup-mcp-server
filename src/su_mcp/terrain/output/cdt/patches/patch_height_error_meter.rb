# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Measures reconstructed mesh height error against samples inside one patch domain.
    class PatchHeightErrorMeter
      DEGENERATE_EPSILON = 1e-12
      WORST_SAMPLE_LIMIT = 256

      def measure(state:, domain:, mesh:, base_tolerance:, feature_geometry:, samples: nil)
        _ = [state, base_tolerance, feature_geometry]
        source_samples = samples || domain.each_sample.map { |column, row| [column, row] }
        rows = source_samples.map do |column, row|
          sample_error(domain, mesh, column, row)
        end
        errors = rows.map { |row| row.fetch(:error) }
        {
          maxHeightError: errors.max || 0.0,
          rmsError: rms(errors),
          p95Error: percentile(errors, 0.95),
          denseRatio: dense_ratio(domain, mesh),
          scanSampleCount: rows.length,
          worstSamples: rows.sort_by do |row|
            [-row.fetch(:error), row.fetch(:row), row.fetch(:column)]
          end.first(WORST_SAMPLE_LIMIT)
        }
      end

      private

      def sample_error(domain, mesh, column, row)
        x = domain.x_at(column)
        y = domain.y_at(row)
        actual = mesh_height_at(mesh, x, y)
        expected = domain.elevation_at(column, row)
        {
          sample: [column, row],
          column: column,
          row: row,
          point: [x, y],
          expected: expected,
          actual: actual,
          error: actual ? (expected - actual).abs : 1.0e30
        }
      end

      def mesh_height_at(mesh, x, y)
        mesh.fetch(:triangles).each do |triangle|
          height = triangle_height_at(mesh, triangle, x, y)
          return height if height
        end
        nil
      end

      def triangle_height_at(mesh, triangle, x, y)
        points = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        weights = barycentric_weights(points, x, y)
        return nil unless weights
        return nil unless weights.all? { |weight| weight.between?(-1e-6, 1.0 + 1e-6) }

        (weights[0] * points[0][2]) + (weights[1] * points[1][2]) + (weights[2] * points[2][2])
      end

      # rubocop:disable Metrics/AbcSize
      def barycentric_weights(points, x, y)
        a, b, c = points
        denominator = ((b[1] - c[1]) * (a[0] - c[0])) + ((c[0] - b[0]) * (a[1] - c[1]))
        return nil if denominator.abs <= DEGENERATE_EPSILON

        first = (((b[1] - c[1]) * (x - c[0])) + ((c[0] - b[0]) * (y - c[1]))) / denominator
        second = (((c[1] - a[1]) * (x - c[0])) + ((a[0] - c[0]) * (y - c[1]))) / denominator
        [first, second, 1.0 - first - second]
      end
      # rubocop:enable Metrics/AbcSize

      def rms(errors)
        return 0.0 if errors.empty?

        Math.sqrt(errors.sum { |error| error * error } / errors.length)
      end

      def percentile(errors, ratio)
        return 0.0 if errors.empty?

        sorted = errors.sort
        sorted.fetch(((sorted.length - 1) * ratio).ceil)
      end

      def dense_ratio(domain, mesh)
        dense = domain.dense_equivalent_face_count
        return 0.0 if dense.zero?

        mesh.fetch(:triangles).length.to_f / dense
      end
    end
  end
end
