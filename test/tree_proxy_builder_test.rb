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
    assert_equal(254, proxy_mesh.entities.faces.length)
    assert_equal(240, proxy_mesh.entities.faces.count { |face| face.points.length == 4 })
    assert_equal(12, proxy_mesh.entities.faces.count { |face| face.points.length == 3 })

    horizontal_caps = proxy_mesh.entities.faces.select do |face|
      face.points.length == 12 && face.points.map { |point| point[2] }.uniq.length == 1
    end
    assert_equal(2, horizontal_caps.length)

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

  def span(points, axis:)
    coordinates = points.map { |point| point.fetch(axis) }
    coordinates.max - coordinates.min
  end
end
# rubocop:enable Metrics/MethodLength
