# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/scene_query_commands'

# rubocop:disable Metrics/ClassLength
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
    result = @commands.sample_surface_z(points_request(points: [{ 'x' => 1.0, 'y' => 1.0 }]))

    assert_refusal(result, 'missing_required_field')
    assert_equal('target', result.dig(:refusal, :details, :field))
  end

  def test_requires_sampling_object
    result = @commands.sample_surface_z('target' => { 'persistentId' => '4001' })

    assert_refusal(result, 'missing_required_field')
    assert_equal('sampling', result.dig(:refusal, :details, :field))
  end

  def test_refuses_unresolved_target_host
    result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'missing-surface' },
        points: [{ 'x' => 1.0, 'y' => 1.0 }]
      )
    )

    assert_refusal(result, 'target_resolution_failed')
    assert_equal('target', result.dig(:refusal, :details, :field))
    assert_equal('none', result.dig(:refusal, :details, :resolution))
  end

  def test_refuses_unsupported_target_host_type
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4009' },
        points: [{ 'x' => 125.0, 'y' => 0.0 }]
      )
    )

    assert_refusal(result, 'unsupported_target_type')
    assert_equal('target', result.dig(:refusal, :details, :field))
    assert_equal('edge', result.dig(:refusal, :details, :targetType))
  end

  def test_refuses_target_host_without_sampleable_faces
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4008' },
        points: [{ 'x' => 1.0, 'y' => 1.0 }]
      )
    )

    assert_refusal(result, 'target_not_sampleable')
    assert_equal('target', result.dig(:refusal, :details, :field))
  end

  def test_refuses_unsupported_sampling_type_with_allowed_values
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => { 'type' => 'grid', 'points' => [{ 'x' => 1.0, 'y' => 1.0 }] }
    )

    assert_refusal(result, 'unsupported_option')
    assert_equal('sampling.type', result.dig(:refusal, :details, :field))
    assert_equal('grid', result.dig(:refusal, :details, :value))
    assert_equal(%w[points profile], result.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_points_sampling_without_points
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => { 'type' => 'points', 'points' => [] }
    )

    assert_refusal(result, 'missing_required_field')
    assert_equal('sampling.points', result.dig(:refusal, :details, :field))
  end

  def test_refuses_points_sampling_with_profile_only_fields
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => {
        'type' => 'points',
        'points' => [{ 'x' => 5.0, 'y' => 5.0 }],
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 1.0, 'y' => 0.0 }]
      }
    )

    assert_refusal(result, 'unsupported_request_field')
    assert_equal('sampling.path', result.dig(:refusal, :details, :field))
  end

  def test_refuses_profile_sampling_without_path
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => { 'type' => 'profile', 'sampleCount' => 3 }
    )

    assert_refusal(result, 'missing_required_field')
    assert_equal('sampling.path', result.dig(:refusal, :details, :field))
  end

  def test_refuses_profile_sampling_with_points
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => {
        'type' => 'profile',
        'points' => [{ 'x' => 5.0, 'y' => 5.0 }],
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 1.0, 'y' => 0.0 }],
        'sampleCount' => 2
      }
    )

    assert_refusal(result, 'unsupported_request_field')
    assert_equal('sampling.points', result.dig(:refusal, :details, :field))
  end

  def test_refuses_profile_sampling_with_neither_spacing_strategy
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 1.0, 'y' => 0.0 }]
      }
    )

    assert_refusal(result, 'missing_required_field')
    assert_equal(
      'sampling.sampleCount|sampling.intervalMeters',
      result.dig(:refusal, :details, :field)
    )
  end

  def test_refuses_profile_sampling_with_both_spacing_strategies
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 1.0, 'y' => 0.0 }],
        'sampleCount' => 2,
        'intervalMeters' => 0.5
      }
    )

    assert_refusal(result, 'mutually_exclusive_fields')
    assert_equal(%w[sampling.sampleCount sampling.intervalMeters],
                 result.dig(:refusal, :details, :fields))
  end

  def test_refuses_profile_path_with_fewer_than_two_distinct_points
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 1.0, 'y' => 1.0 }, { 'x' => 1.0, 'y' => 1.0 }],
        'sampleCount' => 2
      }
    )

    assert_refusal(result, 'invalid_geometry')
    assert_equal('sampling.path', result.dig(:refusal, :details, :field))
  end

  def test_refuses_profile_sampling_above_generated_sample_cap_with_counts
    result = @commands.sample_surface_z(
      'target' => { 'persistentId' => '4001' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 10.0, 'y' => 0.0 }],
        'sampleCount' => 201
      }
    )

    assert_refusal(result, 'sample_cap_exceeded')
    assert_equal(201, result.dig(:refusal, :details, :generatedCount))
    assert_equal(200, result.dig(:refusal, :details, :allowedCap))
  end

  def test_returns_hit_for_a_supported_face_target_using_canonical_points_shape
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4001' },
        points: [{ 'x' => 5.0, 'y' => 5.0 }]
      )
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

  def test_returns_hit_for_supported_group_and_component_targets
    group_result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-group-001' },
        points: [{ 'x' => 25.0, 'y' => 5.0 }]
      )
    )
    component_result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-component-001' },
        points: [{ 'x' => 45.0, 'y' => 5.0 }]
      )
    )

    assert_equal('hit', group_result.dig(:results, 0, :status))
    assert_equal(3.5, group_result.dig(:results, 0, :hitPoint, :z))
    assert_equal('hit', component_result.dig(:results, 0, :status))
    assert_equal(4.25, component_result.dig(:results, 0, :hitPoint, :z))
  end

  def test_returns_miss_for_points_outside_the_resolved_target_geometry
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4001' },
        points: [{ 'x' => 15.0, 'y' => 15.0 }]
      )
    )

    assert_equal(
      [{ samplePoint: { x: 15.0, y: 15.0 }, status: 'miss' }],
      result[:results]
    )
  end

  def test_returns_ambiguous_without_hit_point_when_multiple_distinct_z_clusters_survive
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4004' },
        points: [{ 'x' => 65.0, 'y' => 5.0 }]
      )
    )

    assert_equal('ambiguous', result.dig(:results, 0, :status))
    refute(result.dig(:results, 0).key?(:hitPoint))
  end

  def test_preserves_input_point_order_for_mixed_results
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4001' },
        points: [
          { 'x' => 5.0, 'y' => 5.0 },
          { 'x' => 15.0, 'y' => 15.0 }
        ]
      )
    )

    assert_equal(
      [
        { samplePoint: { x: 5.0, y: 5.0 }, status: 'hit', hitPoint: { x: 5.0, y: 5.0, z: 2.5 } },
        { samplePoint: { x: 15.0, y: 15.0 }, status: 'miss' }
      ],
      result[:results]
    )
  end

  def test_ignore_targets_can_exclude_visible_occluding_geometry
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4006' },
        points: [{ 'x' => 105.0, 'y' => 5.0 }],
        extra: { 'ignoreTargets' => [{ 'persistentId' => '4007' }] }
      )
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal(1.5, result.dig(:results, 0, :hitPoint, :z))
  end

  def test_refuses_unresolved_ignore_targets_without_internal_errors
    result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4006' },
        points: [{ 'x' => 105.0, 'y' => 5.0 }],
        extra: { 'ignoreTargets' => [{ 'sourceElementId' => 'missing-ignore' }] }
      )
    )

    assert_refusal(result, 'ignore_target_resolution_failed')
    assert_equal('ignoreTargets', result.dig(:refusal, :details, :field))
    assert_equal('none', result.dig(:refusal, :details, :resolution))
  end

  def test_resolves_nested_targets_by_source_element_id
    result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-nested-face-001' },
        points: [{ 'x' => 165.0, 'y' => 5.0 }]
      )
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal(6.0, result.dig(:results, 0, :hitPoint, :z))
  end

  def test_visible_only_filters_targets_on_hidden_layers
    visible_result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4011' },
        points: [{ 'x' => 185.0, 'y' => 5.0 }]
      )
    )
    hidden_result = @commands.sample_surface_z(
      points_request(
        target: { 'persistentId' => '4011' },
        points: [{ 'x' => 185.0, 'y' => 5.0 }],
        extra: { 'visibleOnly' => false }
      )
    )

    assert_refusal(visible_result, 'target_not_sampleable')
    assert_equal('hit', hidden_result.dig(:results, 0, :status))
    assert_equal(12.0, hidden_result.dig(:results, 0, :hitPoint, :z))
  end

  def test_visible_only_filters_nested_targets_inside_hidden_parent_containers
    visible_result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-hidden-parent-face-001' },
        points: [{ 'x' => 205.0, 'y' => 5.0 }]
      )
    )
    hidden_result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-hidden-parent-face-001' },
        points: [{ 'x' => 205.0, 'y' => 5.0 }],
        extra: { 'visibleOnly' => false }
      )
    )

    assert_refusal(visible_result, 'target_not_sampleable')
    assert_equal('hit', hidden_result.dig(:results, 0, :status))
    assert_equal(13.0, hidden_result.dig(:results, 0, :hitPoint, :z))
  end

  def test_ignore_targets_filter_nested_descendants_inside_the_sampled_target
    ambiguous_result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-combined-target-001' },
        points: [{ 'x' => 225.0, 'y' => 5.0 }],
        extra: { 'visibleOnly' => false }
      )
    )
    ignored_result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-combined-target-001' },
        points: [{ 'x' => 225.0, 'y' => 5.0 }],
        extra: {
          'visibleOnly' => false,
          'ignoreTargets' => [{ 'sourceElementId' => 'surface-combined-occluder-001' }]
        }
      )
    )

    assert_equal('ambiguous', ambiguous_result.dig(:results, 0, :status))
    assert_equal('hit', ignored_result.dig(:results, 0, :status))
    assert_equal(1.4, ignored_result.dig(:results, 0, :hitPoint, :z))
  end

  def test_samples_sloped_faces_using_the_intersection_z_not_the_face_bounds_center
    result = @commands.sample_surface_z(
      points_request(
        target: { 'sourceElementId' => 'surface-sloped-001' },
        points: [{ 'x' => 144.0, 'y' => 5.0 }]
      )
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal(3.0, result.dig(:results, 0, :hitPoint, :z))
  end

  # rubocop:disable Metrics/MethodLength
  def test_returns_ordered_profile_results_with_distance_progress_and_summary
    result = @commands.sample_surface_z(
      profile_request(
        target: { 'persistentId' => '4001' },
        path: [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 10.0, 'y' => 0.0 }],
        sample_count: 3
      )
    )

    assert_equal(true, result[:success])
    assert_equal(
      [
        {
          index: 0,
          samplePoint: { x: 0.0, y: 0.0 },
          distanceAlongPathMeters: 0.0,
          pathProgress: 0.0,
          status: 'hit',
          hitPoint: { x: 0.0, y: 0.0, z: 2.5 }
        },
        {
          index: 1,
          samplePoint: { x: 5.0, y: 0.0 },
          distanceAlongPathMeters: 5.0,
          pathProgress: 0.5,
          status: 'hit',
          hitPoint: { x: 5.0, y: 0.0, z: 2.5 }
        },
        {
          index: 2,
          samplePoint: { x: 10.0, y: 0.0 },
          distanceAlongPathMeters: 10.0,
          pathProgress: 1.0,
          status: 'hit',
          hitPoint: { x: 10.0, y: 0.0, z: 2.5 }
        }
      ],
      result[:results]
    )
    assert_equal(
      {
        totalSamples: 3,
        hitCount: 3,
        missCount: 0,
        ambiguousCount: 0,
        sampledLengthMeters: 10.0,
        minZ: 2.5,
        maxZ: 2.5
      },
      result[:summary]
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_profile_non_hits_do_not_fabricate_hit_points
    result = @commands.sample_surface_z(
      profile_request(
        target: { 'persistentId' => '4001' },
        path: [{ 'x' => 5.0, 'y' => 5.0 }, { 'x' => 15.0, 'y' => 15.0 }],
        sample_count: 2
      )
    )

    assert_equal('hit', result.dig(:results, 0, :status))
    assert_equal('miss', result.dig(:results, 1, :status))
    refute(result.dig(:results, 1).key?(:hitPoint))
    assert_equal(1, result.dig(:summary, :hitCount))
    assert_equal(1, result.dig(:summary, :missCount))
  end

  private

  def points_request(points:, target: nil, extra: {})
    request = {
      'sampling' => {
        'type' => 'points',
        'points' => points
      }
    }
    request['target'] = target if target
    request.merge(extra)
  end

  def profile_request(target:, path:, sample_count: nil, interval_meters: nil, extra: {})
    sampling = {
      'type' => 'profile',
      'path' => path
    }
    sampling['sampleCount'] = sample_count unless sample_count.nil?
    sampling['intervalMeters'] = interval_meters unless interval_meters.nil?
    {
      'target' => target,
      'sampling' => sampling
    }.merge(extra)
  end

  def assert_refusal(result, code)
    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal(code, result.dig(:refusal, :code))
  end
end
# rubocop:enable Metrics/ClassLength
