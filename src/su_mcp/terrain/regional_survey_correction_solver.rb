# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Bounded regional survey correction over an explicit terrain support region.
    class RegionalSurveyCorrectionSolver
      def initialize(context)
        @context = context
      end

      def run
        solved = solve_minimum_norm(coherent_seed, survey_targets, context.mutable_indices)
        return { refusal: solved.fetch(:refusal) } if solved.is_a?(Hash) && solved.key?(:refusal)

        { after: solved, solver_metrics: {} }
      end

      private

      attr_reader :context

      def coherent_seed
        residuals = survey_residuals
        context.state.elevations.each_with_index.map do |height, index|
          sample = context.sample_for(index)
          next height unless context.mutable_sample?(sample)

          height + inverse_distance_weighted_residual(sample.fetch(:coordinate), residuals)
        end
      end

      def inverse_distance_weighted_residual(coordinate, residuals)
        exact = residuals.find do |residual|
          context.distance(coordinate, residual.fetch(:point)).zero?
        end
        return exact.fetch(:residual) if exact

        weights = residuals.map { |residual| [residual, residual_weight(coordinate, residual)] }
        total = weights.sum { |_residual, weight| weight }
        weights.sum { |residual, weight| residual.fetch(:residual) * weight } / total
      end

      def residual_weight(coordinate, residual)
        1.0 / [context.distance(coordinate, residual.fetch(:point)), 0.001].max
      end

      def solve_minimum_norm(source_elevations, targets, mutable)
        variables = variables_for(targets, mutable)
        return { refusal: no_affected_samples_refusal } if variables.empty?

        rows = rows_for(targets, variables)
        residuals = residuals_for(targets, source_elevations)
        multipliers = solve_linear_system(gram_matrix(rows), residuals)
        return { refusal: contradictory_solver_refusal(targets) } unless multipliers

        apply_deltas(source_elevations, variables, rows, multipliers)
      end

      def variables_for(targets, mutable)
        variables = targets.flat_map do |target|
          context.stencil_weights(target.fetch(:point)).keys
        end
        variables.uniq.select { |index| mutable.include?(index) }.sort
      end

      def rows_for(targets, variables)
        targets.map do |target|
          weights = context.stencil_weights(target.fetch(:point))
          variables.map { |index| weights.fetch(index, 0.0) }
        end
      end

      def residuals_for(targets, source_elevations)
        targets.map do |target|
          target.fetch(:z) - context.interpolate(source_elevations, target.fetch(:point))
        end
      end

      def gram_matrix(rows)
        rows.map { |row_a| rows.map { |row_b| dot(row_a, row_b) } }
      end

      def apply_deltas(source_elevations, variables, rows, multipliers)
        after = source_elevations.dup
        variables.each_with_index do |index, column|
          after[index] += delta_for_column(rows, multipliers, column)
        end
        after
      end

      def delta_for_column(rows, multipliers, column)
        rows.each_index.sum do |row|
          rows.fetch(row).fetch(column) * multipliers.fetch(row)
        end
      end

      def solve_linear_system(matrix, vector)
        size = vector.length
        augmented = augmented_matrix(matrix, vector)
        size.times do |pivot|
          pivot_row = (pivot...size).max_by { |row| augmented.fetch(row).fetch(pivot).abs }
          return nil if augmented.fetch(pivot_row).fetch(pivot).abs < 1e-10

          reduce_pivot!(augmented, pivot, pivot_row, size)
        end
        augmented.map { |row| row.fetch(size) }
      end

      def augmented_matrix(matrix, vector)
        matrix.each_with_index.map do |row, index|
          row.map(&:to_f) + [vector.fetch(index)]
        end
      end

      def reduce_pivot!(augmented, pivot, pivot_row, size)
        augmented[pivot], augmented[pivot_row] = augmented[pivot_row], augmented[pivot]
        scale = augmented.fetch(pivot).fetch(pivot)
        (pivot..size).each { |column| augmented.fetch(pivot)[column] /= scale }
        size.times do |row|
          next if row == pivot

          eliminate_row!(augmented, pivot, row, size)
        end
      end

      def eliminate_row!(augmented, pivot, row, size)
        factor = augmented.fetch(row).fetch(pivot)
        (pivot..size).each do |column|
          augmented.fetch(row)[column] -= factor * augmented.fetch(pivot).fetch(column)
        end
      end

      def survey_targets
        targets = context.survey_points.map do |survey_point|
          point = context.point_for(survey_point)
          { id: survey_point['id'], point: point, z: point.fetch('z') }
        end
        # Collapse duplicate equations; survey diagnostics still emits every requested point.
        targets.uniq { |target| context.target_key(target) }
      end

      def before
        context.state.elevations
      end

      def survey_residuals
        context.survey_points.map do |survey_point|
          point = context.point_for(survey_point)
          { point: point, residual: point.fetch('z') - context.interpolate(before, point) }
        end
      end

      def dot(first, second)
        first.zip(second).sum { |a, b| a * b }
      end

      def no_affected_samples_refusal
        refusal(
          code: 'edit_region_has_no_affected_samples',
          message: 'Survey correction support region does not affect mutable samples.',
          details: { field: 'region' }
        )
      end

      def contradictory_solver_refusal(targets)
        refusal(
          code: 'contradictory_survey_points',
          message: 'Survey point constraints cannot be solved together.',
          details: { surveyPoints: targets.map { |target| target.slice(:id, :point) } }
        )
      end

      def refusal(code:, message:, details:)
        {
          success: true,
          outcome: 'refused',
          refusal: { code: code, message: message, details: details }
        }
      end
    end
  end
end
