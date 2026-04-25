# frozen_string_literal: true

module SU_MCP
  # Request-local XY index for already prepared sample-surface face entries.
  class PreparedFaceIndex
    INDEX_THRESHOLD = 16
    MAX_AXIS_BUCKETS = 64

    def initialize(face_entries, coordinate_converter:, tolerance:)
      @face_entries = face_entries
      @coordinate_converter = coordinate_converter
      @tolerance = tolerance.to_f
      @always_entries = []
      @buckets = {}

      build_index
    end

    def candidates_for(sample_point)
      return face_entries unless indexed?

      x_value = converted_coordinate(sample_point[:x])
      y_value = converted_coordinate(sample_point[:y])
      return face_entries if x_value.nil? || y_value.nil?
      return always_entries unless within_index_bounds?(x_value, y_value)

      (always_entries + Array(buckets[bucket_key_for(x_value, y_value)])).uniq
    end

    private

    attr_reader :face_entries, :coordinate_converter, :tolerance, :always_entries, :buckets,
                :index_bounds, :columns, :rows, :cell_width, :cell_height

    def build_index
      indexable_entries = split_indexable_entries
      return if indexable_entries.length < INDEX_THRESHOLD

      return unless index_configured?(indexable_entries)

      indexable_entries.each { |entry| index_entry(entry) }
    end

    def split_indexable_entries
      indexable_entries, unindexed_entries = face_entries.partition do |entry|
        valid_bounds?(entry[:world_xy_bounds])
      end
      always_entries.concat(unindexed_entries)
      indexable_entries
    end

    def index_configured?(indexable_entries)
      @index_bounds = combined_bounds(indexable_entries)
      return false unless valid_bounds?(index_bounds)

      configure_grid(indexable_entries.length)
      cell_width&.positive? && cell_height&.positive?
    end

    def configure_grid(entry_count)
      axis_buckets = [Math.sqrt(entry_count).ceil, MAX_AXIS_BUCKETS].min
      @columns = axis_buckets
      @rows = axis_buckets
      @cell_width = (index_bounds.fetch(:max_x) - index_bounds.fetch(:min_x)) / columns.to_f
      @cell_height = (index_bounds.fetch(:max_y) - index_bounds.fetch(:min_y)) / rows.to_f
    end

    def index_entry(entry)
      min_column, max_column = cell_range(
        entry.dig(:world_xy_bounds, :min_x),
        entry.dig(:world_xy_bounds, :max_x),
        axis: :x
      )
      min_row, max_row = cell_range(
        entry.dig(:world_xy_bounds, :min_y),
        entry.dig(:world_xy_bounds, :max_y),
        axis: :y
      )

      (min_column..max_column).each do |column|
        (min_row..max_row).each do |row|
          (buckets[[column, row]] ||= []) << entry
        end
      end
    end

    def indexed?
      !buckets.empty?
    end

    def combined_bounds(entries)
      bounds = entries.map { |entry| entry.fetch(:world_xy_bounds) }
      {
        min_x: bounds.map { |entry_bounds| entry_bounds.fetch(:min_x) }.min,
        max_x: bounds.map { |entry_bounds| entry_bounds.fetch(:max_x) }.max,
        min_y: bounds.map { |entry_bounds| entry_bounds.fetch(:min_y) }.min,
        max_y: bounds.map { |entry_bounds| entry_bounds.fetch(:max_y) }.max
      }
    end

    def cell_range(minimum, maximum, axis:)
      [
        cell_for(minimum - tolerance, axis: axis),
        cell_for(maximum + tolerance, axis: axis)
      ].minmax
    end

    def cell_for(value, axis:)
      if axis == :x
        raw_cell = ((value - index_bounds.fetch(:min_x)) / cell_width).floor
        raw_cell.clamp(0, columns - 1)
      else
        raw_cell = ((value - index_bounds.fetch(:min_y)) / cell_height).floor
        raw_cell.clamp(0, rows - 1)
      end
    end

    def bucket_key_for(x_value, y_value)
      [cell_for(x_value, axis: :x), cell_for(y_value, axis: :y)]
    end

    def within_index_bounds?(x_value, y_value)
      x_value.between?(index_bounds.fetch(:min_x) - tolerance,
                       index_bounds.fetch(:max_x) + tolerance) &&
        y_value.between?(index_bounds.fetch(:min_y) - tolerance,
                         index_bounds.fetch(:max_y) + tolerance)
    end

    def valid_bounds?(bounds)
      bounds.is_a?(Hash) &&
        bounds.values_at(:min_x, :max_x, :min_y, :max_y).all?(Numeric) &&
        bounds.fetch(:max_x) >= bounds.fetch(:min_x) &&
        bounds.fetch(:max_y) >= bounds.fetch(:min_y)
    end

    def converted_coordinate(value)
      converted = coordinate_converter.call(value)
      converted.respond_to?(:to_f) ? converted.to_f : nil
    rescue StandardError
      nil
    end
  end
end
