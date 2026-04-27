# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Complete survey-point grids define a piecewise bilinear regional residual field.
    class SurveyGridResidualField
      def initialize(context:, residuals:)
        @context = context
        @residuals = residuals
      end

      def seed
        return nil unless model && covers_mutable_samples?

        context.state.elevations.each_with_index.map do |height, index|
          sample = context.sample_for(index)
          next height unless context.mutable_sample?(sample)

          height + value_at(sample.fetch(:coordinate))
        end
      end

      private

      attr_reader :context, :residuals

      def model
        @model ||= build_model
      end

      def build_model
        x_values = axis_values('x')
        y_values = axis_values('y')
        return nil if x_values.length < 2 || y_values.length < 2

        values = residual_values
        return nil unless complete_grid?(x_values, y_values, values)

        { x_values: x_values, y_values: y_values, values: values }
      end

      def axis_values(axis)
        residuals.map { |residual| residual.fetch(:point).fetch(axis).to_f }.uniq.sort
      end

      def residual_values
        residuals.each_with_object({}) do |residual, values|
          point = residual.fetch(:point)
          values[[point.fetch('x').to_f, point.fetch('y').to_f]] = residual.fetch(:residual)
        end
      end

      def complete_grid?(x_values, y_values, values)
        x_values.all? do |x_value|
          y_values.all? { |y_value| values.key?([x_value, y_value]) }
        end
      end

      def covers_mutable_samples?
        x_range = model.fetch(:x_values).first..model.fetch(:x_values).last
        y_range = model.fetch(:y_values).first..model.fetch(:y_values).last
        context.each_sample.all? do |sample|
          !context.mutable_sample?(sample) || sample_inside?(sample, x_range, y_range)
        end
      end

      def sample_inside?(sample, x_range, y_range)
        coordinate = sample.fetch(:coordinate)
        x_range.cover?(coordinate.fetch('x').to_f) &&
          y_range.cover?(coordinate.fetch('y').to_f)
      end

      def value_at(coordinate)
        x_pair = bracket_values(model.fetch(:x_values), coordinate.fetch('x').to_f)
        y_pair = bracket_values(model.fetch(:y_values), coordinate.fetch('y').to_f)
        bilinear_value(x_pair, y_pair, coordinate)
      end

      def bracket_values(values, coordinate)
        return [values.first, values.first] if coordinate <= values.first

        values.each_cons(2).find do |left, right|
          coordinate.between?(left, right)
        end || [values.last, values.last]
      end

      def bilinear_value(x_pair, y_pair, coordinate)
        left, right = x_pair
        bottom, top = y_pair
        x_ratio = interpolation_ratio(coordinate.fetch('x').to_f, left, right)
        y_ratio = interpolation_ratio(coordinate.fetch('y').to_f, bottom, top)
        lower = interpolate(grid_value(left, bottom), grid_value(right, bottom), x_ratio)
        upper = interpolate(grid_value(left, top), grid_value(right, top), x_ratio)
        interpolate(lower, upper, y_ratio)
      end

      def grid_value(x_value, y_value)
        model.fetch(:values).fetch([x_value, y_value])
      end

      def interpolation_ratio(value, lower, upper)
        return 0.0 if lower == upper

        (value - lower) / (upper - lower)
      end

      def interpolate(lower, upper, ratio)
        lower + ((upper - lower) * ratio)
      end
    end
  end
end
