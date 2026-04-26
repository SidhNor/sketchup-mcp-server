# frozen_string_literal: true

require_relative 'heightmap_state'
require_relative 'fixed_control_evaluator'
require_relative 'region_influence'
require_relative 'sample_window'

module SU_MCP
  module Terrain
    # SketchUp-free bounded target-height terrain edit kernel.
    # rubocop:disable Metrics/ClassLength, Metrics/MethodLength
    class BoundedGradeEdit
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01

      def apply(state:, request:)
        no_data_refusal = no_data_refusal_for(state)
        return no_data_refusal if no_data_refusal

        weighted_samples = weighted_samples_for(state, request)
        return no_affected_samples_refusal if weighted_samples.empty?

        edited_elevations = edited_elevations_for(state, request, weighted_samples)
        fixed_control_refusal = fixed_control_evaluator(
          state,
          edited_elevations,
          request
        ).conflict_refusal
        return fixed_control_refusal if fixed_control_refusal

        {
          outcome: 'edited',
          state: edited_state(state, edited_elevations),
          diagnostics: diagnostics_for(state, edited_elevations, weighted_samples, request)
        }
      end

      private

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

      def weighted_samples_for(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).flat_map do |row|
          (0...columns).filter_map do |column|
            coordinate = coordinate_for(state, column, row)
            weight = edit_weight_for(coordinate, request.fetch('region'))
            weight = 0.0 if preserve_sample?(state, column, row, request)
            next unless weight.positive?

            { column: column, row: row, index: (row * columns) + column, weight: weight }
          end
        end
      end

      def edited_elevations_for(state, request, weighted_samples)
        target = request.fetch('operation').fetch('targetElevation').to_f
        elevations = state.elevations.dup
        weighted_samples.each do |sample|
          before = elevations.fetch(sample.fetch(:index))
          weight = sample.fetch(:weight)
          elevations[sample.fetch(:index)] = before + ((target - before) * weight)
        end
        elevations
      end

      def edit_weight_for(coordinate, region)
        region_influence.weight_for(coordinate, region)
      end

      def preserve_sample?(state, column, row, request)
        coordinate = coordinate_for(state, column, row)
        preserve_zones(request).any? do |zone|
          region_influence.preserve_zone_contains?(coordinate, zone, state.spacing)
        end
      end

      def coordinate_for(state, column, row)
        {
          x: state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          y: state.origin.fetch('y') + (row * state.spacing.fetch('y'))
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

      def diagnostics_for(state, edited_elevations, weighted_samples, request)
        changed_samples = weighted_samples.map do |sample|
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
        {
          samples: changed_samples,
          changedSampleCount: changed_samples.length,
          changedRegion: changed_region(changed_samples),
          fixedControls: {
            violations: [],
            controls: fixed_control_summaries(state, edited_elevations, request)
          },
          preserveZones: { protectedSampleCount: protected_sample_count(state, request) },
          warnings: []
        }
      end

      def changed_region(samples)
        SampleWindow.from_samples(samples).to_changed_region
      end

      def fixed_control_summaries(state, edited_elevations, request)
        fixed_control_evaluator(state, edited_elevations, request).summaries
      end

      def protected_sample_count(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).sum do |row|
          (0...columns).count { |column| preserve_sample?(state, column, row, request) }
        end
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

      def region_influence
        @region_influence ||= RegionInfluence.new
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
    # rubocop:enable Metrics/ClassLength, Metrics/MethodLength
  end
end
