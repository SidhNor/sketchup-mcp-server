# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/scene_query_test_support'
require_relative '../src/su_mcp/scene_query_commands'

class SampleSurfaceZSceneQueryCommandsTest < Minitest::Test
  include SceneQueryTestSupport

  def setup
    @commands = SU_MCP::SceneQueryCommands.new
    Sketchup.active_model_override = build_sample_surface_z_model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_requires_a_target_reference_with_at_least_one_identifier
    error = assert_raises(RuntimeError) do
      @commands.sample_surface_z('samplePoints' => [{ 'x' => 1.0, 'y' => 1.0 }])
    end

    assert_equal('Target reference with at least one identifier is required', error.message)
  end

  def test_requires_at_least_one_sample_point
    error = assert_raises(RuntimeError) do
      @commands.sample_surface_z('target' => { 'persistentId' => '4001' }, 'samplePoints' => [])
    end

    assert_equal('At least one sample point is required', error.message)
  end

  def test_returns_hit_for_a_supported_face_target
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'samplePoints' => [{ 'x' => 5.0, 'y' => 5.0 }]
    )

    assert_equal(
      {
        success: true,
        results: [
          {
            samplePoint: { x: 5.0, y: 5.0 },
            status: 'hit',
            hitPoint: { x: 5.0, y: 5.0, z: 2.5 }
          }
        ]
      },
      result
    )
  end

  def test_returns_hit_for_a_supported_group_target
    result = @commands.sample_surface_z(
      'target' => { 'sourceElementId' => 'surface-group-001' },
      'samplePoints' => [{ 'x' => 25.0, 'y' => 5.0 }]
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal(3.5, result.dig(:results, 0, :hitPoint, :z))
  end

  def test_returns_hit_for_a_supported_component_target
    result = @commands.sample_surface_z(
      'target' => { 'entityId' => '403' },
      'samplePoints' => [{ 'x' => 45.0, 'y' => 5.0 }]
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal(4.25, result.dig(:results, 0, :hitPoint, :z))
  end

  def test_applies_group_and_component_transformations_when_sampling_nested_faces
    group_result = @commands.sample_surface_z(
      'target' => { 'sourceElementId' => 'surface-group-001' },
      'samplePoints' => [{ 'x' => 25.0, 'y' => 5.0 }]
    )
    component_result = @commands.sample_surface_z(
      'target' => { 'sourceElementId' => 'surface-component-001' },
      'samplePoints' => [{ 'x' => 45.0, 'y' => 5.0 }]
    )

    assert_equal(3.5, group_result.dig(:results, 0, :hitPoint, :z))
    assert_equal(4.25, component_result.dig(:results, 0, :hitPoint, :z))
  end

  def test_returns_miss_for_points_outside_the_resolved_target_geometry
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'samplePoints' => [{ 'x' => 15.0, 'y' => 15.0 }]
    )

    assert_equal(
      [{ samplePoint: { x: 15.0, y: 15.0 }, status: 'miss' }],
      result[:results]
    )
  end

  def test_returns_ambiguous_when_multiple_distinct_z_clusters_survive
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4004' },
      'samplePoints' => [{ 'x' => 65.0, 'y' => 5.0 }]
    )

    assert_equal('ambiguous', result.dig(:results, 0, :status))
    refute(result.dig(:results, 0).key?(:hitPoint))
  end

  def test_clusters_near_equal_candidate_z_values_into_a_single_hit
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4005' },
      'samplePoints' => [{ 'x' => 85.0, 'y' => 5.0 }]
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_in_delta(8.0, result.dig(:results, 0, :hitPoint, :z), 0.001)
  end

  def test_preserves_input_point_order_for_mixed_results
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'samplePoints' => [
        { 'x' => 5.0, 'y' => 5.0 },
        { 'x' => 15.0, 'y' => 15.0 }
      ]
    )

    assert_equal(
      [
        { samplePoint: { x: 5.0, y: 5.0 }, status: 'hit', hitPoint: { x: 5.0, y: 5.0, z: 2.5 } },
        { samplePoint: { x: 15.0, y: 15.0 }, status: 'miss' }
      ],
      result[:results]
    )
  end

  def test_uses_visible_only_default_and_treats_a_visible_occluder_as_interference
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4006' },
      'samplePoints' => [{ 'x' => 105.0, 'y' => 5.0 }]
    )

    assert_equal('miss', result.dig(:results, 0, :status))
  end

  def test_ignore_targets_can_exclude_visible_occluding_geometry
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4006' },
      'ignoreTargets' => [{ 'persistentId' => '4007' }],
      'samplePoints' => [{ 'x' => 105.0, 'y' => 5.0 }]
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal(1.5, result.dig(:results, 0, :hitPoint, :z))
  end

  def test_rejects_unsupported_target_types
    error = assert_raises(RuntimeError) do
      @commands.sample_surface_z(
        'target' => { 'persistentId' => '4009' },
        'samplePoints' => [{ 'x' => 125.0, 'y' => 0.0 }]
      )
    end

    assert_equal('Target type edge is not supported by sample_surface_z', error.message)
  end

  def test_rejects_targets_without_sampleable_faces
    error = assert_raises(RuntimeError) do
      @commands.sample_surface_z(
        'target' => { 'persistentId' => '4008' },
        'samplePoints' => [{ 'x' => 0.0, 'y' => 0.0 }]
      )
    end

    assert_equal('Target resolves to no sampleable face geometry', error.message)
  end

  def test_serializes_hit_points_in_world_space_meters
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4003' },
      'samplePoints' => [{ 'x' => 45.25, 'y' => 5.75 }]
    )

    hit_point = result.dig(:results, 0, :hitPoint)

    assert_instance_of(Float, hit_point[:x])
    assert_instance_of(Float, hit_point[:y])
    assert_instance_of(Float, hit_point[:z])
    assert_equal({ x: 45.25, y: 5.75, z: 4.25 }, hit_point)
  end

  def test_samples_sloped_faces_using_the_intersection_z_not_the_face_bounds_center
    result = @commands.sample_surface_z(
      'target' => { 'sourceElementId' => 'surface-sloped-001' },
      'samplePoints' => [{ 'x' => 144.0, 'y' => 5.0 }]
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal(3.0, result.dig(:results, 0, :hitPoint, :z))
  end
end
