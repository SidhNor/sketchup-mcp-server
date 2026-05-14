# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/cdt/residual_cdt_engine'
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

  def test_residual_refinement_reports_scan_and_retriangulation_probes
    result = run_engine(state: rough_state(columns: 17, rows: 17))
    residual = result.dig(:metrics, :residualRefinement)
    probes = residual.fetch(:probes)

    assert_operator(probes.fetch(:passCount), :>, 0)
    assert_operator(probes.fetch(:scanCount), :>=, probes.fetch(:passCount))
    assert_operator(probes.fetch(:scanSeconds), :>=, 0.0)
    assert_operator(probes.fetch(:scanSampleCount), :>=, 0)
    assert_operator(probes.fetch(:pointInsertionSeconds), :>=, 0.0)
    assert_operator(probes.fetch(:retriangulationCount), :>=, 0)
    assert_operator(probes.fetch(:retriangulationSeconds), :>=, 0.0)
    assert_equal(probes.fetch(:passCount), probes.fetch(:pointsAddedByPass).length)
    assert_equal(probes.fetch(:passCount), probes.fetch(:pointCountByPass).length)
  end

  def test_residual_refinement_spatially_thins_candidate_insertions
    result = run_engine(
      state: smooth_state(columns: 17, rows: 17),
      height_error_meter: ClusteredResidualHeightErrorMeter.new,
      residual_refinement_max_passes: 1,
      residual_refinement_batch_size: 16,
      residual_refinement_insert_batch_size: 3,
      residual_refinement_spacing_factor: 2.0
    )
    residual = result.dig(:metrics, :residualRefinement)
    probes = residual.fetch(:probes)

    assert_equal(3, probes.fetch(:pointsAddedByPass).first)
    assert_equal(7, result.fetch(:selectedPointCount))
    assert_equal(3, residual.fetch(:insertBatchSize))
    assert_equal(2.0, residual.fetch(:spacingFactor))
    assert_equal(3, probes.fetch(:insertBatchSize))
    assert_equal(2.0, probes.fetch(:spacingFactor))
  end

  def test_residual_passes_use_injected_triangulation_adapter
    adapter = RecordingTriangulationAdapter.new
    result = run_engine(
      state: rough_state(columns: 33, rows: 33),
      triangulation_adapter: adapter
    )

    assert_equal('accepted', result.fetch(:status))
    assert_operator(adapter.calls.length, :>, 1)
    assert_operator(adapter.calls.last.fetch(:point_count), :>,
                    adapter.calls.first.fetch(:point_count))
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

  def test_spatially_thinned_residuals_reduce_faces_without_breaking_tolerance
    terrain_state = moderate_state(columns: 17, rows: 17)
    old_like = run_engine(
      state: terrain_state,
      residual_refinement_insert_batch_size: 128,
      residual_refinement_spacing_factor: 1.0
    )
    thinned = run_engine(state: terrain_state)

    assert_operator(thinned.dig(:metrics, :faceCount), :<,
                    old_like.dig(:metrics, :faceCount))
    assert_operator(thinned.fetch(:selectedPointCount), :<,
                    old_like.fetch(:selectedPointCount))
    assert_operator(thinned.dig(:metrics, :maxHeightError), :<=, 0.05)
    assert_equal('residual_satisfied',
                 thinned.dig(:metrics, :residualRefinement, :stopReason))
  end

  def test_reports_phase_timing_for_cdt_compute_path
    result = run_engine(state: smooth_state(columns: 9, rows: 9))
    phases = result.dig(:timing, :phases)

    assert_operator(result.dig(:timing, :totalSeconds), :>=, 0.0)
    %i[
      inputNormalizationSeconds
      pointPlanningSeconds
      triangulationSeconds
      residualRefinementSeconds
    ].each do |key|
      assert_operator(phases.fetch(key), :>=, 0.0)
    end
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

  def test_firm_constraints_are_clipped_before_adapter_triangulation
    adapter = RecordingTriangulationAdapter.new
    result = run_engine(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: crossing_firm_geometry,
      triangulation_adapter: adapter
    )

    assert_equal('accepted', result.fetch(:status))
    assert_includes(JSON.generate(result.fetch(:limitations)), 'firm_constraint_clipped')
    adapter.calls.first.fetch(:constraints).each do |constraint|
      [constraint.fetch(:start), constraint.fetch(:end)].each do |point|
        assert(point[0].between?(0.0, 4.0), point.inspect)
        assert(point[1].between?(0.0, 4.0), point.inspect)
      end
    end
  end

  def test_hard_domain_violation_maps_to_hard_failure_category
    result = run_engine(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new(
        outputAnchorCandidates: [
          { id: 'outside-hard', featureId: 'fixed', role: 'control',
            strength: 'hard', ownerLocalPoint: [99.0, 99.0] }
        ]
      )
    )

    assert_equal('hard_output_geometry_violation', result.fetch(:failureCategory))
    assert_includes(JSON.generate(result.fetch(:limitations)), 'hard_domain_violation')
  end

  def test_hard_protected_region_crossing_patch_domain_is_clipped_without_rejection
    result = run_engine(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new(
        protectedRegions: [
          { id: 'wide-preserve', featureId: 'preserve', role: 'protected',
            strength: 'hard', primitive: 'rectangle',
            ownerLocalBounds: [[-2.0, 1.0], [2.0, 3.0]] }
        ]
      )
    )

    assert_equal('accepted', result.fetch(:status))
    assert_equal('none', result.fetch(:failureCategory))
    refute_includes(JSON.generate(result.fetch(:limitations)), 'hard_domain_violation')
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

  def test_recovery_path_runs_final_scan_after_last_insertion
    result = SU_MCP::Terrain::ResidualCdtEngine.new(
      height_error_meter: RecoveryFinalScanHeightErrorMeter.new,
      residual_refinement_max_passes: 1,
      residual_refinement_batch_size: 1,
      residual_refinement_insert_batch_size: 1
    ).run(**engine_input(state: smooth_state(columns: 17, rows: 17)))
    residual = result.dig(:metrics, :residualRefinement)

    assert_equal('residual_satisfied', residual.fetch(:stopReason))
    assert_operator(residual.dig(:probes, :recoveryPassCount), :>, 0)
    assert_operator(residual.dig(:probes, :finalScanCount), :>, 1)
  end

  def test_point_budget_exhaustion_returns_before_triangulation
    adapter = RecordingTriangulationAdapter.new
    result = run_engine(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: many_anchor_geometry,
      triangulation_adapter: adapter,
      max_point_budget: 4
    )

    assert_equal('max_point_budget_exceeded', result.fetch(:budgetStatus))
    assert_equal(0, adapter.calls.length)
    assert_equal('performance_limit_exceeded', result.fetch(:failureCategory))
  end

  private

  def run_engine(state:, feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
                 max_point_budget: 4096, **options)
    SU_MCP::Terrain::ResidualCdtEngine.new(**options).run(
      **engine_input(
        state: state,
        feature_geometry: feature_geometry,
        max_point_budget: max_point_budget
      )
    )
  end

  def engine_input(state:, feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
                   max_point_budget: 4096)
    {
      state: state,
      feature_geometry: feature_geometry,
      base_tolerance: 0.05,
      max_point_budget: max_point_budget,
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

  def moderate_state(columns:, rows:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      (Math.sin(column * 0.45) * 2.0) + (Math.cos(row * 0.37) * 1.5)
    end
    state_with(columns: columns, rows: rows, elevations: elevations, id: 'moderate-cdt-state')
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

  def many_anchor_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: 10.times.map do |index|
        { id: "anchor-#{index}", featureId: "fixed-#{index}", role: 'control',
          strength: 'hard', ownerLocalPoint: [index.to_f % 5, (index / 5).to_f] }
      end
    )
  end

  def crossing_firm_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        { id: 'crossing-firm', featureId: 'corridor', role: 'centerline',
          strength: 'firm', ownerLocalStart: [-10.0, 2.0],
          ownerLocalEnd: [10.0, 2.0] }
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

  class ClusteredResidualHeightErrorMeter
    SAMPLES = [
      { point: [4.0, 4.0], column: 4, row: 4, error: 1.0, residualExcess: 0.95 },
      { point: [4.0, 5.0], column: 4, row: 5, error: 0.95, residualExcess: 0.90 },
      { point: [5.0, 4.0], column: 5, row: 4, error: 0.90, residualExcess: 0.85 },
      { point: [15.0, 15.0], column: 15, row: 15, error: 0.85, residualExcess: 0.80 },
      { point: [15.0, 16.0], column: 15, row: 16, error: 0.80, residualExcess: 0.75 },
      { point: [8.0, 8.0], column: 8, row: 8, error: 0.75, residualExcess: 0.70 }
    ].freeze

    def initialize
      @sample_calls = 0
    end

    def worst_samples_with_local_tolerance(limit:, **)
      @sample_calls += 1
      return [] if @sample_calls > 1

      SAMPLES.first(limit)
    end

    def max_error(...)
      0.05
    end
  end

  class RecoveryFinalScanHeightErrorMeter
    def initialize
      @sample_calls = 0
    end

    def worst_samples_with_local_tolerance(limit:, **)
      @sample_calls += 1
      return [] if @sample_calls > 3

      [{ point: [@sample_calls.to_f, @sample_calls.to_f], residualExcess: 1.0 }]
        .first(limit)
    end

    def max_error(...)
      0.05
    end
  end

  class RecordingTriangulationAdapter
    attr_reader :calls

    def initialize
      @triangulator = SU_MCP::Terrain::CdtTriangulator.new
      @calls = []
    end

    def triangulate(points:, constraints:)
      calls << {
        point_count: points.length,
        constraint_count: constraints.length,
        constraints: constraints
      }
      @triangulator.triangulate(points: points, constraints: constraints)
    end
  end
end
