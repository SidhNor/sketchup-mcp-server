# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/builder_refusal'
require_relative '../../src/su_mcp/semantic/structure_builder'

class StructureBuilderTest < Minitest::Test
  include SemanticTestSupport

  class FakeTerrainAnchorResolver
    attr_reader :calls

    def initialize(sample_z: 8.5, refusal: nil)
      @sample_z = sample_z
      @refusal = refusal
      @calls = []
    end

    def resolve(host_target:, anchor_xy:, role:)
      @calls << { host_target: host_target, anchor_xy: anchor_xy, role: role }
      raise @refusal if @refusal

      @sample_z
    end
  end

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

  def test_build_creates_structure_into_supplied_destination_collection
    parent_group = @model.active_entities.add_group

    group = @builder.build(
      model: @model,
      destination: parent_group.entities,
      params: {
        'elementType' => 'structure',
        'definition' => {
          'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
          'height' => 2.4,
          'structureCategory' => 'outbuilding'
        }
      }
    )

    assert_same(group, parent_group.entities.groups.last)
    assert_equal(1, @model.active_entities.groups.length)
  end

  # rubocop:disable Metrics/MethodLength
  def test_build_consumes_sectioned_structure_definition_and_scene_properties
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'structure',
        'definition' => {
          'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
          'elevation' => 0.25,
          'height' => 2.4,
          'structureCategory' => 'outbuilding'
        },
        'sceneProperties' => {
          'name' => 'Sectioned Shed',
          'tag' => 'Structures'
        },
        'representation' => {
          'material' => 'Wood'
        }
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal([2.4], group.entities.faces.first.pushpull_calls)
    assert_equal('Sectioned Shed', group.name)
    assert_equal('Structures', group.layer.name)
    assert_equal('Wood', group.material.name)
  end
  # rubocop:enable Metrics/MethodLength

  def test_build_terrain_anchored_structure_uses_centroid_sampled_planar_base
    host_target = Object.new
    anchor_resolver = FakeTerrainAnchorResolver.new(sample_z: 8.5)
    builder = SU_MCP::Semantic::StructureBuilder.new(terrain_anchor_resolver: anchor_resolver)

    group = builder.build(model: @model, params: terrain_anchored_structure_params(host_target))

    assert_equal([{ host_target: host_target, anchor_xy: [2.0, 1.0], role: 'structure_centroid' }],
                 anchor_resolver.calls)
    assert_equal([8.5], group.entities.faces.first.points.map { |point| point[2] }.uniq)
    assert_equal([2.4], group.entities.faces.first.pushpull_calls)
  end

  def test_build_terrain_anchored_structure_refusal_creates_no_wrapper_group
    parent_group = @model.active_entities.add_group
    refusal = SU_MCP::Semantic::BuilderRefusal.new(
      code: 'invalid_hosting_target',
      message: 'Hosting target is not sampleable.',
      details: { section: 'hosting', role: 'structure_centroid' }
    )
    builder = SU_MCP::Semantic::StructureBuilder.new(
      terrain_anchor_resolver: FakeTerrainAnchorResolver.new(refusal: refusal)
    )

    assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      builder.build(
        model: @model,
        destination: parent_group.entities,
        params: terrain_anchored_structure_params(Object.new)
      )
    end

    assert_equal(1, @model.active_entities.groups.length)
    assert_empty(parent_group.entities.groups)
  end

  private

  def terrain_anchored_structure_params(host_target)
    {
      'elementType' => 'structure',
      'definition' => {
        'mode' => 'footprint_mass',
        'footprint' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
        'elevation' => 99.0,
        'height' => 2.4,
        'structureCategory' => 'outbuilding'
      },
      'hosting' => {
        'mode' => 'terrain_anchored',
        'resolved_target' => host_target
      }
    }
  end
end
