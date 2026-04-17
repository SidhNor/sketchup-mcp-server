# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/retaining_edge_builder'

class RetainingEdgeBuilderTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::RetainingEdgeBuilder.new
  end

  # rubocop:disable Metrics/MethodLength
  def test_build_creates_a_retaining_edge_mass_from_polyline_height_and_thickness
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'retaining_edge',
        'sceneProperties' => {
          'tag' => 'Edges'
        },
        'representation' => {
          'material' => 'Stone'
        },
        'definition' => {
          'mode' => 'polyline',
          'polyline' => [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
          'height' => 0.45,
          'thickness' => 0.25,
          'elevation' => 0.0
        }
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.faces.length)
    assert_equal([0.45], group.entities.faces.first.pushpull_calls)
    assert_equal('Edges', group.layer.name)
  end
  # rubocop:enable Metrics/MethodLength
end
