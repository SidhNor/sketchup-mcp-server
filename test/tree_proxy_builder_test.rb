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

  def test_build_creates_a_clustered_tree_proxy_with_trunk_and_three_canopy_lobes
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
    assert_equal(4, group.entities.groups.length)
    assert_equal('Cherry Proxy', group.name)
    assert_equal('Trees', group.layer.name)
  end
end
# rubocop:enable Metrics/MethodLength
