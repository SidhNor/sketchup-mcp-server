# frozen_string_literal: true

require_relative '../../scene_query/sample_surface_query'
require_relative '../../scene_query/scene_query_serializer'
require_relative '../features/feature_intent_set'
require_relative '../features/terrain_feature_geometry_builder'
require_relative '../output/feature_aware_adaptive_policy'
require_relative '../regions/terrain_state_elevation_sampler'
require_relative '../storage/terrain_repository'

module SU_MCP
  module Terrain
    # Harness-only compact feature-local mesh quality sampler for replay captures.
    # rubocop:disable Metrics/ClassLength
    class FeatureAwareAdaptiveBaselineQualitySampler
      DEFAULT_SAMPLE_BUDGET = 128
      MAX_SAMPLE_BUDGET = 256

      def initialize(
        model:,
        repository: TerrainRepository.new,
        surface_query: SampleSurfaceQuery.new(serializer: SceneQuerySerializer.new),
        sample_budget: DEFAULT_SAMPLE_BUDGET,
        clock: nil
      )
        @model = model
        @repository = repository
        @surface_query = surface_query
        @sample_budget = sample_budget.to_i.clamp(1, MAX_SAMPLE_BUDGET)
        @clock = clock
      end

      def capture(row:, result:, baseline_evidence:)
        started_at = monotonic_seconds
        summary = quality_summary(row: row, result: result, baseline_evidence: baseline_evidence)
        { summary: summary, seconds: rounded(monotonic_seconds - started_at) }
      rescue StandardError => e
        {
          summary: unavailable_summary(e.class.name, e.message),
          seconds: rounded(monotonic_seconds - started_at)
        }
      end

      private

      attr_reader :model, :repository, :surface_query, :sample_budget, :clock

      def quality_summary(row:, result:, baseline_evidence:)
        return { status: 'not_captured', reason: 'row_not_accepted' } if refused?(result)
        return unavailable_summary('model_unavailable') unless model.respond_to?(:entities)

        owner = terrain_owner(source_element_id_for(row))
        return unavailable_summary('terrain_owner_not_found') unless owner

        loaded = repository.load(owner)
        return unavailable_summary('terrain_state_unavailable', loaded) unless
          loaded.fetch(:outcome) == 'loaded'

        state = loaded.fetch(:state)
        samples = planned_samples(state, owner)
        return { status: 'not_applicable', reason: 'no_feature_regions', sampleCount: 0 } if
          samples.empty?

        surface_results = sample_live_surface(row, samples)
        tolerance = base_tolerance_for(result, baseline_evidence)
        summarize_samples(state, samples, surface_results, tolerance)
      end

      def terrain_owner(source_element_id)
        model.entities.to_a.find do |entity|
          entity.respond_to?(:get_attribute) &&
            entity.get_attribute('su_mcp', 'sourceElementId') == source_element_id
        end
      end

      def source_element_id_for(row)
        payload = row.fetch('publicCommandPayload')
        payload.dig('metadata', 'sourceElementId') ||
          payload.dig(:metadata, :sourceElementId) ||
          payload.dig('targetReference', 'sourceElementId') ||
          payload.dig(:targetReference, :sourceElementId)
      end

      def planned_samples(state, owner)
        geometry = TerrainFeatureGeometryBuilder.new.build(state: state)
        targets = sample_targets(geometry, feature_kinds_by_id(state))
        state_sampler = TerrainStateElevationSampler.new(state)
        local_samples = distribute_samples(targets).select do |sample|
          state_sampler.inside_bounds?(point_hash(sample.fetch(:point)))
        end
        local_samples.map do |sample|
          sample.merge(worldPoint: world_point_for(owner, sample.fetch(:point)))
        end
      end

      def feature_kinds_by_id(state)
        FeatureIntentSet.new(state.feature_intent).features.to_h do |feature|
          [feature.fetch('id'), feature.fetch('kind')]
        end
      end

      def sample_targets(geometry, feature_kinds)
        region_targets(geometry.pressure_regions, feature_kinds) +
          region_targets(geometry.protected_regions, feature_kinds) +
          segment_targets(geometry.reference_segments, feature_kinds) +
          anchor_targets(geometry.output_anchor_candidates, feature_kinds)
      end

      def region_targets(regions, feature_kinds)
        regions.filter_map do |region|
          next unless %w[rectangle circle].include?(region['primitive'])

          shape = region_shape(region)
          next unless shape

          {
            type: :region,
            primitive: region.fetch('primitive'),
            shape: shape,
            family: family_for(region, feature_kinds),
            role: region['role'],
            strength: region['strength']
          }
        end
      end

      def region_shape(region)
        region['ownerLocalShape'] || region['ownerLocalBounds'] ||
          region['ownerLocalCenterRadius']
      end

      def segment_targets(segments, feature_kinds)
        segments.map do |segment|
          {
            type: :segment,
            start: segment.fetch('ownerLocalStart'),
            finish: segment.fetch('ownerLocalEnd'),
            family: family_for(segment, feature_kinds),
            role: segment['role'],
            strength: segment['strength']
          }
        end
      end

      def anchor_targets(anchors, feature_kinds)
        anchors.map do |anchor|
          {
            type: :anchor,
            point: anchor.fetch('ownerLocalPoint'),
            family: family_for(anchor, feature_kinds),
            role: anchor['role'],
            strength: anchor['strength']
          }
        end
      end

      def family_for(entry, feature_kinds)
        feature_kinds.fetch(entry['featureId'], entry['role'] || 'feature').to_sym
      end

      def distribute_samples(targets)
        return [] if targets.empty?

        per_target = [sample_budget / targets.length, 1].max
        targets.flat_map { |target| samples_for_target(target, per_target) }.first(sample_budget)
      end

      def samples_for_target(target, count)
        case target.fetch(:type)
        when :region
          region_samples(target, count)
        when :segment
          segment_samples(target, count)
        else
          [sample_for(target, target.fetch(:point))]
        end
      end

      def region_samples(target, count)
        if target.fetch(:primitive) == 'rectangle'
          rectangle_samples(target, count)
        else
          circle_samples(target, count)
        end
      end

      def rectangle_samples(target, count)
        min, max = target.fetch(:shape)
        columns = Math.sqrt(count).ceil
        rows = (count.to_f / columns).ceil
        points = []
        rows.times do |row|
          columns.times do |column|
            points << [
              interpolated(min.fetch(0), max.fetch(0), column, columns),
              interpolated(min.fetch(1), max.fetch(1), row, rows)
            ]
          end
        end
        points.first(count).map { |point| sample_for(target, point) }
      end

      def circle_samples(target, count)
        center_x, center_y, radius = target.fetch(:shape)
        count.times.map do |index|
          radial = radius * Math.sqrt((index + 0.5) / count.to_f)
          angle = (2.0 * Math::PI * index) / count
          sample_for(target, [center_x + (Math.cos(angle) * radial),
                              center_y + (Math.sin(angle) * radial)])
        end
      end

      def segment_samples(target, count)
        start = target.fetch(:start)
        finish = target.fetch(:finish)
        count.times.map do |index|
          progress = (index + 1).to_f / (count + 1)
          sample_for(
            target,
            [
              start.fetch(0) + ((finish.fetch(0) - start.fetch(0)) * progress),
              start.fetch(1) + ((finish.fetch(1) - start.fetch(1)) * progress)
            ]
          )
        end
      end

      def interpolated(minimum, maximum, index, count)
        minimum + ((maximum - minimum) * ((index + 0.5) / count.to_f))
      end

      def sample_for(target, point)
        {
          family: target.fetch(:family),
          role: target[:role],
          strength: target[:strength],
          point: { x: point.fetch(0), y: point.fetch(1) }
        }
      end

      def sample_live_surface(row, samples)
        surface_query.execute(
          entities: model.entities.to_a,
          scene_entities: model.entities.to_a,
          params: {
            'target' => { 'sourceElementId' => source_element_id_for(row) },
            'sampling' => {
              'type' => 'points',
              'points' => samples.map { |sample| sample.fetch(:worldPoint) }
            },
            'visibleOnly' => false
          }
        ).fetch(:results, [])
      end

      def summarize_samples(state, samples, surface_results, base_tolerance)
        state_sampler = TerrainStateElevationSampler.new(state)
        measured = samples.zip(surface_results).map do |sample, result|
          measurement_for(state_sampler, sample, result, base_tolerance)
        end
        summary_for(measured).merge(
          status: 'captured',
          baseToleranceMeters: rounded(base_tolerance),
          families: family_summaries(measured)
        )
      end

      def measurement_for(state_sampler, sample, result, base_tolerance)
        expected = state_sampler.elevation_at(point_hash(sample.fetch(:point)))
        actual = hit_z(result)
        tolerance = local_tolerance(sample, base_tolerance)
        error = expected && actual ? (actual - expected).abs : nil
        sample.merge(error: error, tolerance: tolerance, hit: !error.nil?)
      end

      def point_hash(point)
        { 'x' => point.fetch(:x), 'y' => point.fetch(:y) }
      end

      def world_point_for(owner, point)
        return point unless owner.respond_to?(:transformation) && defined?(Geom)

        local_point = Geom::Point3d.new(
          internal_length(point.fetch(:x)),
          internal_length(point.fetch(:y)),
          0
        )
        world_point = local_point.transform(owner.transformation)
        {
          x: public_meter_value(world_point.x),
          y: public_meter_value(world_point.y)
        }
      rescue StandardError
        point
      end

      def internal_length(value)
        return value.m if value.respond_to?(:m)

        value
      end

      def public_meter_value(value)
        return value.to_m.to_f if value.respond_to?(:to_m)

        value.to_f
      end

      def hit_z(result)
        return nil unless result.is_a?(Hash)
        return nil unless [result[:status], result['status']].include?('hit')

        result.dig(:hitPoint, :z) || result.dig('hitPoint', 'z')
      end

      def local_tolerance(sample, base_tolerance)
        multiplier = if sample[:strength].to_s == 'hard'
                       FeatureAwareAdaptivePolicy::HARD_MULTIPLIER
                     elsif sample[:role].to_s.include?('protected')
                       FeatureAwareAdaptivePolicy::PROTECTED_MULTIPLIER
                     elsif sample[:strength].to_s == 'firm'
                       FeatureAwareAdaptivePolicy::FIRM_MULTIPLIER
                     else
                       FeatureAwareAdaptivePolicy::SOFT_MULTIPLIER
                     end
        [base_tolerance * multiplier,
         base_tolerance * FeatureAwareAdaptivePolicy::TOLERANCE_FLOOR_MULTIPLIER].max
      end

      def summary_for(measurements)
        errors = measurements.filter_map { |measurement| measurement[:error] }
        {
          sampleCount: measurements.length,
          hitCount: errors.length,
          missCount: measurements.length - errors.length
        }.merge(error_summary(errors, measurements))
      end

      def family_summaries(measurements)
        measurements.group_by { |measurement| measurement.fetch(:family) }
                    .transform_values { |items| summary_for(items) }
      end

      def error_summary(errors, measurements)
        return {} if errors.empty?

        tolerances = measurements.map { |measurement| measurement.fetch(:tolerance) }
        {
          maxErrorMeters: rounded(errors.max),
          meanErrorMeters: rounded(errors.sum / errors.length.to_f),
          p95ErrorMeters: rounded(percentile(errors, 95)),
          withinLocalTolerancePercent: rounded(
            within_tolerance_count(measurements) * 100.0 / measurements.length
          ),
          localToleranceRangeMeters: {
            min: rounded(tolerances.min),
            max: rounded(tolerances.max)
          }
        }
      end

      def percentile(values, percentile)
        sorted = values.sort
        index = (((percentile / 100.0) * sorted.length).ceil - 1).clamp(0, sorted.length - 1)
        sorted.fetch(index)
      end

      def within_tolerance_count(measurements)
        measurements.count do |measurement|
          measurement[:error] && measurement.fetch(:error) <= measurement.fetch(:tolerance)
        end
      end

      def base_tolerance_for(result, baseline_evidence)
        (
          result.dig(:output, :derivedMesh, :simplificationTolerance) ||
          result.dig('output', 'derivedMesh', 'simplificationTolerance') ||
          baseline_evidence[:simplificationTolerance] ||
          baseline_evidence['simplificationTolerance'] ||
          0.01
        ).to_f
      end

      def refused?(result)
        result.fetch(:outcome, result['outcome']) == 'refused'
      end

      def unavailable_summary(reason, detail = nil)
        summary = {
          status: 'unavailable',
          reason: reason.to_s
        }
        summary[:detail] = detail if detail.is_a?(Hash) || detail.is_a?(String)
        summary
      end

      def rounded(value)
        value.to_f.round(6)
      end

      def monotonic_seconds
        return clock.monotonic_seconds if clock.respond_to?(:monotonic_seconds)

        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
