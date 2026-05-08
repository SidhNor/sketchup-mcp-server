# frozen_string_literal: true

require_relative 'survey_bilinear_stencil'

module SU_MCP
  module Terrain
    # Read-only bilinear elevation sampler for owner-local public-meter terrain state.
    class TerrainStateElevationSampler
      def initialize(state)
        @state = state
        @stencil = SurveyBilinearStencil.new(state)
      end

      def inside_bounds?(point)
        grid = grid_coordinate(point)
        grid.fetch(:x).between?(0.0, columns - 1) &&
          grid.fetch(:y).between?(0.0, rows - 1)
      end

      def elevation_at(point)
        return nil unless inside_bounds?(point)

        weights = stencil.weights_for(point)
        return nil if weights.any? do |index, weight|
          weight.positive? && state.elevations.fetch(index).nil?
        end

        weights.sum { |index, weight| state.elevations.fetch(index).to_f * weight }
      end

      private

      attr_reader :state, :stencil

      def grid_coordinate(point)
        {
          x: (point.fetch('x').to_f - state.origin.fetch('x')) / state.spacing.fetch('x'),
          y: (point.fetch('y').to_f - state.origin.fetch('y')) / state.spacing.fetch('y')
        }
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
