# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/bounded_grade_edit'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/sample_window'

class BoundedGradeEditTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  def test_target_height_changes_only_samples_inside_hard_rectangle
    result = apply_edit(
      region: rectangle_region(min: [1.0, 1.0], max: [2.0, 2.0]),
      operation: target_height_operation(10.0)
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(
      [
        1.0, 1.0, 1.0, 1.0,
        1.0, 10.0, 10.0, 1.0,
        1.0, 10.0, 10.0, 1.0,
        1.0, 1.0, 1.0, 1.0
      ],
      result.fetch(:state).elevations
    )
  end

  def test_linear_falloff_scales_delta_across_blend_band
    result = apply_edit(
      region: rectangle_region(
        min: [1.0, 1.0],
        max: [1.0, 1.0],
        blend: { 'distance' => 2.0, 'falloff' => 'linear' }
      ),
      operation: target_height_operation(9.0)
    )

    assert_in_delta(9.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
    assert_in_delta(5.0, elevation_at(result.fetch(:state), 0, 1), 1e-9)
  end

  def test_smooth_falloff_uses_ue_aligned_smoothstep_formula
    # UE Landscape smooth falloff applies y * y * (3 - 2 * y) to linear falloff.
    result = apply_edit(
      region: rectangle_region(
        min: [1.0, 1.0],
        max: [1.0, 1.0],
        blend: { 'distance' => 2.0, 'falloff' => 'smooth' }
      ),
      operation: target_height_operation(9.0)
    )

    linear_weight = 1.0 - (1.0 / 2.0)
    smooth_weight = linear_weight * linear_weight * (3.0 - (2.0 * linear_weight))
    expected = 1.0 + ((9.0 - 1.0) * smooth_weight)
    assert_in_delta(expected, elevation_at(result.fetch(:state), 0, 1), 1e-9)
  end

  def test_rectangle_outer_blend_boundary_remains_zero_weight
    # Locks the shared helper's exact outer-boundary behavior for rectangle parity.
    result = apply_edit(
      region: rectangle_region(
        min: [1.0, 1.0],
        max: [1.0, 1.0],
        blend: { 'distance' => 1.0, 'falloff' => 'linear' }
      ),
      operation: target_height_operation(9.0)
    )

    assert_equal(1.0, elevation_at(result.fetch(:state), 0, 1))
  end

  def test_target_height_changes_samples_inside_circle_and_blend_only
    result = apply_edit(
      region: circle_region(
        center: { 'x' => 1.0, 'y' => 1.0 },
        radius: 0.5,
        blend: { 'distance' => 1.0, 'falloff' => 'linear' }
      ),
      operation: target_height_operation(9.0)
    )

    assert_in_delta(9.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
    assert_in_delta(5.0, elevation_at(result.fetch(:state), 2, 1), 1e-9)
    assert_equal(1.0, elevation_at(result.fetch(:state), 3, 1))
    assert_equal(1.0, elevation_at(result.fetch(:state), 3, 3))
  end

  def test_fixed_control_prediction_uses_edge_stencil_bilinear_interpolation
    fixed_controls = [
      {
        'id' => 'edge-control',
        'point' => { 'x' => 0.5, 'y' => 0.0 },
        'elevation' => 8.0
      }
    ]

    result = apply_edit(
      state: sloped_state,
      region: rectangle_region(min: [0.0, 0.0], max: [1.0, 1.0]),
      operation: target_height_operation(8.0),
      constraints: { 'fixedControls' => fixed_controls }
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_empty(result.dig(:diagnostics, :fixedControls, :violations))
  end

  def test_fixed_controls_support_implicit_and_explicit_tolerance # rubocop:disable Metrics/MethodLength
    fixed_controls = [
      {
        'id' => 'implicit-control',
        'point' => { 'x' => 1.0, 'y' => 1.0 },
        'elevation' => 1.0,
        'tolerance' => 100.0
      },
      {
        'id' => 'explicit-control',
        'point' => { 'x' => 2.0, 'y' => 2.0 },
        'elevation' => 1.0,
        'tolerance' => 0.25
      }
    ]

    conflict = apply_edit(
      region: rectangle_region(min: [1.0, 1.0], max: [2.0, 2.0]),
      operation: target_height_operation(20.0),
      constraints: { 'fixedControls' => fixed_controls }
    )

    assert_equal('refused', conflict.fetch(:outcome))
    assert_equal('fixed_control_conflict', conflict.dig(:refusal, :code))
    assert_equal('explicit-control', conflict.dig(:refusal, :details, :controlId))
    assert_in_delta(0.25, conflict.dig(:refusal, :details, :effectiveTolerance), 1e-9)
  end

  def test_preserve_zone_overlap_protects_influenced_samples_outside_zone_rectangle
    result = apply_edit(
      region: rectangle_region(
        min: [1.0, 1.0],
        max: [2.0, 2.0],
        blend: { 'distance' => 2.0, 'falloff' => 'linear' }
      ),
      operation: target_height_operation(9.0),
      constraints: {
        'preserveZones' => [
          { 'type' => 'rectangle', 'bounds' => rectangle_bounds(min: [1.5, 1.5], max: [2.5, 2.5]) }
        ]
      }
    )

    assert_equal(1.0, elevation_at(result.fetch(:state), 2, 2))
    assert_operator(result.dig(:diagnostics, :preserveZones, :protectedSampleCount), :>=, 4)
  end

  def test_circle_preserve_zone_protects_target_height_samples
    result = apply_edit(
      region: circle_region(center: { 'x' => 1.0, 'y' => 1.0 }, radius: 1.5),
      operation: target_height_operation(9.0),
      constraints: {
        'preserveZones' => [
          { 'type' => 'circle', 'center' => { 'x' => 1.0, 'y' => 1.0 }, 'radius' => 0.1 }
        ]
      }
    )

    assert_equal(1.0, elevation_at(result.fetch(:state), 1, 1))
    assert_operator(result.dig(:diagnostics, :preserveZones, :protectedSampleCount), :>, 0)
  end

  def test_changed_region_matches_shared_sample_window_summary
    result = apply_edit(
      region: rectangle_region(min: [1.0, 1.0], max: [2.0, 2.0]),
      operation: target_height_operation(10.0)
    )

    expected = SU_MCP::Terrain::SampleWindow.from_samples(
      result.dig(:diagnostics, :samples)
    ).to_changed_region

    assert_equal(expected, result.dig(:diagnostics, :changedRegion))
  end

  def test_refuses_no_data_state_before_full_regeneration
    result = apply_edit(
      state: flat_state(elevations: [
                          1.0, 1.0, 1.0,
                          1.0, nil, 1.0,
                          1.0, 1.0, 1.0
                        ], columns: 3, rows: 3),
      region: rectangle_region(min: [1.0, 1.0], max: [1.0, 1.0]),
      operation: target_height_operation(5.0)
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_no_data_unsupported', result.dig(:refusal, :code))
    assert_equal([{ column: 1, row: 1 }], result.dig(:refusal, :details, :samples))
  end

  private

  def apply_edit(operation:, region:, state: flat_state, constraints: {})
    SU_MCP::Terrain::BoundedGradeEdit.new.apply(
      state: state,
      request: {
        'operation' => operation,
        'region' => region,
        'constraints' => constraints
      }
    )
  end

  def target_height_operation(height)
    {
      'mode' => 'target_height',
      'targetElevation' => height
    }
  end

  def rectangle_region(min:, max:, blend: { 'distance' => 0.0, 'falloff' => 'none' })
    {
      'type' => 'rectangle',
      'bounds' => rectangle_bounds(min: min, max: max),
      'blend' => blend
    }
  end

  def circle_region(center:, radius:, blend: { 'distance' => 0.0, 'falloff' => 'none' })
    {
      'type' => 'circle',
      'center' => center,
      'radius' => radius,
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

  def elevation_at(state, column, row)
    state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
  end

  def flat_state(elevations: Array.new(16, 1.0), columns: 4, rows: 4)
    terrain_state(elevations: elevations, columns: columns, rows: rows)
  end

  def sloped_state
    terrain_state(elevations: [0.0, 2.0, 4.0, 6.0], columns: 2, rows: 2)
  end

  def terrain_state(elevations:, columns:, rows:)
    SU_MCP::Terrain::HeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end
end
