# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Shared fixed-control elevation checks for heightmap edit kernels.
    class FixedControlEvaluator
      def initialize(state:, after_elevations:, fixed_controls:, default_tolerance:)
        @state = state
        @after_elevations = after_elevations
        @fixed_controls = fixed_controls
        @default_tolerance = default_tolerance
      end

      def conflict_refusal
        conflict = fixed_controls.lazy.map { |control| conflict_for(control) }.find(&:itself)
        conflict ? fixed_control_refusal(conflict) : nil
      end

      def summaries
        fixed_controls.map do |control|
          point = control.fetch('point')
          fixed_elevation = fixed_elevation_for(control, point)
          predicted_after = interpolate(after_elevations, point)
          {
            id: control['id'],
            point: point,
            beforeElevation: interpolate(state.elevations, point),
            fixedElevation: fixed_elevation,
            predictedAfterElevation: predicted_after,
            delta: (predicted_after - fixed_elevation).abs,
            effectiveTolerance: tolerance_for(control),
            status: 'preserved'
          }.compact
        end
      end

      def interpolate(elevations, point)
        stencil = interpolation_stencil(point)
        interpolate_stencil_heights(*stencil_heights(elevations, stencil), stencil)
      end

      def interpolation_stencil(point)
        x_grid, y_grid = grid_position(point)
        columns, rows = dimensions
        x0, x1 = index_pair(x_grid, columns)
        y0, y1 = index_pair(y_grid, rows)
        {
          x0: x0,
          y0: y0,
          x1: x1,
          y1: y1,
          tx: x1 == x0 ? 0.0 : x_grid - x0,
          ty: y1 == y0 ? 0.0 : y_grid - y0,
          columns: columns
        }
      end

      def stencil_heights(elevations, stencil)
        columns = stencil.fetch(:columns)
        x0 = stencil.fetch(:x0)
        x1 = stencil.fetch(:x1)
        y0 = stencil.fetch(:y0)
        y1 = stencil.fetch(:y1)

        [
          elevations.fetch((y0 * columns) + x0),
          elevations.fetch((y0 * columns) + x1),
          elevations.fetch((y1 * columns) + x0),
          elevations.fetch((y1 * columns) + x1)
        ]
      end

      def grid_position(point)
        [
          (point.fetch('x').to_f - state.origin.fetch('x')) / state.spacing.fetch('x'),
          (point.fetch('y').to_f - state.origin.fetch('y')) / state.spacing.fetch('y')
        ]
      end

      def dimensions
        [
          state.dimensions.fetch('columns'),
          state.dimensions.fetch('rows')
        ]
      end

      def index_pair(grid_value, count)
        index0 = grid_value.floor.clamp(0, count - 1)
        [index0, (index0 + 1).clamp(0, count - 1)]
      end

      def interpolate_stencil_heights(z00, z10, z01, z11, stencil)
        tx = stencil.fetch(:tx)
        ty = stencil.fetch(:ty)
        lower = z00 + ((z10 - z00) * tx)
        upper = z01 + ((z11 - z01) * tx)
        lower + ((upper - lower) * ty)
      end

      private

      attr_reader :state, :after_elevations, :fixed_controls, :default_tolerance

      def conflict_for(control)
        point = control.fetch('point')
        fixed_elevation = fixed_elevation_for(control, point)
        predicted_after = interpolate(after_elevations, point)
        delta = (predicted_after - fixed_elevation).abs
        tolerance = tolerance_for(control)
        return nil unless delta > tolerance

        {
          control: control,
          tolerance: tolerance,
          predicted_delta: delta
        }
      end

      def fixed_elevation_for(control, point)
        return control.fetch('elevation').to_f if control.key?('elevation')

        interpolate(state.elevations, point)
      end

      def tolerance_for(control)
        control.fetch('tolerance', default_tolerance).to_f
      end

      def fixed_control_refusal(conflict)
        {
          success: true,
          outcome: 'refused',
          refusal: {
            code: 'fixed_control_conflict',
            message: 'Terrain edit would move a fixed control outside tolerance.',
            details: {
              controlId: conflict.fetch(:control)['id'],
              effectiveTolerance: conflict.fetch(:tolerance),
              predictedDelta: conflict.fetch(:predicted_delta)
            }.compact
          }
        }
      end
    end
  end
end
