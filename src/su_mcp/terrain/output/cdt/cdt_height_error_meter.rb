# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Measures reconstructed CDT mesh height error against every source heightmap sample.
    class CdtHeightErrorMeter # rubocop:disable Metrics/ClassLength
      BARYCENTRIC_EPSILON = 1e-6
      DEGENERATE_EPSILON = 1e-12
      UNCOVERED_SAMPLE_ERROR = 1.0e30

      def max_error(state:, mesh:)
        worst_samples(state: state, mesh: mesh, limit: 1)
          .fetch(0, { error: 0.0 })
          .fetch(:error)
      end

      def worst_samples(state:, mesh:, limit:)
        spatial_index = triangle_spatial_index(state, mesh)
        samples = []
        (0...rows(state)).each do |row|
          (0...columns(state)).each do |column|
            samples << sample_error(state, mesh, spatial_index, column, row)
          end
        end
        samples.sort_by do |sample|
          [-sample.fetch(:error), sample.fetch(:row), sample.fetch(:column)]
        end.first(limit)
      end

      def worst_samples_with_local_tolerance(state:, mesh:, limit:, base_tolerance:,
                                             feature_geometry:)
        spatial_index = triangle_spatial_index(state, mesh)
        samples = []
        (0...rows(state)).each do |row|
          (0...columns(state)).each do |column|
            sample = sample_error(state, mesh, spatial_index, column, row)
            tolerance = local_tolerance_for_sample(
              state, feature_geometry, base_tolerance.to_f, sample
            )
            samples << sample.merge(
              localTolerance: tolerance,
              residualExcess: sample.fetch(:error) - tolerance
            )
          end
        end
        distributed_samples(
          samples.select { |sample| sample.fetch(:residualExcess).positive? },
          limit,
          state
        )
      end

      private

      def distributed_samples(samples, limit, state)
        sorted = samples.sort_by { |sample| residual_sort_key(sample) }
        selected = []
        selected_keys = {}
        sorted.group_by { |sample| bucket_key(state, sample) }.each_value do |bucket_samples|
          sample = bucket_samples.min_by { |item| residual_sort_key(item) }
          selected << sample
          selected_keys[[sample.fetch(:column), sample.fetch(:row)]] = true
          break if selected.length >= limit
        end
        sorted.each do |sample|
          break if selected.length >= limit

          key = [sample.fetch(:column), sample.fetch(:row)]
          next if selected_keys[key]

          selected << sample
          selected_keys[key] = true
        end
        selected.sort_by { |sample| residual_sort_key(sample) }
      end

      def residual_sort_key(sample)
        [-sample.fetch(:residualExcess), -sample.fetch(:error), sample.fetch(:row),
         sample.fetch(:column)]
      end

      def bucket_key(state, sample)
        bucket_columns = [(columns(state) / 4.0).ceil, 1].max
        bucket_rows = [(rows(state) / 4.0).ceil, 1].max
        [sample.fetch(:column) / bucket_columns, sample.fetch(:row) / bucket_rows]
      end

      def local_tolerance_for_sample(state, feature_geometry, base_tolerance, sample)
        tolerance = base_tolerance
        tolerance *= 0.75 if soft_influence_at?(state, feature_geometry, sample)
        tolerance *= 0.5 if firm_influence_at?(state, feature_geometry, sample)
        tolerance *= 0.25 if hard_influence_at?(state, feature_geometry, sample)
        [tolerance, base_tolerance * 0.1].max
      end

      def hard_influence_at?(state, feature_geometry, sample)
        point = sample.fetch(:point)
        anchor_at_sample?(state, feature_geometry, point) ||
          feature_geometry.protected_regions.any? do |region|
            region.fetch('primitive', nil) == 'rectangle' &&
              point_in_bounds?(point, normalize_bounds(region.fetch('ownerLocalBounds')))
          end
      end

      def firm_influence_at?(state, feature_geometry, sample)
        return true if affected_window_at?(feature_geometry, sample)

        influencing_item_at?(state, feature_geometry, sample.fetch(:point), 'firm')
      end

      def soft_influence_at?(state, feature_geometry, sample)
        influencing_item_at?(state, feature_geometry, sample.fetch(:point), 'soft')
      end

      def influencing_item_at?(state, feature_geometry, point, strength)
        feature_geometry.pressure_regions.any? do |item|
          item.fetch('strength', nil) == strength && item_influences_point?(state, item, point)
        end || feature_geometry.reference_segments.any? do |item|
          item.fetch('strength', nil) == strength && item_influences_point?(state, item, point)
        end
      end

      def anchor_at_sample?(state, feature_geometry, point)
        threshold = nominal_spacing(state) * 0.5
        feature_geometry.output_anchor_candidates.any? do |anchor|
          xy_distance(anchor.fetch('ownerLocalPoint'), point) <= threshold
        end
      end

      def affected_window_at?(feature_geometry, sample)
        feature_geometry.affected_windows.any? do |window|
          sample.fetch(:column).between?(window.fetch('minCol'), window.fetch('maxCol')) &&
            sample.fetch(:row).between?(window.fetch('minRow'), window.fetch('maxRow'))
        end
      end

      def item_influences_point?(state, item, point)
        if item.key?('ownerLocalStart')
          return reference_segment_influences_point?(state, item, point)
        end

        case item.fetch('primitive', nil)
        when 'rectangle'
          point_in_bounds?(point, normalize_bounds(item.fetch('ownerLocalShape')))
        when 'circle'
          point_in_circle?(point, item.fetch('ownerLocalShape'))
        when 'corridor'
          point_in_corridor?(point, item.fetch('ownerLocalShape'))
        else
          false
        end
      end

      def reference_segment_influences_point?(state, segment, point)
        distance_to_segment(point, segment.fetch('ownerLocalStart'),
                            segment.fetch('ownerLocalEnd')) <= nominal_spacing(state)
      end

      def point_in_corridor?(point, shape)
        radius = (shape.fetch('width', 0.0).to_f / 2.0) + shape.fetch('blendDistance', 0.0).to_f
        shape.fetch('centerline').each_cons(2).any? do |start_point, end_point|
          distance_to_segment(point, start_point, end_point) <= radius
        end
      end

      def point_in_circle?(point, circle)
        cx, cy, radius = circle
        ((point[0] - cx)**2) + ((point[1] - cy)**2) <= radius.to_f**2
      end

      def point_in_bounds?(point, bounds)
        point[0].between?(bounds.fetch(:min_x), bounds.fetch(:max_x)) &&
          point[1].between?(bounds.fetch(:min_y), bounds.fetch(:max_y))
      end

      def normalize_bounds(points)
        xs = points.map(&:first)
        ys = points.map { |point| point[1] }
        { min_x: xs.min, min_y: ys.min, max_x: xs.max, max_y: ys.max }
      end

      def distance_to_segment(point, start_point, end_point)
        dx = end_point[0] - start_point[0]
        dy = end_point[1] - start_point[1]
        length_squared = (dx * dx) + (dy * dy)
        return xy_distance(point, start_point) if length_squared.zero?

        ratio =
          (((point[0] - start_point[0]) * dx) + ((point[1] - start_point[1]) * dy)) /
          length_squared
        clamped = ratio.clamp(0.0, 1.0)
        projection = [start_point[0] + (dx * clamped), start_point[1] + (dy * clamped)]
        xy_distance(point, projection)
      end

      def xy_distance(first, second)
        dx = first[0] - second[0]
        dy = first[1] - second[1]
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def sample_error(state, mesh, spatial_index, column, row)
        x = x_at(state, column)
        y = y_at(state, row)
        actual = mesh_height_at(mesh, spatial_index, x, y, column, row)
        expected = elevation_at(state, column, row)
        error = actual ? (expected - actual).abs : UNCOVERED_SAMPLE_ERROR
        {
          column: column,
          row: row,
          point: [x, y],
          expected: expected,
          actual: actual,
          error: error
        }
      end

      def mesh_height_at(mesh, spatial_index, x, y, column, row)
        candidate_triangles(spatial_index, column, row).each do |triangle|
          height = triangle_height_at(mesh, triangle, x, y)
          return height if height
        end
        nil
      end

      def triangle_height_at(mesh, triangle, x, y)
        point_a, point_b, point_c = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        weights = barycentric_weights(point_a, point_b, point_c, x, y)
        return nil unless weights
        return nil unless weights.all? { |weight| covered_weight?(weight) }

        (weights[0] * point_a[2]) + (weights[1] * point_b[2]) + (weights[2] * point_c[2])
      end

      def triangle_spatial_index(state, mesh)
        column_count = columns(state)
        buckets = Array.new(column_count * rows(state))
        mesh.fetch(:triangles).each do |triangle|
          triangle_bucket_bounds(state, mesh, triangle).then do |min_column, min_row, max_column,
                                                                max_row|
            (min_row..max_row).each do |row|
              (min_column..max_column).each do |column|
                index = (row * column_count) + column
                (buckets[index] ||= []) << triangle
              end
            end
          end
        end
        { buckets: buckets, columns: column_count, fallback: mesh.fetch(:triangles) }
      end

      def candidate_triangles(spatial_index, column, row)
        index = (row * spatial_index.fetch(:columns)) + column
        spatial_index.fetch(:buckets).fetch(index) || spatial_index.fetch(:fallback)
      end

      def triangle_bucket_bounds(state, mesh, triangle)
        bounds = triangle_xy_bounds(state, mesh, triangle)
        [
          clamped_column(state, bounds.fetch(:min_x).floor),
          clamped_row(state, bounds.fetch(:min_y).floor),
          clamped_column(state, bounds.fetch(:max_x).ceil),
          clamped_row(state, bounds.fetch(:max_y).ceil)
        ]
      end

      def triangle_xy_bounds(state, mesh, triangle)
        points = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        xs = points.map { |point| column_for_x(state, point.fetch(0)) }
        ys = points.map { |point| row_for_y(state, point.fetch(1)) }
        { min_x: xs.min, min_y: ys.min, max_x: xs.max, max_y: ys.max }
      end

      def clamped_column(state, column)
        column.clamp(0, columns(state) - 1)
      end

      def clamped_row(state, row)
        row.clamp(0, rows(state) - 1)
      end

      def covered_weight?(weight)
        weight.between?(-BARYCENTRIC_EPSILON, 1.0 + BARYCENTRIC_EPSILON)
      end

      def barycentric_weights(point_a, point_b, point_c, x, y)
        denominator = barycentric_denominator(point_a, point_b, point_c)
        return nil if denominator.abs <= DEGENERATE_EPSILON

        first = barycentric_first_weight(point_a, point_b, point_c, x, y, denominator)
        second = barycentric_second_weight(point_a, point_b, point_c, x, y, denominator)
        [first, second, 1.0 - first - second]
      end

      def barycentric_denominator(point_a, point_b, point_c)
        ((point_b[1] - point_c[1]) * (point_a[0] - point_c[0])) +
          ((point_c[0] - point_b[0]) * (point_a[1] - point_c[1]))
      end

      def barycentric_first_weight(_point_a, point_b, point_c, x, y, denominator)
        (((point_b[1] - point_c[1]) * (x - point_c[0])) +
          ((point_c[0] - point_b[0]) * (y - point_c[1]))) / denominator
      end

      def barycentric_second_weight(point_a, _point_b, point_c, x, y, denominator)
        (((point_c[1] - point_a[1]) * (x - point_c[0])) +
          ((point_a[0] - point_c[0]) * (y - point_c[1]))) / denominator
      end

      def columns(state)
        state.dimensions.fetch('columns')
      end

      def rows(state)
        state.dimensions.fetch('rows')
      end

      def x_at(state, column)
        state.origin.fetch('x') + (column * state.spacing.fetch('x'))
      end

      def y_at(state, row)
        state.origin.fetch('y') + (row * state.spacing.fetch('y'))
      end

      def column_for_x(state, x)
        (x - state.origin.fetch('x')) / state.spacing.fetch('x')
      end

      def row_for_y(state, y)
        (y - state.origin.fetch('y')) / state.spacing.fetch('y')
      end

      def nominal_spacing(state)
        [state.spacing.fetch('x').to_f, state.spacing.fetch('y').to_f].max
      end

      def elevation_at(state, column, row)
        state.elevations.fetch((row * columns(state)) + column)
      end
    end
  end
end
