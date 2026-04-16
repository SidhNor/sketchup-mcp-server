# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/structure_builder'

class StructureBuilderTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::StructureBuilder.new
  end

  def test_build_creates_prismatic_mass_from_footprint_and_height
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'structure',
        'sourceElementId' => 'shed-001',
        'status' => 'proposed',
        'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
        'elevation' => 0.25,
        'height' => 2.4,
        'structureCategory' => 'outbuilding'
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal([2.4], group.entities.faces.first.pushpull_calls)
  end

  def test_build_requires_structure_category
    error = assert_raises(ArgumentError) do
      @builder.build(
        model: @model,
        params: {
          'elementType' => 'structure',
          'sourceElementId' => 'shed-001',
          'status' => 'proposed',
          'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
          'height' => 2.4
        }
      )
    end

    assert_match(/structureCategory/, error.message)
  end

  def test_build_extrudes_upward_even_for_reversed_footprint_order
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'structure',
        'sourceElementId' => 'shed-001',
        'status' => 'proposed',
        'footprint' => [[0.0, 0.0], [0.0, 3.0], [2.0, 3.0], [2.0, 0.0]],
        'height' => 2.4,
        'structureCategory' => 'outbuilding'
      }
    )

    assert_equal([2.4], group.entities.faces.first.pushpull_calls)
  end
end
