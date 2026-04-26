# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/sample_window'
begin
  require_relative '../../src/su_mcp/terrain/local_fairing_edit'
rescue LoadError
  # Skeleton-first TDD: implementation file is introduced after this failing surface exists.
end

class LocalFairingEditTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_reduces_mean_absolute_neighborhood_residual_on_noisy_patch
    result = apply_edit(state: noisy_state)

    fairing = result.dig(:diagnostics, :fairing)
    assert_equal('edited', result.fetch(:outcome))
    assert_equal('mean_absolute_neighborhood_residual', fairing.fetch(:metric))
    assert_operator(fairing.fetch(:afterResidual), :<, fairing.fetch(:beforeResidual))
    assert_equal(true, fairing.fetch(:improved))
    assert_operator(result.dig(:diagnostics, :changedSampleCount), :>, 0)
    assert_equal(2, result.fetch(:state).revision)
  end

  def test_applies_exact_strength_lerp_from_prior_pass_snapshot
    result = apply_edit(
      state: terrain_state(elevations: [
                             0.0, 0.0, 0.0,
                             0.0, 9.0, 0.0,
                             0.0, 0.0, 0.0
                           ], columns: 3, rows: 3),
      region: rectangle_region(min: [1.0, 1.0], max: [1.0, 1.0]),
      operation: fairing_operation(strength: 0.5, radius: 1)
    )

    assert_in_delta(5.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
    assert_equal(1, result.dig(:diagnostics, :fairing, :actualIterations))
  end

  def test_multi_iteration_uses_snapshots_not_scan_order_mutation
    result = apply_edit(
      state: terrain_state(elevations: [
                             0.0, 0.0, 0.0,
                             0.0, 9.0, 0.0,
                             0.0, 0.0, 0.0
                           ], columns: 3, rows: 3),
      operation: fairing_operation(strength: 1.0, radius: 1, iterations: 2)
    )

    assert_equal(2, result.dig(:diagnostics, :fairing, :actualIterations))
    assert_in_delta(16.0 / 9.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
  end

  def test_reads_out_of_region_context_without_mutating_out_of_region_samples
    result = apply_edit(
      state: terrain_state(elevations: [
                             10.0, 10.0, 10.0,
                             10.0, 0.0, 10.0,
                             10.0, 10.0, 10.0
                           ], columns: 3, rows: 3),
      region: rectangle_region(min: [1.0, 1.0], max: [1.0, 1.0]),
      operation: fairing_operation(strength: 1.0, radius: 1)
    )

    assert_in_delta(80.0 / 9.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
    assert_equal(10.0, elevation_at(result.fetch(:state), 0, 0))
  end

  def test_blend_weights_scale_fairing_delta
    result = apply_edit(
      state: terrain_state(elevations: [
                             10.0, 10.0, 10.0,
                             10.0, 0.0, 10.0,
                             10.0, 10.0, 10.0
                           ], columns: 3, rows: 3),
      region: rectangle_region(
        min: [1.0, 1.0],
        max: [1.0, 1.0],
        blend: { 'distance' => 1.0, 'falloff' => 'linear' }
      ),
      operation: fairing_operation(strength: 1.0, radius: 1)
    )

    assert_equal(10.0, elevation_at(result.fetch(:state), 0, 1))
    assert_in_delta(80.0 / 9.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
  end

  def test_preserve_zone_samples_remain_unchanged_but_can_inform_neighbors
    result = apply_edit(
      state: terrain_state(elevations: [
                             10.0, 10.0, 10.0,
                             10.0, 0.0, 10.0,
                             10.0, 10.0, 10.0
                           ], columns: 3, rows: 3),
      constraints: {
        'preserveZones' => [
          { 'type' => 'rectangle', 'bounds' => rectangle_bounds(min: [1.0, 1.0], max: [1.0, 1.0]) }
        ]
      }
    )

    assert_equal(0.0, elevation_at(result.fetch(:state), 1, 1))
    assert_operator(result.dig(:diagnostics, :preserveZones, :protectedSampleCount), :>, 0)
    refute_includes(changed_sample_locations(result), { column: 1, row: 1 })
  end

  def test_refuses_fixed_control_conflict_after_candidate_fairing
    result = apply_edit(
      state: noisy_state,
      constraints: {
        'fixedControls' => [
          {
            'id' => 'threshold',
            'point' => { 'x' => 2.0, 'y' => 2.0 },
            'elevation' => 9.0,
            'tolerance' => 0.01
          }
        ]
      }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('fixed_control_conflict', result.dig(:refusal, :code))
  end

  def test_refuses_no_affected_samples_no_data_and_no_material_change
    assert_refusal(
      apply_edit(region: rectangle_region(min: [100.0, 100.0], max: [101.0, 101.0])),
      'edit_region_has_no_affected_samples'
    )
    assert_refusal(apply_edit(state: state_with_no_data), 'terrain_no_data_unsupported')
    assert_refusal(apply_edit(state: flat_state), 'fairing_no_effect')
  end

  def test_changed_region_and_samples_use_material_delta_tolerance
    result = apply_edit(state: noisy_state)

    changed_samples = result.dig(:diagnostics, :samples)
    expected = SU_MCP::Terrain::SampleWindow.from_samples(changed_samples).to_changed_region

    assert_equal(expected, result.dig(:diagnostics, :changedRegion))
    assert_equal(changed_samples.length, result.dig(:diagnostics, :changedSampleCount))
    changed_samples.each { |sample| assert_operator(sample.fetch(:delta).abs, :>, 1e-6) }
  end

  def test_material_change_without_residual_improvement_succeeds_with_warning
    result = apply_edit(
      editor: NonImprovingResidualFairingEdit.new,
      state: terrain_state(elevations: [
                             0.0, 10.0, 0.0,
                             10.0, 0.0, 10.0,
                             0.0, 10.0, 0.0
                           ], columns: 3, rows: 3),
      operation: fairing_operation(strength: 1.0, radius: 1)
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(false, result.dig(:diagnostics, :fairing, :improved))
    assert_operator(result.dig(:diagnostics, :changedSampleCount), :>, 0)
    assert_includes(result.dig(:diagnostics, :warnings), 'fairing_residual_not_improved')
  end

  def test_clips_neighborhood_at_edges_and_keeps_steady_slope_stable
    slope = terrain_state(elevations: [
                            0.0, 1.0, 2.0, 3.0, 4.0,
                            1.0, 2.0, 3.0, 4.0, 5.0,
                            2.0, 3.0, 4.0, 5.0, 6.0,
                            3.0, 4.0, 5.0, 6.0, 7.0,
                            4.0, 5.0, 6.0, 7.0, 8.0
                          ], columns: 5, rows: 5)
    result = apply_edit(
      state: slope,
      region: rectangle_region(min: [1.0, 1.0], max: [3.0, 3.0])
    )

    assert_refusal(result, 'fairing_no_effect')
  end

  private

  def apply_edit(state: noisy_state,
                 editor: SU_MCP::Terrain::LocalFairingEdit.new,
                 operation: fairing_operation,
                 region: rectangle_region(min: [0.0, 0.0], max: [4.0, 4.0]),
                 constraints: {})
    editor.apply(
      state: state,
      request: {
        'operation' => operation,
        'region' => region,
        'constraints' => constraints
      }
    )
  end

  def fairing_operation(strength: 0.5, radius: 1, iterations: 1)
    {
      'mode' => 'local_fairing',
      'strength' => strength,
      'neighborhoodRadiusSamples' => radius,
      'iterations' => iterations
    }
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

  def assert_refusal(result, code)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end

  def elevation_at(state, column, row)
    state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
  end

  def changed_sample_locations(result)
    result.dig(:diagnostics, :samples).map do |sample|
      { column: sample.fetch(:column), row: sample.fetch(:row) }
    end
  end

  def flat_state
    terrain_state(elevations: Array.new(25, 1.0), columns: 5, rows: 5)
  end

  def noisy_state
    terrain_state(
      elevations: [
        1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 9.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0, 1.0
      ],
      columns: 5,
      rows: 5
    )
  end

  def state_with_no_data
    elevations = Array.new(25, 1.0)
    elevations[12] = nil
    terrain_state(elevations: elevations, columns: 5, rows: 5)
  end

  def terrain_state(elevations:, columns:, rows:)
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  class NonImprovingResidualFairingEdit < SU_MCP::Terrain::LocalFairingEdit
    private

    # Forces the acceptance path where changed terrain succeeds with a non-improvement warning.
    def residual_for(_state, _elevations, _candidates, _request)
      1.0
    end
  end
end
