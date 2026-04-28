# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/sample_surface_evidence'
require_relative '../../src/su_mcp/scene_validation/measurement_service'

class MeasurementServiceTest < Minitest::Test
  include SceneQueryTestSupport

  INCHES_PER_METER = 39.37007874015748

  PointLike = Struct.new(:x, :y, :z)

  def setup
    @service = SU_MCP::MeasurementService.new
  end

  def test_measures_world_bounds_in_public_meters
    entity = measurement_group(
      source_element_id: 'bounds-target',
      bounds: custom_bounds(
        min: [0.0, 0.0, 0.0],
        max: [2 * INCHES_PER_METER, 3 * INCHES_PER_METER, 4 * INCHES_PER_METER]
      )
    )

    result = @service.measure(mode: 'bounds', kind: 'world_bounds', target: entity)

    assert_equal('measured', result.fetch(:outcome))
    assert_equal('m', result.dig(:measurement, :unit))
    assert_in_delta(2.0, result.dig(:measurement, :value, :size).fetch(:x), 0.0001)
    assert_in_delta(3.0, result.dig(:measurement, :value, :size).fetch(:y), 0.0001)
    assert_in_delta(4.0, result.dig(:measurement, :value, :size).fetch(:z), 0.0001)
  end

  def test_measures_height_as_z_bounds_extent_in_meters
    entity = measurement_group(
      source_element_id: 'height-target',
      bounds: custom_bounds(
        min: [0.0, 0.0, 10 * INCHES_PER_METER],
        max: [1.0, 2.0, 15.5 * INCHES_PER_METER]
      )
    )

    result = @service.measure(mode: 'height', kind: 'bounds_z', target: entity)

    assert_equal('measured', result.fetch(:outcome))
    assert_equal('m', result.dig(:measurement, :unit))
    assert_in_delta(5.5, result.dig(:measurement, :value), 0.0001)
  end

  def test_measures_distance_between_world_bounds_centers
    from = measurement_group(
      source_element_id: 'from-target',
      bounds: point_bounds([0.0, 0.0, 0.0])
    )
    to = measurement_group(
      source_element_id: 'to-target',
      bounds: point_bounds([3 * INCHES_PER_METER, 4 * INCHES_PER_METER, 0.0])
    )

    result = @service.measure(
      mode: 'distance',
      kind: 'bounds_center_to_bounds_center',
      from: from,
      to: to
    )

    assert_equal('measured', result.fetch(:outcome))
    assert_equal('m', result.dig(:measurement, :unit))
    assert_in_delta(5.0, result.dig(:measurement, :value), 0.0001)
  end

  def test_measures_distance_without_vector_magnitude_api
    from = measurement_group(
      source_element_id: 'from-target',
      bounds: point_like_bounds([0.0, 0.0, 0.0])
    )
    to = measurement_group(
      source_element_id: 'to-target',
      bounds: point_like_bounds([0.0, 0.0, 2 * INCHES_PER_METER])
    )

    result = @service.measure(
      mode: 'distance',
      kind: 'bounds_center_to_bounds_center',
      from: from,
      to: to
    )

    assert_equal('measured', result.fetch(:outcome))
    assert_in_delta(2.0, result.dig(:measurement, :value), 0.0001)
  end

  def test_measures_horizontal_bounds_area_in_square_meters
    entity = measurement_group(
      source_element_id: 'area-target',
      bounds: custom_bounds(
        min: [0.0, 0.0, 0.0],
        max: [2 * INCHES_PER_METER, 3 * INCHES_PER_METER, 1.0]
      )
    )

    result = @service.measure(mode: 'area', kind: 'horizontal_bounds', target: entity)

    assert_equal('measured', result.fetch(:outcome))
    assert_equal('m2', result.dig(:measurement, :unit))
    assert_in_delta(6.0, result.dig(:measurement, :value), 0.0001)
  end

  def test_measures_surface_area_for_nested_faces_with_transform
    entity = transformed_surface_group

    result = @service.measure(mode: 'area', kind: 'surface', target: entity)

    assert_equal('measured', result.fetch(:outcome))
    assert_equal('m2', result.dig(:measurement, :unit))
    assert_in_delta(24.0, result.dig(:measurement, :value), 0.0001)
    assert_equal(1, result.dig(:measurement, :evidence, :faceCount))
  end

  def test_returns_unavailable_when_surface_area_has_no_faces
    entity = measurement_group(source_element_id: 'empty-target')

    result = @service.measure(mode: 'area', kind: 'surface', target: entity)

    assert_equal('unavailable', result.fetch(:outcome))
    assert_equal('no_faces', result.dig(:measurement, :reason))
  end

  def test_returns_unavailable_for_invalid_bounds
    entity = measurement_group(source_element_id: 'invalid-bounds', bounds: invalid_bounds)

    result = @service.measure(mode: 'height', kind: 'bounds_z', target: entity)

    assert_equal('unavailable', result.fetch(:outcome))
    assert_equal('invalid_bounds', result.dig(:measurement, :reason))
  end

  def test_dispatches_terrain_profile_elevation_summary_to_profile_reducer
    samples = [
      SU_MCP::SampleSurfaceEvidence::Sample.new(
        index: 0,
        x: 0.0,
        y: 0.0,
        z: 1.0,
        distance_along_path_meters: 0.0,
        path_progress: 0.0,
        status: 'hit'
      ),
      SU_MCP::SampleSurfaceEvidence::Sample.new(
        index: 1,
        x: 5.0,
        y: 0.0,
        z: 2.0,
        distance_along_path_meters: 5.0,
        path_progress: 1.0,
        status: 'hit'
      )
    ]

    result = @service.measure(
      mode: 'terrain_profile',
      kind: 'elevation_summary',
      profile_samples: samples
    )

    assert_equal('measured', result.fetch(:outcome))
    assert_equal('terrain_profile', result.dig(:measurement, :mode))
    assert_equal('elevation_summary', result.dig(:measurement, :kind))
    assert_equal(1.0, result.dig(:measurement, :value, :minElevation))
    assert_equal(2.0, result.dig(:measurement, :value, :maxElevation))
  end

  private

  def measurement_group(source_element_id:, bounds: custom_bounds, entities: [])
    build_scene_query_group(
      entity_id: 901,
      origin_x: 0,
      layer: FakeLayer.new('Layer0'),
      material: FakeMaterial.new('Concrete'),
      details: {
        persistent_id: 9001,
        name: source_element_id,
        entities: entities,
        attributes: { 'su_mcp' => { 'sourceElementId' => source_element_id } }
      }
    ).tap do |group|
      group.instance_variable_set(:@bounds, bounds)
    end
  end

  def custom_bounds(min: [0.0, 0.0, 0.0], max: [1.0, 2.0, 3.0])
    min_point = FakePoint.new(*min)
    max_point = FakePoint.new(*max)
    FakeBounds.new(
      min: min_point,
      max: max_point,
      center: center_point(min, max),
      size: [max[0] - min[0], max[1] - min[1], max[2] - min[2]]
    )
  end

  def center_point(min, max)
    FakePoint.new(
      (min[0] + max[0]) / 2.0,
      (min[1] + max[1]) / 2.0,
      (min[2] + max[2]) / 2.0
    )
  end

  def point_bounds(point)
    custom_bounds(min: point, max: point)
  end

  def point_like_bounds(point)
    center = PointLike.new(*point)
    FakeBounds.new(
      min: center,
      max: center,
      center: center,
      size: [0.0, 0.0, 0.0]
    )
  end

  def transformed_surface_group
    layer = FakeLayer.new('Terrain')
    material = FakeMaterial.new('Soil')
    build_sample_surface_group(
      entity_id: 502,
      persistent_id: 5002,
      source_element_id: 'surface-target',
      name: 'Surface Target',
      layer: layer,
      material: material,
      child_faces: [surface_face(layer, material)],
      transformation: FakeTransformation.new(FakePoint.new(0.0, 0.0, 0.0), scale: 2.0)
    )
  end

  def surface_face(layer, material)
    build_sample_surface_face(
      entity_id: 501,
      persistent_id: 5001,
      name: 'Nested Face',
      layer: layer,
      material: material,
      x_range: [0.0, 2 * INCHES_PER_METER],
      y_range: [0.0, 3 * INCHES_PER_METER],
      z_value: 0.0
    )
  end

  def invalid_bounds
    Object.new.tap do |bounds|
      def bounds.valid?
        false
      end
    end
  end
end
