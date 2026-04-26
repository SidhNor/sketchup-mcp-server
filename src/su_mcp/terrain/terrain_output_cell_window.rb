# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Output-domain cell window for derived terrain mesh replacement.
    class TerrainOutputCellWindow
      attr_reader :min_column, :min_row, :max_column, :max_row

      class << self
        def from_sample_window(window:, state:)
          return new(empty: true) if window.empty?

          dimensions = state.dimensions
          new(
            affected_cell_bounds(window, dimensions),
            full_bounds: full_cell_bounds(dimensions)
          )
        end

        private

        def affected_cell_bounds(window, dimensions)
          {
            min_column: [window.min_column - 1, 0].max,
            min_row: [window.min_row - 1, 0].max,
            max_column: [window.max_column, max_cell_column(dimensions)].min,
            max_row: [window.max_row, max_cell_row(dimensions)].min
          }
        end

        def full_cell_bounds(dimensions)
          {
            max_column: max_cell_column(dimensions),
            max_row: max_cell_row(dimensions)
          }
        end

        def max_cell_column(dimensions)
          dimensions.fetch('columns') - 2
        end

        def max_cell_row(dimensions)
          dimensions.fetch('rows') - 2
        end
      end

      def initialize(bounds = nil, empty: false, full_bounds: nil)
        @empty = empty
        @full_max_column = full_bounds&.fetch(:max_column)
        @full_max_row = full_bounds&.fetch(:max_row)
        return if empty?

        @min_column = normalize_index(bounds.fetch(:min_column), 'min_column')
        @min_row = normalize_index(bounds.fetch(:min_row), 'min_row')
        @max_column = normalize_index(bounds.fetch(:max_column), 'max_column')
        @max_row = normalize_index(bounds.fetch(:max_row), 'max_row')
        raise ArgumentError, 'cell window minimum must not exceed maximum' if invalid_range?
      end

      def empty?
        @empty == true
      end

      def whole_grid?
        return false if empty?
        return false unless @full_max_column && @full_max_row

        min_column.zero? && min_row.zero? &&
          max_column == @full_max_column &&
          max_row == @full_max_row
      end

      def cell_count
        return 0 if empty?

        ((max_column - min_column) + 1) * ((max_row - min_row) + 1)
      end

      def each_cell
        return enum_for(:each_cell) unless block_given?
        return if empty?

        (min_row..max_row).each do |row|
          (min_column..max_column).each do |column|
            yield column, row
          end
        end
      end

      def ==(other)
        other.is_a?(self.class) &&
          empty? == other.empty? &&
          min_column == other.min_column &&
          min_row == other.min_row &&
          max_column == other.max_column &&
          max_row == other.max_row
      end

      private

      def normalize_index(value, field)
        raise ArgumentError, "#{field} must be an integer" unless value.is_a?(Integer)
        raise ArgumentError, "#{field} must be non-negative" if value.negative?

        value
      end

      def invalid_range?
        min_column > max_column || min_row > max_row
      end
    end
  end
end
