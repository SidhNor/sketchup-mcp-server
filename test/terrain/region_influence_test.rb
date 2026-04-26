# frozen_string_literal: true

require_relative '../test_helper'
begin
  require_relative '../../src/su_mcp/terrain/region_influence'
rescue LoadError
  # Skeleton-first TDD: production helper is introduced after this failing surface exists.
end

class RegionInfluenceTest < Minitest::Test
  def test_rectangle_weight_matches_existing_linear_falloff_boundary_semantics
    region = rectangle_region(
      min: [1.0, 1.0],
      max: [1.0, 1.0],
      blend: { 'distance' => 1.0, 'falloff' => 'linear' }
    )

    assert_equal(1.0, influence.weight_for({ x: 1.0, y: 1.0 }, region))
    assert_equal(0.0, influence.weight_for({ x: 0.0, y: 1.0 }, region))
  end

  def test_circle_weight_supports_center_radius_linear_smooth_and_outer_boundary
    assert_equal(1.0, influence.weight_for({ x: 2.0, y: 2.0 }, circle_region(radius: 1.0)))
    assert_equal(1.0, influence.weight_for({ x: 3.0, y: 2.0 }, circle_region(radius: 1.0)))
  end

  def test_circle_weight_supports_linear_and_smooth_blend_shoulders
    assert_in_delta(
      0.5,
      influence.weight_for(
        { x: 3.5, y: 2.0 },
        circle_region(radius: 1.0, blend: { 'distance' => 1.0, 'falloff' => 'linear' })
      ),
      1e-9
    )
    assert_in_delta(
      0.5,
      influence.weight_for(
        { x: 3.5, y: 2.0 },
        circle_region(radius: 1.0, blend: { 'distance' => 1.0, 'falloff' => 'smooth' })
      ),
      1e-9
    )
  end

  def test_circle_weight_is_zero_at_outer_blend_boundary
    assert_equal(
      0.0,
      influence.weight_for(
        { x: 4.0, y: 2.0 },
        circle_region(radius: 1.0, blend: { 'distance' => 1.0, 'falloff' => 'linear' })
      )
    )
  end

  def test_preserve_zone_membership_supports_rectangle_and_circle_sample_footprints
    spacing = { 'x' => 2.0, 'y' => 4.0 }
    zone = {
      'type' => 'rectangle',
      'bounds' => rectangle_bounds(min: [1.0, 1.0], max: [1.0, 1.0])
    }

    assert(influence.preserve_zone_contains?(
             { 'x' => 0.0, 'y' => 2.0 },
             zone,
             spacing
           ))
    assert(influence.preserve_zone_contains?(
             { x: 2.9, y: 2.0 },
             circle_preserve_zone(center: { 'x' => 0.0, 'y' => 2.0 }, radius: 0.75),
             spacing
           ))
  end

  private

  def influence
    SU_MCP::Terrain::RegionInfluence.new
  end

  def rectangle_region(min:, max:, blend: { 'distance' => 0.0, 'falloff' => 'none' })
    {
      'type' => 'rectangle',
      'bounds' => rectangle_bounds(min: min, max: max),
      'blend' => blend
    }
  end

  def rectangle_bounds(min:, max:)
    {
      'minX' => min[0],
      'minY' => min[1],
      'maxX' => max[0],
      'maxY' => max[1]
    }
  end

  def circle_region(center: { 'x' => 2.0, 'y' => 2.0 }, radius: 1.0,
                    blend: { 'distance' => 0.0, 'falloff' => 'none' })
    {
      'type' => 'circle',
      'center' => center,
      'radius' => radius,
      'blend' => blend
    }
  end

  def circle_preserve_zone(center:, radius:)
    {
      'type' => 'circle',
      'center' => center,
      'radius' => radius
    }
  end
end
