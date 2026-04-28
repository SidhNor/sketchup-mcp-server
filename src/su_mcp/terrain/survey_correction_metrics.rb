# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Computes terrain-shape metrics used by public survey correction evidence.
    class SurveyCorrectionMetrics
      REGIONAL_NORMALIZED_RESIDUAL_RANGE_LIMIT = 2.0
      REGIONAL_SLOPE_INCREASE_LIMIT = 6.0
      REGIONAL_CURVATURE_INCREASE_LIMIT = 12.0

      def initialize(context:, after_elevations:, solver_metrics:)
        @context = context
        @after_elevations = after_elevations
        @solver_metrics = solver_metrics
      end

      def to_h
        shape = shape_metrics
        {
          max_sample_delta: max_sample_delta,
          slope_proxy: shape.fetch(:slope_proxy),
          curvature_proxy: shape.fetch(:curvature_proxy),
          preserve_zone_drift: context.preserve_zone_drift(after_elevations),
          regional_coherence: regional_coherence(shape),
          detail_preservation: detail_preservation,
          detail_suppression: detail_suppression
        }
      end

      private

      attr_reader :context, :after_elevations, :solver_metrics

      def shape_metrics
        {
          slope_proxy: proxy_summary(slope_values(before), slope_values(after_elevations)),
          curvature_proxy: proxy_summary(
            curvature_values(before),
            curvature_values(after_elevations)
          )
        }
      end

      def detail_preservation
        solver_metrics.fetch(:detailRetention, { outsideInfluenceRatio: 1.0 })
      end

      def detail_suppression
        solver_metrics.fetch(:detailSuppression, { coreEnergy: 0.0, blendEnergy: 0.0 })
      end

      def regional_coherence(shape)
        return { status: 'not_applicable' } unless context.regional?

        residual_range = survey_residual_range
        footprint_length = support_footprint_length
        normalized_range = normalized_residual_range_for(residual_range, footprint_length)
        slope = shape.fetch(:slope_proxy)
        curvature = shape.fetch(:curvature_proxy)
        safe = regional_safe?(normalized_range, slope, curvature)
        {
          status: safe ? 'satisfied' : 'unsafe',
          surveyResidualRange: residual_range,
          supportFootprintLength: footprint_length,
          normalizedSurveyResidualRange: normalized_range,
          slopeMaxIncrease: slope.fetch(:maxIncrease),
          curvatureMaxIncrease: curvature.fetch(:maxIncrease)
        }
      end

      def regional_safe?(normalized_residual_range, slope, curvature)
        normalized_residual_range <= REGIONAL_NORMALIZED_RESIDUAL_RANGE_LIMIT &&
          slope.fetch(:maxIncrease) <= REGIONAL_SLOPE_INCREASE_LIMIT &&
          curvature.fetch(:maxIncrease) <= REGIONAL_CURVATURE_INCREASE_LIMIT
      end

      def survey_residual_range
        residuals = context.survey_points.map do |survey_point|
          point = context.point_for(survey_point)
          point.fetch('z') - context.interpolate(before, point)
        end
        return 0.0 if residuals.empty?

        residuals.max - residuals.min
      end

      def support_footprint_length
        samples = context.each_sample.select { |sample| context.mutable_sample?(sample) }
        x_values = samples.map { |sample| sample.fetch(:coordinate).fetch('x').to_f }
        y_values = samples.map { |sample| sample.fetch(:coordinate).fetch('y').to_f }
        [
          axis_range(x_values),
          axis_range(y_values),
          context.state.spacing.fetch('x'),
          context.state.spacing.fetch('y')
        ].max
      end

      def normalized_residual_range_for(residual_range, footprint_length)
        residual_range / footprint_length
      end

      def axis_range(values)
        return 0.0 if values.empty?

        values.max - values.min
      end

      def max_sample_delta
        before.zip(after_elevations).map do |before_height, after_height|
          (after_height - before_height).abs
        end.max || 0.0
      end

      def slope_values(elevations)
        adjacent_pairs.map do |first, second, spacing|
          (elevations.fetch(second) - elevations.fetch(first)).abs / spacing
        end
      end

      def curvature_values(elevations)
        curvature_triplets.map do |first, middle, last, spacing|
          numerator = elevations.fetch(first) - (2.0 * elevations.fetch(middle)) +
                      elevations.fetch(last)
          numerator.abs / (spacing**2)
        end
      end

      def adjacent_pairs
        each_grid_index.flat_map do |column, row, index|
          adjacent_pairs_for(column, row, index)
        end
      end

      def adjacent_pairs_for(column, row, index)
        pairs = []
        pairs << [index, index + 1, context.state.spacing.fetch('x')] if column < columns - 1
        pairs << [index, index + columns, context.state.spacing.fetch('y')] if row < rows - 1
        pairs
      end

      def curvature_triplets
        horizontal_curvature_triplets + vertical_curvature_triplets
      end

      def horizontal_curvature_triplets
        (0...rows).flat_map do |row|
          (1...(columns - 1)).map do |column|
            index = (row * columns) + column
            [index - 1, index, index + 1, context.state.spacing.fetch('x')]
          end
        end
      end

      def vertical_curvature_triplets
        (1...(rows - 1)).flat_map do |row|
          (0...columns).map do |column|
            index = (row * columns) + column
            [index - columns, index, index + columns, context.state.spacing.fetch('y')]
          end
        end
      end

      def proxy_summary(before_values, after_values)
        before_max = before_values.max || 0.0
        after_max = after_values.max || 0.0
        {
          beforeMax: before_max,
          afterMax: after_max,
          maxIncrease: [after_max - before_max, 0.0].max
        }
      end

      def each_grid_index
        (0...rows).flat_map do |row|
          (0...columns).map { |column| [column, row, (row * columns) + column] }
        end
      end

      def before
        context.state.elevations
      end

      def columns
        context.state.dimensions.fetch('columns')
      end

      def rows
        context.state.dimensions.fetch('rows')
      end
    end
  end
end
