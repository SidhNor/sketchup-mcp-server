# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/sample_window'
require_relative '../../src/su_mcp/terrain/corridor_transition_edit'

class CorridorTransitionEditTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_corridor_transition_raises_and_lowers_against_endpoint_interpolation
    raised = apply_edit(state: flat_state(1.0), start_elevation: 1.0, end_elevation: 5.0)
    lowered = apply_edit(state: flat_state(5.0), start_elevation: 5.0, end_elevation: 1.0)

    assert_equal('edited', raised.fetch(:outcome))
    assert_in_delta(3.0, elevation_at(raised.fetch(:state), 2, 2), 1e-9)
    assert_in_delta(3.0, elevation_at(lowered.fetch(:state), 2, 2), 1e-9)
    assert_equal(2, raised.fetch(:state).revision)
  end

  def test_side_blend_preserve_zone_and_changed_region_use_sample_window
    result = apply_edit(
      side_blend: { 'distance' => 1.0, 'falloff' => 'cosine' },
      constraints: {
        'preserveZones' => [
          {
            'id' => 'tree-root-zone',
            'type' => 'rectangle',
            'bounds' => { 'minX' => 2.0, 'minY' => 2.0, 'maxX' => 2.0, 'maxY' => 2.0 }
          }
        ]
      }
    )

    assert_preserved_center_sample(result)
    assert_changed_region_from_sample_window(result)
  end

  def test_refuses_no_data_state
    assert_refusal(
      apply_edit(state: state_with_no_data),
      'terrain_no_data_unsupported'
    )
  end

  def test_refuses_no_affected_samples
    assert_refusal(
      apply_edit(start_point: { 'x' => 100.0, 'y' => 100.0 },
                 end_point: { 'x' => 110.0, 'y' => 100.0 }),
      'edit_region_has_no_affected_samples'
    )
  end

  def test_refuses_fixed_control_conflicts
    assert_refusal(
      apply_edit(constraints: {
                   'fixedControls' => [
                     {
                       'id' => 'threshold',
                       'point' => { 'x' => 2.0, 'y' => 2.0 },
                       'elevation' => 1.0,
                       'tolerance' => 0.01
                     }
                   ]
                 }),
      'fixed_control_conflict'
    )
  end

  def test_transition_diagnostics_include_controls_slope_delta_summary_and_warnings
    result = apply_edit(side_blend: { 'distance' => 1.0, 'falloff' => 'cosine' })

    transition = result.dig(:diagnostics, :transition)
    assert_equal('corridor_transition', transition.fetch(:mode))
    assert_equal(2.0, transition.fetch(:width))
    assert_equal({ 'distance' => 1.0, 'falloff' => 'cosine' }, transition.fetch(:sideBlend))
    assert_includes(transition.keys, :endpointDeltas)
    assert_includes(transition.keys, :deltaSummary)
  end

  def test_exact_end_control_sample_updates_with_non_zero_origin_and_fractional_spacing
    state = terrain_state(
      origin: { 'x' => 2100.0, 'y' => 1000.0, 'z' => 0.0 },
      spacing: { 'x' => 0.1, 'y' => 0.1 },
      columns: 101,
      rows: 101,
      elevations: Array.new(10_201, -0.1)
    )
    result = apply_edit(
      state: state,
      start_point: { 'x' => 2102.0, 'y' => 1002.0 },
      end_point: { 'x' => 2108.0, 'y' => 1008.0 },
      start_elevation: 1.0,
      end_elevation: 4.0,
      width: 0.5,
      side_blend: { 'distance' => 0.0, 'falloff' => 'none' }
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_in_delta(4.0, elevation_at(result.fetch(:state), 80, 80), 1e-9)
    assert_in_delta(0.0, result.dig(:diagnostics, :transition, :endpointDeltas, :end), 1e-9)
  end

  private

  def apply_edit(options = {})
    request = corridor_request(options)
    SU_MCP::Terrain::CorridorTransitionEdit.new.apply(
      state: options.fetch(:state, flat_state(1.0)),
      request: request
    )
  end

  def corridor_request(options)
    {
      'operation' => { 'mode' => 'corridor_transition' },
      'region' => corridor_region(options),
      'constraints' => options.fetch(:constraints, {})
    }
  end

  def corridor_region(options)
    {
      'type' => 'corridor',
      'startControl' => {
        'point' => options.fetch(:start_point, { 'x' => 0.0, 'y' => 2.0 }),
        'elevation' => options.fetch(:start_elevation, 1.0)
      },
      'endControl' => {
        'point' => options.fetch(:end_point, { 'x' => 4.0, 'y' => 2.0 }),
        'elevation' => options.fetch(:end_elevation, 5.0)
      },
      'width' => options.fetch(:width, 2.0),
      'sideBlend' => options.fetch(:side_blend, { 'distance' => 0.0, 'falloff' => 'none' })
    }
  end

  def assert_refusal(result, code)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end

  def elevation_at(state, column, row)
    state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
  end

  def assert_preserved_center_sample(result)
    assert_equal(1.0, elevation_at(result.fetch(:state), 2, 2))
    assert_operator(result.dig(:diagnostics, :preserveZones, :protectedSampleCount), :>, 0)
    refute_includes(changed_sample_locations(result), { column: 2, row: 2 })
  end

  def assert_changed_region_from_sample_window(result)
    assert_equal(
      SU_MCP::Terrain::SampleWindow.from_samples(result.dig(:diagnostics, :samples))
        .to_changed_region,
      result.dig(:diagnostics, :changedRegion)
    )
  end

  def changed_sample_locations(result)
    result.dig(:diagnostics, :samples).map do |sample|
      { column: sample.fetch(:column), row: sample.fetch(:row) }
    end
  end

  def flat_state(elevation)
    terrain_state(elevations: Array.new(25, elevation))
  end

  def state_with_no_data
    elevations = Array.new(25, 1.0)
    elevations[12] = nil
    terrain_state(elevations: elevations)
  end

  def terrain_state(elevations:,
                    origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
                    spacing: { 'x' => 1.0, 'y' => 1.0 },
                    columns: 5,
                    rows: 5)
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: origin,
      spacing: spacing,
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end
end
