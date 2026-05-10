# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Performs run-local point insertion by replacing only the affected triangle cavity.
    class PatchAffectedRegionUpdater
      DEGENERATE_EPSILON = 1e-12

      def insert(triangulation:, point:, domain:, boundary_segments:,
                 force_rebuild_detection: false)
        pair = point.map(&:to_f)
        unless domain.contains_point?(pair)
          return fallback(
            'out_of_domain_vertex',
            triangulation,
            boundary_violation: 'out_of_domain_vertex'
          )
        end
        # MTA-32 VALIDATION-ONLY: deterministic hook for proving rebuilds fail closed. Remove this
        # test hook once MTA-34 has production replacement telemetry for rebuild detection.
        return rebuild_failure(triangulation) if force_rebuild_detection

        vertices = triangulation.fetch(:vertices).map(&:dup)
        triangles = triangulation.fetch(:triangles).map(&:dup)
        affected_indices = affected_triangle_indices(vertices, triangles, pair)
        return fallback('triangulation_update_failed', triangulation) if affected_indices.empty?

        inserted_index = vertices.length
        vertices << pair
        replacements = replacement_triangles(vertices, triangles, affected_indices, inserted_index)
        remaining = triangles.each_with_index
                             .reject { |_triangle, index| affected_indices.include?(index) }
                             .map(&:first)
        updated_triangles = remaining + replacements
        updated = triangulation.merge(vertices: vertices, triangles: updated_triangles)
        diagnostics = diagnostics_for(
          before: triangulation,
          after: updated,
          affected_indices: affected_indices,
          replacements: replacements,
          rebuild_detected: false,
          recomputation_scope: 'affected',
          boundary_violation: nil
        )
        {
          status: 'accepted',
          triangulation: updated,
          affectedTriangles: affected_indices.map { |index| triangles.fetch(index) },
          diagnostics: diagnostics.merge(
            boundaryConstraintPreserved: boundary_preserved?(updated, boundary_segments)
          )
        }
      end

      private

      def rebuild_failure(triangulation)
        {
          status: 'fallback',
          reason: 'affected_region_update_failed',
          triangulation: triangulation,
          diagnostics: diagnostics_for(
            before: triangulation,
            after: triangulation,
            affected_indices: [],
            replacements: [],
            rebuild_detected: true,
            recomputation_scope: 'full',
            boundary_violation: 'full_patch_rebuild_detected'
          )
        }
      end

      def fallback(reason, triangulation, boundary_violation: reason)
        {
          status: 'fallback',
          reason: reason,
          triangulation: triangulation,
          diagnostics: diagnostics_for(
            before: triangulation,
            after: triangulation,
            affected_indices: [],
            replacements: [],
            rebuild_detected: false,
            recomputation_scope: 'none',
            boundary_violation: boundary_violation
          )
        }
      end

      def affected_triangle_indices(vertices, triangles, point)
        containing = triangles.each_index.select do |index|
          point_in_triangle?(vertices, point, triangles.fetch(index))
        end
        circumcircle = triangles.each_index.select do |index|
          inside_circumcircle?(vertices, point, triangles.fetch(index))
        end
        affected = (containing + circumcircle).uniq
        return affected unless affected.empty?

        containing
      end

      def replacement_triangles(vertices, triangles, affected_indices, inserted_index)
        replacements = boundary_edges(triangles.values_at(*affected_indices)).map do |edge|
          orient_triangle([edge[0], edge[1], inserted_index], vertices)
        end
        replacements.reject do |triangle|
          triangle_area(vertices, triangle).abs <= DEGENERATE_EPSILON
        end
      end

      def boundary_edges(triangles)
        counts = Hash.new(0)
        directed = {}
        triangles.each do |triangle|
          triangle_edges(triangle).each do |edge|
            key = edge.sort
            counts[key] += 1
            directed[key] = edge
          end
        end
        counts.select { |_key, count| count == 1 }.keys.map { |key| directed.fetch(key) }
      end

      def triangle_edges(triangle)
        [[triangle[0], triangle[1]], [triangle[1], triangle[2]], [triangle[2], triangle[0]]]
      end

      def point_in_triangle?(vertices, point, triangle)
        weights = barycentric_weights(triangle.map { |index| vertices.fetch(index) }, point)
        weights&.all? { |weight| weight.between?(-1e-9, 1.0 + 1e-9) }
      end

      # rubocop:disable Metrics/AbcSize
      def barycentric_weights(points, point)
        a, b, c = points
        denominator = ((b[1] - c[1]) * (a[0] - c[0])) + ((c[0] - b[0]) * (a[1] - c[1]))
        return nil if denominator.abs <= DEGENERATE_EPSILON

        first = (((b[1] - c[1]) * (point[0] - c[0])) +
          ((c[0] - b[0]) * (point[1] - c[1]))) / denominator
        second = (((c[1] - a[1]) * (point[0] - c[0])) +
          ((a[0] - c[0]) * (point[1] - c[1]))) / denominator
        [first, second, 1.0 - first - second]
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize
      def inside_circumcircle?(vertices, point, triangle)
        a, b, c = triangle.map { |index| vertices.fetch(index) }
        ax = a[0] - point[0]
        ay = a[1] - point[1]
        bx = b[0] - point[0]
        by = b[1] - point[1]
        cx = c[0] - point[0]
        cy = c[1] - point[1]
        determinant = (((ax * ax) + (ay * ay)) * ((bx * cy) - (cx * by))) -
                      (((bx * bx) + (by * by)) * ((ax * cy) - (cx * ay))) +
                      (((cx * cx) + (cy * cy)) * ((ax * by) - (bx * ay)))
        orientation(a, b, c).positive? ? determinant.positive? : determinant.negative?
      end
      # rubocop:enable Metrics/AbcSize

      def orient_triangle(triangle, vertices)
        triangle_area(vertices, triangle).negative? ? triangle.reverse : triangle
      end

      def triangle_area(vertices, triangle)
        orientation(*triangle.map { |index| vertices.fetch(index) }) / 2.0
      end

      def orientation(point_a, point_b, point_c)
        ((point_b[0] - point_a[0]) * (point_c[1] - point_a[1])) -
          ((point_b[1] - point_a[1]) * (point_c[0] - point_a[0]))
      end

      def boundary_preserved?(triangulation, boundary_segments)
        boundary_segments.all? do |segment|
          edge_present?(triangulation, segment.fetch(:start), segment.fetch(:end))
        end
      end

      def edge_present?(triangulation, start_point, end_point)
        start_index = point_index(triangulation.fetch(:vertices), start_point)
        end_index = point_index(triangulation.fetch(:vertices), end_point)
        return false unless start_index && end_index

        triangulation.fetch(:triangles).any? do |triangle|
          triangle_edges(triangle).any? { |edge| edge.sort == [start_index, end_index].sort }
        end
      end

      def point_index(vertices, point)
        vertices.index { |candidate| distance_squared(candidate, point) <= 1e-12 }
      end

      def distance_squared(first, second)
        dx = first[0] - second[0]
        dy = first[1] - second[1]
        (dx * dx) + (dy * dy)
      end

      def diagnostics_for(before:, after:, affected_indices:, replacements:, rebuild_detected:,
                          recomputation_scope:, boundary_violation:)
        {
          affectedTriangleCount: affected_indices.length,
          crossedTriangleCount: affected_indices.length,
          removedTriangleCount: affected_indices.length,
          createdTriangleCount: replacements.length,
          beforePointCount: before.fetch(:vertices).length,
          afterPointCount: after.fetch(:vertices).length,
          totalPatchTriangleCount: after.fetch(:triangles).length,
          rebuildDetected: rebuild_detected,
          recomputationScope: recomputation_scope,
          boundaryViolationReason: boundary_violation
        }
      end
    end
  end
end
