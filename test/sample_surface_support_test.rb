# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/scene_query_test_support'
require_relative '../src/su_mcp/sample_surface_support'

class SampleSurfaceSupportTest < Minitest::Test
  include SceneQueryTestSupport

  class FakeSerializer
    def entity_type_key(entity)
      case entity
      when Sketchup::Group
        'group'
      when Sketchup::ComponentInstance
        'componentinstance'
      when Sketchup::Face
        'face'
      when Sketchup::Edge
        'edge'
      else
        entity.class.name.split('::').last.downcase
      end
    end
  end

  def setup
    @serializer = FakeSerializer.new
    @support = SU_MCP::SampleSurfaceSupport.new(serializer: @serializer)
    @model = build_sample_surface_z_model
  end

  def test_collects_sampleable_faces_for_groups_and_components
    group_target = @model.entities.find { |entity| entity.entityID == 402 }
    component_target = @model.entities.find { |entity| entity.entityID == 403 }

    group_faces = @support.sampleable_faces_for(
      group_target,
      visible_only: true,
      transform_chain: []
    )
    component_faces = @support.sampleable_faces_for(
      component_target,
      visible_only: true,
      transform_chain: []
    )

    assert_equal(1, group_faces.length)
    assert_equal(1, component_faces.length)
  end

  def test_ignores_hidden_entities_when_visible_only_is_true
    hidden_group = hidden_group_target

    faces = @support.sampleable_faces_for(hidden_group, visible_only: true, transform_chain: [])

    assert_equal([], faces)
  end

  def test_clusters_near_equal_hits_using_the_tolerance
    hits = [{ z: 8.0 }, { z: 8.0004 }, { z: 9.5 }]

    clusters = @support.cluster_hits(hits)

    assert_equal(2, clusters.length)
    assert_equal([8.0, 8.0004], clusters.first.map { |hit| hit[:z] })
  end

  def test_excludes_target_and_ignored_entities_from_blocking_face_collection
    target_entity = @model.entities.find { |entity| entity.entityID == 406 }
    ignored_entity = @model.entities.find { |entity| entity.entityID == 407 }

    blocking_faces = @support.blocking_faces_for(
      @model.entities,
      target_entity: target_entity,
      ignore_entities: [ignored_entity]
    )

    refute(blocking_faces.any? { |entry| entry[:face].entityID == 406 })
    refute(blocking_faces.any? { |entry| entry[:face].entityID == 407 })
  end

  private

  def hidden_group_target
    build_sample_surface_group(
      entity_id: 499,
      persistent_id: 4999,
      source_element_id: 'surface-hidden-001',
      name: 'Hidden Group',
      layer: FakeLayer.new('Terrain'),
      material: FakeMaterial.new('Soil'),
      child_faces: [hidden_face]
    )
  end

  def hidden_face
    build_sample_surface_face(
      entity_id: 498,
      persistent_id: 4998,
      name: 'Hidden Face',
      layer: FakeLayer.new('Terrain'),
      material: FakeMaterial.new('Soil'),
      x_range: [0.0, 1.0],
      y_range: [0.0, 1.0],
      z_value: 2.0,
      hidden: true
    )
  end
end
