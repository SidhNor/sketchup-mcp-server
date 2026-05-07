# frozen_string_literal: true

require 'time'

require_relative 'adaptive_output_conformity'
require_relative 'intent_aware_adaptive_grid_policy'

module SU_MCP
  module Terrain
    # Real validation-only MTA-23 adaptive candidate. Not production-wired.
    class IntentAwareEnhancedAdaptiveGridPrototype # rubocop:disable Metrics/ClassLength
      BACKEND = 'mta23_intent_aware_adaptive_grid_prototype'
      RESULT_SCHEMA_VERSION = 1
      PROTOTYPE_RESIDUAL_LIMITATION = 'prototype_role_residuals_are_first_pass_metrics'

      def run(state:, feature_geometry:, base_tolerance:, max_cell_budget:,
              max_face_budget:, max_runtime_budget:)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @state = state
        @feature_geometry = feature_geometry
        @policy = IntentAwareAdaptiveGridPolicy.new(
          feature_geometry: feature_geometry,
          base_tolerance: base_tolerance,
          tile_columns: columns
        )
        @split_events = Hash.new(0)
        cells, budget_status = subdivide(max_cell_budget, max_runtime_budget, started)
        planned = prototype_emission_cells(cells)
        mesh = emit_mesh(planned)
        if budget_status == 'ok' && mesh.fetch(:triangles).length > max_face_budget
          budget_status = 'max_face_budget_exceeded'
        end
        metrics = metrics_for(mesh, planned, budget_status, started)

        result_row(mesh, planned, metrics, budget_status)
      rescue StandardError => e
        candidate_error(e)
      end

      private

      attr_reader :state, :feature_geometry, :policy

      def subdivide(max_cell_budget, max_runtime_budget, started)
        cells = [cell(0, 0, columns - 1, rows - 1)]
        budget_status = 'ok'
        loop do
          annotate_cells!(cells)
          candidate = cells.max_by { |item| policy.split_priority(item) }
          break unless split_needed?(candidate)

          if cells.length >= max_cell_budget
            budget_status = 'max_cell_budget_exceeded'
            break
          end
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started > max_runtime_budget
            budget_status = 'max_runtime_budget_exceeded'
            break
          end

          @split_events[candidate.fetch(:split_reason)] += 1
          cells.delete(candidate)
          cells.concat(split_cell(candidate))
        end
        annotate_cells!(cells, budget_status: budget_status)
        [cells, budget_status]
      end

      def annotate_cells!(cells, budget_status: 'ok')
        cells.each do |item|
          item[:height_error] = max_cell_error(item)
          item[:local_tolerance] = policy.local_tolerance(item)
          status = policy.hard_requirement_status_for(item, vertices: cell_corner_vertices(item))
          item[:hard_requirement_status] = status.fetch(:status)
          item[:hard_violation_counts] = status.fetch(:hardViolationCounts)
          item[:firm_pressure] = policy.pressure_coverage_needed?(item, 'firm')
          item[:soft_pressure] = policy.pressure_coverage_needed?(item, 'soft')
          item[:split_reason] = split_reason(item, budget_status)
        end
      end

      def split_needed?(item)
        return false if min_cell?(item)

        %w[
          hard_requirement_unresolved height_error_exceeded firm_pressure_needed
          soft_pressure_useful
        ].include?(item.fetch(:split_reason))
      end

      def split_reason(item, budget_status)
        return 'budget_stop' unless budget_status == 'ok'
        if item.fetch(:hard_requirement_status) == 'violated_at_min_size'
          return 'hard_violation_at_min_size'
        end
        return 'hard_requirement_unresolved' if item.fetch(:hard_requirement_status) == 'unresolved'
        return 'height_error_exceeded' if item.fetch(:height_error) > item.fetch(:local_tolerance)
        return 'firm_pressure_needed' if item.fetch(:firm_pressure)
        return 'soft_pressure_useful' if item.fetch(:soft_pressure)
        return 'min_size_stop' if min_cell?(item)

        'satisfied'
      end

      def split_cell(item)
        mid_col = (item.fetch(:min_col) + item.fetch(:max_col)) / 2
        mid_row = (item.fetch(:min_row) + item.fetch(:max_row)) / 2
        [
          [item.fetch(:min_col), item.fetch(:min_row), mid_col, mid_row],
          [mid_col, item.fetch(:min_row), item.fetch(:max_col), mid_row],
          [item.fetch(:min_col), mid_row, mid_col, item.fetch(:max_row)],
          [mid_col, mid_row, item.fetch(:max_col), item.fetch(:max_row)]
        ].select { |a, b, c, d| a < c && b < d }.map { |bounds| cell(*bounds) }
      end

      def cell(min_col, min_row, max_col, max_row)
        { min_col: min_col, min_row: min_row, max_col: max_col, max_row: max_row }
      end

      def conformity_cell(item)
        {
          min_column: item.fetch(:min_col),
          min_row: item.fetch(:min_row),
          max_column: item.fetch(:max_col),
          max_row: item.fetch(:max_row),
          max_error: item.fetch(:height_error)
        }
      end

      def emit_mesh(planned)
        vertices = []
        vertex_index = {}
        triangles = planned.flat_map do |cell|
          cell.fetch(:emission_triangles).map do |triangle|
            triangle.map do |point|
              vertex = vertex_for(point)
              key = vertex.map { |value| value.round(6) }
              vertex_index[key] ||= begin
                vertices << vertex
                vertices.length - 1
              end
            end
          end
        end
        { vertices: vertices, triangles: triangles }
      end

      def vertex_for(point)
        col, row = point
        x = origin_x + (col * spacing_x)
        y = origin_y + (row * spacing_y)
        [x, y, fitted_elevation(col, row)]
      end

      def metrics_for(mesh, planned, budget_status, started)
        crossings = policy.protected_crossing_metrics(triangles: mesh_triangles(mesh))
        anchors = policy.anchor_hit_metrics(vertices: mesh.fetch(:vertices))
        topology = topology_checks(mesh)
        {
          meshType: 'adaptive_tin',
          faceCount: mesh.fetch(:triangles).length,
          vertexCount: mesh.fetch(:vertices).length,
          denseEquivalentFaceCount: dense_equivalent_face_count,
          denseRatio: mesh.fetch(:triangles).length.to_f / dense_equivalent_face_count,
          maxHeightError: planned.map { |cell| cell.fetch(:max_error) }.max || 0.0,
          profileChecks: [],
          topologyChecks: topology,
          topologyResiduals: topology_residuals(topology),
          protectedCrossingCount: crossings.fetch(:protectedCrossingCount),
          protectedCrossingSeverity: crossings.fetch(:protectedCrossingSeverity),
          hardViolationCounts: anchors.fetch(:hardViolationCounts),
          anchorHitDistances: anchors.fetch(:anchorHitDistances),
          firmResidualsByRole: firm_residuals_by_role,
          splitReasonHistogram: split_histogram(planned),
          timing: { elapsedSeconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started },
          budgetStatus: budget_status
        }
      end

      def result_row(mesh, planned, metrics, budget_status)
        {
          caseId: nil,
          resultSchemaVersion: RESULT_SCHEMA_VERSION,
          backend: BACKEND,
          evidenceMode: 'local_backend_capture',
          mesh: mesh,
          candidateCells: planned.map { |cell| candidate_cell_payload(cell) },
          metrics: metrics,
          budgetStatus: budget_status,
          failureCategory: failure_category(metrics, budget_status),
          featureGeometryDigest: feature_geometry.feature_geometry_digest,
          referenceGeometryDigest: feature_geometry.reference_geometry_digest,
          knownResiduals: [],
          limitations: limitations,
          provenance: { source: 'MTA-23 validation-only prototype' }
        }
      end

      def candidate_cell_payload(cell)
        {
          min_col: cell.fetch(:min_column),
          min_row: cell.fetch(:min_row),
          max_col: cell.fetch(:max_column),
          max_row: cell.fetch(:max_row),
          height_error: cell.fetch(:max_error),
          split_reason: cell.fetch(:split_reason, 'satisfied')
        }
      end

      def failure_category(metrics, budget_status)
        if feature_geometry.failure_category == 'feature_geometry_failed'
          return 'feature_geometry_failed'
        end
        if !metrics.fetch(:hardViolationCounts).empty? ||
           metrics.fetch(:protectedCrossingCount).positive?
          return 'hard_output_geometry_violation'
        end
        return 'topology_invalid' if metrics.dig(:topologyChecks, :nonManifoldEdgeCount).positive?
        return 'performance_limit_exceeded' unless budget_status == 'ok'
        return 'firm_feature_residual_high' if firm_residual_high?(metrics)

        'none'
      end

      def candidate_error(error)
        {
          resultSchemaVersion: RESULT_SCHEMA_VERSION,
          backend: BACKEND,
          evidenceMode: 'local_backend_capture',
          metrics: {},
          budgetStatus: 'ok',
          failureCategory: 'candidate_generation_failed',
          limitations: [{ reason: error.message }],
          knownResiduals: [],
          provenance: { source: 'MTA-23 validation-only prototype' }
        }
      end

      def firm_residuals_by_role
        # MTA-23 first-pass role residuals are intentionally diagnostic, not production metrics.
        {
          'corridor_centerline' => residual_for_roles(%w[centerline]),
          'corridor_side_band' => residual_for_roles(%w[side_transition]),
          'corridor_endpoint_cap' => residual_for_roles(%w[endpoint_cap]),
          'survey_anchor' => 0.0,
          'planar_plane_fit' => 0.0
        }
      end

      def residual_for_roles(roles)
        feature_geometry.reference_segments.select do |segment|
          roles.include?(segment.fetch('role'))
        end.length.to_f
      end

      def topology_residuals(topology)
        # MTA-23 role keys exist before hosted role classifiers do.
        {
          'corridor_endpoint_cap' => { maxNormalBreakDeg: topology.fetch(:maxNormalBreakDeg) },
          'corridor_side_band' => { maxNormalBreakDeg: topology.fetch(:maxNormalBreakDeg) },
          'protected_boundary' => { maxNormalBreakDeg: topology.fetch(:maxNormalBreakDeg) },
          'general_terrain' => { maxNormalBreakDeg: topology.fetch(:maxNormalBreakDeg) }
        }
      end

      def topology_checks(mesh)
        normals = mesh.fetch(:triangles).map { |triangle| triangle_normal(mesh, triangle) }
        {
          downFaceCount: normals.count { |normal| normal[2].negative? },
          nonManifoldEdgeCount: non_manifold_edge_count(mesh.fetch(:triangles)),
          maxNormalBreakDeg: max_normal_break(normals)
        }
      end

      def non_manifold_edge_count(triangles)
        edges = Hash.new(0)
        triangles.each do |triangle|
          triangle.each_cons(2) { |a, b| edges[[a, b].sort] += 1 }
          edges[[triangle.last, triangle.first].sort] += 1
        end
        edges.values.count { |count| count > 2 }
      end

      def max_normal_break(normals)
        return 0.0 if normals.length < 2

        normals.combination(2).map { |a, b| angle_between(a, b) }.max || 0.0
      end

      # rubocop:disable Metrics/AbcSize
      def triangle_normal(mesh, triangle)
        a, b, c = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        u = [b[0] - a[0], b[1] - a[1], b[2] - a[2]]
        v = [c[0] - a[0], c[1] - a[1], c[2] - a[2]]
        cross = [
          (u[1] * v[2]) - (u[2] * v[1]),
          (u[2] * v[0]) - (u[0] * v[2]),
          (u[0] * v[1]) - (u[1] * v[0])
        ]
        length = Math.sqrt(cross.sum { |value| value * value })
        return [0.0, 0.0, 1.0] if length.zero?

        cross.map { |value| value / length }
      end
      # rubocop:enable Metrics/AbcSize

      def angle_between(first, second)
        dot = first.zip(second).sum { |a, b| a * b }
        dot = dot.clamp(-1.0, 1.0)
        Math.acos(dot) * 180.0 / Math::PI
      end

      def mesh_triangles(mesh)
        mesh.fetch(:triangles).map do |triangle|
          triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        end
      end

      def split_histogram(planned)
        histogram = @split_events.dup
        planned.each_with_object(histogram) do |cell, memo|
          memo[cell.fetch(:split_reason, 'satisfied')] += 1
        end
      end

      def prototype_emission_cells(cells)
        # Validation-only mirror of AdaptiveOutputConformity; never wired to production
        # TerrainSurfaceCommands or TerrainOutputPlan paths.
        AdaptiveOutputConformity.cells(cells.map { |cell| conformity_cell(cell) })
      end

      def limitations
        feature_geometry.limitations + [{ category: PROTOTYPE_RESIDUAL_LIMITATION }]
      end

      def firm_residual_high?(metrics)
        metrics.fetch(:firmResidualsByRole).values.any? { |value| value.to_f > 10.0 }
      end

      def max_cell_error(item)
        (item.fetch(:min_row)..item.fetch(:max_row)).flat_map do |row|
          (item.fetch(:min_col)..item.fetch(:max_col)).map do |col|
            (elevation_at(col, row) - fitted_elevation_for_cell(col, row, item)).abs
          end
        end.max || 0.0
      end

      def fitted_elevation_for_cell(col, row, item)
        x_ratio = ratio(col, item.fetch(:min_col), item.fetch(:max_col))
        y_ratio = ratio(row, item.fetch(:min_row), item.fetch(:max_row))
        z00 = elevation_at(item.fetch(:min_col), item.fetch(:min_row))
        z10 = elevation_at(item.fetch(:max_col), item.fetch(:min_row))
        z01 = elevation_at(item.fetch(:min_col), item.fetch(:max_row))
        z11 = elevation_at(item.fetch(:max_col), item.fetch(:max_row))
        bottom = z00 + ((z10 - z00) * x_ratio)
        top = z01 + ((z11 - z01) * x_ratio)
        bottom + ((top - bottom) * y_ratio)
      end

      def fitted_elevation(col, row)
        min_col = col.floor
        min_row = row.floor
        max_col = col.ceil
        max_row = row.ceil
        x_ratio = ratio(col, min_col, max_col)
        y_ratio = ratio(row, min_row, max_row)
        z00 = elevation_at(min_col, min_row)
        z10 = elevation_at(max_col, min_row)
        z01 = elevation_at(min_col, max_row)
        z11 = elevation_at(max_col, max_row)
        bottom = z00 + ((z10 - z00) * x_ratio)
        top = z01 + ((z11 - z01) * x_ratio)
        bottom + ((top - bottom) * y_ratio)
      end

      def ratio(value, min, max)
        return 0.0 if max == min

        (value - min).to_f / (max - min)
      end

      def elevation_at(col, row)
        state.elevations.fetch((row * columns) + col)
      end

      def cell_corner_vertices(item)
        [
          vertex_for([item.fetch(:min_col), item.fetch(:min_row)]),
          vertex_for([item.fetch(:max_col), item.fetch(:min_row)]),
          vertex_for([item.fetch(:max_col), item.fetch(:max_row)]),
          vertex_for([item.fetch(:min_col), item.fetch(:max_row)])
        ]
      end

      def min_cell?(item)
        (item.fetch(:max_col) - item.fetch(:min_col)) <= 1 &&
          (item.fetch(:max_row) - item.fetch(:min_row)) <= 1
      end

      def dense_equivalent_face_count
        (columns - 1) * (rows - 1) * 2
      end

      def columns
        state.dimensions.fetch('columns')
      end

      def rows
        state.dimensions.fetch('rows')
      end

      def origin_x
        state.origin.fetch('x')
      end

      def origin_y
        state.origin.fetch('y')
      end

      def spacing_x
        state.spacing.fetch('x')
      end

      def spacing_y
        state.spacing.fetch('y')
      end
    end
  end
end
