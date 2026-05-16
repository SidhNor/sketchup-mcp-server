# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/asset_instance_creator'

class AssetOrientationTransformBuilderTest < Minitest::Test
  include StagedAssetTestSupport

  MatrixTransform = Struct.new(:matrix_values) do
    def to_a
      matrix_values
    end
  end

  def test_preserves_source_axes_when_yaw_is_omitted
    source_matrix = [
      0.0, 1.0, 0.0, 0.0,
      -1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      10.0, 20.0, 30.0, 1.0
    ]
    source_transform = MatrixTransform.new(source_matrix)

    result = builder.build(
      source_transform: source_transform,
      origin: SceneQueryTestSupport::FakePoint.new(100.0, 200.0, 300.0),
      orientation: {
        mode: 'upright',
        yawDegrees: nil,
        sourceHeadingPreserved: true,
        explicit: false
      }
    )

    assert_equal(source_transform.to_a.first(12), result.fetch(:matrix).first(12))
    assert_equal([100.0, 200.0, 300.0, 1.0], result.fetch(:matrix).last(4))
  end

  def test_explicit_upright_without_yaw_preserves_heading_and_uses_model_vertical
    source_matrix = [
      0.0, 2.0, 0.0, 0.0,
      -3.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 4.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]

    result = builder.build(
      source_transform: MatrixTransform.new(source_matrix),
      origin: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
      orientation: {
        mode: 'upright',
        yawDegrees: nil,
        sourceHeadingPreserved: true,
        explicit: true
      }
    )

    assert_in_delta(0.0, result.fetch(:matrix)[0], 1e-9)
    assert_in_delta(2.0, result.fetch(:matrix)[1], 1e-9)
    assert_in_delta(-3.0, result.fetch(:matrix)[4], 1e-9)
    assert_in_delta(0.0, result.fetch(:matrix)[5], 1e-9)
    assert_in_delta(0.0, result.fetch(:matrix)[8], 1e-9)
    assert_in_delta(0.0, result.fetch(:matrix)[9], 1e-9)
    assert_in_delta(Math.sqrt(17.0), result.fetch(:matrix)[10], 1e-9)
  end

  def test_applies_upright_yaw_around_model_vertical
    result = builder.build(
      source_transform: MatrixTransform.new(identity_matrix),
      origin: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
      orientation: {
        mode: 'upright',
        yawDegrees: 90.0,
        sourceHeadingPreserved: false,
        explicit: true
      }
    )

    assert_in_delta(0.0, result.fetch(:matrix)[0], 1e-9)
    assert_in_delta(1.0, result.fetch(:matrix)[1], 1e-9)
    assert_in_delta(-1.0, result.fetch(:matrix)[4], 1e-9)
    assert_in_delta(0.0, result.fetch(:matrix)[5], 1e-9)
    assert_equal('upright', result.dig(:evidence, :mode))
    assert_equal(90.0, result.dig(:evidence, :yawDegrees))
  end

  def test_aligns_to_surface_frame_and_applies_yaw_around_local_up
    frame = {
      origin: SceneQueryTestSupport::FakePoint.new(10.0, 20.0, 4.0),
      x_axis: [1.0, 0.0, 0.0],
      y_axis: [0.0, 0.8944271909999159, 0.4472135954999579],
      up_axis: [0.0, -0.4472135954999579, 0.8944271909999159],
      evidence: {
        hitPoint: [10.0, 20.0, 4.0],
        slopeDegrees: 26.5650511771
      }
    }

    result = builder.build(
      source_transform: MatrixTransform.new(identity_matrix),
      origin: frame.fetch(:origin),
      orientation: {
        mode: 'surface_aligned',
        yawDegrees: nil,
        sourceHeadingPreserved: true,
        surfaceFrame: frame
      }
    )

    assert_in_delta(0.0, result.fetch(:matrix)[8], 1e-9)
    assert_in_delta(-0.4472135954999579, result.fetch(:matrix)[9], 1e-9)
    assert_in_delta(0.8944271909999159, result.fetch(:matrix)[10], 1e-9)
    assert_equal('surface_aligned', result.dig(:evidence, :mode))
    assert_equal(26.5650511771, result.dig(:evidence, :surface, :slopeDegrees))
  end

  def test_surface_aligned_without_yaw_preserves_source_heading
    source_matrix = [
      0.0, 1.0, 0.0, 0.0,
      -1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
    source_transform = MatrixTransform.new(source_matrix)

    result = builder.build(
      source_transform: source_transform,
      origin: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
      orientation: {
        mode: 'surface_aligned',
        yawDegrees: nil,
        sourceHeadingPreserved: true,
        surfaceFrame: flat_surface_frame
      }
    )

    assert_in_delta(0.0, result.fetch(:matrix)[0], 1e-9)
    assert_in_delta(1.0, result.fetch(:matrix)[1], 1e-9)
    assert_in_delta(-1.0, result.fetch(:matrix)[4], 1e-9)
    assert_in_delta(0.0, result.fetch(:matrix)[5], 1e-9)
  end

  def test_surface_aligned_preserves_source_axis_scale
    source_matrix = [
      2.0, 0.0, 0.0, 0.0,
      0.0, 3.0, 0.0, 0.0,
      0.0, 0.0, 4.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
    source_transform = MatrixTransform.new(source_matrix)

    result = builder.build(
      source_transform: source_transform,
      origin: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
      orientation: {
        mode: 'surface_aligned',
        yawDegrees: nil,
        sourceHeadingPreserved: true,
        surfaceFrame: flat_surface_frame
      }
    )

    assert_in_delta(2.0, axis_length(result.fetch(:matrix), 0), 1e-9)
    assert_in_delta(3.0, axis_length(result.fetch(:matrix), 4), 1e-9)
    assert_in_delta(4.0, axis_length(result.fetch(:matrix), 8), 1e-9)
  end

  def test_surface_aligned_preserves_source_definition_axis_correction
    source_matrix = [
      0.0, 0.0, 1.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      -1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]

    result = builder.build(
      source_transform: MatrixTransform.new(source_matrix),
      origin: sloped_surface_frame.fetch(:origin),
      orientation: {
        mode: 'surface_aligned',
        yawDegrees: nil,
        sourceHeadingPreserved: true,
        surfaceFrame: sloped_surface_frame
      }
    )

    assert_axis(sloped_surface_frame.fetch(:up_axis), result.fetch(:matrix), 0)
  end

  private

  def builder
    SU_MCP::StagedAssets.const_get(:AssetOrientationTransformBuilder).new
  end

  def identity_matrix
    [
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    ]
  end

  def flat_surface_frame
    {
      origin: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
      x_axis: [1.0, 0.0, 0.0],
      y_axis: [0.0, 1.0, 0.0],
      up_axis: [0.0, 0.0, 1.0],
      evidence: {
        hitPoint: [0.0, 0.0, 0.0],
        slopeDegrees: 0.0
      }
    }
  end

  def sloped_surface_frame
    {
      origin: SceneQueryTestSupport::FakePoint.new(0.0, 0.0, 0.0),
      x_axis: [1.0, 0.0, 0.0],
      y_axis: [0.0, 0.8944271909999159, 0.4472135954999579],
      up_axis: [0.0, -0.4472135954999579, 0.8944271909999159],
      evidence: {
        hitPoint: [0.0, 0.0, 0.0],
        slopeDegrees: 26.5650511771
      }
    }
  end

  def axis_length(matrix, start_index)
    Math.sqrt(
      (matrix[start_index]**2) +
      (matrix[start_index + 1]**2) +
      (matrix[start_index + 2]**2)
    )
  end

  def assert_axis(expected, matrix, start_index)
    expected.each_with_index do |component, offset|
      assert_in_delta(component, matrix[start_index + offset], 1e-9)
    end
  end
end
