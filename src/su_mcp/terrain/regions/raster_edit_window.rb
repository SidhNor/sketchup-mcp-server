# frozen_string_literal: true

require_relative 'sample_window'

module SU_MCP
  module Terrain
    # Bounded uniform raster edit window backed by dense terrain state.
    class RasterEditWindow
      MAX_SAMPLES = 262_144

      attr_reader :state, :sample_window

      def initialize(state:, sample_window:)
        raise ArgumentError, 'sample window must not be empty' if sample_window.empty?
        if sample_window.sample_count > MAX_SAMPLES
          raise ArgumentError, 'terrain edit window too large'
        end

        @state = state
        @sample_window = sample_window
        @elevations = state.elevations.dup
        @dirty_window = SampleWindow.new(empty: true)
      end

      def elevation_at(column:, row:)
        elevations.fetch(index_for(column, row))
      end

      def elevation_at_xy(x:, y:)
        column = ((x - state.origin.fetch('x')) / state.spacing.fetch('x')).round
        row = ((y - state.origin.fetch('y')) / state.spacing.fetch('y')).round
        elevation_at(column: column, row: row)
      end

      def write_elevation(column:, row:, elevation:)
        raise ArgumentError, 'elevation must be numeric' unless elevation.is_a?(Numeric)
        raise ArgumentError, 'elevation must be finite' unless elevation.finite?

        elevations[index_for(column, row)] = elevation.to_f
        mark_dirty(column, row)
      end

      def dirty_sample_bounds
        dirty_window.to_changed_region
      end

      def dirty_tile_ids
        return [] unless state.respond_to?(:tile_ids_for_window)

        state.tile_ids_for_window(dirty_window)
      end

      def commit(revision: state.revision + 1)
        state.with_elevations(elevations, revision: revision)
      end

      private

      attr_reader :elevations, :dirty_window

      def index_for(column, row)
        validate_in_window!(column, row)
        (row * state.dimensions.fetch('columns')) + column
      end

      def validate_in_window!(column, row)
        unless column.between?(sample_window.min_column, sample_window.max_column) &&
               row.between?(sample_window.min_row, sample_window.max_row)
          raise ArgumentError, 'sample is outside raster edit window'
        end
      end

      def mark_dirty(column, row)
        sample = SampleWindow.new(
          min_column: column,
          min_row: row,
          max_column: column,
          max_row: row
        )
        @dirty_window = dirty_window.union(sample)
      end
    end
  end
end
