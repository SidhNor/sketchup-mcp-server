# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/cdt_terrain_candidate_backend'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class CdtTerrainCandidateBackendTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_consumes_feature_geometry_primitives_and_emits_json_safe_candidate_mesh
    result = backend.run(state: state, feature_geometry: feature_geometry,
                         base_tolerance: 0.05, max_point_budget: 256,
                         max_face_budget: 128, max_runtime_budget: 10.0)

    assert_candidate_identity(result)
    assert_candidate_mesh_and_digests(result)
    assert_candidate_constraint_summary(result)
    assert(JSON.parse(JSON.generate(result)))
    refute_includes(JSON.generate(result), 'Sketchup::')
  end

  def test_candidate_backend_wraps_production_residual_engine_without_changing_row_shape
    engine = ResidualEngineSpy.new
    result = SU_MCP::Terrain::CdtTerrainCandidateBackend.new(
      residual_engine: engine
    ).run(state: state, feature_geometry: feature_geometry,
          base_tolerance: 0.05, max_point_budget: 256,
          max_face_budget: 128, max_runtime_budget: 10.0)

    assert_equal(1, engine.calls)
    assert_candidate_identity(result)
    assert_candidate_mesh_and_digests(result)
    assert_candidate_constraint_summary(result)
    assert_includes(result.fetch(:metrics).keys, :residualRefinement)
    assert_equal('ruby_bowyer_watson_constraint_recovery', result.fetch(:triangulatorKind))
  end

  def assert_candidate_identity(result)
    assert_equal('mta24_constrained_delaunay_cdt_prototype', result.fetch(:backend))
    assert_equal(1, result.fetch(:resultSchemaVersion))
  end

  def assert_candidate_mesh_and_digests(result)
    assert_operator(result.dig(:mesh, :vertices).length, :>, 0)
    assert_operator(result.dig(:mesh, :triangles).length, :>, 0)
    assert_equal(feature_geometry.feature_geometry_digest, result.fetch(:featureGeometryDigest))
    assert_equal(feature_geometry.reference_geometry_digest, result.fetch(:referenceGeometryDigest))
    assert_equal(state_digest(state), result.fetch(:stateDigest))
  end

  def assert_candidate_constraint_summary(result)
    assert_operator(result.fetch(:constraintCount), :>=, 7)
    assert_equal(
      { anchors: 1, protectedRegions: 1, pressureRegions: 1, referenceSegments: 1,
        affectedWindows: 1 },
      result.fetch(:constraintSourceSummary)
    )
  end

  def test_valid_heightmap_still_emits_mesh_row_when_constraints_are_degraded
    result = backend.run(state: state, feature_geometry: intersecting_geometry,
                         base_tolerance: 0.05, max_point_budget: 256,
                         max_face_budget: 128, max_runtime_budget: 10.0)

    assert_operator(result.dig(:mesh, :triangles).length, :>, 0)
    assert_equal('none', result.fetch(:failureCategory))
    assert_operator(result.fetch(:constrainedEdgeCoverage), :<, 1.0)
    assert_includes(JSON.generate(result.fetch(:limitations)), 'intersecting_constraint')
  end

  def test_feature_geometry_failure_and_runtime_budget_are_recorded_without_edit_refusal
    failed = SU_MCP::Terrain::TerrainFeatureGeometry.new(
      failureCategory: 'feature_geometry_failed',
      limitations: [{ category: 'preserve_region_derivation', reason: 'unsupported polygon' }]
    )
    result = backend.run(state: state, feature_geometry: failed,
                         base_tolerance: 0.05, max_point_budget: 256,
                         max_face_budget: 128, max_runtime_budget: 10.0)
    over_budget = backend.run(state: state, feature_geometry: feature_geometry,
                              base_tolerance: 0.05, max_point_budget: 3,
                              max_face_budget: 128, max_runtime_budget: 10.0)

    assert_operator(result.dig(:mesh, :triangles).length, :>, 0)
    assert_equal('feature_geometry_failed', result.fetch(:failureCategory))
    assert_equal('max_point_budget_exceeded', over_budget.fetch(:budgetStatus))
    assert_equal('performance_limit_exceeded', over_budget.fetch(:failureCategory))
  end

  def test_candidate_row_records_topology_height_and_cdt_diagnostics
    result = backend.run(state: state, feature_geometry: feature_geometry,
                         base_tolerance: 0.05, max_point_budget: 256,
                         max_face_budget: 128, max_runtime_budget: 10.0)
    metrics = result.fetch(:metrics)

    %i[
      faceCount vertexCount denseRatio maxHeightError protectedCrossingCount
      hardViolationCounts topologyChecks topologyResiduals timing budgetStatus
    ].each { |field| assert_includes(metrics.keys, field) }
    assert_includes(result.keys, :constrainedEdgeCoverage)
    assert_includes(result.keys, :delaunayViolationCount)
    assert_equal('ruby_bowyer_watson_constraint_recovery',
                 result.fetch(:triangulatorKind))
    assert_match(/\Amta24-ruby-cdt-prototype-/, result.fetch(:triangulatorVersion))
  end

  def test_smooth_state_is_simplified_before_cdt_triangulation
    terrain_state = smooth_state(columns: 33, rows: 33)
    result = backend.run(state: terrain_state,
                         feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
                         base_tolerance: 0.05, max_point_budget: 4096,
                         max_face_budget: 32 * 32 * 2, max_runtime_budget: 60.0)

    assert_operator(result.fetch(:selectedPointCount), :<, 33 * 33)
    assert_operator(result.dig(:metrics, :denseRatio), :<=, 0.25)
    assert_operator(result.dig(:metrics, :maxHeightError), :<=, 0.05)
    assert_equal('none', result.fetch(:failureCategory))
  end

  def test_height_error_is_measured_from_source_heightmap
    terrain_state = smooth_state(columns: 17, rows: 17)
    result = backend.run(state: terrain_state,
                         feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
                         base_tolerance: 0.05, max_point_budget: 4096,
                         max_face_budget: 16 * 16 * 2, max_runtime_budget: 10.0)

    assert_kind_of(Numeric, result.dig(:metrics, :maxHeightError))
    assert_operator(result.dig(:metrics, :maxHeightError), :>=, 0.0)
  end

  def test_rough_state_uses_residual_driven_refinement_after_seed_planning
    terrain_state = rough_state(columns: 33, rows: 33)
    result = backend.run(state: terrain_state,
                         feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
                         base_tolerance: 0.05, max_point_budget: 4096,
                         max_face_budget: 32 * 32 * 2, max_runtime_budget: 60.0)
    residual = result.dig(:metrics, :residualRefinement)

    assert_operator(residual.fetch(:residualCount), :>, 0)
    assert_operator(result.fetch(:selectedPointCount), :>, residual.fetch(:seedCount))
    assert_includes(%w[residual_satisfied max_passes safety_cap stalled],
                    residual.fetch(:stopReason))
    assert_operator(residual.fetch(:maxResidualExcess), :>=, 0.0)
    assert_includes(JSON.generate(result.fetch(:limitations)), 'cdt_mesh_residual_refinement')
    assert_equal('none', result.fetch(:failureCategory))
  end

  def test_flat_final_heightmap_with_feature_intent_stays_seed_sparse
    result = backend.run(state: smooth_state(columns: 17, rows: 17),
                         feature_geometry: feature_geometry,
                         base_tolerance: 0.05, max_point_budget: 4096,
                         max_face_budget: 16 * 16 * 2, max_runtime_budget: 10.0)
    residual = result.dig(:metrics, :residualRefinement)

    assert_equal(0, residual.fetch(:residualCount))
    assert_equal('residual_satisfied', residual.fetch(:stopReason))
    assert_operator(result.fetch(:selectedPointCount), :<=, 12)
    assert_operator(result.fetch(:selectedPointCount), :<, 17 * 17)
  end

  def test_residual_refinement_settings_are_reported_for_cap_sweeps
    terrain_state = rough_state(columns: 33, rows: 33)
    result = backend_with_residual_settings(
      point_ratio: 0.55,
      max_passes: 8,
      batch_size: 32
    ).run(state: terrain_state,
          feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
          base_tolerance: 0.05, max_point_budget: 4096,
          max_face_budget: 32 * 32 * 2, max_runtime_budget: 10.0)
    residual = result.dig(:metrics, :residualRefinement)

    assert_residual_sweep_settings(residual)
    assert_operator(result.fetch(:selectedPointCount), :<=, (33 * 33 * 0.55).ceil)
    assert_in_delta(
      result.fetch(:selectedPointCount).to_f / result.fetch(:denseSourcePointCount),
      residual.fetch(:selectedPointRatio),
      0.000_001
    )
    assert_equal(result.dig(:metrics, :denseRatio), residual.fetch(:faceDenseRatio))
  end

  def test_higher_residual_ratio_allows_same_or_more_points_without_budget_failure
    terrain_state = rough_state(columns: 33, rows: 33)
    low = run_rough_cap_sweep_case(terrain_state, 0.45)
    high = run_rough_cap_sweep_case(terrain_state, 0.60)

    assert_operator(low.fetch(:selectedPointCount), :<=, (33 * 33 * 0.45).ceil)
    assert_operator(high.fetch(:selectedPointCount), :<=, (33 * 33 * 0.60).ceil)
    assert_operator(high.fetch(:selectedPointCount), :>=, low.fetch(:selectedPointCount))
    assert_equal('ok', low.fetch(:budgetStatus))
    assert_equal('ok', high.fetch(:budgetStatus))
  end

  def test_zero_residual_passes_disables_backend_residual_refinement
    terrain_state = rough_state(columns: 33, rows: 33)
    result = backend_with_residual_settings(
      point_ratio: 0.60,
      max_passes: 0,
      batch_size: 32
    ).run(state: terrain_state,
          feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
          base_tolerance: 0.05, max_point_budget: 4096,
          max_face_budget: 32 * 32 * 2, max_runtime_budget: 10.0)
    residual = result.dig(:metrics, :residualRefinement)

    assert_equal(false, residual.fetch(:enabled))
    assert_equal(4, result.fetch(:selectedPointCount))
    assert_equal('disabled', residual.fetch(:stopReason))
    refute_includes(JSON.generate(result.fetch(:limitations)), 'cdt_mesh_residual_refinement')
  end

  def test_residual_settings_are_clamped_for_comparison_safety
    result = backend_with_residual_settings(
      point_ratio: 2.0,
      max_passes: 99,
      batch_size: 999
    ).run(state: smooth_state(columns: 17, rows: 17),
          feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
          base_tolerance: 0.05, max_point_budget: 4096,
          max_face_budget: 16 * 16 * 2, max_runtime_budget: 10.0)
    residual = result.dig(:metrics, :residualRefinement)

    assert_equal(1.0, residual.fetch(:pointRatio))
    assert_equal(48, residual.fetch(:maxPasses))
    assert_equal(256, residual.fetch(:batchSize))
  end

  def test_pruned_non_manifold_topology_is_reported_as_degraded_not_clean
    result = backend_with_pruning_triangulator.run(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 0.05,
      max_point_budget: 4096,
      max_face_budget: 128,
      max_runtime_budget: 10.0
    )

    assert_includes(JSON.generate(result.fetch(:limitations)), 'non_manifold_edge_pruned')
    refute_equal('none', result.fetch(:failureCategory))
    assert_equal('topology_degraded', result.fetch(:failureCategory))
  end

  def test_retriangulated_non_manifold_topology_is_reported_as_degraded_not_clean
    result = backend_with_retriangulating_triangulator.run(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 0.05,
      max_point_budget: 4096,
      max_face_budget: 128,
      max_runtime_budget: 10.0
    )

    assert_includes(JSON.generate(result.fetch(:limitations)), 'non_manifold_edge_retriangulated')
    assert_equal('topology_degraded', result.fetch(:failureCategory))
  end

  def test_repaired_non_manifold_topology_is_reported_as_degraded_not_clean
    result = backend_with_repairing_triangulator.run(
      state: smooth_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 0.05,
      max_point_budget: 4096,
      max_face_budget: 128,
      max_runtime_budget: 10.0
    )

    assert_includes(JSON.generate(result.fetch(:limitations)), 'non_manifold_edge_repaired')
    assert_equal('topology_degraded', result.fetch(:failureCategory))
  end

  private

  def assert_residual_sweep_settings(residual)
    assert_equal(0.55, residual.fetch(:pointRatio))
    assert_equal((33 * 33 * 0.55).ceil, residual.fetch(:safetyCap))
    assert_equal(8, residual.fetch(:maxPasses))
    assert_equal(32, residual.fetch(:batchSize))
    assert_equal(true, residual.fetch(:enabled))
  end

  def backend
    @backend ||= SU_MCP::Terrain::CdtTerrainCandidateBackend.new
  end

  def backend_with_pruning_triangulator
    SU_MCP::Terrain::CdtTerrainCandidateBackend.new(
      triangulator: PruningTriangulator.new
    )
  end

  def backend_with_retriangulating_triangulator
    SU_MCP::Terrain::CdtTerrainCandidateBackend.new(
      triangulator: RetriangulatingTriangulator.new
    )
  end

  def backend_with_repairing_triangulator
    SU_MCP::Terrain::CdtTerrainCandidateBackend.new(
      triangulator: RepairingTriangulator.new
    )
  end

  def backend_with_residual_settings(point_ratio:, max_passes:, batch_size:)
    SU_MCP::Terrain::CdtTerrainCandidateBackend.new(
      residual_refinement_point_ratio: point_ratio,
      residual_refinement_max_passes: max_passes,
      residual_refinement_batch_size: batch_size
    )
  end

  def run_rough_cap_sweep_case(terrain_state, point_ratio)
    backend_with_residual_settings(
      point_ratio: point_ratio,
      max_passes: 12,
      batch_size: 64
    ).run(state: terrain_state,
          feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
          base_tolerance: 0.05, max_point_budget: 4096,
          max_face_budget: 32 * 32 * 2, max_runtime_budget: 10.0)
  end

  def state
    elevations = Array.new(25) do |index|
      column = index % 5
      row = index / 5
      column == 2 && row == 2 ? 3.0 : column + (row * 0.25)
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 5, 'rows' => 5 },
      elevations: elevations,
      revision: 1,
      state_id: 'mta24-cdt-state'
    )
  end

  def smooth_state(columns:, rows:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      column + (row * 0.25)
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'mta24-smooth-cdt-state'
    )
  end

  def rough_state(columns:, rows:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      (Math.sin(column * 0.9) * 10.0) + (Math.cos(row * 0.7) * 7.0) +
        ((column % 5).zero? ? 4.0 : 0.0)
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'mta24-rough-cdt-state'
    )
  end

  def feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        { id: 'fixed', featureId: 'fixed', role: 'control', strength: 'hard',
          ownerLocalPoint: [2.0, 2.0], tolerance: 0.01 }
      ],
      protectedRegions: [
        { id: 'protected', featureId: 'preserve', role: 'protected',
          primitive: 'rectangle', ownerLocalBounds: [[1.0, 1.0], [3.0, 3.0]] }
      ],
      pressureRegions: [
        { id: 'corridor-pressure', featureId: 'corridor', role: 'centerline',
          strength: 'firm', primitive: 'corridor',
          ownerLocalShape: { centerline: [[0.0, 2.0], [4.0, 2.0]],
                             width: 1.0, blendDistance: 0.5 },
          targetCellSize: 1 }
      ],
      referenceSegments: [
        { id: 'center', featureId: 'corridor', role: 'centerline', strength: 'firm',
          ownerLocalStart: [0.0, 2.0], ownerLocalEnd: [4.0, 2.0] }
      ],
      affectedWindows: [
        { featureId: 'corridor', role: 'centerline', minCol: 0, minRow: 1, maxCol: 4,
          maxRow: 3, source: 'payload' }
      ],
      tolerances: [{ featureId: 'fixed', role: 'control', strength: 'hard', value: 0.01 }]
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

  def state_digest(terrain_state)
    JSON.generate(
      id: terrain_state.state_id,
      dimensions: terrain_state.dimensions,
      spacing: terrain_state.spacing,
      revision: terrain_state.revision
    )
  end

  class PruningTriangulator
    def triangulate(points:, constraints: [])
      vertices = points.map { |point| [Float(point.fetch(0)), Float(point.fetch(1))] }
      {
        vertices: vertices,
        triangles: [[0, 1, 2]],
        constrainedEdges: [],
        constrainedEdgeCoverage: constraints.empty? ? 1.0 : 0.0,
        delaunayViolationCount: 0,
        limitations: [
          {
            category: 'non_manifold_edge_pruned',
            reason: 'over-shared triangulation edge was pruned by the prototype CDT cleanup'
          }
        ]
      }
    end
  end

  class RetriangulatingTriangulator
    def triangulate(points:, constraints: [])
      vertices = points.map { |point| [Float(point.fetch(0)), Float(point.fetch(1))] }
      {
        vertices: vertices,
        triangles: [[0, 1, 2]],
        constrainedEdges: [],
        constrainedEdgeCoverage: constraints.empty? ? 1.0 : 0.0,
        delaunayViolationCount: 0,
        limitations: [
          {
            category: 'non_manifold_edge_retriangulated',
            reason: 'over-shared triangulation edge was locally retriangulated'
          }
        ]
      }
    end
  end

  class RepairingTriangulator
    def triangulate(points:, constraints: [])
      vertices = points.map { |point| [Float(point.fetch(0)), Float(point.fetch(1))] }
      {
        vertices: vertices,
        triangles: [[0, 1, 2]],
        constrainedEdges: [],
        constrainedEdgeCoverage: constraints.empty? ? 1.0 : 0.0,
        delaunayViolationCount: 0,
        limitations: [
          {
            category: 'non_manifold_edge_repaired',
            reason: 'over-shared triangulation edge was repaired by bounded local retriangulation'
          }
        ]
      }
    end
  end

  class ResidualEngineSpy
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def run(state:, feature_geometry:, **)
      @calls += 1
      dense_source_point_count =
        state.dimensions.fetch('columns') * state.dimensions.fetch('rows')
      {
        status: 'accepted',
        mesh: { vertices: [[0.0, 0.0, 0.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0]],
                triangles: [[0, 1, 2]] },
        metrics: {
          faceCount: 1,
          vertexCount: 3,
          selectedPointCount: 3,
          denseSourcePointCount: dense_source_point_count,
          denseEquivalentFaceCount: 32,
          denseRatio: 0.03125,
          maxHeightError: 0.0,
          protectedCrossingCount: 0,
          hardViolationCounts: {},
          topologyChecks: { downFaceCount: 0, nonManifoldEdgeCount: 0, invalidFaceCount: 0 },
          topologyResiduals: {},
          timing: {},
          budgetStatus: 'ok',
          residualRefinement: {
            enabled: true,
            residualCount: 0,
            seedCount: 3,
            stopReason: 'residual_satisfied'
          }
        },
        featureGeometryDigest: feature_geometry.feature_geometry_digest,
        referenceGeometryDigest: feature_geometry.reference_geometry_digest,
        stateDigest: JSON.generate(id: state.state_id, dimensions: state.dimensions,
                                   spacing: state.spacing, revision: state.revision),
        constraintSourceSummary: {
          anchors: 1,
          protectedRegions: 1,
          pressureRegions: 1,
          referenceSegments: 1,
          affectedWindows: 1
        },
        constraintCount: 7,
        selectedPointCount: 3,
        denseSourcePointCount: dense_source_point_count,
        sourceDimensions: state.dimensions,
        denseEquivalentFaceCount: 32,
        budgetStatus: 'ok',
        failureCategory: 'none',
        constrainedEdgeCoverage: 1.0,
        constrainedEdges: [],
        delaunayViolationCount: 0,
        limitations: []
      }
    end
  end
end
