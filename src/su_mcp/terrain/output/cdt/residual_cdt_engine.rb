# frozen_string_literal: true

require 'json'

require_relative 'cdt_height_error_meter'
require_relative 'cdt_terrain_point_planner'
require_relative 'terrain_triangulation_adapter'

module SU_MCP
  module Terrain
    # Residual CDT engine extracted from the validated CDT stack.
    class ResidualCdtEngine # rubocop:disable Metrics/ClassLength
      RESIDUAL_REFINEMENT_POINT_RATIO = 1.0
      RESIDUAL_REFINEMENT_BATCH_SIZE = 128
      RESIDUAL_REFINEMENT_MAX_PASSES = 24
      POINT_KEY_PRECISION = 9

      Request = Struct.new(
        :state,
        :feature_geometry,
        :base_tolerance,
        :max_point_budget,
        :max_face_budget,
        :max_runtime_budget,
        keyword_init: true
      )

      def initialize(
        point_planner: CdtTerrainPointPlanner.new,
        height_error_meter: CdtHeightErrorMeter.new,
        triangulation_adapter: nil,
        triangulator: nil,
        residual_refinement_point_ratio: RESIDUAL_REFINEMENT_POINT_RATIO,
        residual_refinement_max_passes: RESIDUAL_REFINEMENT_MAX_PASSES,
        residual_refinement_batch_size: RESIDUAL_REFINEMENT_BATCH_SIZE
      )
        @point_planner = point_planner
        @height_error_meter = height_error_meter
        @triangulation_adapter = triangulation_adapter || TerrainTriangulationAdapter.ruby_cdt(
          triangulator: triangulator || CdtTriangulator.new
        )
        @residual_refinement_point_ratio = normalized_residual_refinement_point_ratio(
          residual_refinement_point_ratio
        )
        @residual_refinement_max_passes = normalized_residual_refinement_max_passes(
          residual_refinement_max_passes
        )
        @residual_refinement_batch_size = normalized_residual_refinement_batch_size(
          residual_refinement_batch_size
        )
      end

      def run(state:, feature_geometry:, base_tolerance:, max_point_budget:,
              max_face_budget:, max_runtime_budget:)
        request = Request.new(
          state: state,
          feature_geometry: feature_geometry,
          base_tolerance: base_tolerance,
          max_point_budget: max_point_budget,
          max_face_budget: max_face_budget,
          max_runtime_budget: max_runtime_budget
        )
        build_result(request)
      end

      private

      attr_reader :point_planner, :height_error_meter, :triangulation_adapter,
                  :residual_refinement_point_ratio, :residual_refinement_max_passes,
                  :residual_refinement_batch_size

      def build_result(request)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        normalized = normalize_input(request)
        budget_status = budget_status_for(normalized, request.max_point_budget)
        constraints = if budget_status == 'max_point_budget_exceeded'
                        []
                      else
                        normalized.fetch(:segments)
                      end
        triangulation, mesh = triangulated_mesh(request.state, normalized, constraints)
        if budget_status == 'ok'
          triangulation, mesh = refine_mesh_residuals(
            request: request,
            normalized: normalized,
            constraints: constraints,
            triangulation: triangulation,
            mesh: mesh
          )
        end
        budget_status = face_budget_status(mesh, budget_status, request.max_face_budget)
        budget_status = runtime_budget_status(started, budget_status, request.max_runtime_budget)
        metrics = metrics_for(
          request: request,
          normalized: normalized,
          mesh: mesh,
          triangulation: triangulation,
          budget_status: budget_status,
          started: started
        )
        engine_result(request: request, normalized: normalized, triangulation: triangulation,
                      mesh: mesh, metrics: metrics, budget_status: budget_status)
      end

      def normalize_input(request)
        planned = point_planner.plan(
          state: request.state,
          feature_geometry: request.feature_geometry,
          base_tolerance: request.base_tolerance,
          max_point_budget: request.max_point_budget
        )
        segments = []
        segments.concat(protected_region_segments(request.feature_geometry))
        segments.concat(reference_segments(request.feature_geometry))
        {
          points: planned.fetch(:points),
          segments: segments,
          feature_geometry: request.feature_geometry,
          source_summary: planned.fetch(:featureSourceSummary),
          selected_point_count: planned.fetch(:selectedPointCount),
          seed_point_count: planned.fetch(:seedPointCount),
          mandatory_point_count: planned.fetch(:mandatoryPointCount),
          residual_point_count: planned.fetch(:residualPointCount),
          dense_source_point_count: planned.fetch(:denseSourcePointCount),
          dense_equivalent_face_count: planned.fetch(:denseEquivalentFaceCount),
          source_dimensions: planned.fetch(:sourceDimensions),
          limitations: planned.fetch(:limitations),
          residual_refinement_stop_reason: 'not_started',
          residual_refinement_safety_cap: planned.fetch(:selectedPointCount),
          max_residual_excess: 0.0
        }
      end

      def triangulated_mesh(state, normalized, constraints)
        triangulation = triangulation_adapter.triangulate(
          points: normalized.fetch(:points),
          constraints: constraints
        )
        [triangulation, lift_mesh(state, triangulation)]
      end

      def refine_mesh_residuals(request:, normalized:, constraints:, triangulation:, mesh:)
        limit = residual_refinement_point_limit(normalized, request.max_point_budget)
        normalized[:residual_refinement_safety_cap] = limit
        blocked_reason = blocked_residual_refinement_reason(request, mesh, normalized, limit)
        if blocked_reason
          normalized[:residual_refinement_stop_reason] = blocked_reason
          return [triangulation, mesh]
        end

        triangulation, mesh, stop_reason = run_residual_refinement_passes(
          request, normalized, constraints, [triangulation, mesh], limit
        )
        stop_reason ||= residual_refinement_final_stop_reason(request, mesh, normalized, limit)
        normalized[:residual_refinement_stop_reason] = stop_reason
        add_residual_refinement_budget_limitation(normalized)
        [triangulation, mesh]
      end

      def blocked_residual_refinement_reason(request, mesh, normalized, limit)
        return 'disabled' unless residual_refinement_max_passes.positive?

        if normalized.fetch(:points).length >= limit
          normalized[:max_residual_excess] = max_residual_excess(request, mesh, normalized)
          return 'safety_cap'
        end

        nil
      end

      def run_residual_refinement_passes(request, normalized, constraints, mesh_result, limit)
        triangulation, mesh = mesh_result
        stop_reason = nil
        residual_refinement_max_passes.times do
          samples = residual_samples(request, mesh, normalized, residual_refinement_batch_size)
          normalized[:max_residual_excess] = sample_residual_excess(samples)
          if samples.empty?
            stop_reason = 'residual_satisfied'
            break
          end
          if normalized.fetch(:points).length >= limit
            stop_reason = 'safety_cap'
            break
          end

          added = add_mesh_residual_points(normalized, samples, limit)
          if added.zero?
            stop_reason = 'stalled'
            break
          end

          add_residual_refinement_limitation(normalized)
          triangulation, mesh = triangulated_mesh(request.state, normalized, constraints)
        end
        [triangulation, mesh, stop_reason]
      end

      def residual_refinement_point_limit(normalized, max_point_budget)
        dense_points = normalized.fetch(:dense_source_point_count)
        residual_limit = (dense_points * residual_refinement_point_ratio).ceil
        residual_limit.clamp(normalized.fetch(:points).length, max_point_budget)
      end

      def residual_samples(request, mesh, normalized, limit)
        height_error_meter.worst_samples_with_local_tolerance(
          state: request.state,
          mesh: mesh,
          limit: limit,
          base_tolerance: request.base_tolerance,
          feature_geometry: normalized.fetch(:feature_geometry)
        )
      end

      def sample_residual_excess(samples)
        samples.fetch(0, { residualExcess: 0.0 }).fetch(:residualExcess)
      end

      def max_residual_excess(request, mesh, normalized)
        sample_residual_excess(residual_samples(request, mesh, normalized, 1))
      end

      def residual_refinement_final_stop_reason(request, mesh, normalized, limit)
        remaining = residual_samples(request, mesh, normalized, 1)
        normalized[:max_residual_excess] = sample_residual_excess(remaining)
        return 'residual_satisfied' if remaining.empty?
        return 'safety_cap' if normalized.fetch(:points).length >= limit

        'max_passes'
      end

      def add_mesh_residual_points(normalized, samples, limit)
        existing = normalized.fetch(:points).to_h { |point| [point_key(point), true] }
        added = 0
        samples.each do |sample|
          break if normalized.fetch(:points).length >= limit
          next if existing[point_key(sample.fetch(:point))]

          normalized.fetch(:points) << sample.fetch(:point)
          existing[point_key(sample.fetch(:point))] = true
          added += 1
        end
        normalized[:selected_point_count] = normalized.fetch(:points).length
        normalized[:residual_point_count] += added
        added
      end

      def add_residual_refinement_limitation(normalized)
        normalized.fetch(:limitations) << {
          category: 'cdt_mesh_residual_refinement',
          reason: 'worst CDT mesh residual samples were added before retriangulation'
        }
      end

      def add_residual_refinement_budget_limitation(normalized)
        return unless normalized.fetch(:residual_refinement_stop_reason) == 'safety_cap'

        normalized.fetch(:limitations) << {
          category: 'cdt_mesh_residual_refinement_budget',
          reason: 'CDT mesh residual refinement stopped before dense-grid selection'
        }
      end

      def protected_region_segments(feature_geometry)
        feature_geometry.protected_regions.flat_map do |region|
          next [] unless region.fetch('primitive') == 'rectangle'

          min, max = region.fetch('ownerLocalBounds')
          corners = [[min[0], min[1]], [max[0], min[1]], [max[0], max[1]], [min[0], max[1]]]
          segment_loop(corners, region.fetch('id'), region.fetch('strength', 'hard'))
        end
      end

      def reference_segments(feature_geometry)
        feature_geometry.reference_segments.map do |segment|
          {
            id: segment.fetch('id'),
            start: segment.fetch('ownerLocalStart'),
            end: segment.fetch('ownerLocalEnd'),
            strength: segment.fetch('strength', 'firm')
          }
        end
      end

      def segment_loop(points, id, strength)
        points.each_with_index.map do |point, index|
          {
            id: "#{id}:edge:#{index}",
            start: point,
            end: points.fetch((index + 1) % points.length),
            strength: strength
          }
        end
      end

      def budget_status_for(normalized, max_point_budget)
        if normalized.fetch(:limitations).any? do |item|
          item.fetch(:category, nil) == 'point_budget'
        end
          return 'max_point_budget_exceeded'
        end

        normalized.fetch(:points).length >= max_point_budget ? 'max_point_budget_exceeded' : 'ok'
      end

      def face_budget_status(mesh, current_status, max_face_budget)
        return current_status unless current_status == 'ok'

        mesh.fetch(:triangles).length > max_face_budget ? 'max_face_budget_exceeded' : 'ok'
      end

      def runtime_budget_status(started, current_status, max_runtime_budget)
        return current_status unless current_status == 'ok'

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        elapsed > max_runtime_budget ? 'max_runtime_budget_exceeded' : 'ok'
      end

      def lift_mesh(state, triangulation)
        vertices = triangulation.fetch(:vertices).map do |point|
          [point[0], point[1], elevation_at_owner_point(state, point)]
        end
        { vertices: vertices, triangles: triangulation.fetch(:triangles) }
      end

      # rubocop:disable Metrics/AbcSize
      def elevation_at_owner_point(state, point)
        column = (point[0] - state.origin.fetch('x')) / state.spacing.fetch('x')
        row = (point[1] - state.origin.fetch('y')) / state.spacing.fetch('y')
        min_column = column.floor.clamp(0, columns(state) - 1)
        min_row = row.floor.clamp(0, rows(state) - 1)
        max_column = column.ceil.clamp(0, columns(state) - 1)
        max_row = row.ceil.clamp(0, rows(state) - 1)
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
      # rubocop:enable Metrics/AbcSize

      def metrics_for(request:, normalized:, mesh:, triangulation:, budget_status:, started:)
        topology = topology_checks(mesh)
        coverage = triangulation.fetch(:constrainedEdgeCoverage)
        {
          faceCount: mesh.fetch(:triangles).length,
          vertexCount: mesh.fetch(:vertices).length,
          selectedPointCount: normalized.fetch(:selected_point_count),
          denseSourcePointCount: normalized.fetch(:dense_source_point_count),
          denseEquivalentFaceCount: normalized.fetch(:dense_equivalent_face_count),
          denseRatio: mesh.fetch(:triangles).length.to_f /
            normalized.fetch(:dense_equivalent_face_count),
          maxHeightError: height_error_meter.max_error(state: request.state, mesh: mesh),
          protectedCrossingCount: coverage < 1.0 ? 1 : 0,
          protectedCrossingSeverity: coverage < 1.0 ? 'degraded' : 'none',
          hardViolationCounts: anchor_violation_counts(request.feature_geometry, mesh),
          anchorHitDistances: anchor_hit_distances(request.feature_geometry, mesh),
          topologyChecks: topology,
          topologyResiduals: topology_residuals(topology),
          firmResidualsByRole: firm_residuals_by_role(request.feature_geometry, coverage),
          residualRefinement: residual_refinement_metrics(normalized, mesh),
          timing: { elapsedSeconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started },
          budgetStatus: budget_status
        }
      end

      def residual_refinement_metrics(normalized, mesh)
        dense_source_points = normalized.fetch(:dense_source_point_count)
        {
          pointRatio: residual_refinement_point_ratio,
          safetyCap: normalized.fetch(:residual_refinement_safety_cap),
          selectedPointRatio: normalized.fetch(:selected_point_count).to_f / dense_source_points,
          faceDenseRatio: mesh.fetch(:triangles).length.to_f /
            normalized.fetch(:dense_equivalent_face_count),
          maxPasses: residual_refinement_max_passes,
          batchSize: residual_refinement_batch_size,
          seedCount: normalized.fetch(:seed_point_count),
          mandatoryCount: normalized.fetch(:mandatory_point_count),
          residualCount: normalized.fetch(:residual_point_count),
          stopReason: normalized.fetch(:residual_refinement_stop_reason),
          maxResidualExcess: normalized.fetch(:max_residual_excess),
          enabled: residual_refinement_max_passes.positive?
        }
      end

      def engine_result(request:, normalized:, triangulation:, mesh:, metrics:, budget_status:)
        {
          status: 'accepted',
          mesh: mesh,
          metrics: metrics,
          limits: {
            pointBudget: request.max_point_budget,
            faceBudget: request.max_face_budget,
            runtimeBudget: request.max_runtime_budget
          },
          budgetStatus: budget_status,
          failureCategory: failure_category(request.feature_geometry, normalized, triangulation,
                                            metrics, budget_status),
          featureGeometryDigest: request.feature_geometry.feature_geometry_digest,
          referenceGeometryDigest: request.feature_geometry.reference_geometry_digest,
          stateDigest: state_digest(request.state),
          selectedPointCount: normalized.fetch(:selected_point_count),
          denseSourcePointCount: normalized.fetch(:dense_source_point_count),
          sourceDimensions: normalized.fetch(:source_dimensions),
          constraintCount: constraint_count(request.feature_geometry, normalized),
          constraintSourceSummary: normalized.fetch(:source_summary),
          constrainedEdgeCoverage: triangulation.fetch(:constrainedEdgeCoverage),
          constrainedEdges: triangulation.fetch(:constrainedEdges),
          delaunayViolationCount: triangulation.fetch(:delaunayViolationCount),
          limitations: limitations(request.feature_geometry, normalized, triangulation,
                                   budget_status)
        }
      end

      def constraint_count(feature_geometry, normalized)
        normalized.fetch(:segments).length +
          feature_geometry.output_anchor_candidates.length +
          feature_geometry.pressure_regions.length +
          feature_geometry.affected_windows.length
      end

      def failure_category(feature_geometry, normalized, triangulation, metrics, budget_status)
        if feature_geometry.failure_category == 'feature_geometry_failed'
          return 'feature_geometry_failed'
        end
        return 'performance_limit_exceeded' unless budget_status == 'ok'
        return 'topology_degraded' if topology_degraded?(normalized, triangulation)

        return 'hard_output_geometry_violation' unless metrics.fetch(:hardViolationCounts).empty?
        return 'topology_invalid' if metrics.dig(:topologyChecks, :nonManifoldEdgeCount).positive?
        return 'firm_feature_residual_high' if firm_residual_high?(metrics)

        'none'
      end

      def topology_degraded?(normalized, triangulation)
        limitations = normalized.fetch(:limitations) + triangulation.fetch(:limitations)
        limitations.any? do |item|
          %w[
            non_manifold_edge_pruned
            non_manifold_edge_repaired
            non_manifold_edge_retriangulated
            non_manifold_edge_unresolved
          ].include?(item.fetch(:category, nil))
        end
      end

      def limitations(feature_geometry, normalized, triangulation, budget_status)
        items = feature_geometry.limitations + normalized.fetch(:limitations) +
                triangulation.fetch(:limitations)
        items << { category: 'budget_status', reason: budget_status } if budget_status != 'ok'
        items.uniq
      end

      def anchor_violation_counts(feature_geometry, mesh)
        feature_geometry.output_anchor_candidates.each_with_object({}) do |anchor, memo|
          tolerance = anchor.fetch('tolerance', 1e-6).to_f
          distance = nearest_xy_distance(anchor.fetch('ownerLocalPoint'), mesh.fetch(:vertices))
          memo[anchor.fetch('id')] = distance if distance > tolerance
        end
      end

      def anchor_hit_distances(feature_geometry, mesh)
        feature_geometry.output_anchor_candidates.to_h do |anchor|
          [anchor.fetch('id'), nearest_xy_distance(anchor.fetch('ownerLocalPoint'),
                                                   mesh.fetch(:vertices))]
        end
      end

      def nearest_xy_distance(point, vertices)
        vertices.map do |vertex|
          dx = vertex[0] - point[0]
          dy = vertex[1] - point[1]
          Math.sqrt((dx * dx) + (dy * dy))
        end.min || Float::INFINITY
      end

      def topology_checks(mesh)
        normals = mesh.fetch(:triangles).map { |triangle| triangle_normal(mesh, triangle) }
        {
          downFaceCount: normals.count { |normal| normal[2].negative? },
          nonManifoldEdgeCount: non_manifold_edge_count(mesh.fetch(:triangles)),
          invalidFaceCount: 0,
          maxNormalBreakDeg: max_normal_break(normals)
        }
      end

      def topology_residuals(topology)
        {
          'protected_boundary' => { maxNormalBreakDeg: topology.fetch(:maxNormalBreakDeg) },
          'corridor_centerline' => { maxNormalBreakDeg: topology.fetch(:maxNormalBreakDeg) },
          'general_terrain' => { maxNormalBreakDeg: topology.fetch(:maxNormalBreakDeg) }
        }
      end

      def firm_residuals_by_role(feature_geometry, coverage)
        residual = (1.0 - coverage) * feature_geometry.reference_segments.length
        { 'reference_segments' => residual, 'pressure_regions' => 0.0 }
      end

      def firm_residual_high?(metrics)
        metrics.fetch(:firmResidualsByRole).values.any? { |value| value.to_f > 10.0 }
      end

      def non_manifold_edge_count(triangles)
        edges = Hash.new(0)
        triangles.each do |triangle|
          triangle.each_cons(2) { |a, b| edges[[a, b].sort] += 1 }
          edges[[triangle.last, triangle.first].sort] += 1
        end
        edges.values.count { |count| count > 2 }
      end

      # rubocop:disable Metrics/AbcSize
      def triangle_normal(mesh, triangle)
        point_a, point_b, point_c = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        u = [point_b[0] - point_a[0], point_b[1] - point_a[1], point_b[2] - point_a[2]]
        v = [point_c[0] - point_a[0], point_c[1] - point_a[1], point_c[2] - point_a[2]]
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

      def max_normal_break(normals)
        return 0.0 if normals.length < 2

        normals.combination(2).map { |a, b| angle_between(a, b) }.max || 0.0
      end

      def angle_between(first, second)
        dot = first.zip(second).sum { |a, b| a * b }
        Math.acos(dot.clamp(-1.0, 1.0)) * 180.0 / Math::PI
      end

      def state_digest(state)
        JSON.generate(
          id: state.state_id,
          dimensions: state.dimensions,
          spacing: state.spacing,
          revision: state.revision
        )
      end

      def columns(state)
        state.dimensions.fetch('columns')
      end

      def rows(state)
        state.dimensions.fetch('rows')
      end

      def x_at(state, column)
        state.origin.fetch('x') + (column * state.spacing.fetch('x'))
      end

      def y_at(state, row)
        state.origin.fetch('y') + (row * state.spacing.fetch('y'))
      end

      def elevation_at(state, column, row)
        state.elevations.fetch((row * columns(state)) + column)
      end

      def ratio(value, min, max)
        return 0.0 if max == min

        (value - min).to_f / (max - min)
      end

      def point_key(point)
        point.map { |value| value.round(POINT_KEY_PRECISION) }
      end

      def normalized_residual_refinement_point_ratio(value)
        Float(value).clamp(0.35, 1.0)
      rescue ArgumentError, TypeError
        RESIDUAL_REFINEMENT_POINT_RATIO
      end

      def normalized_residual_refinement_max_passes(value)
        Integer(value).clamp(0, 48)
      rescue ArgumentError, TypeError
        RESIDUAL_REFINEMENT_MAX_PASSES
      end

      def normalized_residual_refinement_batch_size(value)
        Integer(value).clamp(1, 256)
      rescue ArgumentError, TypeError
        RESIDUAL_REFINEMENT_BATCH_SIZE
      end
    end
  end
end
