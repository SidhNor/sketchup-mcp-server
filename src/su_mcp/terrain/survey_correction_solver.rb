# frozen_string_literal: true

require_relative 'sample_window'

module SU_MCP
  module Terrain
    # Production survey-correction math promoted from the MTA-14 evaluation harness.
    # This class stays SketchUp-free and returns only terrain-domain arrays and metrics.
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity, Layout/LineLength
    # rubocop:disable Style/MultilineBlockChain
    class SurveyCorrectionSolver
      DEFAULT_PARAMETERS = {
        radius_samples: 1,
        passes: 1,
        core_radius_m: 0.5,
        blend_radius_m: 1.5,
        falloff: 'smoothstep',
        material_delta_tolerance: 1e-6
      }.freeze

      def initialize(state:, survey_points:, mutable_indices:, parameters: {})
        @state = state
        @survey_points = survey_points
        @mutable_indices = mutable_indices
        @parameters = DEFAULT_PARAMETERS.merge(parameters)
      end

      def run
        calculation = base_detail_elevations
        return calculation if calculation.key?(:refusal)

        after = calculation.fetch(:after)
        {
          after: after,
          metrics: metrics_for(calculation, after)
        }
      end

      private

      attr_reader :state, :survey_points, :mutable_indices, :parameters

      def base_detail_elevations
        base = low_pass(state.elevations)
        detail = state.elevations.zip(base).map { |height, base_height| height - base_height }
        mask = detail_mask
        retained_detail = detail.zip(mask).map { |value, factor| value * factor }
        targets = survey_points.map do |survey_point|
          point = survey_point.fetch('point')
          {
            id: survey_point['id'],
            point: point,
            z: point.fetch('z') - interpolate(retained_detail, point)
          }
        end.uniq { |target| target_key(target) }
        # Collapse duplicate equations; callers still report every requested survey point.
        solve_result = solve_minimum_norm(base, targets)
        return solve_result if solve_result.key?(:refusal)

        corrected_base = solve_result.fetch(:after)
        after = corrected_base.zip(retained_detail).map.with_index do |(base_height, detail_height), index|
          mutable_indices.include?(index) ? base_height + detail_height : state.elevations.fetch(index)
        end
        {
          after: after,
          detail: detail,
          retained_detail: retained_detail,
          mask: mask
        }
      end

      def solve_minimum_norm(source_elevations, targets)
        variables = targets.flat_map do |target|
          stencil_weights(target.fetch(:point)).keys
        end.uniq.select { |index| mutable_indices.include?(index) }.sort
        return { refusal: refusal('edit_region_has_no_affected_samples') } if variables.empty?

        rows = targets.map do |target|
          weights = stencil_weights(target.fetch(:point))
          variables.map { |index| weights.fetch(index, 0.0) }
        end
        residuals = targets.map do |target|
          target.fetch(:z) - interpolate(source_elevations, target.fetch(:point))
        end
        gram = rows.map { |row_a| rows.map { |row_b| dot(row_a, row_b) } }
        multipliers = solve_linear_system(gram, residuals)
        return { refusal: refusal('contradictory_survey_points') } unless multipliers

        deltas = variables.map.with_index do |_variable, column|
          rows.each_index.sum { |row| rows.fetch(row).fetch(column) * multipliers.fetch(row) }
        end
        after = source_elevations.dup
        variables.each_with_index { |index, offset| after[index] += deltas.fetch(offset) }
        { after: after }
      end

      def metrics_for(calculation, after)
        detail = calculation.fetch(:detail)
        retained = calculation.fetch(:retained_detail)
        {
          detailRetention: detail_retention(detail, retained),
          detailSuppression: detail_suppression(detail, retained),
          changedRegion: changed_region(state.elevations, after)
        }
      end

      def low_pass(elevations)
        radius = parameters.fetch(:radius_samples)
        smoothed = elevations.dup
        parameters.fetch(:passes).times do
          snapshot = smoothed.dup
          smoothed = each_sample.map do |sample|
            neighborhood = neighborhood_indices(sample.fetch(:column), sample.fetch(:row), radius)
            neighborhood.sum { |index| snapshot.fetch(index) } / neighborhood.length.to_f
          end
        end
        smoothed
      end

      def detail_mask
        each_sample.map do |sample|
          next 1.0 unless mutable_indices.include?(sample.fetch(:index))

          survey_points.map do |survey_point|
            mask_for(sample.fetch(:coordinate), survey_point.fetch('point'))
          end.min || 1.0
        end
      end

      def mask_for(coordinate, point)
        core = parameters.fetch(:core_radius_m)
        blend = parameters.fetch(:blend_radius_m)
        distance = distance_between(coordinate, point)
        return 0.0 if distance <= core
        return 1.0 if blend <= 0.0 || distance >= core + blend

        normalized = (distance - core) / blend
        return normalized if parameters.fetch(:falloff) == 'linear'

        smoothstep(normalized)
      end

      def detail_retention(detail, retained)
        outside = each_sample.filter_map do |sample|
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
        { outsideInfluenceRatio: ratio }
      end

      def detail_suppression(detail, retained)
        core = 0.0
        blend = 0.0
        each_sample.each do |sample|
          zone = influence_zone(sample.fetch(:coordinate))
          index = sample.fetch(:index)
          suppression = (detail.fetch(index) - retained.fetch(index)).abs
          core += suppression if zone == :core
          blend += suppression if zone == :blend
        end
        { coreEnergy: core, blendEnergy: blend }
      end

      def in_influence?(coordinate)
        influence_radius = parameters.fetch(:core_radius_m) + parameters.fetch(:blend_radius_m)
        survey_points.any? do |survey_point|
          distance_between(coordinate, survey_point.fetch('point')) < influence_radius
        end
      end

      def influence_zone(coordinate)
        min_distance = survey_points.map do |survey_point|
          distance_between(coordinate, survey_point.fetch('point'))
        end.min
        return nil unless min_distance
        return :core if min_distance <= parameters.fetch(:core_radius_m)
        if min_distance < parameters.fetch(:core_radius_m) + parameters.fetch(:blend_radius_m)
          return :blend
        end

        nil
      end

      def changed_region(before, after)
        samples = before.each_index.filter_map do |index|
          delta = after.fetch(index) - before.fetch(index)
          next unless delta.abs > parameters.fetch(:material_delta_tolerance)

          columns = state.dimensions.fetch('columns')
          { column: index % columns, row: index / columns }
        end
        {
          sampleCount: samples.length,
          bounds: SampleWindow.from_samples(samples).to_changed_region
        }
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
        [
          [(y0 * columns) + x0, (1.0 - tx) * (1.0 - ty)],
          [(y0 * columns) + x1, tx * (1.0 - ty)],
          [(y1 * columns) + x0, (1.0 - tx) * ty],
          [(y1 * columns) + x1, tx * ty]
        ].each_with_object(Hash.new(0.0)) do |(index, weight), weights|
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

      def neighborhood_indices(column, row, radius)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        row_range = ([row - radius, 0].max)..([row + radius, rows - 1].min)
        column_range = ([column - radius, 0].max)..([column + radius, columns - 1].min)
        row_range.flat_map { |y| column_range.map { |x| (y * columns) + x } }
      end

      def each_sample
        state.elevations.each_index.map do |index|
          columns = state.dimensions.fetch('columns')
          column = index % columns
          row = index / columns
          {
            index: index,
            column: column,
            row: row,
            coordinate: {
              'x' => state.origin.fetch('x') + (column * state.spacing.fetch('x')),
              'y' => state.origin.fetch('y') + (row * state.spacing.fetch('y'))
            }
          }
        end
      end

      def distance_between(first, second)
        dx = first.fetch('x') - second.fetch('x')
        dy = first.fetch('y') - second.fetch('y')
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def smoothstep(value)
        value * value * (3.0 - (2.0 * value))
      end

      def dot(first, second)
        first.zip(second).sum { |a, b| a * b }
      end

      def target_key(target)
        point = target.fetch(:point)
        [point.fetch('x'), point.fetch('y'), target.fetch(:z)]
      end

      def refusal(code)
        {
          refusal: {
            success: true,
            outcome: 'refused',
            refusal: {
              code: code,
              message: 'Survey point constraints cannot be solved for the requested support.',
              details: { field: 'constraints.surveyPoints' }
            }
          }
        }
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity, Layout/LineLength
    # rubocop:enable Style/MultilineBlockChain
  end
end
