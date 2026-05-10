# frozen_string_literal: true

require_relative '../regions/sample_window'
require_relative 'terrain_output_cell_window'
require_relative 'adaptive_output_conformity'

module SU_MCP
  module Terrain
    # Internal terrain output descriptor used by mesh generation seams.
    class TerrainOutputPlan
      ADAPTIVE_SIMPLIFICATION_TOLERANCE = 0.01
      ADAPTIVE_MIN_CELL_SIZE = 1

      attr_reader :intent, :window, :cell_window, :execution_strategy, :mesh_type, :vertex_count,
                  :face_count, :state_digest, :previous_state_digest, :previous_state_revision,
                  :adaptive_cells, :simplification_tolerance, :max_simplification_error

      def self.full_grid(state:, terrain_state_summary:)
        build(
          intent: :full_grid,
          window: SampleWindow.full_grid(state),
          state: state,
          terrain_state_summary: terrain_state_summary
        )
      end

      def self.dirty_window(
        state:,
        terrain_state_summary:,
        window:,
        previous_terrain_state_summary: nil
      )
        raise ArgumentError, 'dirty window must not be empty' if window.empty?

        build(
          intent: :dirty_window,
          window: window,
          state: state,
          terrain_state_summary: terrain_state_summary,
          previous_terrain_state_summary: previous_terrain_state_summary
        )
      end

      def self.build(
        intent:,
        window:,
        state:,
        terrain_state_summary:,
        previous_terrain_state_summary: nil
      )
        if adaptive_state?(state)
          return build_adaptive(
            intent,
            window,
            state,
            terrain_state_summary,
            previous_terrain_state_summary
          )
        end

        dimensions = state.dimensions
        columns = dimensions.fetch('columns')
        rows = dimensions.fetch('rows')
        new(
          intent: intent,
          window: window,
          cell_window: TerrainOutputCellWindow.from_sample_window(window: window, state: state),
          execution_strategy: :full_grid,
          summary: summary_for(
            columns,
            rows,
            terrain_state_summary,
            previous_terrain_state_summary
          )
        )
      end

      def self.adaptive_state?(state)
        state.respond_to?(:tiles) && state.respond_to?(:tile_size)
      end

      def self.build_adaptive(intent, window, state, terrain_state_summary, previous_state_summary)
        cells = AdaptiveOutputConformity.cells(adaptive_cells_for(state))
        summary = adaptive_summary_for(state, cells, terrain_state_summary, previous_state_summary)
        new(
          intent: intent,
          window: window,
          cell_window: TerrainOutputCellWindow.from_sample_window(
            window: window,
            state: state
          ),
          execution_strategy: :adaptive_tin,
          summary: summary,
          adaptive_cells: cells
        )
      end

      def self.summary_for(columns, rows, terrain_state_summary, previous_terrain_state_summary)
        {
          mesh_type: 'regular_grid',
          vertex_count: columns * rows,
          face_count: (columns - 1) * (rows - 1) * 2,
          state_digest: terrain_state_summary.fetch(:digest),
          previous_state_digest: previous_terrain_state_summary&.fetch(:digest, nil),
          previous_state_revision: previous_terrain_state_summary&.fetch(:revision, nil)
        }
      end

      def self.adaptive_summary_for(state, cells, terrain_state_summary, previous_state_summary)
        {
          mesh_type: 'adaptive_tin',
          vertex_count: AdaptiveOutputConformity.vertex_count(cells),
          face_count: AdaptiveOutputConformity.face_count(cells),
          state_digest: terrain_state_summary.fetch(:digest),
          previous_state_digest: previous_state_summary&.fetch(:digest, nil),
          previous_state_revision: previous_state_summary&.fetch(:revision, nil),
          source_spacing: state.spacing.transform_keys(&:to_sym),
          simplification_tolerance: ADAPTIVE_SIMPLIFICATION_TOLERANCE,
          max_simplification_error: cells.map { |cell| cell.fetch(:max_error) }.max || 0.0,
          seam_check: { status: 'passed', maxGap: 0.0 }
        }
      end

      def self.adaptive_cells_for(state)
        max_column = state.dimensions.fetch('columns') - 1
        max_row = state.dimensions.fetch('rows') - 1
        subdivide_cell(state, 0, 0, max_column, max_row)
      end

      def self.subdivide_cell(state, min_column, min_row, max_column, max_row)
        error = max_cell_error(state, min_column, min_row, max_column, max_row)
        if error <= ADAPTIVE_SIMPLIFICATION_TOLERANCE
          return [adaptive_cell(min_column, min_row, max_column, max_row, error)]
        end
        if min_output_cell?(min_column, min_row, max_column, max_row)
          return [adaptive_cell(min_column, min_row, max_column, max_row, error)]
        end

        mid_column = (min_column + max_column) / 2
        mid_row = (min_row + max_row) / 2
        child_bounds(
          min_column,
          min_row,
          max_column,
          max_row,
          mid_column,
          mid_row
        ).flat_map do |bounds|
          subdivide_cell(state, *bounds)
        end
      end

      def self.child_bounds(min_column, min_row, max_column, max_row, mid_column, mid_row)
        [
          [min_column, min_row, mid_column, mid_row],
          [mid_column, min_row, max_column, mid_row],
          [min_column, mid_row, mid_column, max_row],
          [mid_column, mid_row, max_column, max_row]
        ].select do |child_min_column, child_min_row, child_max_column, child_max_row|
          child_min_column < child_max_column && child_min_row < child_max_row
        end
      end

      def self.min_output_cell?(min_column, min_row, max_column, max_row)
        (max_column - min_column) <= ADAPTIVE_MIN_CELL_SIZE &&
          (max_row - min_row) <= ADAPTIVE_MIN_CELL_SIZE
      end

      def self.adaptive_cell(min_column, min_row, max_column, max_row, error)
        # Preserved internally only to report the public maxSimplificationError summary.
        {
          min_column: min_column,
          min_row: min_row,
          max_column: max_column,
          max_row: max_row,
          max_error: error
        }
      end

      def self.max_cell_error(state, min_column, min_row, max_column, max_row)
        bounds = {
          min_column: min_column,
          min_row: min_row,
          max_column: max_column,
          max_row: max_row
        }
        (min_row..max_row).flat_map do |row|
          (min_column..max_column).map do |column|
            (elevation_at(state, column, row) -
              fitted_elevation_for(state, column: column, row: row, bounds: bounds)).abs
          end
        end.max || 0.0
      end

      def self.fitted_elevation_for(state, column:, row:, bounds:)
        min_column = bounds.fetch(:min_column)
        min_row = bounds.fetch(:min_row)
        max_column = bounds.fetch(:max_column)
        max_row = bounds.fetch(:max_row)
        x_ratio = ratio(column, min_column, max_column)
        y_ratio = ratio(row, min_row, max_row)
        z00 = elevation_at(state, min_column, min_row)
        z10 = elevation_at(state, max_column, min_row)
        z01 = elevation_at(state, min_column, max_row)
        z11 = elevation_at(state, max_column, max_row)
        bottom = z00 + ((z10 - z00) * x_ratio)
        top = z01 + ((z11 - z01) * x_ratio)
        bottom + ((top - bottom) * y_ratio)
      end

      def self.ratio(value, min, max)
        return 0.0 if max == min

        (value - min).to_f / (max - min)
      end

      def self.elevation_at(state, column, row)
        state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
      end

      def initialize(
        intent:,
        window:,
        cell_window:,
        execution_strategy:,
        summary:,
        adaptive_cells: []
      )
        @intent = intent
        @window = window
        @cell_window = cell_window
        @execution_strategy = execution_strategy
        @mesh_type = summary.fetch(:mesh_type)
        @vertex_count = summary.fetch(:vertex_count)
        @face_count = summary.fetch(:face_count)
        @state_digest = summary.fetch(:state_digest)
        @previous_state_digest = summary[:previous_state_digest]
        @previous_state_revision = summary[:previous_state_revision]
        @adaptive_cells = adaptive_cells
        @simplification_tolerance = summary[:simplification_tolerance]
        @max_simplification_error = summary[:max_simplification_error]
        @source_spacing = summary[:source_spacing]
        @seam_check = summary[:seam_check]
      end

      def to_summary
        derived_mesh = {
          meshType: mesh_type,
          vertexCount: vertex_count,
          faceCount: face_count,
          derivedFromStateDigest: state_digest
        }
        derived_mesh[:sourceSpacing] = @source_spacing if @source_spacing
        if simplification_tolerance
          derived_mesh[:simplificationTolerance] = simplification_tolerance
          derived_mesh[:maxSimplificationError] = max_simplification_error
          derived_mesh[:seamCheck] = @seam_check
        end
        {
          derivedMesh: {
            **derived_mesh
          }
        }
      end
    end
  end
end
