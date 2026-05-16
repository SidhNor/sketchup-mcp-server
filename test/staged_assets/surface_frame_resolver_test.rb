# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/staged_asset_commands'

class SurfaceFrameResolverTest < Minitest::Test
  include StagedAssetTestSupport

  def setup
    Sketchup.active_model_override = build_sample_surface_z_model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_resolves_sloped_surface_hit_frame_and_slope_evidence
    result = resolver.resolve(
      surface_reference: { 'sourceElementId' => 'surface-sloped-001' },
      sample_position: [144.0, 1.0, 0.0]
    )

    assert_equal('ready', result.fetch(:outcome))
    assert_equal([144.0, 1.0, 3.0], result.dig(:frame, :evidence, :hitPoint))
    assert_in_delta(26.565, result.dig(:frame, :evidence, :slopeDegrees), 0.001)
    assert_in_delta(0.894427, result.dig(:frame, :up_axis)[2], 0.000001)
  end

  def test_refuses_surface_miss
    result = resolver.resolve(
      surface_reference: { 'sourceElementId' => 'surface-sloped-001' },
      sample_position: [155.0, 1.0, 0.0]
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('surface_frame_miss', result.dig(:refusal, :code))
    assert_equal('placement.orientation.surfaceReference', result.dig(:refusal, :details, :field))
  end

  def test_refuses_ambiguous_surface_frame
    result = resolver.resolve(
      surface_reference: { 'sourceElementId' => 'surface-ambiguous-001' },
      sample_position: [65.0, 1.0, 0.0]
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('ambiguous_surface_frame', result.dig(:refusal, :code))
  end

  def test_refuses_unsupported_resolved_surface_target
    result = resolver.resolve(
      surface_reference: { 'sourceElementId' => 'surface-edge-001' },
      sample_position: [125.0, 0.0, 0.0]
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('unsupported_surface_reference', result.dig(:refusal, :code))
  end

  def test_resolves_runtime_face_plane_without_fake_surface_details
    face = build_scene_query_face(
      entity_id: 501,
      origin_x: 0,
      layer: staged_asset_layer,
      material: staged_asset_material,
      details: {
        name: 'Runtime Plane Face',
        persistent_id: 5001,
        attributes: {
          'su_mcp' => { 'sourceElementId' => 'runtime-plane-001' }
        }
      }
    )
    internal_z = 0.75 * SU_MCP::Semantic::LengthConverter::METERS_TO_INTERNAL
    face.define_singleton_method(:plane) { [0.0, 0.0, 1.0, -internal_z] }
    face.define_singleton_method(:classify_point) { |_point| Sketchup::Face::PointInside }
    Sketchup.active_model_override = staged_asset_model(face)

    result = resolver.resolve(
      surface_reference: { 'sourceElementId' => 'runtime-plane-001' },
      sample_position: [1.0, 2.0, 0.0]
    )

    assert_equal('ready', result.fetch(:outcome))
    assert_equal([1.0, 2.0, 0.75], result.dig(:frame, :evidence, :hitPoint))
    assert_equal(0.0, result.dig(:frame, :evidence, :slopeDegrees))
    assert_equal([0.0, 0.0, 1.0], result.dig(:frame, :up_axis))
  end

  private

  def resolver
    SU_MCP::StagedAssets.const_get(:SurfaceFrameResolver).new
  end
end
