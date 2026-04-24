# frozen_string_literal: true

module SU_MCP
  # Generates ordered profile sample stations before host-surface evaluation.
  # rubocop:disable Metrics/MethodLength
  class SampleSurfaceProfileGenerator
    DEFAULT_SAMPLE_CAP = 200

    def initialize(sample_cap: DEFAULT_SAMPLE_CAP)
      @sample_cap = sample_cap
    end

    def generate(path:, sample_count: nil, interval_meters: nil)
      segments = normalized_segments(path)
      total_length = segments.sum { |segment| segment.fetch(:length) }
      raise 'Profile path must contain at least two distinct XY positions' if total_length.zero?

      distances = sample_distances(
        total_length: total_length,
        sample_count: sample_count,
        interval_meters: interval_meters
      )
      raise_if_above_cap(distances.length)

      distances.each_with_index.map do |distance, index|
        point = point_at_distance(segments, distance)
        {
          index: index,
          x: point.fetch(:x),
          y: point.fetch(:y),
          distance_along_path_meters: distance,
          path_progress: progress_for(distance, total_length)
        }
      end
    end

    # Raised when generated station count would exceed the public sampling cap.
    class SampleCapExceeded < RuntimeError
      attr_reader :generated_count, :allowed_cap

      def initialize(generated_count:, allowed_cap:)
        @generated_count = generated_count
        @allowed_cap = allowed_cap
        super(
          "Profile sampling would generate #{generated_count} samples; " \
          "allowed cap is #{allowed_cap}"
        )
      end
    end

    private

    attr_reader :sample_cap

    def normalized_segments(path)
      points = Array(path).map { |point| normalized_point(point) }
      points.each_cons(2).filter_map do |from, to|
        length = distance_between(from, to)
        next if length.zero?

        { from: from, to: to, length: length }
      end
    end

    def normalized_point(point)
      {
        x: numeric_coordinate(point, :x),
        y: numeric_coordinate(point, :y)
      }
    end

    def numeric_coordinate(point, key)
      raw_value = point[key] if point.respond_to?(:key?) && point.key?(key)
      if raw_value.nil? && point.respond_to?(:key?) && point.key?(key.to_s)
        raw_value = point[key.to_s]
      end
      Float(raw_value)
    rescue ArgumentError, TypeError
      raise "Profile path point #{key} must be numeric"
    end

    def distance_between(from, to)
      Math.sqrt(((to.fetch(:x) - from.fetch(:x))**2) + ((to.fetch(:y) - from.fetch(:y))**2))
    end

    def sample_distances(total_length:, sample_count:, interval_meters:)
      return count_distances(total_length, sample_count) unless sample_count.nil?

      interval_distances(total_length, interval_meters)
    end

    def count_distances(total_length, sample_count)
      count = Integer(sample_count)
      raise 'Profile sampleCount must be at least 2' if count < 2

      step = total_length / (count - 1)
      Array.new(count) { |index| rounded_metric(step * index) }
    rescue ArgumentError, TypeError
      raise 'Profile sampleCount must be an integer'
    end

    def interval_distances(total_length, interval_meters)
      interval = Float(interval_meters)
      raise 'Profile intervalMeters must be positive' unless interval.positive?

      distances = []
      current = 0.0
      while current < total_length
        distances << rounded_metric(current)
        current += interval
      end
      total_length = rounded_metric(total_length)
      distances << total_length unless distances.last == total_length
      distances
    rescue ArgumentError, TypeError
      raise 'Profile intervalMeters must be numeric'
    end

    def raise_if_above_cap(generated_count)
      return unless generated_count > sample_cap

      raise SampleCapExceeded.new(generated_count: generated_count, allowed_cap: sample_cap)
    end

    def point_at_distance(segments, distance)
      remaining = distance
      segments.each do |segment|
        length = segment.fetch(:length)
        return interpolate(segment, remaining / length) if remaining <= length

        remaining -= length
      end

      segments.last.fetch(:to)
    end

    def interpolate(segment, progress)
      from = segment.fetch(:from)
      to = segment.fetch(:to)
      {
        x: rounded_metric(from.fetch(:x) + ((to.fetch(:x) - from.fetch(:x)) * progress)),
        y: rounded_metric(from.fetch(:y) + ((to.fetch(:y) - from.fetch(:y)) * progress))
      }
    end

    def progress_for(distance, total_length)
      rounded_metric(distance / total_length)
    end

    def rounded_metric(value)
      value.round(6)
    end
  end
  # rubocop:enable Metrics/MethodLength
end
