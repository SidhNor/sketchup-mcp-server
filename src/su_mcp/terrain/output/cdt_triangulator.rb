# frozen_string_literal: true

module SU_MCP
  module Terrain
    # MTA-24 comparison-only constrained triangulator seam.
    class CdtTriangulator # rubocop:disable Metrics/ClassLength
      VERSION = 'mta24-ruby-cdt-prototype-0'
      ORIENTATION_EPSILON = 1e-9
      DUPLICATE_EPSILON = 1e-6
      NON_MANIFOLD_REPAIR_VERTEX_LIMIT = 12
      NON_MANIFOLD_REPAIR_ITERATION_LIMIT = 32

      def triangulate(points:, constraints: [])
        normalized = normalize_points(points, constraints)
        vertices = normalized.fetch(:points)
        limitations = normalized.fetch(:limitations)
        triangles = delaunay_triangles(vertices)
        normalized_constraints = normalize_constraints(constraints)
        limitation_constraints = intersecting_constraints(normalized_constraints)
        limitations.concat(limitation_constraints.map do |first, second|
          { category: 'intersecting_constraint', constraintIds: [first[:id], second[:id]] }
        end)
        triangles = recover_simple_constraint_edges(vertices, triangles, normalized_constraints)
        triangles = repair_non_manifold_edges(vertices, triangles, limitations)
        coverage = constrained_edge_coverage(vertices, triangles, normalized_constraints,
                                             limitation_constraints)
        limitations.concat(uncovered_constraint_limitations(vertices, triangles,
                                                            normalized_constraints,
                                                            limitation_constraints))

        {
          vertices: vertices,
          triangles: triangles,
          constrainedEdges: covered_constraints(vertices, triangles, normalized_constraints),
          constrainedEdgeCoverage: coverage,
          delaunayViolationCount: delaunay_violation_count(vertices, triangles,
                                                           normalized_constraints),
          limitations: limitations
        }
      end

      private

      def normalize_points(points, constraints)
        limitations = []
        all_points = points.map { |point| point_pair(point) }
        constraints.each do |constraint|
          all_points << point_pair(constraint.fetch(:start))
          all_points << point_pair(constraint.fetch(:end))
        end
        normalized = []
        all_points.each do |point|
          if normalized.any? { |existing| near_point?(existing, point) }
            limitations << { category: 'degenerate_input', reason: 'near_duplicate_point' }
            next
          end

          normalized << point
        end
        if near_collinear?(normalized)
          limitations << { category: 'degenerate_input', reason: 'near_collinear_point' }
        end
        { points: normalized, limitations: limitations.uniq }
      end

      def point_pair(point)
        [Float(point.fetch(0)), Float(point.fetch(1))]
      end

      def normalize_constraints(constraints)
        normalized = constraints.map do |constraint|
          {
            id: constraint.fetch(:id, "constraint-#{object_id}"),
            start: point_pair(constraint.fetch(:start)),
            end: point_pair(constraint.fetch(:end)),
            strength: constraint.fetch(:strength, 'firm')
          }
        end
        normalized.reject { |constraint| near_point?(constraint[:start], constraint[:end]) }
      end

      def near_point?(first, second)
        distance_squared(first, second) <= DUPLICATE_EPSILON * DUPLICATE_EPSILON
      end

      def distance_squared(first, second)
        dx = first.fetch(0) - second.fetch(0)
        dy = first.fetch(1) - second.fetch(1)
        (dx * dx) + (dy * dy)
      end

      def near_collinear?(points)
        return false if points.length < 4

        points.combination(3).any? do |a, b, c|
          !near_point?(a, b) && !near_point?(a, c) && !near_point?(b, c) &&
            orientation(a, b, c).abs <= DUPLICATE_EPSILON
        end
      end

      def delaunay_triangles(points)
        return [] if points.length < 3

        working_points = points.map(&:dup)
        triangles = [super_triangle(working_points)]
        points.each_with_index do |point, index|
          bad = triangles.select do |triangle|
            inside_circumcircle?(point, triangle, working_points)
          end
          polygon = boundary_edges(bad)
          triangles -= bad
          polygon.each do |edge|
            triangles << orient_triangle([edge[0], edge[1], index], working_points)
          end
        end
        real_count = points.length
        triangles.reject { |triangle| triangle.any? { |index| index >= real_count } }
                 .reject do |triangle|
                   triangle_area(working_points, triangle).abs <= ORIENTATION_EPSILON
                 end
                 .uniq
      end

      def super_triangle(points)
        min_x, max_x = points.map(&:first).minmax
        min_y, max_y = points.map { |point| point.fetch(1) }.minmax
        span = [max_x - min_x, max_y - min_y, 1.0].max * 16.0
        base = points.length
        points << [min_x - span, min_y - span]
        points << [min_x + ((max_x - min_x) / 2.0), max_y + span]
        points << [max_x + span, min_y - span]
        [base, base + 1, base + 2]
      end

      # rubocop:disable Metrics/AbcSize
      def inside_circumcircle?(point, triangle, points)
        point_a, point_b, point_c = triangle.map { |index| points.fetch(index) }
        ax = point_a[0] - point[0]
        ay = point_a[1] - point[1]
        bx = point_b[0] - point[0]
        by = point_b[1] - point[1]
        cx = point_c[0] - point[0]
        cy = point_c[1] - point[1]
        determinant = (((ax * ax) + (ay * ay)) * ((bx * cy) - (cx * by))) -
                      (((bx * bx) + (by * by)) * ((ax * cy) - (cx * ay))) +
                      (((cx * cx) + (cy * cy)) * ((ax * by) - (bx * ay)))
        if orientation(point_a, point_b, point_c).positive?
          determinant > ORIENTATION_EPSILON
        else
          determinant < -ORIENTATION_EPSILON
        end
      end
      # rubocop:enable Metrics/AbcSize

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
        counts.select { |_edge, count| count == 1 }.keys.map { |key| directed.fetch(key) }
      end

      def triangle_edges(triangle)
        [[triangle[0], triangle[1]], [triangle[1], triangle[2]], [triangle[2], triangle[0]]]
      end

      def repair_non_manifold_edges(vertices, triangles, limitations)
        repaired = triangles.dup
        seen_repairs = {}
        repair_count = 0
        loop do
          indexed = indexed_edges(repaired)
          edge, triangle_indices = indexed.find { |_key, indices| indices.length > 2 }
          break unless edge

          signature = repair_signature(edge, triangle_indices, repaired)
          if seen_repairs[signature] || repair_count >= NON_MANIFOLD_REPAIR_ITERATION_LIMIT
            limitations << unresolved_non_manifold_limitation
            break
          end

          seen_repairs[signature] = true
          candidate = local_non_manifold_edge_repair(vertices, repaired, edge, triangle_indices)
          unless candidate &&
                 non_manifold_edge_count(candidate) < non_manifold_edge_count(repaired)
            limitations << unresolved_non_manifold_limitation
            break
          end

          repaired = candidate
          repair_count += 1
          limitations << {
            category: 'non_manifold_edge_repaired',
            reason: 'over-shared triangulation edge was repaired by bounded local retriangulation'
          }
        end
        repaired
      end

      def indexed_edges(triangles)
        edges = Hash.new { |hash, key| hash[key] = [] }
        triangles.each_with_index do |triangle, index|
          triangle_edges(triangle).each { |edge| edges[edge.sort] << index }
        end
        edges
      end

      def repair_signature(edge, triangle_indices, triangles)
        [
          edge.sort,
          triangle_indices.map { |index| triangles.fetch(index).sort }.sort
        ]
      end

      def local_non_manifold_edge_repair(vertices, triangles, edge, triangle_indices)
        local_indices = triangle_indices.flat_map { |index| triangles.fetch(index) }.uniq
        return nil if local_indices.length > NON_MANIFOLD_REPAIR_VERTEX_LIMIT

        replacements = retriangulate_non_manifold_cavity(vertices, triangles, triangle_indices)
        return nil if replacements.empty?

        candidate = triangles.each_with_index
                             .reject { |_triangle, index| triangle_indices.include?(index) }
                             .map(&:first)
        candidate.concat(replacements)
        return nil if replacement_edges_cross_existing?(vertices, candidate, replacements, edge)

        candidate
      end

      def retriangulate_non_manifold_cavity(vertices, triangles, triangle_indices)
        local_indices = triangle_indices.flat_map { |index| triangles.fetch(index) }.uniq
        local_points = local_indices.map { |index| vertices.fetch(index) }
        delaunay_triangles(local_points).map do |triangle|
          orient_triangle(triangle.map { |local_index| local_indices.fetch(local_index) },
                          vertices)
        end
      end

      def replacement_edges_cross_existing?(vertices, candidate, replacements, repaired_edge)
        replacement_edges = replacements.flat_map { |triangle| triangle_edges(triangle) }
        existing_edges = (candidate - replacements).flat_map { |triangle| triangle_edges(triangle) }
        replacement_edges.any? do |replacement|
          existing_edges.any? do |existing|
            next false unless (replacement & existing).empty?
            next false if replacement.sort == repaired_edge.sort

            segments_cross?(vertices.fetch(replacement[0]), vertices.fetch(replacement[1]),
                            vertices.fetch(existing[0]), vertices.fetch(existing[1]))
          end
        end
      end

      def non_manifold_edge_count(triangles)
        indexed_edges(triangles).values.count { |indices| indices.length > 2 }
      end

      def unresolved_non_manifold_limitation
        {
          category: 'non_manifold_edge_unresolved',
          reason: 'over-shared triangulation edge exceeded bounded local repair scope'
        }
      end

      def orient_triangle(triangle, points)
        triangle_points = triangle.map { |index| points.fetch(index) }
        if orientation(*triangle_points).negative?
          triangle.reverse
        else
          triangle
        end
      end

      def triangle_area(points, triangle)
        orientation(*triangle.map { |index| points.fetch(index) }) / 2.0
      end

      def recover_simple_constraint_edges(vertices, triangles, constraints)
        constraints.reduce(triangles) do |memo, constraint|
          start_index = point_index(vertices, constraint[:start])
          end_index = point_index(vertices, constraint[:end])
          next memo unless start_index && end_index
          next memo if edge_present?(memo, start_index, end_index)

          recover_single_edge(vertices, memo, start_index, end_index)
        end
      end

      def recover_single_edge(vertices, triangles, start_index, end_index)
        # Prototype scope: only the simplest quadrilateral diagonal swap is recovered here.
        # General cavity recovery remains surfaced through unsupported_constraint_recovery.
        return triangles unless vertices.length == 4 && triangles.length == 2

        other = (0...vertices.length).to_a - [start_index, end_index]
        [
          orient_triangle([start_index, other[0], end_index], vertices),
          orient_triangle([start_index, end_index, other[1]], vertices)
        ]
      end

      def constrained_edge_coverage(vertices, triangles, constraints, limitation_constraints)
        return 1.0 if constraints.empty?

        blocked = limitation_constraints.flatten.map { |constraint| constraint[:id] }.uniq
        covered = constraints.count do |constraint|
          !blocked.include?(constraint[:id]) && constraint_covered?(vertices, triangles, constraint)
        end
        covered.to_f / constraints.length
      end

      def uncovered_constraint_limitations(vertices, triangles, constraints, limitation_constraints)
        blocked = limitation_constraints.flatten.map { |constraint| constraint[:id] }.uniq
        uncovered = constraints.reject do |constraint|
          blocked.include?(constraint[:id]) || constraint_covered?(vertices, triangles, constraint)
        end
        uncovered.map do |constraint|
          {
            category: 'unsupported_constraint_recovery',
            constraintId: constraint[:id],
            reason: 'constraint edge was not recovered by the prototype triangulator'
          }
        end
      end

      def covered_constraints(vertices, triangles, constraints)
        constraints.select { |constraint| constraint_covered?(vertices, triangles, constraint) }
                   .map { |constraint| [constraint[:start], constraint[:end]] }
      end

      def constraint_covered?(vertices, triangles, constraint)
        start_index = point_index(vertices, constraint[:start])
        end_index = point_index(vertices, constraint[:end])
        return false unless start_index && end_index
        return true if edge_present?(triangles, start_index, end_index)

        covered_by_subedges?(vertices, triangles, constraint)
      end

      def edge_present?(triangles, first, second)
        triangles.any? do |triangle|
          triangle_edges(triangle).any? { |edge| edge.sort == [first, second].sort }
        end
      end

      def covered_by_subedges?(vertices, triangles, constraint)
        indices = vertices.each_index.select do |index|
          point_on_segment?(vertices.fetch(index), constraint[:start], constraint[:end])
        end
        indices = indices.sort_by do |index|
          distance_squared(vertices.fetch(index), constraint[:start])
        end
        return false if indices.length < 2

        indices.each_cons(2).all? { |first, second| edge_present?(triangles, first, second) }
      end

      def point_on_segment?(point, start_point, end_point)
        orientation(start_point, end_point, point).abs <= DUPLICATE_EPSILON &&
          point[0].between?([start_point[0], end_point[0]].min - DUPLICATE_EPSILON,
                            [start_point[0], end_point[0]].max + DUPLICATE_EPSILON) &&
          point[1].between?([start_point[1], end_point[1]].min - DUPLICATE_EPSILON,
                            [start_point[1], end_point[1]].max + DUPLICATE_EPSILON)
      end

      def point_index(vertices, point)
        vertices.index { |candidate| near_point?(candidate, point) }
      end

      def intersecting_constraints(constraints)
        constraints.combination(2).select do |first, second|
          segments_cross?(first[:start], first[:end], second[:start], second[:end])
        end
      end

      def segments_cross?(start_a, end_a, start_b, end_b)
        if [start_a, end_a].any? do |point|
          near_point?(point, start_b) || near_point?(point, end_b)
        end
          return false
        end

        first = orientation(start_a, end_a, start_b)
        second = orientation(start_a, end_a, end_b)
        third = orientation(start_b, end_b, start_a)
        fourth = orientation(start_b, end_b, end_a)
        (first * second).negative? && (third * fourth).negative?
      end

      def delaunay_violation_count(vertices, triangles, constraints)
        constrained_keys = constraints.flat_map do |constraint|
          start_index = point_index(vertices, constraint[:start])
          end_index = point_index(vertices, constraint[:end])
          start_index && end_index ? [[start_index, end_index].sort] : []
        end
        triangles.combination(2).count do |first, second|
          shared = (first & second)
          next false unless shared.length == 2
          next false if constrained_keys.include?(shared.sort)

          opposite = (first + second - shared).uniq
          next false unless opposite.length == 2

          inside_circumcircle?(vertices.fetch(opposite[0]), first, vertices) ||
            inside_circumcircle?(vertices.fetch(opposite[1]), second, vertices)
        end
      end

      def orientation(point_a, point_b, point_c)
        ((point_b[0] - point_a[0]) * (point_c[1] - point_a[1])) -
          ((point_b[1] - point_a[1]) * (point_c[0] - point_a[0]))
      end
    end
  end
end
