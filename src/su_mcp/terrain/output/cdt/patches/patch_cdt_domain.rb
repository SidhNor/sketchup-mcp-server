# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Runtime value object describing the bounded source samples a patch proof may inspect.
    class PatchCdtDomain
      DEFAULT_MARGIN_SAMPLES = 2

      # Raised when a dirty window cannot produce a valid patch domain.
      class InvalidDomain < StandardError
        attr_reader :reason

        def initialize(reason)
          @reason = reason
          super
        end
      end

      attr_reader :state, :dirty_window, :margin_samples, :min_column, :min_row,
                  :max_column, :max_row

      def self.from_window(state:, window:, margin_samples: DEFAULT_MARGIN_SAMPLES)
        raise InvalidDomain, 'empty_dirty_window' if window.empty?

        new(state: state, dirty_window: window, margin_samples: margin_samples)
      end

      # rubocop:disable Metrics/AbcSize
      def initialize(state:, dirty_window:, margin_samples:)
        @state = state
        @dirty_window = dirty_window
        @margin_samples = Integer(margin_samples).clamp(0, [columns, rows].max)
        @min_column = (dirty_window.min_column - @margin_samples).clamp(0, columns - 1)
        @min_row = (dirty_window.min_row - @margin_samples).clamp(0, rows - 1)
        @max_column = (dirty_window.max_column + @margin_samples).clamp(0, columns - 1)
        @max_row = (dirty_window.max_row + @margin_samples).clamp(0, rows - 1)
        raise InvalidDomain, 'patch_domain_invalid' if min_column > max_column || min_row > max_row
      end
      # rubocop:enable Metrics/AbcSize

      def sample_bounds
        {
          minColumn: min_column,
          minRow: min_row,
          maxColumn: max_column,
          maxRow: max_row,
          dirty: {
            minColumn: dirty_window.min_column,
            minRow: dirty_window.min_row,
            maxColumn: dirty_window.max_column,
            maxRow: dirty_window.max_row
          }
        }
      end

      def owner_local_bounds
        {
          minX: x_at(min_column),
          minY: y_at(min_row),
          maxX: x_at(max_column),
          maxY: y_at(max_row)
        }
      end

      def source_dimensions
        {
          columns: columns,
          rows: rows
        }
      end

      def width_samples
        (max_column - min_column) + 1
      end

      def height_samples
        (max_row - min_row) + 1
      end

      def patch_sample_count
        width_samples * height_samples
      end

      def dense_equivalent_face_count
        [(width_samples - 1), 0].max * [(height_samples - 1), 0].max * 2
      end

      def contains_sample?(column:, row:)
        column.between?(min_column, max_column) && row.between?(min_row, max_row)
      end

      def contains_point?(point)
        bounds = owner_local_bounds
        point[0].between?(bounds.fetch(:minX), bounds.fetch(:maxX)) &&
          point[1].between?(bounds.fetch(:minY), bounds.fetch(:maxY))
      end

      def each_sample
        return enum_for(:each_sample) unless block_given?

        (min_row..max_row).each do |row|
          (min_column..max_column).each do |column|
            yield(column, row)
          end
        end
      end

      def to_h
        {
          sampleBounds: sample_bounds,
          ownerLocalBounds: owner_local_bounds,
          sourceDimensions: source_dimensions,
          marginSamples: margin_samples,
          patchSampleCount: patch_sample_count
        }
      end

      def x_at(column)
        state.origin.fetch('x') + (column * state.spacing.fetch('x'))
      end

      def y_at(row)
        state.origin.fetch('y') + (row * state.spacing.fetch('y'))
      end

      def elevation_at(column, row)
        state.elevations.fetch((row * columns) + column)
      end

      def nominal_spacing
        [state.spacing.fetch('x').abs, state.spacing.fetch('y').abs].max
      end

      private

      def columns
        state.dimensions.fetch('columns')
      end

      def rows
        state.dimensions.fetch('rows')
      end
    end
  end
end
