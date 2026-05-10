# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Measures whether an MTA-32 debug patch mesh is topologically credible.
    class PatchTopologyQualityMeter
      AREA_EPSILON = 1e-9
      AREA_COVERAGE_TOLERANCE = 0.02
      MAX_EDGE_LENGTH_MULTIPLIER = 3.0

      def measure(domain:, boundary:, mesh:)
        vertices = mesh.fetch(:vertices)
        triangles = mesh.fetch(:triangles)
        areas = triangles.map { |triangle| signed_area(vertices, triangle) }
        edge_counts = edge_counts_for(triangles)
        area_ratio = area_coverage_ratio(domain, areas)
        max_allowed_edge = domain.nominal_spacing * MAX_EDGE_LENGTH_MULTIPLIER
        edge_lengths = unique_edge_lengths(vertices, edge_counts.keys)
        diagnostics = {
          outOfDomainVertexCount: out_of_domain_vertex_count(domain, vertices),
          degenerateTriangleCount: areas.count { |area| area.abs <= AREA_EPSILON },
          invertedTriangleCount: areas.count(&:negative?),
          nonManifoldEdgeCount: edge_counts.values.count { |count| count > 2 },
          boundaryConstraintPreserved: boundary_preserved?(vertices, triangles, boundary),
          areaCoverageRatio: area_ratio,
          maxEdgeLength: edge_lengths.max || 0.0,
          maxAllowedEdgeLength: max_allowed_edge,
          longEdgeCount: edge_lengths.count { |length| length > max_allowed_edge }
        }
        diagnostics.merge(passed: passed?(diagnostics))
      end

      private

      def passed?(diagnostics)
        diagnostics.fetch(:outOfDomainVertexCount).zero? &&
          diagnostics.fetch(:degenerateTriangleCount).zero? &&
          diagnostics.fetch(:invertedTriangleCount).zero? &&
          diagnostics.fetch(:nonManifoldEdgeCount).zero? &&
          diagnostics.fetch(:boundaryConstraintPreserved) &&
          diagnostics.fetch(:longEdgeCount).zero? &&
          diagnostics.fetch(:areaCoverageRatio).between?(
            1.0 - AREA_COVERAGE_TOLERANCE,
            1.0 + AREA_COVERAGE_TOLERANCE
          )
      end

      def out_of_domain_vertex_count(domain, vertices)
        vertices.count { |vertex| !domain.contains_point?(vertex) }
      end

      def area_coverage_ratio(domain, areas)
        area = domain_area(domain)
        return 0.0 if area <= AREA_EPSILON

        areas.sum(&:abs) / area
      end

      def domain_area(domain)
        bounds = domain.owner_local_bounds
        (bounds.fetch(:maxX) - bounds.fetch(:minX)).abs *
          (bounds.fetch(:maxY) - bounds.fetch(:minY)).abs
      end

      def signed_area(vertices, triangle)
        first, second, third = triangle.map { |index| vertices.fetch(index) }
        (((second[0] - first[0]) * (third[1] - first[1])) -
          ((second[1] - first[1]) * (third[0] - first[0]))) / 2.0
      end

      def edge_counts_for(triangles)
        triangles.each_with_object(Hash.new(0)) do |triangle, counts|
          triangle_edges(triangle).each { |edge| counts[edge.sort] += 1 }
        end
      end

      def unique_edge_lengths(vertices, edges)
        edges.map do |first_index, second_index|
          xy_distance(vertices.fetch(first_index), vertices.fetch(second_index))
        end
      end

      def boundary_preserved?(vertices, triangles, boundary)
        boundary.fetch(:segments).all? do |segment|
          boundary_segment_covered?(
            vertices,
            triangles,
            segment.fetch(:start),
            segment.fetch(:end)
          )
        end
      end

      def boundary_segment_covered?(vertices, triangles, start_point, end_point)
        indexes = segment_vertex_indexes(vertices, start_point, end_point)
        return false if indexes.length < 2

        mesh_edges = edge_counts_for(triangles).keys
        sorted = indexes.sort_by do |index|
          distance_along_segment(vertices.fetch(index), start_point)
        end
        sorted.each_cons(2).all? do |first_index, second_index|
          mesh_edges.include?([first_index, second_index].sort)
        end
      end

      def segment_vertex_indexes(vertices, start_point, end_point)
        vertices.each_index.select do |index|
          point_on_segment?(vertices.fetch(index), start_point, end_point)
        end
      end

      def point_on_segment?(point, start_point, end_point)
        cross = ((point[0] - start_point[0]) * (end_point[1] - start_point[1])) -
                ((point[1] - start_point[1]) * (end_point[0] - start_point[0]))
        return false unless cross.abs <= 1e-6

        point[0].between?(*minmax_with_tolerance(start_point[0], end_point[0])) &&
          point[1].between?(*minmax_with_tolerance(start_point[1], end_point[1]))
      end

      def minmax_with_tolerance(first, second)
        min, max = [first, second].minmax
        [min - 1e-6, max + 1e-6]
      end

      def distance_along_segment(point, start_point)
        xy_distance(point, start_point)
      end

      def triangle_edges(triangle)
        [[triangle[0], triangle[1]], [triangle[1], triangle[2]], [triangle[2], triangle[0]]]
      end

      def xy_distance(first, second)
        dx = first[0] - second[0]
        dy = first[1] - second[1]
        Math.sqrt((dx * dx) + (dy * dy))
      end
    end
  end
end
