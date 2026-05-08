# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/residual_cdt_engine'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class ResidualCdtEngineTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_request_carries_engine_level_inputs_not_adapter_primitives
    request = SU_MCP::Terrain::ResidualCdtEngine::Request.new(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 0.05,
      max_point_budget: 256,
      max_face_budget: 128,
      max_runtime_budget: 10.0
    )

    assert_respond_to(request.state, :elevations)
    assert_respond_to(request.feature_geometry, :feature_geometry_digest)
    assert_equal(0.05, request.base_tolerance)
    refute_respond_to(request, :segments)
    refute_respond_to(request, :points)
  end

  def test_rough_state_adds_residual_points_after_seed_planning
    result = run_engine(state: rough_state(columns: 33, rows: 33))
    residual = result.dig(:metrics, :residualRefinement)

    assert_equal('accepted', result.fetch(:status))
    assert_operator(residual.fetch(:residualCount), :>, 0)
    assert_operator(result.fetch(:selectedPointCount), :>, residual.fetch(:seedCount))
    assert_includes(%w[residual_satisfied max_passes safety_cap stalled],
                    residual.fetch(:stopReason))
    assert_operator(residual.fetch(:maxResidualExcess), :>=, 0.0)
    assert_includes(JSON.generate(result.fetch(:limitations)), 'cdt_mesh_residual_refinement')
    refute_includes(result.keys, :backend)
    refute_includes(result.keys, :candidateRow)
  end

  def test_smooth_state_stays_sparse_and_residual_satisfied
    result = run_engine(state: smooth_state(columns: 17, rows: 17))
    residual = result.dig(:metrics, :residualRefinement)

    assert_equal('accepted', result.fetch(:status))
    assert_equal(0, residual.fetch(:residualCount))
    assert_equal('residual_satisfied', residual.fetch(:stopReason))
    assert_operator(result.fetch(:selectedPointCount), :<, 17 * 17)
    assert_operator(result.dig(:metrics, :denseRatio), :<=, 0.25)
    assert_operator(result.dig(:metrics, :maxHeightError), :<=, 0.05)
  end

  def test_intersecting_constraints_are_diagnostics_not_ruby_cdt_preflight_fallback
    result = run_engine(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: intersecting_geometry
    )

    assert_equal('accepted', result.fetch(:status))
    refute_includes(result.keys, :fallbackReason)
    assert_operator(result.dig(:mesh, :triangles).length, :>, 0)
    assert_includes(JSON.generate(result.fetch(:limitations)), 'intersecting_constraint')
  end

  def test_residual_stop_reason_can_report_max_passes
    result = run_engine(
      state: rough_state(columns: 33, rows: 33),
      residual_refinement_max_passes: 1,
      residual_refinement_batch_size: 1
    )

    assert_equal('max_passes', result.dig(:metrics, :residualRefinement, :stopReason))
  end

  def test_residual_stop_reason_can_report_stalled
    result = SU_MCP::Terrain::ResidualCdtEngine.new(
      height_error_meter: StallingHeightErrorMeter.new
    ).run(**engine_input(state: rough_state(columns: 9, rows: 9)))

    assert_equal('stalled', result.dig(:metrics, :residualRefinement, :stopReason))
  end

  private

  def run_engine(state:, feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
                 **options)
    SU_MCP::Terrain::ResidualCdtEngine.new(**options).run(
      **engine_input(state: state, feature_geometry: feature_geometry)
    )
  end

  def engine_input(state:, feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new)
    {
      state: state,
      feature_geometry: feature_geometry,
      base_tolerance: 0.05,
      max_point_budget: 4096,
      max_face_budget: dense_face_budget(state),
      max_runtime_budget: 10.0
    }
  end

  def dense_face_budget(state)
    (state.dimensions.fetch('columns') - 1) * (state.dimensions.fetch('rows') - 1) * 2
  end

  def smooth_state(columns:, rows:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      column + (row * 0.25)
    end
    state_with(columns: columns, rows: rows, elevations: elevations, id: 'smooth-cdt-state')
  end

  def rough_state(columns:, rows:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      (Math.sin(column * 0.9) * 10.0) + (Math.cos(row * 0.7) * 7.0) +
        ((column % 5).zero? ? 4.0 : 0.0)
    end
    state_with(columns: columns, rows: rows, elevations: elevations, id: 'rough-cdt-state')
  end

  def state_with(columns:, rows:, elevations:, id:)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: id
    )
  end

  def intersecting_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        { id: 'a', featureId: 'a', role: 'centerline', strength: 'firm',
          ownerLocalStart: [0.0, 0.0], ownerLocalEnd: [4.0, 4.0] },
        { id: 'b', featureId: 'b', role: 'side_transition', strength: 'firm',
          ownerLocalStart: [0.0, 4.0], ownerLocalEnd: [4.0, 0.0] }
      ]
    )
  end

  class StallingHeightErrorMeter
    def worst_samples_with_local_tolerance(...)
      [{ point: [0.0, 0.0], residualExcess: 1.0 }]
    end

    def max_error(...)
      1.0
    end
  end
end
