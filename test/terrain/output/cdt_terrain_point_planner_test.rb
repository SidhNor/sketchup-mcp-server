# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/cdt/cdt_terrain_point_planner'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class CdtTerrainPointPlannerTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_planar_state_selects_sparse_points_and_reports_dense_baseline
    result = planner.plan(
      state: planar_state(columns: 33, rows: 33),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 0.05,
      max_point_budget: 4096
    )

    assert_equal(4, result.fetch(:points).length)
    assert_equal(4, result.fetch(:seedPointCount))
    assert_equal(4, result.fetch(:mandatoryPointCount))
    assert_equal(0, result.fetch(:residualPointCount))
    assert_equal(33 * 33, result.fetch(:denseSourcePointCount))
    assert_equal(32 * 32 * 2, result.fetch(:denseEquivalentFaceCount))
    assert_equal({ 'columns' => 33, 'rows' => 33 }, result.fetch(:sourceDimensions))
    assert_equal(0, result.dig(:featureSourceSummary, :anchors))
  end

  def test_height_error_tolerance_does_not_drive_seed_planner_density
    loose = planner.plan(
      state: ridge_state,
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 5.0,
      max_point_budget: 4096
    )
    tight = planner.plan(
      state: ridge_state,
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 0.05,
      max_point_budget: 4096
    )

    assert_equal(loose.fetch(:points), tight.fetch(:points))
  end

  def test_rough_terrain_still_starts_from_seed_points_only
    result = planner.plan(
      state: rough_state(columns: 33, rows: 33),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
      base_tolerance: 0.05,
      max_point_budget: 4096
    )

    assert_equal(4, result.fetch(:points).length)
    refute_includes(JSON.generate(result.fetch(:limitations)), 'simplification_point_budget')
  end

  def test_feature_geometry_adds_required_seed_points_without_dense_prefill
    result = planner.plan(
      state: planar_state(columns: 17, rows: 17),
      feature_geometry: feature_geometry,
      base_tolerance: 1.0,
      max_point_budget: 4096
    )

    points = result.fetch(:points)
    assert_required_feature_seed_points(points)
    assert_operator(points.count { |point| point[1].between?(7.0, 9.0) }, :<=, 4)
    assert_equal(points.length, result.fetch(:seedPointCount))
    assert_equal(points.length, result.fetch(:mandatoryPointCount))
    assert_equal(0, result.fetch(:residualPointCount))
    assert_feature_source_summary(result)
  end

  def test_reference_segment_seeding_uses_endpoints_without_unit_scaled_prefill
    result = planner.plan(
      state: large_spacing_state,
      feature_geometry: long_reference_geometry,
      base_tolerance: 1.0,
      max_point_budget: 4096
    )

    assert_operator(result.fetch(:points).length, :<=, 10)
    assert_includes(result.fetch(:points), [26_314.0, 6_279.0])
    assert_includes(result.fetch(:points), [30_211.6, 6_279.0])
    refute_includes(JSON.generate(result.fetch(:limitations)), 'point_budget')
  end

  def test_hard_anchor_outside_domain_is_rejected_before_expanding_hull
    result = planner.plan(
      state: planar_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new(
        outputAnchorCandidates: [
          { id: 'hard-outside', featureId: 'fixed', role: 'control', strength: 'hard',
            ownerLocalPoint: [99.0, 99.0], tolerance: 0.01 }
        ]
      ),
      base_tolerance: 1.0,
      max_point_budget: 4096
    )

    refute_includes(result.fetch(:points), [99.0, 99.0])
    assert_includes(
      result.fetch(:limitations).map { |item| item.fetch(:category) },
      'hard_domain_violation'
    )
  end

  def test_firm_reference_segment_is_clipped_to_domain_without_hard_failure
    result = planner.plan(
      state: planar_state(columns: 5, rows: 5),
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new(
        referenceSegments: [
          { id: 'firm-crossing', featureId: 'corridor', role: 'centerline', strength: 'firm',
            ownerLocalStart: [-10.0, 2.0], ownerLocalEnd: [10.0, 2.0], targetCellSize: 1 }
        ]
      ),
      base_tolerance: 1.0,
      max_point_budget: 4096
    )

    assert(result.fetch(:points).all? { |point| point[0].between?(0.0, 4.0) })
    assert_includes(result.fetch(:points), [0.0, 2.0])
    assert_includes(result.fetch(:points), [4.0, 2.0])
    assert_includes(
      result.fetch(:limitations).map { |item| item.fetch(:category) },
      'firm_constraint_clipped'
    )
  end

  private

  def assert_required_feature_seed_points(points)
    [[8.0, 8.0], [4.0, 4.0], [12.0, 12.0], [0.0, 8.0], [16.0, 8.0]].each do |point|
      assert_includes(points, point)
    end
  end

  def assert_feature_source_summary(result)
    assert_equal(1, result.dig(:featureSourceSummary, :anchors))
    assert_equal(1, result.dig(:featureSourceSummary, :protectedRegions))
    assert_equal(1, result.dig(:featureSourceSummary, :pressureRegions))
    assert_equal(1, result.dig(:featureSourceSummary, :referenceSegments))
    assert_equal(1, result.dig(:featureSourceSummary, :affectedWindows))
  end

  def planner
    @planner ||= SU_MCP::Terrain::CdtTerrainPointPlanner.new
  end

  def planar_state(columns:, rows:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      column + (row * 0.25)
    end
    state(columns: columns, rows: rows, elevations: elevations, state_id: 'planar')
  end

  def ridge_state
    columns = 17
    rows = 17
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      column == 8 || row == 8 ? 4.0 : 0.0
    end
    state(columns: columns, rows: rows, elevations: elevations, state_id: 'ridge')
  end

  def rough_state(columns:, rows:)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      (Math.sin(column * 0.9) * 10.0) + (Math.cos(row * 0.7) * 7.0) +
        ((column % 5).zero? ? 4.0 : 0.0)
    end
    state(columns: columns, rows: rows, elevations: elevations, state_id: 'rough')
  end

  def state(columns:, rows:, elevations:, state_id:)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: state_id
    )
  end

  def large_spacing_state
    columns = 33
    rows = 33
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      column + (row * 0.25)
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 26_314.0, 'y' => 4_330.0, 'z' => 0.0 },
      spacing: { 'x' => 121.8, 'y' => 121.8 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'large-spacing'
    )
  end

  def long_reference_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        { id: 'long-center', featureId: 'corridor', role: 'centerline', strength: 'firm',
          ownerLocalStart: [26_314.0, 6_279.0],
          ownerLocalEnd: [30_211.6, 6_279.0],
          targetCellSize: 1 }
      ]
    )
  end

  def feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        { id: 'fixed', featureId: 'fixed', role: 'control', strength: 'hard',
          ownerLocalPoint: [8.0, 8.0], tolerance: 0.01 }
      ],
      protectedRegions: [
        { id: 'protected', featureId: 'preserve', role: 'protected', primitive: 'rectangle',
          ownerLocalBounds: [[4.0, 4.0], [12.0, 12.0]] }
      ],
      pressureRegions: [
        { id: 'corridor-pressure', featureId: 'corridor', role: 'centerline', strength: 'firm',
          primitive: 'corridor', ownerLocalShape: { centerline: [[0.0, 8.0], [16.0, 8.0]],
                                                    width: 1.0, blendDistance: 1.0 },
          targetCellSize: 1 }
      ],
      referenceSegments: [
        { id: 'center', featureId: 'corridor', role: 'centerline', strength: 'firm',
          ownerLocalStart: [0.0, 8.0], ownerLocalEnd: [16.0, 8.0], targetCellSize: 1 }
      ],
      affectedWindows: [
        { featureId: 'corridor', role: 'centerline', minCol: 0, minRow: 7, maxCol: 16,
          maxRow: 9, source: 'payload' }
      ]
    )
  end
end
