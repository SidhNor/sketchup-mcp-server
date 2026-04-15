# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require_relative 'test_helper'
require_relative 'support/semantic_test_support'
require_relative '../src/su_mcp/semantic/path_builder'

class PathBuilderTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::PathBuilder.new
  end

  def test_build_creates_a_path_mass_from_centerline_width_and_thickness
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'path',
        'sourceElementId' => 'main-walk-001',
        'status' => 'proposed',
        'path' => {
          'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
          'width' => 1.6,
          'elevation' => 0.0,
          'thickness' => 0.1
        },
        'name' => 'Main Walk',
        'tag' => 'Paths',
        'material' => 'Gravel'
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.faces.length)
    assert_equal([-0.1], group.entities.faces.first.pushpull_calls)
    assert_includes(group.entities.faces.first.points, [8.0, 1.8, 0.0])
    assert_equal('Main Walk', group.name)
  end
end
# rubocop:enable Metrics/MethodLength
