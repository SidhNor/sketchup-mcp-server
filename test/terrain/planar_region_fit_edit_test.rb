# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/planar_region_fit_edit'

class PlanarRegionFitEditTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_exact_coplanar_rectangle_fit_replaces_full_weight_samples_with_plane
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        region: rectangle_region(min: [0.0, 0.0], max: [2.0, 2.0]),
        controls: plane_controls
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    state = result.fetch(:state)
    assert_in_delta(1.0, elevation_at(state, 0, 0), 1e-9)
    assert_in_delta(1.2, elevation_at(state, 2, 0), 1e-9)
    assert_in_delta(1.8, elevation_at(state, 0, 2), 1e-9)
    planar = result.dig(:diagnostics, :planarFit)
    assert_equal('z = ax + by + c', planar.dig(:plane, :equation, :form))
    assert_in_delta(0.0, planar.dig(:quality, :maxResidual), 1e-9)
    assert_equal(9, planar.fetch(:fullWeightSampleCount))
  end

  def test_exact_coplanar_circle_fit_changes_only_positive_weight_samples
    result = editor.apply(
      state: flat_state(columns: 5, rows: 5),
      request: planar_request(
        region: circle_region(center: [2.0, 2.0], radius: 1.0),
        controls: [
          control('south', 2.0, 1.0, 1.0),
          control('east', 3.0, 2.0, 1.1),
          control('west', 1.0, 2.0, 0.9)
        ]
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_in_delta(1.0, elevation_at(result.fetch(:state), 2, 2), 1e-9)
    assert_in_delta(0.0, elevation_at(result.fetch(:state), 0, 0), 1e-9)
    assert_equal('circle', result.dig(:diagnostics, :planarFit, :supportRegionType))
  end

  def test_blend_shoulder_interpolates_existing_elevation_toward_plane
    result = editor.apply(
      state: flat_state(columns: 4, rows: 3, elevation: 0.0),
      request: planar_request(
        region: rectangle_region(
          min: [1.0, 1.0],
          max: [2.0, 2.0],
          blend: { 'distance' => 2.0, 'falloff' => 'linear' }
        ),
        controls: [
          control('c', 1.0, 1.0, 10.0),
          control('e', 2.0, 1.0, 10.0),
          control('n', 1.0, 2.0, 10.0)
        ]
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_in_delta(10.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
    assert_in_delta(5.0, elevation_at(result.fetch(:state), 0, 1), 1e-9)
    assert_equal(4, result.dig(:diagnostics, :planarFit, :fullWeightSampleCount))
    assert_operator(result.dig(:diagnostics, :planarFit, :blendSampleCount), :>, 0)
  end

  def test_near_coplanar_controls_succeed_when_residuals_are_within_tolerance
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        controls: [
          control('sw', 0.0, 0.0, 1.0, tolerance: 0.05),
          control('se', 2.0, 0.0, 1.2, tolerance: 0.05),
          control('nw', 0.0, 2.0, 1.8, tolerance: 0.05),
          control('near', 2.0, 2.0, 2.01, tolerance: 0.05)
        ]
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_operator(result.dig(:diagnostics, :planarFit, :quality, :maxResidual), :<=, 0.05)
  end

  def test_non_coplanar_controls_refuse_with_residual_details
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        controls: [
          control('sw', 0.0, 0.0, 1.0, tolerance: 0.01),
          control('se', 2.0, 0.0, 1.0, tolerance: 0.01),
          control('nw', 0.0, 2.0, 1.0, tolerance: 0.01),
          control('bad', 2.0, 2.0, 3.0, tolerance: 0.01)
        ]
      )
    )

    assert_refusal(result, 'non_coplanar_controls')
    assert_equal('bad', result.dig(:refusal, :details, :violatingControls).first.fetch(:id))
    assert_operator(result.dig(:refusal, :details, :quality, :maxResidual), :>, 0.01)
  end

  def test_same_xy_conflicting_controls_refuse
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        controls: [
          control('a', 0.0, 0.0, 1.0, tolerance: 0.01),
          control('b', 0.0, 0.0, 1.2, tolerance: 0.01),
          control('c', 2.0, 0.0, 1.0),
          control('d', 0.0, 2.0, 1.0)
        ]
      )
    )

    assert_refusal(result, 'contradictory_planar_controls')
  end

  def test_collinear_effective_controls_refuse
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(controls: [
                                control('a', 0.0, 0.0, 1.0),
                                control('b', 1.0, 1.0, 1.2),
                                control('c', 2.0, 2.0, 1.4)
                              ])
    )

    assert_refusal(result, 'degenerate_planar_control_set')
  end

  def test_control_outside_terrain_bounds_refuses
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(controls: plane_controls + [control('outside', 4.0, 4.0, 2.0)])
    )

    assert_refusal(result, 'planar_control_outside_bounds')
  end

  def test_control_outside_support_region_refuses
    result = editor.apply(
      state: flat_state(columns: 5, rows: 5),
      request: planar_request(
        region: rectangle_region(min: [0.0, 0.0], max: [1.0, 1.0]),
        controls: [
          control('a', 0.0, 0.0, 1.0),
          control('b', 1.0, 0.0, 1.0),
          control('outside', 3.0, 3.0, 1.0)
        ]
      )
    )

    assert_refusal(result, 'planar_control_outside_support_region')
  end

  def test_control_inside_preserve_zone_refuses
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        controls: plane_controls,
        preserve_zones: [
          { 'type' => 'circle', 'center' => { 'x' => 0.0, 'y' => 0.0 }, 'radius' => 0.1 }
        ]
      )
    )

    assert_refusal(result, 'planar_control_preserve_zone_conflict')
  end

  def test_preserve_zone_samples_remain_unchanged
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        controls: plane_controls,
        preserve_zones: [
          {
            'type' => 'rectangle',
            'bounds' => { 'minX' => 1.5, 'minY' => 1.5, 'maxX' => 2.5, 'maxY' => 2.5 }
          }
        ]
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_in_delta(0.0, elevation_at(result.fetch(:state), 2, 2), 1e-9)
    assert_operator(result.dig(:diagnostics, :planarFit, :preservedSampleCount), :>, 0)
  end

  def test_fixed_control_conflict_refuses_before_edit_success
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        controls: plane_controls,
        fixed_controls: [
          {
            'id' => 'fixed',
            'point' => { 'x' => 1.0, 'y' => 1.0 },
            'elevation' => 0.0,
            'tolerance' => 0.01
          }
        ]
      )
    )

    assert_refusal(result, 'fixed_control_conflict')
  end

  def test_off_grid_boundary_controls_refuse_when_discrete_surface_cannot_satisfy_them
    result = editor.apply(
      state: flat_state(
        columns: 21,
        rows: 36,
        spacing: { 'x' => 2.0, 'y' => 2.0 }
      ),
      request: planar_request(
        region: rectangle_region(min: [8.0, 15.0], max: [32.0, 55.0]),
        controls: [
          control('sw', 8.0, 15.0, 1.0, tolerance: 0.03),
          control('se', 32.0, 15.0, 1.0, tolerance: 0.03),
          control('nw', 8.0, 55.0, 1.0, tolerance: 0.03)
        ]
      )
    )

    assert_refusal(result, 'planar_fit_unsafe')
    assert_equal('discrete_heightmap_cannot_satisfy_planar_controls',
                 result.dig(:refusal, :details, :reason))
    assert_equal(%w[sw se nw],
                 result.dig(:refusal, :details, :violatingControls).map { |row| row.fetch(:id) })
  end

  def test_no_data_state_refuses
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3, elevations: [
                          0.0, 0.0, 0.0,
                          0.0, nil, 0.0,
                          0.0, 0.0, 0.0
                        ]),
      request: planar_request(controls: plane_controls)
    )

    assert_refusal(result, 'terrain_no_data_unsupported')
  end

  def test_fully_protected_region_refuses_no_affected_samples
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(
        controls: [
          control('a', 0.0, 0.0, 1.0),
          control('b', 2.0, 0.0, 1.0),
          control('c', 0.0, 2.0, 1.0)
        ],
        preserve_zones: [
          {
            'type' => 'rectangle',
            'bounds' => { 'minX' => -1.0, 'minY' => -1.0, 'maxX' => 3.0, 'maxY' => 3.0 }
          }
        ]
      )
    )

    assert_refusal(result, 'edit_region_has_no_affected_samples')
  end

  def test_close_controls_emit_grid_warning_when_otherwise_safe
    result = editor.apply(
      state: flat_state(columns: 3, rows: 3),
      request: planar_request(controls: [
                                control('a', 0.0, 0.0, 1.0),
                                control('b', 0.25, 0.0, 1.0),
                                control('c', 0.0, 2.0, 1.0)
                              ])
    )

    assert_equal('edited', result.fetch(:outcome))
    warnings = result.dig(:diagnostics, :planarFit, :grid, :warnings)
    assert_equal('close_planar_controls', warnings.first.fetch(:code))
  end

  def test_non_zero_origin_and_non_uniform_spacing_use_public_meter_coordinates
    result = editor.apply(
      state: flat_state(
        columns: 3,
        rows: 3,
        origin: { 'x' => 10.0, 'y' => 20.0, 'z' => 0.0 },
        spacing: { 'x' => 2.0, 'y' => 0.5 }
      ),
      request: planar_request(
        region: rectangle_region(min: [10.0, 20.0], max: [14.0, 21.0]),
        controls: [
          control('sw', 10.0, 20.0, 1.0),
          control('se', 14.0, 20.0, 1.4),
          control('nw', 10.0, 21.0, 1.5)
        ]
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_in_delta(1.0, elevation_at(result.fetch(:state), 0, 0), 1e-9)
    assert_in_delta(1.4, elevation_at(result.fetch(:state), 2, 0), 1e-9)
    assert_in_delta(1.5, elevation_at(result.fetch(:state), 0, 2), 1e-9)
    assert_equal({ x: 10.0, y: 20.0 }, result.dig(:diagnostics, :planarFit, :controls, 0, :point))
  end

  private

  def editor
    SU_MCP::Terrain::PlanarRegionFitEdit.new
  end

  def assert_refusal(result, code)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end

  def planar_request(region: rectangle_region(min: [0.0, 0.0], max: [2.0, 2.0]),
                     controls: plane_controls, fixed_controls: [], preserve_zones: [])
    {
      'operation' => { 'mode' => 'planar_region_fit' },
      'region' => region,
      'constraints' => {
        'planarControls' => controls,
        'fixedControls' => fixed_controls,
        'preserveZones' => preserve_zones
      }
    }
  end

  def plane_controls
    [
      control('sw', 0.0, 0.0, 1.0),
      control('se', 2.0, 0.0, 1.2),
      control('nw', 0.0, 2.0, 1.8)
    ]
  end

  def control(id, x, y, z, tolerance: 0.03)
    {
      'id' => id,
      'point' => { 'x' => x, 'y' => y, 'z' => z },
      'tolerance' => tolerance
    }
  end

  def rectangle_region(min:, max:, blend: { 'distance' => 0.0, 'falloff' => 'none' })
    {
      'type' => 'rectangle',
      'bounds' => {
        'minX' => min[0],
        'minY' => min[1],
        'maxX' => max[0],
        'maxY' => max[1]
      },
      'blend' => blend
    }
  end

  def circle_region(center:, radius:, blend: { 'distance' => 0.0, 'falloff' => 'none' })
    {
      'type' => 'circle',
      'center' => { 'x' => center[0], 'y' => center[1] },
      'radius' => radius,
      'blend' => blend
    }
  end

  def flat_state(columns:, rows:, elevation: 0.0, elevations: nil,
                 origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
                 spacing: { 'x' => 1.0, 'y' => 1.0 })
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: origin,
      spacing: spacing,
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations || Array.new(columns * rows, elevation),
      revision: 1,
      state_id: 'state-1'
    )
  end

  def elevation_at(state, column, row)
    state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
  end
end
