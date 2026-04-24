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
    assert_equal(%w[bounds height distance area], refusal.dig(:refusal, :details, :allowedValues))
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

  private

  def request_refusal(params)
    SU_MCP::MeasureSceneRequest.new(params).refusal
  end

  def assert_refusal(result, code)
    assert_equal(true, result.fetch(:success))
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end
end
