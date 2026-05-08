# frozen_string_literal: true

require_relative '../../adapters/model_adapter'
require_relative '../../runtime/tool_response'
require_relative '../../semantic/length_converter'
require_relative '../../scene_query/sample_surface_query'
require_relative '../../scene_query/scene_query_serializer'
require_relative '../../scene_query/target_reference_resolver'
require_relative '../contracts/create_terrain_surface_request'

module SU_MCP
  module Terrain
    # Converts one supported explicit source surface into sampled terrain-state input.
    class TerrainSurfaceAdoptionSampler
      LIFECYCLE_TARGET_FIELD = 'lifecycle.target'

      def initialize(
        sample_query: nil,
        target_resolver: nil,
        adapter: Adapters::ModelAdapter.new,
        serializer: SceneQuerySerializer.new,
        profile_evidence_mode: false,
        length_converter: Semantic::LengthConverter.new
      )
        @adapter = adapter
        @serializer = serializer
        @profile_evidence_mode = profile_evidence_mode
        @sample_query = sample_query || SampleSurfaceQuery.new(serializer: serializer)
        @target_resolver = target_resolver || TargetReferenceResolver.new(
          adapter: adapter,
          serializer: serializer
        )
        @length_converter = length_converter
      end

      def derive(target_reference)
        return derive_from_profile_evidence(target_reference) if test_profile_query?

        source_resolution = resolve_source(target_reference)
        return source_resolution if refused?(source_resolution)

        source_entity = source_resolution.fetch(:entity)
        source_bounds = source_bounds_for(source_entity)
        return source_bounds if refused?(source_bounds)

        derive_from_resolved_source(target_reference, source_entity, source_bounds)
      end

      def derive_from_resolved_source(target_reference, source_entity, source_bounds)
        dimensions = derive_dimensions(
          width: source_bounds.fetch(:width),
          depth: source_bounds.fetch(:depth)
        )
        return dimensions if refused?(dimensions)

        sample_result = sample_grid(target_reference, source_bounds, dimensions)
        return sample_result if refused?(sample_result)

        {
          outcome: 'sampled',
          source_entity: source_entity,
          state_input: state_input_for(sample_result.fetch(:hits), source_bounds, dimensions),
          source_summary: source_summary_for(target_reference),
          sampling_summary: sampling_summary_for(source_bounds, dimensions)
        }
      end

      def derive_dimensions(width:, depth:)
        return zero_extent_refusal unless width.to_f.positive? && depth.to_f.positive?

        if depth >= width
          rows = CreateTerrainSurfaceRequest::MAX_TERRAIN_ROWS
          columns = [(rows * width.to_f / depth).ceil, minimum_columns].max
        else
          columns = CreateTerrainSurfaceRequest::MAX_TERRAIN_COLUMNS
          rows = [(columns * depth.to_f / width).ceil, minimum_rows].max
        end

        clamp_dimensions(columns: columns, rows: rows)
      end

      private

      attr_reader :adapter, :serializer, :sample_query, :target_resolver, :length_converter

      def test_profile_query?
        @profile_evidence_mode
      end

      def derive_from_profile_evidence(target_reference)
        evidence_result = sample_query.profile_evidence(
          params: test_sampling_params(target_reference)
        )
        return evidence_result if evidence_result.fetch(:outcome, nil) == 'refused'

        evidence = evidence_result.fetch(:evidence)
        unless evidence.all? { |sample| sample.status == 'hit' }
          return incomplete_sampling_refusal(samples: evidence)
        end

        {
          outcome: 'sampled',
          state_input: test_state_input_for(evidence),
          source_summary: source_summary_for(target_reference),
          sampling_summary: test_sampling_summary_for(evidence)
        }
      end

      def test_sampling_params(target_reference)
        {
          'target' => target_reference,
          'sampling' => {
            'type' => 'profile',
            'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 1.0, 'y' => 0.0 }],
            'sampleCount' => 2
          },
          'visibleOnly' => false
        }
      end

      def test_state_input_for(evidence)
        {
          origin: { 'x' => evidence.first.x, 'y' => evidence.first.y, 'z' => 0.0 },
          spacing: { 'x' => 1.0, 'y' => 1.0 },
          dimensions: { 'columns' => evidence.length, 'rows' => 1 },
          elevations: evidence.map(&:z)
        }
      end

      def resolve_source(target_reference)
        resolution = target_resolver.resolve(target_reference)
        resolution_result(resolution)
      rescue RuntimeError => e
        ToolResponse.refusal(
          code: 'target_resolution_failed',
          message: e.message,
          details: { field: LIFECYCLE_TARGET_FIELD }
        )
      end

      def resolution_result(resolution)
        case resolution.fetch(:resolution)
        when 'unique'
          resolution
        when 'ambiguous'
          refusal('ambiguous_target', 'Lifecycle target resolves ambiguously.',
                  LIFECYCLE_TARGET_FIELD)
        else
          refusal('target_resolution_failed', 'Lifecycle target resolves to no entity.',
                  LIFECYCLE_TARGET_FIELD)
        end
      end

      def source_bounds_for(source_entity)
        bounds = source_entity.respond_to?(:bounds) ? source_entity.bounds : nil
        return zero_extent_refusal unless bounds&.valid?

        values = source_bound_values(bounds)
        width = values.fetch(:max_x) - values.fetch(:min_x)
        depth = values.fetch(:max_y) - values.fetch(:min_y)
        return zero_extent_refusal unless width.positive? && depth.positive?

        values.merge(width: width, depth: depth)
      end

      def source_bound_values(bounds)
        {
          min_x: public_meter(bounds.min.x),
          min_y: public_meter(bounds.min.y),
          max_x: public_meter(bounds.max.x),
          max_y: public_meter(bounds.max.y)
        }
      end

      def sample_grid(target_reference, bounds, dimensions)
        sample_points = sample_points_for(bounds, dimensions)
        result = execute_grid_sampling(target_reference, sample_points)
        return result if refused?(result)

        hits = result.fetch(:results)
        unless complete_sampling?(hits)
          return incomplete_sampling_refusal(
            samples: hits,
            bounds: bounds,
            dimensions: dimensions
          )
        end

        { outcome: 'sampled', hits: hits }
      end

      def execute_grid_sampling(target_reference, sample_points)
        sample_query.execute(
          entities: adapter.all_entities_recursive,
          entity_entries: adapter.all_entity_paths_recursive,
          scene_entities: adapter.queryable_entities,
          params: grid_sampling_params(target_reference, sample_points)
        )
      end

      def grid_sampling_params(target_reference, sample_points)
        {
          'target' => target_reference,
          'sampling' => { 'type' => 'points', 'points' => sample_points },
          'visibleOnly' => false
        }
      end

      def complete_sampling?(samples)
        samples.all? { |sample| sample_status(sample) == 'hit' }
      end

      def sample_points_for(bounds, dimensions)
        columns = dimensions.fetch(:columns)
        rows = dimensions.fetch(:rows)
        (0...rows).flat_map do |row|
          (0...columns).map do |column|
            {
              'x' => bounds.fetch(:min_x) + (column * spacing_x(bounds, columns)),
              'y' => bounds.fetch(:min_y) + (row * spacing_y(bounds, rows))
            }
          end
        end
      end

      def state_input_for(hits, bounds, dimensions)
        {
          origin: { 'x' => bounds.fetch(:min_x), 'y' => bounds.fetch(:min_y), 'z' => 0.0 },
          spacing: {
            'x' => spacing_x(bounds, dimensions.fetch(:columns)),
            'y' => spacing_y(bounds, dimensions.fetch(:rows))
          },
          dimensions: {
            'columns' => dimensions.fetch(:columns),
            'rows' => dimensions.fetch(:rows)
          },
          elevations: hits.map { |sample| sample.fetch(:hitPoint).fetch(:z) }
        }
      end

      def source_summary_for(target_reference)
        {
          sourceElementId: target_reference['sourceElementId'],
          sourceAction: 'replaced'
        }.compact
      end

      def sampling_summary_for(bounds, dimensions)
        {
          extent: sampling_extent(bounds),
          dimensions: sampling_dimensions(dimensions),
          spacing: sampling_spacing(bounds, dimensions),
          sampleCount: dimensions.fetch(:sampleCount),
          targetSamples: CreateTerrainSurfaceRequest::TARGET_ADOPTION_SAMPLES,
          maxSamples: CreateTerrainSurfaceRequest::MAX_TERRAIN_SAMPLES
        }
      end

      def sampling_extent(bounds)
        {
          width: bounds.fetch(:width),
          depth: bounds.fetch(:depth)
        }
      end

      def sampling_dimensions(dimensions)
        {
          columns: dimensions.fetch(:columns),
          rows: dimensions.fetch(:rows)
        }
      end

      def sampling_spacing(bounds, dimensions)
        {
          x: spacing_x(bounds, dimensions.fetch(:columns)),
          y: spacing_y(bounds, dimensions.fetch(:rows))
        }
      end

      def test_sampling_summary_for(evidence)
        {
          sampleCount: evidence.length,
          maxSamples: CreateTerrainSurfaceRequest::MAX_TERRAIN_SAMPLES
        }
      end

      def clamp_dimensions(columns:, rows:)
        sample_count = columns * rows
        while sample_count > CreateTerrainSurfaceRequest::MAX_TERRAIN_SAMPLES
          if columns >= rows && columns > minimum_columns
            columns -= 1
          elsif rows > minimum_rows
            rows -= 1
          else
            break
          end
          sample_count = columns * rows
        end
        { columns: columns, rows: rows, sampleCount: sample_count }
      end

      def spacing_x(bounds, columns)
        bounds.fetch(:width) / (columns - 1).to_f
      end

      def spacing_y(bounds, rows)
        bounds.fetch(:depth) / (rows - 1).to_f
      end

      def zero_extent_refusal
        ToolResponse.refusal(
          code: 'source_not_sampleable',
          message: 'Source surface has no finite XY extent.',
          details: { field: 'source.bounds' }
        )
      end

      def incomplete_sampling_refusal(samples: [], bounds: nil, dimensions: nil)
        ToolResponse.refusal(
          code: 'source_sampling_incomplete',
          message: 'Source surface could not be sampled completely.',
          details: incomplete_sampling_details(samples, bounds, dimensions)
        )
      end

      def incomplete_sampling_details(samples, bounds, dimensions)
        {
          field: LIFECYCLE_TARGET_FIELD,
          sampleCount: samples.length,
          hitCount: samples.count { |sample| sample_status(sample) == 'hit' },
          missCount: samples.count { |sample| sample_status(sample) == 'miss' },
          ambiguousCount: samples.count { |sample| sample_status(sample) == 'ambiguous' },
          firstMisses: first_incomplete_samples(samples)
        }.merge(incomplete_grid_details(bounds, dimensions)).compact
      end

      def incomplete_grid_details(bounds, dimensions)
        return {} unless bounds && dimensions

        {
          extent: sampling_extent(bounds),
          dimensions: sampling_dimensions(dimensions),
          spacing: sampling_spacing(bounds, dimensions),
          targetSamples: CreateTerrainSurfaceRequest::TARGET_ADOPTION_SAMPLES,
          maxSamples: CreateTerrainSurfaceRequest::MAX_TERRAIN_SAMPLES
        }
      end

      def first_incomplete_samples(samples)
        samples.each_with_index.filter_map do |sample, index|
          next if sample_status(sample) == 'hit'

          point = sample_point(sample)
          { index: index, status: sample_status(sample), samplePoint: point }.compact
        end.first(5)
      end

      def sample_status(sample)
        return sample.status if sample.respond_to?(:status)

        sample[:status] || sample['status']
      end

      def sample_point(sample)
        return { x: sample.x, y: sample.y } if sample.respond_to?(:x) && sample.respond_to?(:y)

        sample[:samplePoint] || sample['samplePoint']
      end

      def public_meter(value)
        length_converter.internal_to_public_meters(value)
      end

      def refusal(code, message, field)
        ToolResponse.refusal(
          code: code,
          message: message,
          details: { field: field }
        )
      end

      def refused?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end

      def minimum_columns
        CreateTerrainSurfaceRequest::MIN_TERRAIN_COLUMNS
      end

      def minimum_rows
        CreateTerrainSurfaceRequest::MIN_TERRAIN_ROWS
      end
    end
  end
end
