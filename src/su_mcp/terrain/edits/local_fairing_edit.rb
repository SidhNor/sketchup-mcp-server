# frozen_string_literal: true

require_relative '../regions/fixed_control_evaluator'
require_relative '../regions/region_influence'
require_relative '../regions/sample_window'

module SU_MCP
  module Terrain
    # SketchUp-free bounded local terrain fairing kernel.
    # rubocop:disable Metrics/ParameterLists
    class LocalFairingEdit
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01
      MATERIAL_DELTA_TOLERANCE = 1e-6
      METRIC = 'mean_absolute_neighborhood_residual'

      def apply(state:, request:)
        no_data_refusal = no_data_refusal_for(state)
        return no_data_refusal if no_data_refusal

        candidates = candidate_samples_for(state, request)
        return no_affected_samples_refusal if candidates.empty?

        edited_elevations, actual_iterations, convergence_warnings = fair_elevations(
          state,
          request,
          candidates
        )
        fixed_control_refusal = fixed_control_evaluator(
          state,
          edited_elevations,
          request
        ).conflict_refusal
        return fixed_control_refusal if fixed_control_refusal

        changed_samples = changed_samples_for(state, edited_elevations, candidates)
        return no_effect_refusal if changed_samples.empty?

        diagnostics = diagnostics_for(
          state,
          edited_elevations,
          candidates,
          changed_samples,
          request,
          actual_iterations,
          convergence_warnings
        )
        {
          outcome: 'edited',
          state: edited_state(state, edited_elevations),
          diagnostics: diagnostics
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

      def candidate_samples_for(state, request)
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

      def fair_elevations(state, request, candidates)
        operation = request.fetch('operation')
        radius = operation.fetch('neighborhoodRadiusSamples')
        strength = operation.fetch('strength').to_f
        iterations = operation.fetch('iterations', 1)
        elevations = state.elevations.dup
        actual_iterations = 0
        warnings = []

        iterations.times do
          snapshot = elevations.dup
          max_delta = apply_fairing_pass!(elevations, snapshot, state, candidates, radius, strength)
          actual_iterations += 1
          break if max_delta <= MATERIAL_DELTA_TOLERANCE
        end

        if actual_iterations.positive? && actual_iterations < iterations
          warnings << 'converged_early'
        end

        [elevations, actual_iterations, warnings]
      end

      def apply_fairing_pass!(elevations, snapshot, state, candidates, radius, strength)
        candidates.map do |sample|
          before = snapshot.fetch(sample.fetch(:index))
          average = neighborhood_average(state, snapshot, sample, radius)
          after = before + ((average - before) * strength * sample.fetch(:weight))
          elevations[sample.fetch(:index)] = after
          (after - before).abs
        end.max || 0.0
      end

      def neighborhood_average(state, elevations, sample, radius)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        column_range = clipped_range(sample.fetch(:column), radius, columns)
        row_range = clipped_range(sample.fetch(:row), radius, rows)
        values = row_range.flat_map do |row|
          column_range.map { |column| elevations.fetch((row * columns) + column) }
        end
        values.sum / values.length.to_f
      end

      def clipped_range(index, radius, count)
        ([index - radius, 0].max)..([index + radius, count - 1].min)
      end

      def diagnostics_for(state, edited_elevations, candidates, changed_samples, request,
                          actual_iterations, convergence_warnings)
        before_residual = residual_for(state, state.elevations, candidates, request)
        after_residual = residual_for(state, edited_elevations, candidates, request)
        improved = after_residual < before_residual
        warnings = convergence_warnings.dup
        warnings << 'fairing_residual_not_improved' unless improved
        {
          samples: changed_samples,
          changedSampleCount: changed_samples.length,
          changedRegion: SampleWindow.from_samples(changed_samples).to_changed_region,
          fixedControls: {
            violations: [],
            controls: fixed_control_summaries(state, edited_elevations, request)
          },
          preserveZones: { protectedSampleCount: protected_sample_count(state, request) },
          fairing: fairing_summary(
            request,
            before_residual,
            after_residual,
            improved,
            actual_iterations,
            warnings,
            changed_samples.length
          ),
          warnings: warnings
        }
      end

      def fairing_summary(request, before_residual, after_residual, improved, actual_iterations,
                          warnings, changed_sample_count)
        operation = request.fetch('operation')
        {
          metric: METRIC,
          beforeResidual: before_residual,
          afterResidual: after_residual,
          improved: improved,
          strength: operation.fetch('strength').to_f,
          neighborhoodRadiusSamples: operation.fetch('neighborhoodRadiusSamples'),
          iterations: operation.fetch('iterations', 1),
          actualIterations: actual_iterations,
          changedSampleCount: changed_sample_count,
          warnings: warnings
        }
      end

      def residual_for(state, elevations, candidates, request)
        radius = request.fetch('operation').fetch('neighborhoodRadiusSamples')
        residuals = candidates.map do |sample|
          (elevations.fetch(sample.fetch(:index)) -
            neighborhood_average(state, elevations, sample, radius)).abs
        end
        residuals.sum / residuals.length.to_f
      end

      def changed_samples_for(state, edited_elevations, candidates)
        candidates.filter_map do |sample|
          before = state.elevations.fetch(sample.fetch(:index))
          after = edited_elevations.fetch(sample.fetch(:index))
          delta = after - before
          next unless delta.abs > MATERIAL_DELTA_TOLERANCE

          {
            column: sample.fetch(:column),
            row: sample.fetch(:row),
            before: before,
            after: after,
            delta: delta,
            weight: sample.fetch(:weight)
          }
        end
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

      def protected_sample_count(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).sum do |row|
          (0...columns).count { |column| preserve_sample?(state, column, row, request) }
        end
      end

      def fixed_control_summaries(state, edited_elevations, request)
        fixed_control_evaluator(state, edited_elevations, request).summaries
      end

      def fixed_control_evaluator(state, edited_elevations, request)
        FixedControlEvaluator.new(
          state: state,
          after_elevations: edited_elevations,
          fixed_controls: fixed_controls(request),
          default_tolerance: DEFAULT_FIXED_CONTROL_TOLERANCE
        )
      end

      def coordinate_for(state, column, row)
        {
          'x' => state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          'y' => state.origin.fetch('y') + (row * state.spacing.fetch('y'))
        }
      end

      def edited_state(state, elevations)
        state.with_elevations(elevations, revision: state.revision + 1)
      end

      def fixed_controls(request)
        request.fetch('constraints', {}).fetch('fixedControls', [])
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

      def no_effect_refusal
        refusal(
          code: 'fairing_no_effect',
          message: 'Local fairing produced no material terrain changes.',
          details: { field: 'operation.mode', tolerance: MATERIAL_DELTA_TOLERANCE }
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
    # rubocop:enable Metrics/ParameterLists
  end
end
