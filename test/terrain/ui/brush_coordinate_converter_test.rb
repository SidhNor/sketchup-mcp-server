# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/semantic/length_converter'
require_relative '../../../src/su_mcp/terrain/ui/brush_coordinate_converter'

class TerrainUiBrushCoordinateConverterTest < Minitest::Test
  Point = Struct.new(:x, :y, :z)
  Owner = Struct.new(:transformation, keyword_init: true)

  def test_converts_identity_world_internal_point_to_public_meter_xy
    result = converter.owner_local_xy(point(78.74015748031496, 39.37007874015748, 0.0),
                                      owner: owner_with_transform(nil))

    assert_in_delta(2.0, result.fetch('x'), 1e-9)
    assert_in_delta(1.0, result.fetch('y'), 1e-9)
  end

  def test_applies_owner_inverse_translation_before_meter_conversion
    transform = FakeTransform.new(translation: [39.37007874015748, 0.0, 0.0], scale: 1.0)

    result = converter.owner_local_xy(point(78.74015748031496, 39.37007874015748, 0.0),
                                      owner: owner_with_transform(transform))

    assert_in_delta(1.0, result.fetch('x'), 1e-9)
    assert_in_delta(1.0, result.fetch('y'), 1e-9)
  end

  def test_applies_owner_inverse_scale_before_meter_conversion
    transform = FakeTransform.new(translation: [0.0, 0.0, 0.0], scale: 2.0)

    result = converter.owner_local_xy(point(78.74015748031496, 39.37007874015748, 0.0),
                                      owner: owner_with_transform(transform))

    assert_in_delta(1.0, result.fetch('x'), 1e-9)
    assert_in_delta(0.5, result.fetch('y'), 1e-9)
  end

  def test_accepts_point_like_objects_with_xyz_methods
    result = converter.owner_local_xy(point(39.37007874015748, 0.0, 12.0),
                                      owner: owner_with_transform(nil))

    assert_equal({ 'x' => 1.0, 'y' => 0.0 }, result)
  end

  private

  class FakeTransform
    def initialize(translation:, scale:)
      @translation = translation
      @scale = scale
    end

    def inverse_apply(x_value, y_value, z_value)
      [
        (x_value - @translation[0]) / @scale,
        (y_value - @translation[1]) / @scale,
        (z_value - @translation[2]) / @scale
      ]
    end
  end

  def converter
    SU_MCP::Terrain::UI::BrushCoordinateConverter.new(
      length_converter: SU_MCP::Semantic::LengthConverter.new
    )
  end

  def point(x_value, y_value, z_value)
    Point.new(x_value, y_value, z_value)
  end

  def owner_with_transform(transform)
    Owner.new(transformation: transform)
  end
end
