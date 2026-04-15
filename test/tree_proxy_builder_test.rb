# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require_relative 'test_helper'
require_relative 'support/semantic_test_support'
require_relative '../src/su_mcp/semantic/tree_proxy_builder'

class TreeProxyBuilderTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::TreeProxyBuilder.new
  end

  # rubocop:disable Metrics/AbcSize
  def test_build_creates_a_connected_tiered_tree_proxy_mesh
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'tree_proxy',
        'sourceElementId' => 'tree-001',
        'status' => 'retained',
        'tree_proxy' => {
          'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
          'canopyDiameterX' => 6.0,
          'canopyDiameterY' => 5.6,
          'height' => 5.5,
          'trunkDiameter' => 0.45,
          'speciesHint' => 'cherry'
        },
        'name' => 'Cherry Proxy',
        'tag' => 'Trees'
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.groups.length)
    assert_equal(0, group.entities.faces.length)
    assert_equal('Cherry Proxy', group.name)
    assert_equal('Trees', group.layer.name)

    proxy_mesh = group.entities.groups.first
    assert_instance_of(SemanticTestSupport::FakeGroup, proxy_mesh)
    assert_equal(0, proxy_mesh.entities.groups.length)
    assert_equal(470, proxy_mesh.entities.faces.length)
    assert_equal(24, proxy_mesh.entities.faces.count { |face| face.points.length == 4 })
    assert_equal(444, proxy_mesh.entities.faces.count { |face| face.points.length == 3 })

    horizontal_caps = proxy_mesh.entities.faces.select do |face|
      face.points.length == 12 && face.points.map { |point| point[2] }.uniq.length == 1
    end
    assert_equal(2, horizontal_caps.length)
    assert_empty(non_planar_faces(proxy_mesh))

    cap_levels = horizontal_caps.map { |face| face.points.first[2] }.sort
    assert_in_delta(0.0, cap_levels.first, 1e-9)
    assert_in_delta(
      5.5 * SU_MCP::Semantic::TreeProxyBuilder::TRUNK_TOP_RATIO,
      cap_levels.last,
      1e-9
    )

    base_cap = horizontal_caps.first
    assert_in_delta(0.45, span(base_cap.points, axis: 0), 1e-9)
    assert_in_delta(0.45, span(base_cap.points, axis: 1), 1e-9)

    z_levels = proxy_mesh.entities.faces
                         .flat_map { |face| face.points.map { |point| point[2] } }
                         .uniq
                         .sort
    assert_equal(21, z_levels.length)
    assert_in_delta(5.5 * SU_MCP::Semantic::TreeProxyBuilder::CANOPY_BASE_RATIO, z_levels[1], 1e-9)
    assert_in_delta(5.5, z_levels.last, 1e-9)
  end
  # rubocop:enable Metrics/AbcSize

  private

  def non_planar_faces(group)
    group.entities.faces.select do |face|
      face.points.length > 3 && !planar_points?(face.points)
    end
  end

  def planar_points?(points, tolerance: 1e-9)
    return true if points.length <= 3

    origin = points[0]
    normal = triangle_normal(origin, points[1], points[2])
    return true if near_zero_vector?(normal)

    points[3..].all? do |point|
      vector = subtract_points(point, origin)
      dot_product(normal, vector).abs <= tolerance
    end
  end

  def triangle_normal(point_a, point_b, point_c)
    cross_product(
      subtract_points(point_b, point_a),
      subtract_points(point_c, point_a)
    )
  end

  def subtract_points(point, origin)
    [
      point[0].to_f - origin[0].to_f,
      point[1].to_f - origin[1].to_f,
      point[2].to_f - origin[2].to_f
    ]
  end

  # rubocop:disable Metrics/AbcSize
  def cross_product(left, right)
    [
      (left[1].to_f * right[2].to_f) - (left[2].to_f * right[1].to_f),
      (left[2].to_f * right[0].to_f) - (left[0].to_f * right[2].to_f),
      (left[0].to_f * right[1].to_f) - (left[1].to_f * right[0].to_f)
    ]
  end
  # rubocop:enable Metrics/AbcSize

  def dot_product(left, right)
    left.zip(right).sum { |left_value, right_value| left_value.to_f * right_value.to_f }
  end

  def near_zero_vector?(vector, tolerance: 1e-9)
    vector.all? { |value| value.abs <= tolerance }
  end

  def span(points, axis:)
    coordinates = points.map { |point| point.fetch(axis) }
    coordinates.max - coordinates.min
  end
end
# rubocop:enable Metrics/MethodLength
