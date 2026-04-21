# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/semantic/path_builder'

class PathBuilderTest < Minitest::Test
  include SemanticTestSupport
  include SceneQueryTestSupport

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

  def test_build_consumes_sectioned_path_definition_and_scene_properties
    group = @builder.build(
      model: @model,
      params: {
        'elementType' => 'path',
        'definition' => {
          'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
          'width' => 1.6,
          'elevation' => 0.0,
          'thickness' => 0.1
        },
        'sceneProperties' => {
          'name' => 'Sectioned Walk',
          'tag' => 'Paths'
        },
        'representation' => {
          'material' => 'Gravel'
        }
      }
    )

    assert_instance_of(SemanticTestSupport::FakeGroup, group)
    assert_equal(1, group.entities.faces.length)
    assert_equal([-0.1], group.entities.faces.first.pushpull_calls)
    assert_equal('Sectioned Walk', group.name)
    assert_equal('Paths', group.layer.name)
    assert_equal('Gravel', group.material.name)
  end

  def test_build_creates_path_into_supplied_destination_collection
    parent_group = @model.active_entities.add_group

    group = @builder.build(
      model: @model,
      destination: parent_group.entities,
      params: {
        'elementType' => 'path',
        'definition' => {
          'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
          'width' => 1.6,
          'thickness' => 0.1
        }
      }
    )

    assert_same(group, parent_group.entities.groups.last)
    assert_equal(1, @model.active_entities.groups.length)
  end

  def test_build_surface_drape_path_follows_terrain_along_length_with_horizontal_sections
    terrain_target = build_sample_surface_face(
      entity_id: 401,
      persistent_id: 4001,
      name: 'Sloped Terrain',
      layer: SceneQueryTestSupport::FakeLayer.new('Terrain'),
      material: SceneQueryTestSupport::FakeMaterial.new('Soil'),
      x_range: [0.0, 10.0],
      y_range: [-2.0, 2.0],
      z_value: 1.0,
      slope_x: 0.5
    )
    builder = SU_MCP::Semantic::PathBuilder.new(
      drape_builder: SU_MCP::Semantic::PathDrapeBuilder.new(
        station_spacing: 100.0,
        clearance: 0.2,
        cross_slope_sample_fractions: [-0.5, 0.0, 0.5]
      )
    )

    group = builder.build(
      model: @model,
      params: {
        'elementType' => 'path',
        'definition' => {
          'centerline' => [[0.0, 0.0], [10.0, 0.0]],
          'width' => 2.0
        },
        'hosting' => {
          'mode' => 'surface_drape',
          'resolved_target' => terrain_target
        }
      }
    )

    face_points = group.entities.faces.flat_map(&:points).uniq

    assert_equal(2, group.entities.faces.length)
    assert_includes(face_points, [0.0, 1.0, 1.2])
    assert_includes(face_points, [0.0, -1.0, 1.2])
    assert_includes(face_points, [10.0, 1.0, 6.2])
    assert_includes(face_points, [10.0, -1.0, 6.2])
  end

  def test_build_surface_drape_path_raises_cross_section_to_clear_highest_sample
    terrain_target = build_sample_surface_face(
      entity_id: 402,
      persistent_id: 4002,
      name: 'Cross Sloped Terrain',
      layer: SceneQueryTestSupport::FakeLayer.new('Terrain'),
      material: SceneQueryTestSupport::FakeMaterial.new('Soil'),
      x_range: [0.0, 10.0],
      y_range: [-2.0, 2.0],
      z_value: 1.0,
      slope_y: 0.5
    )
    builder = SU_MCP::Semantic::PathBuilder.new(
      drape_builder: SU_MCP::Semantic::PathDrapeBuilder.new(
        station_spacing: 100.0,
        clearance: 0.2,
        cross_slope_sample_fractions: [-0.5, 0.0, 0.5]
      )
    )

    group = builder.build(
      model: @model,
      params: {
        'elementType' => 'path',
        'definition' => {
          'centerline' => [[0.0, 0.0], [10.0, 0.0]],
          'width' => 2.0
        },
        'hosting' => {
          'mode' => 'surface_drape',
          'resolved_target' => terrain_target
        }
      }
    )

    face_points = group.entities.faces.flat_map(&:points).uniq

    assert_includes(face_points, [0.0, 1.0, 2.7])
    assert_includes(face_points, [0.0, -1.0, 2.7])
    assert_includes(face_points, [10.0, 1.0, 2.7])
    assert_includes(face_points, [10.0, -1.0, 2.7])
  end

  def test_build_surface_drape_path_refuses_when_any_station_cannot_sample_terrain
    terrain_target = build_sample_surface_face(
      entity_id: 403,
      persistent_id: 4003,
      name: 'Short Terrain Patch',
      layer: SceneQueryTestSupport::FakeLayer.new('Terrain'),
      material: SceneQueryTestSupport::FakeMaterial.new('Soil'),
      x_range: [0.0, 4.0],
      y_range: [-1.0, 1.0],
      z_value: 1.0
    )

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      @builder.build(
        model: @model,
        params: {
          'elementType' => 'path',
          'definition' => {
            'centerline' => [[0.0, 0.0], [10.0, 0.0]],
            'width' => 2.0
          },
          'hosting' => {
            'mode' => 'surface_drape',
            'resolved_target' => terrain_target
          }
        }
      )
    end

    assert_equal('terrain_sample_miss', error.code)
    assert_equal('hosting', error.details[:section])
  end
end
# rubocop:enable Metrics/MethodLength
