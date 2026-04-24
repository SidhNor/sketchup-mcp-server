# frozen_string_literal: true

require_relative '../scene_query/scene_query_serializer'
require_relative 'measurement_result_builder'

module SU_MCP
  # Reduces internal profile sampling rows into terrain elevation measurements.
  class TerrainProfileElevationSummary
    MODE = 'terrain_profile'
    KIND = 'elevation_summary'
    EVIDENCE_SAMPLE_LIMIT = 50

    def initialize(result_builder: nil, serializer: nil)
      @result_builder = result_builder || MeasurementResultBuilder.new
      @serializer = serializer || SceneQuerySerializer.new
    end

    def measure(samples)
      samples = Array(samples)
      hit_samples = samples.select { |sample| sample.status == 'hit' }
      return unavailable_profile_result(samples) if hit_samples.empty?

      result_builder.measured(
        MODE,
        KIND,
        value: value_for(samples, hit_samples),
        unit: 'm',
        evidence: evidence_for(samples)
      )
    end

    private

    attr_reader :result_builder, :serializer

    def unavailable_profile_result(samples)
      ambiguous = count_status(samples, 'ambiguous').positive?
      reason = ambiguous ? 'no_unambiguous_profile_hits' : 'no_profile_hits'
      result = result_builder.unavailable(MODE, KIND, reason)
      result.fetch(:measurement)[:evidence] = evidence_for(samples)
      result
    end

    def value_for(samples, hit_samples)
      elevations = elevation_extents(hit_samples)
      endpoints = endpoint_elevations(samples)

      sample_counts(samples, hit_samples)
        .merge(elevation_values(elevations))
        .merge(endpoint_values(endpoints))
        .merge(rise_fall_values(samples))
    end

    def sample_counts(samples, hit_samples)
      {
        sampledLengthMeters: rounded(samples.last&.distance_along_path_meters || 0.0),
        totalSamples: samples.length,
        hitCount: hit_samples.length,
        missCount: count_status(samples, 'miss'),
        ambiguousCount: count_status(samples, 'ambiguous')
      }
    end

    def elevation_values(elevations)
      {
        minElevation: elevations.fetch(:min),
        maxElevation: elevations.fetch(:max),
        elevationRange: rounded(elevations.fetch(:max) - elevations.fetch(:min))
      }
    end

    def endpoint_values(endpoints)
      {
        startElevation: endpoints.fetch(:start),
        endElevation: endpoints.fetch(:end),
        netElevationDelta: net_elevation_delta(endpoints.fetch(:start), endpoints.fetch(:end))
      }
    end

    def rise_fall_values(samples)
      {
        totalRise: complete?(samples) ? total_rise(samples) : nil,
        totalFall: complete?(samples) ? total_fall(samples) : nil
      }
    end

    def elevation_extents(hit_samples)
      elevations = hit_samples.map(&:z)
      { min: rounded(elevations.min), max: rounded(elevations.max) }
    end

    def endpoint_elevations(samples)
      { start: endpoint_elevation(samples.first), end: endpoint_elevation(samples.last) }
    end

    def evidence_for(samples)
      {
        summary: evidence_summary(samples),
        omittedQuantities: omitted_quantities(samples),
        samples: evidence_samples(samples),
        samplesTruncated: samples.length > EVIDENCE_SAMPLE_LIMIT,
        sampleLimit: EVIDENCE_SAMPLE_LIMIT
      }
    end

    def evidence_summary(samples)
      {
        totalSamples: samples.length,
        hitCount: count_status(samples, 'hit'),
        missCount: count_status(samples, 'miss'),
        ambiguousCount: count_status(samples, 'ambiguous'),
        sampledLengthMeters: rounded(samples.last&.distance_along_path_meters || 0.0),
        complete: complete?(samples)
      }
    end

    def omitted_quantities(samples)
      first_hit = samples.first&.status == 'hit'
      last_hit = samples.last&.status == 'hit'
      endpoint_omissions(first_hit, last_hit) + completeness_omissions(samples)
    end

    def endpoint_omissions(first_hit, last_hit)
      omitted = []
      omitted << omitted_quantity('startElevation', 'requires_start_sample_hit') unless first_hit
      omitted << omitted_quantity('endElevation', 'requires_end_sample_hit') unless last_hit
      unless first_hit && last_hit
        omitted << omitted_quantity('netElevationDelta', 'requires_endpoint_samples_hit')
      end
      omitted
    end

    def completeness_omissions(samples)
      return [] if complete?(samples)

      [
        omitted_quantity('totalRise', 'requires_all_samples_hit'),
        omitted_quantity('totalFall', 'requires_all_samples_hit')
      ]
    end

    def omitted_quantity(field, reason)
      { field: field, reason: reason }
    end

    def evidence_samples(samples)
      selected = if samples.length <= EVIDENCE_SAMPLE_LIMIT
                   samples
                 else
                   samples.first(EVIDENCE_SAMPLE_LIMIT - 1) + [samples.last]
                 end
      selected.map { |sample| serializer.serialize_sampling_evidence(sample) }
    end

    def endpoint_elevation(sample)
      sample&.status == 'hit' ? rounded(sample.z) : nil
    end

    def net_elevation_delta(start_elevation, end_elevation)
      return nil if start_elevation.nil? || end_elevation.nil?

      rounded(end_elevation - start_elevation)
    end

    def total_rise(samples)
      rounded(z_deltas(samples).select(&:positive?).sum)
    end

    def total_fall(samples)
      rounded(z_deltas(samples).select(&:negative?).sum.abs)
    end

    def z_deltas(samples)
      samples.each_cons(2).map do |previous, current|
        current.z.to_f - previous.z.to_f
      end
    end

    def count_status(samples, status)
      samples.count { |sample| sample.status == status }
    end

    def complete?(samples)
      samples.all? { |sample| sample.status == 'hit' }
    end

    def rounded(value)
      value.to_f.round(6)
    end
  end
end
