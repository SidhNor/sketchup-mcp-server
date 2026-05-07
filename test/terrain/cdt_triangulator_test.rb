# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/cdt_triangulator'

class CdtTriangulatorTest < Minitest::Test
  def test_unconstrained_square_produces_delaunay_valid_mesh
    result = triangulator.triangulate(
      points: square_points,
      constraints: []
    )

    assert_equal(4, result.fetch(:vertices).length)
    assert_equal(2, result.fetch(:triangles).length)
    assert_equal(0, result.fetch(:delaunayViolationCount))
    assert_equal(1.0, result.fetch(:constrainedEdgeCoverage))
    assert_empty(result.fetch(:limitations))
  end

  def test_constrained_edges_are_recovered_and_not_flipped_away
    result = triangulator.triangulate(
      points: square_points,
      constraints: [
        { id: 'diagonal', start: [0.0, 0.0], end: [1.0, 1.0], strength: 'hard' }
      ]
    )

    assert_includes(result.fetch(:constrainedEdges), [[0.0, 0.0], [1.0, 1.0]])
    assert_equal(1.0, result.fetch(:constrainedEdgeCoverage))
    assert(result.fetch(:triangles).any? { |triangle| triangle_edge?(result, triangle, [0, 3]) })
  end

  def test_intersecting_constraints_record_limitation_but_still_emit_mesh
    result = triangulator.triangulate(
      points: square_points,
      constraints: [
        { id: 'a', start: [0.0, 0.0], end: [1.0, 1.0], strength: 'hard' },
        { id: 'b', start: [0.0, 1.0], end: [1.0, 0.0], strength: 'firm' }
      ]
    )

    assert_operator(result.fetch(:triangles).length, :>, 0)
    assert_operator(result.fetch(:constrainedEdgeCoverage), :<, 1.0)
    assert_includes(JSON.generate(result.fetch(:limitations)), 'intersecting_constraint')
  end

  def test_near_duplicate_and_near_collinear_points_record_degeneracy_limitation
    result = triangulator.triangulate(
      points: square_points + [[0.000_000_1, 0.0], [0.5, 0.000_000_1]],
      constraints: []
    )

    assert_operator(result.fetch(:triangles).length, :>, 0)
    assert_includes(JSON.generate(result.fetch(:limitations)), 'degenerate_input')
    assert_equal(0, non_manifold_edge_count(result.fetch(:triangles)))
  end

  def test_non_manifold_cleanup_covers_live_gap_shape_without_dropping_faces
    limitations = []
    vertices = live_gap_vertices
    triangles = live_gap_triangles

    repaired = triangulator.send(:repair_non_manifold_edges, vertices, triangles, limitations)

    assert_equal(0, non_manifold_edge_count(repaired))
    assert_operator(repaired.length, :>=, triangles.length)
    assert_original_triangle_interiors_covered(vertices, triangles, repaired)
    assert_positive_area_triangles(vertices, repaired)
  end

  def test_non_manifold_repair_preserves_unrelated_neighbor_triangles
    limitations = []
    vertices = live_gap_vertices + [[4.0, 4.0], [5.0, 4.0], [4.0, 5.0]]
    triangles = live_gap_triangles + [[6, 7, 8]]

    repaired = triangulator.send(:repair_non_manifold_edges, vertices, triangles, limitations)

    assert_includes(repaired, [6, 7, 8])
    assert_equal(0, non_manifold_edge_count(repaired))
  end

  private

  def triangulator
    @triangulator ||= SU_MCP::Terrain::CdtTriangulator.new
  end

  def square_points
    [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0]]
  end

  def live_gap_vertices
    [
      [0.0, 2.0],
      [1.0, 2.0],
      [2.0, 2.0],
      [3.0, 0.0],
      [0.0, 0.0],
      [0.0, 1.0]
    ]
  end

  def live_gap_triangles
    [
      [2, 1, 5],
      [5, 3, 1],
      [1, 0, 5],
      [4, 1, 5]
    ]
  end

  def triangle_edge?(result, triangle, edge)
    points = edge.map { |index| result.fetch(:vertices).fetch(index) }
    triangle_points = triangle.map { |index| result.fetch(:vertices).fetch(index) }
    triangle_points.combination(2).any? { |candidate| candidate.sort == points.sort }
  end

  def non_manifold_edge_count(triangles)
    edges = Hash.new(0)
    triangles.each do |triangle|
      triangle.each_cons(2) { |a, b| edges[[a, b].sort] += 1 }
      edges[[triangle.last, triangle.first].sort] += 1
    end
    edges.values.count { |count| count > 2 }
  end

  def assert_original_triangle_interiors_covered(vertices, original, repaired)
    original.each do |triangle|
      point = triangle_centroid(vertices, triangle)
      assert(
        repaired.any? { |candidate| point_in_triangle?(vertices, point, candidate) },
        "expected repaired mesh to cover original triangle centroid #{point.inspect}"
      )
    end
  end

  def assert_positive_area_triangles(vertices, triangles)
    triangles.each do |triangle|
      assert_operator(orientation(*triangle.map { |index| vertices.fetch(index) }).abs, :>, 1e-9)
    end
  end

  def triangle_centroid(vertices, triangle)
    points = triangle.map { |index| vertices.fetch(index) }
    [
      points.sum { |point| point[0] } / 3.0,
      points.sum { |point| point[1] } / 3.0
    ]
  end

  def point_in_triangle?(vertices, point, triangle)
    points = triangle.map { |index| vertices.fetch(index) }
    orientations = [
      orientation(points[0], points[1], point),
      orientation(points[1], points[2], point),
      orientation(points[2], points[0], point)
    ]
    orientations.all? { |value| value >= -1e-9 } ||
      orientations.all? { |value| value <= 1e-9 }
  end

  def orientation(point_a, point_b, point_c)
    ((point_b[0] - point_a[0]) * (point_c[1] - point_a[1])) -
      ((point_b[1] - point_a[1]) * (point_c[0] - point_a[0]))
  end

  def triangle_edges(triangle)
    [[triangle[0], triangle[1]], [triangle[1], triangle[2]], [triangle[2], triangle[0]]]
  end
end
