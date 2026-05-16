# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/staged_assets/staged_asset_commands'

class OrientationRequestTest < Minitest::Test
  def test_defaults_to_upright_source_heading_preservation_when_orientation_is_omitted
    result = orientation_request.normalize(nil)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal(
      {
        mode: 'upright',
        yawDegrees: nil,
        sourceHeadingPreserved: true,
        surfaceReference: nil,
        explicit: false
      },
      result.fetch(:orientation)
    )
  end

  def test_normalizes_explicit_upright_yaw
    result = orientation_request.normalize(
      'mode' => 'upright',
      'yawDegrees' => 45
    )

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('upright', result.dig(:orientation, :mode))
    assert_equal(45.0, result.dig(:orientation, :yawDegrees))
    assert_equal(false, result.dig(:orientation, :sourceHeadingPreserved))
    assert_equal(true, result.dig(:orientation, :explicit))
  end

  def test_refuses_unknown_orientation_mode_with_allowed_values
    result = orientation_request.normalize('mode' => 'tilted')

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('unsupported_orientation_mode', result.dig(:refusal, :code))
    assert_equal(
      {
        field: 'placement.orientation.mode',
        value: 'tilted',
        allowedValues: %w[upright surface_aligned]
      },
      result.dig(:refusal, :details)
    )
  end

  def test_refuses_non_finite_yaw
    result = orientation_request.normalize(
      'mode' => 'upright',
      'yawDegrees' => Float::INFINITY
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('invalid_orientation_yaw', result.dig(:refusal, :code))
    assert_equal('placement.orientation.yawDegrees', result.dig(:refusal, :details, :field))
  end

  def test_requires_surface_reference_for_surface_aligned_mode
    result = orientation_request.normalize('mode' => 'surface_aligned')

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('missing_surface_reference', result.dig(:refusal, :code))
    assert_equal('placement.orientation.surfaceReference', result.dig(:refusal, :details, :field))
  end

  def test_accepts_direct_surface_reference_for_surface_aligned_mode
    result = orientation_request.normalize(
      'mode' => 'surface_aligned',
      'yawDegrees' => 30,
      'surfaceReference' => { 'sourceElementId' => 'terrain-main' }
    )

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('surface_aligned', result.dig(:orientation, :mode))
    assert_equal(30.0, result.dig(:orientation, :yawDegrees))
    assert_equal({ 'sourceElementId' => 'terrain-main' },
                 result.dig(:orientation, :surfaceReference))
  end

  private

  def orientation_request
    SU_MCP::StagedAssets.const_get(:OrientationRequest).new
  end
end
