# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/planting_mass_builder'

class PlantingMassBuilderTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::PlantingMassBuilder.new
  end

  def test_build_creates_a_planting_mass_from_boundary_and_average_height
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'planting_mass',
        'sourceElementId' => 'hedge-001',
        'status' => 'proposed',
        'planting_mass' => {
          'boundary' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
          'averageHeight' => 1.8,
          'plantingCategory' => 'hedge',
          'elevation' => 0.0
        },
        'name' => 'Hedge Mass'
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.faces.length)
    assert_equal([1.8], group.entities.faces.first.pushpull_calls)
    assert_equal('Hedge Mass', group.name)
  end
end
