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
    assert_equal(10, z_levels.length)
    assert_in_delta(5.5, z_levels.last, 1e-9)

    widest_canopy_ring = widest_ring_points(
      proxy_mesh,
      center_x: 14.0,
      center_y: 37.7,
      lower_z: cap_levels.last,
      upper_z: 5.5
    )
    assert_equal(12, widest_canopy_ring.length)

    radii = ordered_ring_points(widest_canopy_ring, center_x: 14.0, center_y: 37.7).map do |point|
      radial_distance(point, center_x: 14.0, center_y: 37.7)
    end
    assert_three_lobe_profile(radii)
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

  def widest_ring_points(group, center_x:, center_y:, lower_z:, upper_z:)
    ring_points = ring_levels(group)
                  .select { |z| z > lower_z && z < upper_z }
                  .map { |z| unique_points_at_z(group, z) }
                  .select { |points| points.length == 12 }

    ring_points.max_by do |points|
      points.sum { |point| radial_distance(point, center_x: center_x, center_y: center_y) }
    end
  end

  def ring_levels(group)
    group.entities.faces
         .flat_map { |face| face.points.map { |point| point[2] } }
         .uniq
         .sort
  end

  def unique_points_at_z(group, z_height, tolerance: 1e-9)
    group.entities.faces
         .flat_map(&:points)
         .select { |point| (point[2] - z_height).abs <= tolerance }
         .uniq { |point| point.map { |value| value.round(9) } }
  end

  def ordered_ring_points(points, center_x:, center_y:)
    points.sort_by do |point|
      Math.atan2(point[1] - center_y, point[0] - center_x)
    end
  end

  def radial_distance(point, center_x:, center_y:)
    Math.hypot(point[0] - center_x, point[1] - center_y)
  end

  # rubocop:disable Metrics/AbcSize
  def assert_three_lobe_profile(radii)
    peak_indices = local_extrema_indices(radii, :>)
    valley_indices = local_extrema_indices(radii, :<)

    assert_equal(3, peak_indices.length)
    assert_equal(3, valley_indices.length)

    peak_indices.each_cons(2) do |left, right|
      assert_equal(4, right - left)
    end
    assert_equal(4, (peak_indices.first + radii.length) - peak_indices.last)

    peak_radii = peak_indices.map { |index| radii[index] }
    valley_radii = valley_indices.map { |index| radii[index] }
    assert_operator(peak_radii.max / peak_radii.min, :<, 1.1)
    assert_operator(valley_radii.max, :<, peak_radii.min)
  end
  # rubocop:enable Metrics/AbcSize

  def local_extrema_indices(values, operator)
    values.each_index.select do |index|
      current = values[index]
      previous = values[(index - 1) % values.length]
      following = values[(index + 1) % values.length]
      current.public_send(operator, previous) && current.public_send(operator, following)
    end
  end

  def span(points, axis:)
    coordinates = points.map { |point| point.fetch(axis) }
    coordinates.max - coordinates.min
  end
end
# rubocop:enable Metrics/MethodLength
