# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/scene_validation/measure_scene_request'

class MeasureSceneRequestTest < Minitest::Test
  def test_refuses_unsupported_mode_with_allowed_values
    refusal = request_refusal(
      'mode' => 'clearance',
      'kind' => 'nearest',
      'target' => { 'entityId' => '101' }
    )

    assert_refusal(refusal, 'unsupported_mode')
    assert_equal('mode', refusal.dig(:refusal, :details, :field))
    assert_equal('clearance', refusal.dig(:refusal, :details, :value))
    assert_equal(%w[bounds height distance area terrain_profile],
                 refusal.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_unsupported_kind_with_allowed_values_for_mode
    refusal = request_refusal(
      'mode' => 'area',
      'kind' => 'footprint',
      'target' => { 'entityId' => '101' }
    )

    assert_refusal(refusal, 'unsupported_kind')
    assert_equal('kind', refusal.dig(:refusal, :details, :field))
    assert_equal(%w[surface horizontal_bounds], refusal.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_illegal_mode_kind_combination
    refusal = request_refusal(
      'mode' => 'height',
      'kind' => 'surface',
      'target' => { 'entityId' => '101' }
    )

    assert_refusal(refusal, 'unsupported_kind')
    assert_equal('height', refusal.dig(:refusal, :details, :mode))
    assert_equal('surface', refusal.dig(:refusal, :details, :value))
  end

  def test_refuses_missing_target_for_target_based_mode
    refusal = request_refusal(
      'mode' => 'height',
      'kind' => 'bounds_z'
    )

    assert_refusal(refusal, 'missing_required_field')
    assert_equal('target', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_missing_from_for_distance_mode
    refusal = request_refusal(
      'mode' => 'distance',
      'kind' => 'bounds_center_to_bounds_center',
      'to' => { 'entityId' => '101' }
    )

    assert_refusal(refusal, 'missing_required_field')
    assert_equal('from', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_selector_shaped_reference
    refusal = request_refusal(
      'mode' => 'height',
      'kind' => 'bounds_z',
      'target' => { 'targetSelector' => { 'identity' => { 'entityId' => '101' } } }
    )

    assert_refusal(refusal, 'unsupported_reference_field')
    assert_equal('target.targetSelector', refusal.dig(:refusal, :details, :field))
  end

  def test_accepts_terrain_profile_elevation_summary_with_profile_sampling
    refusal = request_refusal(
      'mode' => 'terrain_profile',
      'kind' => 'elevation_summary',
      'target' => { 'sourceElementId' => 'terrain-001' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 5.0, 'y' => 0.0 }],
        'sampleCount' => 5
      },
      'samplingPolicy' => {
        'visibleOnly' => true,
        'ignoreTargets' => [{ 'sourceElementId' => 'tree-001' }]
      }
    )

    assert_nil(refusal)
  end

  def test_refuses_terrain_profile_without_sampling
    refusal = request_refusal(
      'mode' => 'terrain_profile',
      'kind' => 'elevation_summary',
      'target' => { 'sourceElementId' => 'terrain-001' }
    )

    assert_refusal(refusal, 'missing_required_field')
    assert_equal('sampling', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_points_sampling_for_terrain_profile_with_allowed_values
    refusal = request_refusal(
      'mode' => 'terrain_profile',
      'kind' => 'elevation_summary',
      'target' => { 'sourceElementId' => 'terrain-001' },
      'sampling' => {
        'type' => 'points',
        'points' => [{ 'x' => 0.0, 'y' => 0.0 }]
      }
    )

    assert_refusal(refusal, 'unsupported_sampling_type')
    assert_equal('sampling.type', refusal.dig(:refusal, :details, :field))
    assert_equal(['profile'], refusal.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_invalid_terrain_profile_spacing
    refusal = request_refusal(
      'mode' => 'terrain_profile',
      'kind' => 'elevation_summary',
      'target' => { 'sourceElementId' => 'terrain-001' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 5.0, 'y' => 0.0 }],
        'sampleCount' => 5,
        'intervalMeters' => 1.0
      }
    )

    assert_refusal(refusal, 'mutually_exclusive_fields')
    assert_equal(%w[sampling.sampleCount sampling.intervalMeters],
                 refusal.dig(:refusal, :details, :fields))
  end

  def test_refuses_invalid_sampling_policy_visible_only
    refusal = request_refusal(
      'mode' => 'terrain_profile',
      'kind' => 'elevation_summary',
      'target' => { 'sourceElementId' => 'terrain-001' },
      'sampling' => profile_sampling,
      'samplingPolicy' => { 'visibleOnly' => 'yes' }
    )

    assert_refusal(refusal, 'invalid_request')
    assert_equal('samplingPolicy.visibleOnly', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_invalid_sampling_policy_ignore_targets
    refusal = request_refusal(
      'mode' => 'terrain_profile',
      'kind' => 'elevation_summary',
      'target' => { 'sourceElementId' => 'terrain-001' },
      'sampling' => profile_sampling,
      'samplingPolicy' => { 'ignoreTargets' => { 'sourceElementId' => 'tree-001' } }
    )

    assert_refusal(refusal, 'invalid_request')
    assert_equal('samplingPolicy.ignoreTargets', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_terrain_only_fields_on_generic_modes
    refusal = request_refusal(
      'mode' => 'height',
      'kind' => 'bounds_z',
      'target' => { 'entityId' => '101' },
      'samplingPolicy' => { 'visibleOnly' => true }
    )

    assert_refusal(refusal, 'unsupported_request_field')
    assert_equal('samplingPolicy', refusal.dig(:refusal, :details, :field))
  end

  private

  def request_refusal(params)
    SU_MCP::MeasureSceneRequest.new(params).refusal
  end

  def profile_sampling
    {
      'type' => 'profile',
      'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 5.0, 'y' => 0.0 }],
      'sampleCount' => 5
    }
  end

  def assert_refusal(result, code)
    refute_nil(result)
    assert_equal(true, result.fetch(:success))
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end
end
