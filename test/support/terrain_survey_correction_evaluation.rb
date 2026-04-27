# frozen_string_literal: true

require 'set'

require_relative '../../src/su_mcp/terrain/fixed_control_evaluator'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/region_influence'
require_relative '../../src/su_mcp/terrain/sample_window'

module SU_MCP
  module Terrain
    # Test-owned terrain-domain evaluation harness for MTA-14 survey correction strategy selection.
    class SurveyCorrectionEvaluation
      DEFAULT_PARAMETERS = {
        'radiusSamples' => 1,
        'passes' => 1,
        'coreRadiusM' => 0.5,
        'blendRadiusM' => 1.5,
        'falloff' => 'smoothstep',
        'surveyTolerance' => 0.01,
        'fixedControlTolerance' => 0.01,
        'maxSampleDelta' => 20.0,
        'slopeIncreaseLimit' => 20.0,
        'curvatureIncreaseLimit' => 20.0,
        'materialDeltaTolerance' => 1e-6
      }.freeze

      class << self
        def run(state:, survey_points:, strategy:, parameters: {}, fixed_controls: [],
                preserve_zones: [])
          new(
            state: state,
            survey_points: survey_points,
            strategy: strategy,
            parameters: parameters,
            fixed_controls: fixed_controls,
            preserve_zones: preserve_zones
          ).run
        end

        def repeated_workflow(state:, steps:, strategy:, parameters:)
          first_acceptable = nil
          current_state = state
          evaluations = steps.map do |survey_points|
            evaluation = run(
              state: current_state,
              survey_points: survey_points,
              strategy: strategy,
              parameters: parameters
            )
            if evaluation.dig('recommendationInputs', 'status') == 'satisfied'
              current_state = HeightmapState.from_h(evaluation.fetch('state'))
              first_acceptable ||= current_state.elevations
            end
            evaluation
          end
          last = evaluations.last
          {
            'steps' => evaluations,
            'metrics' => {
              'cumulativeDrift' => cumulative_drift_for(
                first_acceptable || state.elevations,
                current_state.elevations,
                current_state,
                steps.last,
                normalize_parameters(parameters)
              )
            },
            'recommendationInputs' => last.fetch('recommendationInputs')
          }
        end

        def compare_strategies(state:, survey_points:, parameter_matrix:)
          evaluations = [run(state: state, survey_points: survey_points, strategy: :minimum_change)]
          parameter_matrix.each do |parameters|
            evaluations << run(
              state: state,
              survey_points: survey_points,
              strategy: :base_detail,
              parameters: parameters
            )
          end
          {
            'evaluations' => evaluations,
            'recommendation' => recommend_from(evaluations)
          }
        end

        def recommend_from(evaluations)
          chosen = evaluations.find do |evaluation|
            inputs = evaluation.fetch('recommendationInputs')
            evaluation.fetch('strategy') == 'base_detail' &&
              inputs.fetch('status') == 'satisfied' &&
              inputs.fetch('detailPreserving') &&
              !inputs.fetch('thresholdOnly')
          end
          return recommendation_for(chosen) if chosen

          {
            'status' => 'escalate_mta11',
            'strategy' => nil,
            'detailPreserving' => false,
            'thresholdOnly' => false,
            'deferredSolver' => 'constrained_penalty_solver_deferred'
          }
        end

        def normalize_parameters(parameters)
          DEFAULT_PARAMETERS.merge(stringify_keys(parameters))
        end

        private

        def recommendation_for(evaluation)
          {
            'status' => 'satisfied',
            'strategy' => evaluation.fetch('strategy'),
            'parameters' => evaluation.fetch('parameters'),
            'detailPreserving' => true,
            'thresholdOnly' => false,
            'deferredSolver' => 'constrained_penalty_solver_deferred'
          }
        end

        def cumulative_drift_for(reference, current, state, survey_points, parameters)
          excluded = influence_indices_for(state, survey_points, parameters)
          deltas = current.each_index.filter_map do |index|
            next if excluded.include?(index)

            (current.fetch(index) - reference.fetch(index)).abs
          end
          drift_summary(deltas)
        end

        def influence_indices_for(state, survey_points, parameters)
          radius = parameters.fetch('coreRadiusM') + parameters.fetch('blendRadiusM')
          each_sample(state).filter_map do |sample|
            affected = survey_points.any? do |point|
              distance_between(sample.fetch(:coordinate), point.fetch('point')) <= radius
            end
            sample.fetch(:index) if affected
          end.to_set
        end

        def stringify_keys(hash)
          hash.each_with_object({}) { |(key, value), normalized| normalized[key.to_s] = value }
        end

        def distance_between(first, second)
          dx = first.fetch('x') - second.fetch('x')
          dy = first.fetch('y') - second.fetch('y')
          Math.sqrt((dx * dx) + (dy * dy))
        end

        def drift_summary(deltas)
          return { 'max' => 0.0, 'mean' => 0.0 } if deltas.empty?

          { 'max' => deltas.max, 'mean' => deltas.sum / deltas.length.to_f }
        end
      end

      def initialize(state:, survey_points:, strategy:, parameters:, fixed_controls:,
                     preserve_zones:)
        @state = state
        @survey_points = survey_points
        @strategy = strategy.to_s
        @parameters = self.class.normalize_parameters(parameters)
        @fixed_controls = fixed_controls
        @preserve_zones = preserve_zones
      end

      def run
        refusal = input_refusal
        return refusal_result(refusal) if refusal

        before = state.elevations
        calculation = corrected_elevations
        return refusal_result(calculation.fetch(:refusal)) if calculation.key?(:refusal)

        after = calculation.fetch(:after)
        fixed_refusal = fixed_control_refusal(after)
        return refusal_result(fixed_refusal) if fixed_refusal

        metrics = metrics_for(before, after, calculation)
        refusals = [
          preserve_zone_refusal_for(metrics),
          metric_refusal_for(metrics)
        ].compact
        status = refusals.empty? ? status_for(metrics) : 'refuse'
        result_for(after, calculation, metrics, status, refusals)
      end

      private

      attr_reader :state, :survey_points, :strategy, :parameters, :fixed_controls, :preserve_zones

      def input_refusal
        out_of_bounds = survey_points.find { |point| !inside_bounds?(point.fetch('point')) }
        return refusal('survey_point_outside_bounds', out_of_bounds) if out_of_bounds

        no_data = survey_points.find do |point|
          stencil_weights(point.fetch('point')).keys.any? do |index|
            state.elevations.fetch(index).nil?
          end
        end
        return refusal('survey_point_over_no_data', no_data) if no_data

        contradiction = contradictory_point
        return refusal('contradictory_survey_points', contradiction) if contradiction

        preserve_conflict = survey_points.find do |point|
          inside_preserve_zone?(point.fetch('point'))
        end
        if preserve_conflict
          return refusal('survey_point_preserve_zone_conflict',
                         preserve_conflict)
        end

        nil
      end

      def corrected_elevations
        case strategy
        when 'minimum_change'
          baseline_elevations(state.elevations, survey_targets(survey_points))
        when 'base_detail'
          base_detail_elevations
        else
          { refusal: refusal('unsupported_strategy', { 'strategy' => strategy }) }
        end
      end

      def baseline_elevations(source_elevations, targets)
        solve_result = solve_minimum_norm(source_elevations, targets)
        return solve_result if solve_result.key?(:refusal)

        { after: solve_result.fetch(:after),
          retained_detail: Array.new(source_elevations.length, 0.0) }
      end

      def base_detail_elevations
        base = low_pass(state.elevations)
        detail = state.elevations.zip(base).map { |height, base_height| height - base_height }
        mask = detail_mask
        retained_detail = detail.zip(mask).map { |value, factor| value * factor }
        retained_by_point = survey_points.to_h do |survey_point|
          [survey_point.fetch('id'),
           interpolate(retained_detail, survey_point.fetch('point'))]
        end
        targets = survey_points.map do |survey_point|
          retained_value = retained_by_point.fetch(survey_point.fetch('id'))
          {
            'id' => survey_point.fetch('id'),
            'point' => survey_point.fetch('point'),
            'z' => survey_point.fetch('point').fetch('z') - retained_value
          }
        end
        solve_result = solve_minimum_norm(base, targets)
        return solve_result if solve_result.key?(:refusal)

        corrected_base = solve_result.fetch(:after)
        {
          after: corrected_base.zip(retained_detail).map do |base_height, detail_height|
            base_height + detail_height
          end,
          base: base,
          detail: detail,
          mask: mask,
          retained_detail: retained_detail,
          retained_detail_at_survey_points: retained_by_point
        }
      end

      def solve_minimum_norm(source_elevations, targets)
        variables = affected_variables_for(targets)
        rows = targets.map do |target|
          variables.map do |index|
            stencil_weights(target.fetch('point')).fetch(index, 0.0)
          end
        end
        residuals = targets.map do |target|
          target.fetch('z') - interpolate(source_elevations, target.fetch('point'))
        end
        # Minimum-norm dual solve: A A^T lambda = residuals, deltas = A^T lambda.
        gram = rows.map { |row_a| rows.map { |row_b| dot(row_a, row_b) } }
        multipliers = solve_linear_system(gram, residuals)
        return { refusal: refusal('contradictory_survey_points', targets) } unless multipliers

        deltas = variables.map.with_index do |_variable, column|
          rows.each_index.sum { |row| rows.fetch(row).fetch(column) * multipliers.fetch(row) }
        end
        after = source_elevations.dup
        variables.each_with_index { |index, offset| after[index] += deltas.fetch(offset) }
        { after: after }
      end

      def affected_variables_for(targets)
        targets.flat_map { |target| stencil_weights(target.fetch('point')).keys }.uniq.sort
      end

      def metrics_for(before, after, calculation)
        detail, retained = detail_arrays_for(calculation)
        {
          'maxSampleDelta' => max_sample_delta(before, after),
          'changedRegion' => changed_region(before, after),
          'detailRetention' => detail_retention(detail, retained),
          'detailSuppression' => detail_suppression(detail, retained),
          'slopeProxy' => proxy_summary(slope_values(before), slope_values(after)),
          'curvatureProxy' => proxy_summary(curvature_values(before), curvature_values(after)),
          'fixedControlDrift' => fixed_control_drift(after),
          'preserveZoneDrift' => preserve_zone_drift(before, after),
          'cumulativeDrift' => { 'max' => 0.0, 'mean' => 0.0 }
        }
      end

      def detail_arrays_for(calculation)
        if calculation.key?(:detail)
          return [calculation.fetch(:detail),
                  calculation.fetch(:retained_detail)]
        end

        detail = state.elevations.zip(low_pass(state.elevations)).map do |height, base_height|
          height - base_height
        end
        [detail, detail]
      end

      def result_for(after, calculation, metrics, status, refusals)
        {
          'strategy' => strategy,
          'parameters' => parameters,
          'surveyPoints' => survey_summaries(after, status),
          'metrics' => metrics,
          'warnings' => status == 'warn' ? ['approaches_distortion_threshold'] : [],
          'refusals' => refusals,
          'recommendationInputs' => recommendation_inputs(calculation, status),
          'state' => edited_state(after).to_h
        }
      end

      def recommendation_inputs(calculation, status)
        inputs = {
          'status' => status,
          'detailPreserving' => strategy == 'base_detail' && status == 'satisfied',
          'thresholdOnly' => false
        }
        if calculation.key?(:retained_detail_at_survey_points)
          inputs['retainedDetailAtSurveyPoints'] =
            calculation.fetch(:retained_detail_at_survey_points)
        end
        inputs
      end

      def survey_summaries(after, status)
        survey_points.map do |survey_point|
          point = survey_point.fetch('point')
          after_elevation = interpolate(after, point)
          tolerance = survey_point.fetch('tolerance', parameters.fetch('surveyTolerance')).to_f
          residual = after_elevation - point.fetch('z')
          {
            'id' => survey_point.fetch('id'),
            'point' => point,
            'beforeElevation' => interpolate(state.elevations, point),
            'afterElevation' => after_elevation,
            'residual' => residual,
            'tolerance' => tolerance,
            'status' => residual.abs <= tolerance ? status : 'refused'
          }
        end
      end

      def refusal_result(refusal)
        {
          'strategy' => strategy,
          'parameters' => parameters,
          'surveyPoints' => [],
          'metrics' => empty_metrics,
          'warnings' => [],
          'refusals' => [refusal],
          'recommendationInputs' => {
            'status' => 'refuse',
            'detailPreserving' => false,
            'thresholdOnly' => false
          },
          'state' => state.to_h
        }
      end

      def empty_metrics
        {
          'maxSampleDelta' => 0.0,
          'changedRegion' => { 'sampleCount' => 0, 'bounds' => nil },
          'detailRetention' => { 'outsideInfluenceRatio' => 0.0 },
          'detailSuppression' => { 'coreEnergy' => 0.0, 'blendEnergy' => 0.0 },
          'slopeProxy' => { 'beforeMax' => 0.0, 'afterMax' => 0.0, 'maxIncrease' => 0.0 },
          'curvatureProxy' => { 'beforeMax' => 0.0, 'afterMax' => 0.0, 'maxIncrease' => 0.0 },
          'fixedControlDrift' => { 'max' => 0.0, 'controls' => [] },
          'preserveZoneDrift' => { 'max' => 0.0, 'mean' => 0.0, 'zones' => [] },
          'cumulativeDrift' => { 'max' => 0.0, 'mean' => 0.0 }
        }
      end

      def low_pass(elevations)
        radius = parameters.fetch('radiusSamples').to_i
        smoothed = elevations.dup
        parameters.fetch('passes').to_i.times do
          snapshot = smoothed.dup
          smoothed = each_sample(state).map do |sample|
            neighborhood = neighborhood_indices(sample.fetch(:column), sample.fetch(:row), radius)
            neighborhood.sum { |index| snapshot.fetch(index) } / neighborhood.length.to_f
          end
        end
        smoothed
      end

      def detail_mask
        each_sample(state).map do |sample|
          survey_points.map do |survey_point|
            mask_for(sample.fetch(:coordinate), survey_point.fetch('point'))
          end.min || 1.0
        end
      end

      def mask_for(coordinate, point)
        core = parameters.fetch('coreRadiusM')
        blend = parameters.fetch('blendRadiusM')
        distance = distance(coordinate, point)
        return 0.0 if distance <= core
        return 1.0 if blend <= 0.0 || distance >= core + blend

        normalized = (distance - core) / blend
        return normalized if parameters.fetch('falloff') == 'linear'

        smoothstep(normalized)
      end

      def detail_retention(detail, retained)
        outside = each_sample(state).filter_map do |sample|
          sample.fetch(:index) unless in_influence?(sample.fetch(:coordinate))
        end
        denominator = outside.sum { |index| detail.fetch(index).abs }
        ratio = if denominator.zero?
                  1.0
                else
                  outside.sum do |index|
                    retained.fetch(index).abs
                  end / denominator
                end
        { 'outsideInfluenceRatio' => ratio }
      end

      def detail_suppression(detail, retained)
        core = 0.0
        blend = 0.0
        each_sample(state).each do |sample|
          zone = influence_zone(sample.fetch(:coordinate))
          index = sample.fetch(:index)
          suppression = (detail.fetch(index) - retained.fetch(index)).abs
          core += suppression if zone == :core
          blend += suppression if zone == :blend
        end
        { 'coreEnergy' => core, 'blendEnergy' => blend }
      end

      def in_influence?(coordinate)
        influence_radius = parameters.fetch('coreRadiusM') + parameters.fetch('blendRadiusM')
        survey_points.any? do |survey_point|
          distance(coordinate, survey_point.fetch('point')) < influence_radius
        end
      end

      def influence_zone(coordinate)
        min_distance = survey_points.map do |survey_point|
          distance(coordinate, survey_point.fetch('point'))
        end.min
        return nil unless min_distance
        return :core if min_distance <= parameters.fetch('coreRadiusM')
        if min_distance < parameters.fetch('coreRadiusM') + parameters.fetch('blendRadiusM')
          return :blend
        end

        nil
      end

      def max_sample_delta(before, after)
        before.zip(after).map do |before_height, after_height|
          (after_height - before_height).abs
        end.max || 0.0
      end

      def changed_region(before, after)
        tolerance = parameters.fetch('materialDeltaTolerance')
        samples = before.each_index.filter_map do |index|
          delta = after.fetch(index) - before.fetch(index)
          next unless delta.abs > tolerance

          columns = state.dimensions.fetch('columns')
          { column: index % columns, row: index / columns }
        end
        {
          'sampleCount' => samples.length,
          'bounds' => SampleWindow.from_samples(samples).to_changed_region&.then do |region|
            stringify_nested_keys(region)
          end
        }
      end

      def slope_values(elevations)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        values = []
        (0...rows).each do |row|
          (0...columns).each do |column|
            index = (row * columns) + column
            if column < columns - 1
              values << adjacent_slope(elevations, index, index + 1, state.spacing.fetch('x'))
            end
            if row < rows - 1
              values << adjacent_slope(elevations, index, index + columns, state.spacing.fetch('y'))
            end
          end
        end
        values
      end

      def adjacent_slope(elevations, first, second, spacing)
        (elevations.fetch(second) - elevations.fetch(first)).abs / spacing
      end

      def curvature_values(elevations)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        values = []
        (0...rows).each do |row|
          (1...(columns - 1)).each do |column|
            index = (row * columns) + column
            values << curvature_value(
              elevations,
              index - 1,
              index,
              index + 1,
              state.spacing.fetch('x')
            )
          end
        end
        (1...(rows - 1)).each do |row|
          (0...columns).each do |column|
            index = (row * columns) + column
            values << curvature_value(
              elevations,
              index - columns,
              index,
              index + columns,
              state.spacing.fetch('y')
            )
          end
        end
        values
      end

      def curvature_value(elevations, first, middle, last, spacing)
        (elevations.fetch(first) - (2.0 * elevations.fetch(middle)) + elevations.fetch(last)).abs /
          (spacing**2)
      end

      def proxy_summary(before_values, after_values)
        before_max = before_values.max || 0.0
        after_max = after_values.max || 0.0
        { 'beforeMax' => before_max, 'afterMax' => after_max,
          'maxIncrease' => [after_max - before_max, 0.0].max }
      end

      def fixed_control_drift(after)
        evaluator = FixedControlEvaluator.new(
          state: state,
          after_elevations: after,
          fixed_controls: fixed_controls,
          default_tolerance: parameters.fetch('fixedControlTolerance')
        )
        controls = evaluator.summaries.map do |summary|
          { 'id' => summary[:id], 'delta' => summary[:delta],
            'effectiveTolerance' => summary[:effectiveTolerance] }
        end
        { 'max' => controls.map do |control|
          control.fetch('delta')
        end.max || 0.0, 'controls' => controls }
      end

      def fixed_control_refusal(after)
        drift = fixed_control_drift(after)
        conflict = drift.fetch('controls').find do |control|
          control.fetch('delta') > control.fetch('effectiveTolerance')
        end
        return nil unless conflict

        refusal('fixed_control_conflict', conflict)
      end

      def preserve_zone_drift(before, after)
        zones = preserve_zones.map do |zone|
          deltas = each_sample(state).filter_map do |sample|
            next unless region_influence.preserve_zone_contains?(sample.fetch(:coordinate), zone,
                                                                 state.spacing)

            index = sample.fetch(:index)
            (after.fetch(index) - before.fetch(index)).abs
          end
          { 'id' => zone['id'], 'max' => deltas.max || 0.0, 'mean' => mean(deltas) }
        end
        zone_maxes = zones.map { |zone| zone.fetch('max') }
        zone_means = zones.map { |zone| zone.fetch('mean') }
        {
          'max' => zone_maxes.max || 0.0,
          'mean' => mean(zone_means),
          'zones' => zones
        }
      end

      def preserve_zone_refusal_for(metrics)
        tolerance = parameters.fetch('preserveZoneTolerance',
                                     parameters.fetch('materialDeltaTolerance'))
        return nil unless metrics.dig('preserveZoneDrift', 'max') > tolerance

        refusal(
          'survey_point_preserve_zone_conflict',
          {
            'maxPreserveZoneDrift' => metrics.dig('preserveZoneDrift', 'max'),
            'tolerance' => tolerance
          }
        )
      end

      def status_for(metrics)
        return 'warn' if metrics.dig('slopeProxy',
                                     'maxIncrease') > parameters.fetch('slopeIncreaseLimit')
        return 'warn' if metrics.dig('curvatureProxy',
                                     'maxIncrease') > parameters.fetch('curvatureIncreaseLimit')

        'satisfied'
      end

      def metric_refusal_for(metrics)
        if metrics.fetch('maxSampleDelta') > parameters.fetch('maxSampleDelta')
          return refusal(
            'required_sample_delta_exceeds_threshold',
            {
              'maxSampleDelta' => metrics.fetch('maxSampleDelta'),
              'threshold' => parameters.fetch('maxSampleDelta')
            }
          )
        end

        nil
      end

      def edited_state(elevations)
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

      def survey_targets(points)
        points.map do |survey_point|
          {
            'id' => survey_point.fetch('id'),
            'point' => survey_point.fetch('point'),
            'z' => survey_point.fetch('point').fetch('z')
          }
        end
      end

      def interpolate(elevations, point)
        stencil_weights(point).sum { |index, weight| elevations.fetch(index) * weight }
      end

      def stencil_weights(point)
        x_grid = (point.fetch('x').to_f - state.origin.fetch('x')) / state.spacing.fetch('x')
        y_grid = (point.fetch('y').to_f - state.origin.fetch('y')) / state.spacing.fetch('y')
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        x0 = x_grid.floor.clamp(0, columns - 1)
        y0 = y_grid.floor.clamp(0, rows - 1)
        x1 = (x0 + 1).clamp(0, columns - 1)
        y1 = (y0 + 1).clamp(0, rows - 1)
        tx = x1 == x0 ? 0.0 : x_grid - x0
        ty = y1 == y0 ? 0.0 : y_grid - y0
        raw_weights = [
          [(y0 * columns) + x0, (1.0 - tx) * (1.0 - ty)],
          [(y0 * columns) + x1, tx * (1.0 - ty)],
          [(y1 * columns) + x0, (1.0 - tx) * ty],
          [(y1 * columns) + x1, tx * ty]
        ]
        raw_weights.each_with_object(Hash.new(0.0)) do |(index, weight), weights|
          weights[index] += weight
        end
      end

      def solve_linear_system(matrix, vector)
        n = vector.length
        augmented = matrix.each_with_index.map do |row, index|
          row.map(&:to_f) + [vector.fetch(index).to_f]
        end
        n.times do |pivot|
          pivot_row = (pivot...n).max_by { |row| augmented.fetch(row).fetch(pivot).abs }
          return nil if augmented.fetch(pivot_row).fetch(pivot).abs < 1e-10

          augmented[pivot], augmented[pivot_row] = augmented[pivot_row], augmented[pivot]
          scale = augmented.fetch(pivot).fetch(pivot)
          (pivot..n).each { |column| augmented.fetch(pivot)[column] /= scale }
          n.times do |row|
            next if row == pivot

            factor = augmented.fetch(row).fetch(pivot)
            (pivot..n).each do |column|
              augmented.fetch(row)[column] -= factor * augmented.fetch(pivot).fetch(column)
            end
          end
        end
        augmented.map { |row| row.fetch(n) }
      end

      def contradictory_point
        survey_points.combination(2).find do |first, second|
          first.fetch('point').fetch('x') == second.fetch('point').fetch('x') &&
            first.fetch('point').fetch('y') == second.fetch('point').fetch('y') &&
            (first.fetch('point').fetch('z') - second.fetch('point').fetch('z')).abs >
              [first.fetch('tolerance', parameters.fetch('surveyTolerance')),
               second.fetch('tolerance', parameters.fetch('surveyTolerance'))].min
        end
      end

      def inside_bounds?(point)
        x_grid = (point.fetch('x').to_f - state.origin.fetch('x')) / state.spacing.fetch('x')
        y_grid = (point.fetch('y').to_f - state.origin.fetch('y')) / state.spacing.fetch('y')
        x_grid.between?(0.0, state.dimensions.fetch('columns') - 1) &&
          y_grid.between?(0.0, state.dimensions.fetch('rows') - 1)
      end

      def inside_preserve_zone?(point)
        preserve_zones.any? do |zone|
          region_influence.preserve_zone_contains?(point, zone, state.spacing)
        end
      end

      def neighborhood_indices(column, row, radius)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        row_range = ([row - radius, 0].max)..([row + radius, rows - 1].min)
        column_range = ([column - radius, 0].max)..([column + radius, columns - 1].min)
        row_range.flat_map { |y| column_range.map { |x| (y * columns) + x } }
      end

      def each_sample(state)
        self.class.send(:each_sample, state)
      end

      def self.each_sample(state)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).flat_map do |row|
          (0...columns).map do |column|
            {
              column: column,
              row: row,
              index: (row * columns) + column,
              coordinate: {
                'x' => state.origin.fetch('x') + (column * state.spacing.fetch('x')),
                'y' => state.origin.fetch('y') + (row * state.spacing.fetch('y'))
              }
            }
          end
        end
      end
      private_class_method :each_sample

      def refusal(code, details)
        { 'code' => code, 'details' => stringify_nested_keys(details) }
      end

      def stringify_nested_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), hash|
            hash[key.to_s] = stringify_nested_keys(nested)
          end
        when Array
          value.map { |nested| stringify_nested_keys(nested) }
        else
          value
        end
      end

      def dot(first, second)
        first.zip(second).sum { |left, right| left * right }
      end

      def distance(first, second)
        dx = first.fetch('x') - second.fetch('x')
        dy = first.fetch('y') - second.fetch('y')
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def smoothstep(value)
        value * value * (3.0 - (2.0 * value))
      end

      def mean(values)
        return 0.0 if values.empty?

        values.sum / values.length.to_f
      end

      def region_influence
        @region_influence ||= RegionInfluence.new
      end
    end
  end
end
