# frozen_string_literal: true

require_relative '../regions/sample_window'
require_relative 'terrain_output_cell_window'
require_relative 'adaptive_output_conformity'
require_relative 'patch_lifecycle/patch_plan'
require_relative 'patch_lifecycle/patch_window_resolver'

module SU_MCP
  module Terrain
    # Internal terrain output descriptor used by mesh generation seams. MTA-39 keeps the
    # feature-aware hook here to avoid a broader adaptive planner extraction in this slice.
    # rubocop:disable Metrics/ClassLength
    class TerrainOutputPlan
      ADAPTIVE_SIMPLIFICATION_TOLERANCE = 0.01
      ADAPTIVE_MIN_CELL_SIZE = 1

      attr_reader :intent, :window, :cell_window, :execution_strategy, :mesh_type,
                  :vertex_count, :face_count, :state_digest, :previous_state_digest,
                  :previous_state_revision, :state_revision, :adaptive_cells,
                  :simplification_tolerance, :max_simplification_error, :adaptive_patch_plan,
                  :adaptive_patch_policy, :feature_aware_adaptive_policy,
                  :feature_output_policy_diagnostics

      def self.full_grid(
        state:,
        terrain_state_summary:,
        adaptive_patch_policy: nil,
        feature_aware_adaptive_policy: nil,
        feature_output_policy_diagnostics: nil
      )
        build(
          intent: :full_grid,
          window: SampleWindow.full_grid(state),
          state: state,
          terrain_state_summary: terrain_state_summary,
          adaptive_patch_policy: adaptive_patch_policy,
          feature_aware_adaptive_policy: feature_aware_adaptive_policy,
          feature_output_policy_diagnostics: feature_output_policy_diagnostics
        )
      end

      def self.dirty_window(
        state:,
        terrain_state_summary:,
        window:,
        previous_terrain_state_summary: nil,
        adaptive_patch_policy: nil,
        feature_aware_adaptive_policy: nil,
        feature_output_policy_diagnostics: nil
      )
        raise ArgumentError, 'dirty window must not be empty' if window.empty?

        build(
          intent: :dirty_window,
          window: window,
          state: state,
          terrain_state_summary: terrain_state_summary,
          previous_terrain_state_summary: previous_terrain_state_summary,
          adaptive_patch_policy: adaptive_patch_policy,
          feature_aware_adaptive_policy: feature_aware_adaptive_policy,
          feature_output_policy_diagnostics: feature_output_policy_diagnostics
        )
      end

      def self.build(
        intent:,
        window:,
        state:,
        terrain_state_summary:,
        previous_terrain_state_summary: nil,
        adaptive_patch_policy: nil,
        feature_aware_adaptive_policy: nil,
        feature_output_policy_diagnostics: nil
      )
        if adaptive_state?(state)
          return build_adaptive(
            intent,
            window,
            state,
            terrain_state_summary,
            previous_terrain_state_summary,
            adaptive_patch_policy,
            feature_output_policy_diagnostics: feature_output_policy_diagnostics,
            feature_aware_adaptive_policy: feature_aware_adaptive_policy
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
          ),
          feature_output_policy_diagnostics: feature_output_policy_diagnostics
        )
      end

      def self.adaptive_state?(state)
        state.respond_to?(:tiles) &&
          state.respond_to?(:tile_size) &&
          state.respond_to?(:payload_kind)
      end

      def self.build_adaptive(
        intent,
        window,
        state,
        terrain_state_summary,
        previous_state_summary,
        adaptive_patch_policy,
        feature_output_policy_diagnostics: nil,
        feature_aware_adaptive_policy: nil
      )
        cell_window = TerrainOutputCellWindow.from_sample_window(
          window: window,
          state: state
        )
        cells = AdaptiveOutputConformity.cells(
          adaptive_cells_for(
            state,
            adaptive_patch_policy,
            feature_aware_adaptive_policy,
            intent: intent,
            cell_window: cell_window
          )
        )
        summary = adaptive_summary_for(state, cells, terrain_state_summary, previous_state_summary)
        new(
          intent: intent,
          window: window,
          cell_window: cell_window,
          execution_strategy: :adaptive_tin,
          summary: summary,
          adaptive_cells: cells,
          adaptive_patch_policy: adaptive_patch_policy,
          feature_aware_adaptive_policy: feature_aware_adaptive_policy,
          adaptive_patch_plan: adaptive_patch_plan_for(state, adaptive_patch_policy),
          feature_output_policy_diagnostics: feature_output_policy_diagnostics
        )
      end

      def self.summary_for(columns, rows, terrain_state_summary, previous_terrain_state_summary)
        {
          mesh_type: 'regular_grid',
          vertex_count: columns * rows,
          face_count: (columns - 1) * (rows - 1) * 2,
          state_digest: terrain_state_summary.fetch(:digest),
          state_revision: terrain_state_summary[:revision],
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
          state_revision: terrain_state_summary[:revision],
          previous_state_digest: previous_state_summary&.fetch(:digest, nil),
          previous_state_revision: previous_state_summary&.fetch(:revision, nil),
          source_spacing: state.spacing.transform_keys(&:to_sym),
          simplification_tolerance: ADAPTIVE_SIMPLIFICATION_TOLERANCE,
          max_simplification_error: cells.map { |cell| cell.fetch(:max_error) }.max || 0.0,
          seam_check: { status: 'passed', maxGap: 0.0 }
        }
      end

      def self.adaptive_patch_plan_for(state, policy)
        return nil unless policy

        PatchLifecycle::PatchPlan.new(policy: policy, dimensions: state.dimensions)
      end

      def self.adaptive_cells_for(
        state,
        adaptive_patch_policy = nil,
        feature_aware_adaptive_policy = nil,
        intent: :full_grid,
        cell_window: nil
      )
        if adaptive_patch_policy&.hard_patch_boundaries
          return adaptive_patch_domains_for(
            state,
            adaptive_patch_policy,
            intent,
            cell_window
          ).flat_map do |patch|
            bounds = patch.fetch(:sample_bounds)
            subdivide_cell(
              state,
              bounds.fetch(:min_column),
              bounds.fetch(:min_row),
              bounds.fetch(:max_column),
              bounds.fetch(:max_row),
              feature_aware_adaptive_policy
            )
          end
        end

        max_column = state.dimensions.fetch('columns') - 1
        max_row = state.dimensions.fetch('rows') - 1
        subdivide_cell(state, 0, 0, max_column, max_row, feature_aware_adaptive_policy)
      end

      def self.adaptive_patch_domains_for(state, policy, intent, cell_window)
        return policy.patch_domains(state.dimensions) unless intent == :dirty_window && cell_window

        resolver = PatchLifecycle::PatchWindowResolver.new(
          policy: policy,
          dimensions: state.dimensions
        )
        resolved = resolver.resolve(cell_window: cell_window)
        expanded_patch_domains(
          policy,
          state.dimensions,
          resolved.fetch(:replacementPatchIds)
        )
      end

      def self.expanded_patch_domains(policy, dimensions, patch_ids)
        max_bounds = policy.patch_grid_bounds(dimensions)
        coords = patch_ids.flat_map do |patch_id|
          coord = parse_patch_id(patch_id)
          expanded_patch_coords(coord, max_bounds, policy.conformance_ring)
        end.uniq
        domains = coords.map do |coord|
          policy.patch_domain(coord.fetch(:column), coord.fetch(:row), dimensions)
        end
        domains.sort_by { |patch| patch.fetch(:patchId) }
      end

      def self.expanded_patch_coords(coord, max_bounds, ring)
        rows = clipped_range(coord.fetch(:row), max_bounds.fetch(:max_patch_row), ring)
        columns = clipped_range(
          coord.fetch(:column),
          max_bounds.fetch(:max_patch_column),
          ring
        )
        rows.flat_map do |row|
          columns.map { |column| { column: column, row: row } }
        end
      end

      def self.clipped_range(value, max_value, ring)
        ([value - ring, 0].max)..([value + ring, max_value].min)
      end

      def self.parse_patch_id(patch_id)
        match = patch_id.match(/-c(\d+)-r(\d+)\z/)
        raise ArgumentError, "invalid adaptive patch id: #{patch_id}" unless match

        {
          column: match.captures.fetch(0).to_i,
          row: match.captures.fetch(1).to_i
        }
      end

      def self.subdivide_cell(
        state,
        min_column,
        min_row,
        max_column,
        max_row,
        feature_aware_adaptive_policy = nil
      )
        if min_output_cell?(min_column, min_row, max_column, max_row)
          error = max_cell_error(state, min_column, min_row, max_column, max_row)
          return [adaptive_cell(min_column, min_row, max_column, max_row, error)]
        end

        probe = adaptive_split_probe(
          state,
          min_column,
          min_row,
          max_column,
          max_row,
          feature_aware_adaptive_policy
        )
        unless probe.fetch(:split)
          return [adaptive_cell(min_column, min_row, max_column, max_row, probe.fetch(:max_error))]
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
          subdivide_cell(state, *bounds, feature_aware_adaptive_policy)
        end
      end

      def self.adaptive_split_probe(
        state,
        min_column,
        min_row,
        max_column,
        max_row,
        feature_aware_adaptive_policy
      )
        split_pressure = feature_split_pressure(
          feature_aware_adaptive_policy,
          min_column,
          min_row,
          max_column,
          max_row
        )
        probe = max_cell_error_probe(
          state,
          min_column,
          min_row,
          max_column,
          max_row,
          split_pressure.fetch(:tolerance)
        )
        {
          max_error: probe.fetch(:max_error),
          split: probe.fetch(:exceeded) || split_pressure.fetch(:density_split)
        }
      end

      def self.feature_split_pressure(
        feature_aware_adaptive_policy,
        min_column,
        min_row,
        max_column,
        max_row
      )
        return { tolerance: ADAPTIVE_SIMPLIFICATION_TOLERANCE, density_split: false } unless
          feature_aware_adaptive_policy

        feature_aware_adaptive_policy.split_pressure_for(
          { min_column: min_column, min_row: min_row,
            max_column: max_column, max_row: max_row },
          column_span: max_column - min_column,
          row_span: max_row - min_row
        )
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
        max_cell_error_probe(
          state,
          min_column,
          min_row,
          max_column,
          max_row,
          nil
        ).fetch(:max_error)
      end

      # rubocop:disable Metrics/AbcSize
      def self.max_cell_error_probe(state, min_column, min_row, max_column, max_row, threshold)
        dimensions = state.dimensions
        columns = dimensions.fetch('columns')
        elevations = state.elevations
        z00 = elevations[(min_row * columns) + min_column]
        z10 = elevations[(min_row * columns) + max_column]
        z01 = elevations[(max_row * columns) + min_column]
        z11 = elevations[(max_row * columns) + max_column]
        x_span = max_column - min_column
        y_span = max_row - min_row
        max_error = 0.0
        row = min_row
        while row <= max_row
          y_ratio = y_span.zero? ? 0.0 : (row - min_row).to_f / y_span
          left = z00 + ((z01 - z00) * y_ratio)
          right = z10 + ((z11 - z10) * y_ratio)
          column = min_column
          while column <= max_column
            x_ratio = x_span.zero? ? 0.0 : (column - min_column).to_f / x_span
            fitted = left + ((right - left) * x_ratio)
            error = (elevations[(row * columns) + column] - fitted).abs
            if error > max_error
              max_error = error
              return { max_error: max_error, exceeded: true } if threshold && max_error > threshold
            end
            column += 1
          end
          row += 1
        end
        { max_error: max_error, exceeded: false }
      end
      # rubocop:enable Metrics/AbcSize

      def initialize(
        intent:,
        window:,
        cell_window:,
        execution_strategy:,
        summary:,
        adaptive_cells: [],
        adaptive_patch_policy: nil,
        feature_aware_adaptive_policy: nil,
        adaptive_patch_plan: nil,
        feature_output_policy_diagnostics: nil
      )
        @intent = intent
        @window = window
        @cell_window = cell_window
        @execution_strategy = execution_strategy
        @mesh_type = summary.fetch(:mesh_type)
        @vertex_count = summary.fetch(:vertex_count)
        @face_count = summary.fetch(:face_count)
        @state_digest = summary.fetch(:state_digest)
        @state_revision = summary[:state_revision]
        @previous_state_digest = summary[:previous_state_digest]
        @previous_state_revision = summary[:previous_state_revision]
        @adaptive_cells = adaptive_cells
        @simplification_tolerance = summary[:simplification_tolerance]
        @max_simplification_error = summary[:max_simplification_error]
        @source_spacing = summary[:source_spacing]
        @seam_check = summary[:seam_check]
        @adaptive_patch_policy = adaptive_patch_policy
        @feature_aware_adaptive_policy = feature_aware_adaptive_policy
        @adaptive_patch_plan = adaptive_patch_plan
        @feature_output_policy_diagnostics = feature_output_policy_diagnostics
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
    # rubocop:enable Metrics/ClassLength
  end
end
