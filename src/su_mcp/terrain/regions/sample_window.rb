# frozen_string_literal: true

module SU_MCP
  module Terrain
    # SketchUp-free sample-index window for managed terrain grid regions.
    class SampleWindow
      attr_reader :min_column, :min_row, :max_column, :max_row

      class << self
        def full_grid(state)
          dimensions = state.dimensions
          new(
            min_column: 0,
            min_row: 0,
            max_column: dimensions.fetch('columns') - 1,
            max_row: dimensions.fetch('rows') - 1
          )
        end

        def from_owner_bounds(state, bounds)
          normalized = normalize_bounds(bounds)
          columns = state.dimensions.fetch('columns')
          rows = state.dimensions.fetch('rows')
          raw_window = raw_window_for(state, normalized)

          clipped_window(raw_window, columns, rows)
        end

        def from_samples(samples)
          return new(empty: true) if samples.empty?

          columns = samples.map { |sample| sample.fetch(:column) { sample.fetch('column') } }
          rows = samples.map { |sample| sample.fetch(:row) { sample.fetch('row') } }
          new(
            min_column: columns.min,
            min_row: rows.min,
            max_column: columns.max,
            max_row: rows.max
          )
        end

        private

        def raw_window_for(state, bounds)
          origin = state.origin
          spacing = state.spacing
          {
            min_column: grid_min(bounds.fetch('minX'), origin.fetch('x'), spacing.fetch('x')),
            max_column: grid_max(bounds.fetch('maxX'), origin.fetch('x'), spacing.fetch('x')),
            min_row: grid_min(bounds.fetch('minY'), origin.fetch('y'), spacing.fetch('y')),
            max_row: grid_max(bounds.fetch('maxY'), origin.fetch('y'), spacing.fetch('y'))
          }
        end

        def clipped_window(window, columns, rows)
          new(
            min_column: window.fetch(:min_column).clamp(0, columns - 1),
            min_row: window.fetch(:min_row).clamp(0, rows - 1),
            max_column: window.fetch(:max_column).clamp(0, columns - 1),
            max_row: window.fetch(:max_row).clamp(0, rows - 1),
            empty: outside_grid?(window, columns, rows)
          )
        end

        def grid_min(value, origin, spacing)
          ((value - origin) / spacing).ceil
        end

        def grid_max(value, origin, spacing)
          ((value - origin) / spacing).floor
        end

        def outside_grid?(window, columns, rows)
          window.fetch(:max_column).negative? ||
            window.fetch(:max_row).negative? ||
            window.fetch(:min_column) >= columns ||
            window.fetch(:min_row) >= rows ||
            window.fetch(:min_column) > window.fetch(:max_column) ||
            window.fetch(:min_row) > window.fetch(:max_row)
        end

        def normalize_bounds(bounds)
          raise ArgumentError, 'bounds must be a hash' unless bounds.is_a?(Hash)

          normalized = bounds.transform_keys(&:to_s)
          validate_bound_numbers!(normalized)
          validate_bound_ranges!(normalized)
          normalized
        end

        def validate_bound_numbers!(bounds)
          %w[minX minY maxX maxY].each do |key|
            value = bounds[key]
            raise ArgumentError, "bounds.#{key} must be numeric" unless value.is_a?(Numeric)
            raise ArgumentError, "bounds.#{key} must be finite" unless value.finite?
          end
        end

        def validate_bound_ranges!(bounds)
          return unless bounds.fetch('minX') > bounds.fetch('maxX') ||
                        bounds.fetch('minY') > bounds.fetch('maxY')

          raise ArgumentError, 'bounds min values must be less than or equal to max values'
        end
      end

      def initialize(
        min_column: nil,
        min_row: nil,
        max_column: nil,
        max_row: nil,
        empty: false
      )
        @empty = empty
        return if empty?

        @min_column = normalize_index(min_column, 'min_column')
        @min_row = normalize_index(min_row, 'min_row')
        @max_column = normalize_index(max_column, 'max_column')
        @max_row = normalize_index(max_row, 'max_row')
        raise ArgumentError, 'window minimum must not exceed maximum' if invalid_range?
      end

      def empty?
        @empty == true
      end

      def sample_count
        return 0 if empty?

        ((max_column - min_column) + 1) * ((max_row - min_row) + 1)
      end

      def to_changed_region
        return nil if empty?

        {
          min: { column: min_column, row: min_row },
          max: { column: max_column, row: max_row }
        }
      end

      def intersection(other)
        return self.class.new(empty: true) if empty? || other.empty?

        min_column = [self.min_column, other.min_column].max
        min_row = [self.min_row, other.min_row].max
        max_column = [self.max_column, other.max_column].min
        max_row = [self.max_row, other.max_row].min

        self.class.new(
          min_column: min_column,
          min_row: min_row,
          max_column: max_column,
          max_row: max_row,
          empty: min_column > max_column || min_row > max_row
        )
      end

      def union(other)
        return other if empty?
        return self if other.empty?

        self.class.new(
          min_column: [min_column, other.min_column].min,
          min_row: [min_row, other.min_row].min,
          max_column: [max_column, other.max_column].max,
          max_row: [max_row, other.max_row].max
        )
      end

      def ==(other)
        other.is_a?(self.class) &&
          empty? == other.empty? &&
          to_changed_region == other.to_changed_region
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
