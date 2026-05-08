# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Bilinear terrain-grid stencil weights for public XY survey coordinates.
    class SurveyBilinearStencil
      def initialize(state)
        @state = state
      end

      def weights_for(point)
        cells_for(corners_for(grid_coordinate(point)))
      end

      private

      attr_reader :state

      def grid_coordinate(point)
        {
          x: (point.fetch('x').to_f - state.origin.fetch('x')) / state.spacing.fetch('x'),
          y: (point.fetch('y').to_f - state.origin.fetch('y')) / state.spacing.fetch('y')
        }
      end

      def corners_for(grid)
        left = grid.fetch(:x).floor.clamp(0, columns - 1)
        top = grid.fetch(:y).floor.clamp(0, rows - 1)
        right = (left + 1).clamp(0, columns - 1)
        bottom = (top + 1).clamp(0, rows - 1)
        {
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          x_ratio: right == left ? 0.0 : grid.fetch(:x) - left,
          y_ratio: bottom == top ? 0.0 : grid.fetch(:y) - top
        }
      end

      def cells_for(corners)
        cells(corners).each_with_object(Hash.new(0.0)) do |(index, weight), weights|
          weights[index] += weight
        end
      end

      def cells(corners)
        left = corners.fetch(:left)
        top = corners.fetch(:top)
        right = corners.fetch(:right)
        bottom = corners.fetch(:bottom)
        x_ratio = corners.fetch(:x_ratio)
        y_ratio = corners.fetch(:y_ratio)
        [
          [(top * columns) + left, (1.0 - x_ratio) * (1.0 - y_ratio)],
          [(top * columns) + right, x_ratio * (1.0 - y_ratio)],
          [(bottom * columns) + left, (1.0 - x_ratio) * y_ratio],
          [(bottom * columns) + right, x_ratio * y_ratio]
        ]
      end

      def columns
        state.dimensions.fetch('columns')
      end

      def rows
        state.dimensions.fetch('rows')
      end
    end
  end
end
