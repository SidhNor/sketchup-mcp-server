# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/pad_builder'

class PadBuilderTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @builder = SU_MCP::Semantic::PadBuilder.new
  end

  def test_build_creates_face_only_group_when_thickness_is_absent
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'pad',
        'sourceElementId' => 'terrace-001',
        'status' => 'proposed',
        'footprint' => [[0.0, 0.0], [4.0, 0.0], [4.0, 3.0], [0.0, 3.0]],
        'elevation' => 0.5
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.faces.length)
    assert_equal([], group.entities.faces.first.pushpull_calls)
  end

  def test_build_pushpulls_downward_when_thickness_is_present
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'pad',
        'sourceElementId' => 'deck-001',
        'status' => 'proposed',
        'footprint' => [[0.0, 0.0], [4.0, 0.0], [4.0, 3.0], [0.0, 3.0]],
        'elevation' => 1.2,
        'thickness' => 0.3
      }
    )

    assert_equal([-0.3], group.entities.faces.first.pushpull_calls)
  end

  def test_build_applies_name_tag_and_material_to_wrapper_group
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'pad',
        'sourceElementId' => 'terrace-001',
        'status' => 'proposed',
        'footprint' => [[0.0, 0.0], [4.0, 0.0], [4.0, 3.0], [0.0, 3.0]],
        'name' => 'Front Terrace',
        'tag' => 'Proposed',
        'material' => 'Concrete'
      }
    )

    assert_equal('Front Terrace', group.name)
    assert_equal('Proposed', group.layer.name)
    assert_equal('Concrete', group.material.display_name)
  end

  def test_build_extrudes_downward_even_for_reversed_footprint_order
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'pad',
        'sourceElementId' => 'deck-001',
        'status' => 'proposed',
        'footprint' => [[0.0, 0.0], [0.0, 3.0], [4.0, 3.0], [4.0, 0.0]],
        'thickness' => 0.3
      }
    )

    assert_equal([-0.3], group.entities.faces.first.pushpull_calls)
  end
end
