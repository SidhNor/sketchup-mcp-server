# frozen_string_literal: true

require_relative 'corridor_frame'
require_relative 'fixed_control_evaluator'
require_relative 'heightmap_state'
require_relative 'sample_window'

module SU_MCP
  module Terrain
    # SketchUp-free corridor transition terrain edit kernel.
    class CorridorTransitionEdit
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01

      def apply(state:, request:)
        no_data_refusal = no_data_refusal_for(state)
        return no_data_refusal if no_data_refusal

        frame = frame_or_refusal(request)
        return frame if refused?(frame)

        weighted_samples = weighted_samples_for(state, frame, request)
        return no_affected_samples_refusal if weighted_samples.empty?

        edited_elevations = edited_elevations_for(state, frame, weighted_samples)
        fixed_control_refusal = fixed_control_evaluator(
          state,
          edited_elevations,
          request
        ).conflict_refusal
        return fixed_control_refusal if fixed_control_refusal

        {
          outcome: 'edited',
          state: edited_state(state, edited_elevations),
          diagnostics: diagnostics_for(state, edited_elevations, weighted_samples, request, frame)
        }
      end

      private

      def refused?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end

      def frame_or_refusal(request)
        region = request.fetch('region')
        CorridorFrame.new(
          start_control: region.fetch('startControl'),
          end_control: region.fetch('endControl'),
          width: region.fetch('width'),
          side_blend: region.fetch('sideBlend', {})
        )
      rescue KeyError, ArgumentError => e
        refusal(
          code: 'invalid_corridor_geometry',
          message: 'Corridor transition controls do not define supported geometry.',
          details: { field: 'region', reason: e.message }
        )
      end

      def no_data_refusal_for(state)
        samples = state.elevations.each_with_index.filter_map do |value, index|
          next unless value.nil?

          columns = state.dimensions.fetch('columns')
          { column: index % columns, row: index / columns }
        end
        return nil if samples.empty?

        refusal(
          code: 'terrain_no_data_unsupported',
          message: 'Terrain state includes no-data samples and cannot be fully regenerated.',
          details: { samples: samples }
        )
      end

      def weighted_samples_for(state, frame, request)
        window = SampleWindow.from_owner_bounds(state, frame.outer_bounds(expand_by: state.spacing))
        return [] if window.empty?

        columns = state.dimensions.fetch('columns')
        (window.min_row..window.max_row).flat_map do |row|
          (window.min_column..window.max_column).filter_map do |column|
            coordinate = coordinate_for(state, column, row)
            weight = frame.weight_at(coordinate)
            weight = 0.0 if preserve_sample?(state, column, row, request)
            next unless weight.positive?

            { column: column, row: row, index: (row * columns) + column, weight: weight }
          end
        end
      end

      def edited_elevations_for(state, frame, weighted_samples)
        elevations = state.elevations.dup
        weighted_samples.each do |sample|
          coordinate = coordinate_for(state, sample.fetch(:column), sample.fetch(:row))
          target = target_elevation_for(frame, coordinate)
          before = elevations.fetch(sample.fetch(:index))
          weight = sample.fetch(:weight)
          elevations[sample.fetch(:index)] = before + ((target - before) * weight)
        end
        elevations
      end

      def target_elevation_for(frame, coordinate)
        start_elevation = frame.start_control.fetch('elevation')
        end_elevation = frame.end_control.fetch('elevation')
        parameter = frame.longitudinal_parameter(coordinate).clamp(0.0, 1.0)
        start_elevation + ((end_elevation - start_elevation) * parameter)
      end

      def diagnostics_for(state, edited_elevations, weighted_samples, request, frame)
        samples = changed_samples(state, edited_elevations, weighted_samples)
        {
          samples: samples,
          changedSampleCount: samples.length,
          changedRegion: SampleWindow.from_samples(samples).to_changed_region,
          fixedControls: {
            violations: [],
            controls: fixed_control_summaries(state, edited_elevations, request)
          },
          preserveZones: { protectedSampleCount: protected_sample_count(state, request) },
          transition: transition_summary(frame, samples, state, edited_elevations),
          warnings: []
        }
      end

      def changed_samples(state, edited_elevations, weighted_samples)
        weighted_samples.map do |sample|
          before = state.elevations.fetch(sample.fetch(:index))
          after = edited_elevations.fetch(sample.fetch(:index))
          {
            column: sample.fetch(:column),
            row: sample.fetch(:row),
            before: before,
            after: after,
            delta: after - before,
            weight: sample.fetch(:weight)
          }
        end
      end

      def transition_summary(frame, samples, state, edited_elevations)
        deltas = samples.map { |sample| sample.fetch(:delta) }
        {
          mode: 'corridor_transition',
          startControl: frame.start_control,
          endControl: frame.end_control,
          width: frame.width,
          sideBlend: frame.side_blend,
          endpointDeltas: endpoint_deltas(frame, state, edited_elevations),
          deltaSummary: {
            min: deltas.min || 0.0,
            max: deltas.max || 0.0
          }
        }
      end

      def endpoint_deltas(frame, state, edited_elevations)
        {
          start: endpoint_delta(frame.start_control, state, edited_elevations),
          end: endpoint_delta(frame.end_control, state, edited_elevations)
        }
      end

      def endpoint_delta(control, state, edited_elevations)
        point = control.fetch('point')
        target = control.fetch('elevation')
        (fixed_control_evaluator(state, edited_elevations, {}).interpolate(
          edited_elevations,
          point
        ) - target).abs
      end

      def fixed_control_summaries(state, edited_elevations, request)
        fixed_control_evaluator(state, edited_elevations, request).summaries
      end

      def preserve_sample?(state, column, row, request)
        coordinate = coordinate_for(state, column, row)
        preserve_zones(request).any? do |zone|
          bounds = expanded_bounds(zone.fetch('bounds'), state)
          coordinate.fetch('x').between?(bounds.fetch('minX'), bounds.fetch('maxX')) &&
            coordinate.fetch('y').between?(bounds.fetch('minY'), bounds.fetch('maxY'))
        end
      end

      def expanded_bounds(bounds, state)
        half_x = state.spacing.fetch('x') / 2.0
        half_y = state.spacing.fetch('y') / 2.0
        {
          'minX' => bounds.fetch('minX') - half_x,
          'minY' => bounds.fetch('minY') - half_y,
          'maxX' => bounds.fetch('maxX') + half_x,
          'maxY' => bounds.fetch('maxY') + half_y
        }
      end

      def protected_sample_count(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).sum do |row|
          (0...columns).count { |column| preserve_sample?(state, column, row, request) }
        end
      end

      def coordinate_for(state, column, row)
        {
          'x' => state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          'y' => state.origin.fetch('y') + (row * state.spacing.fetch('y'))
        }
      end

      def edited_state(state, elevations)
        HeightmapState.new(
          basis: state.basis,
          origin: state.origin,
          spacing: state.spacing,
          dimensions: state.dimensions,
          elevations: elevations,
          revision: state.revision + 1,
          state_id: state.state_id,
          source_summary: state.source_summary,
          constraint_refs: state.constraint_refs,
          owner_transform_signature: state.owner_transform_signature
        )
      end

      def fixed_controls(request)
        request.fetch('constraints', {}).fetch('fixedControls', [])
      end

      def fixed_control_evaluator(state, edited_elevations, request)
        FixedControlEvaluator.new(
          state: state,
          after_elevations: edited_elevations,
          fixed_controls: fixed_controls(request),
          default_tolerance: DEFAULT_FIXED_CONTROL_TOLERANCE
        )
      end

      def preserve_zones(request)
        request.fetch('constraints', {}).fetch('preserveZones', [])
      end

      def no_affected_samples_refusal
        refusal(
          code: 'edit_region_has_no_affected_samples',
          message: 'Terrain edit region does not affect any samples.',
          details: { field: 'region' }
        )
      end

      def refusal(code:, message:, details:)
        {
          success: true,
          outcome: 'refused',
          refusal: {
            code: code,
            message: message,
            details: details
          }
        }
      end
    end
  end
end
