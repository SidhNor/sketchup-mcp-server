# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/intent_aware_enhanced_adaptive_grid_prototype'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class IntentAwareEnhancedAdaptiveGridPrototypeTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_emits_real_vertices_triangles_cells_metrics_and_consumes_feature_geometry
    unconstrained = prototype.run(state: state, feature_geometry: empty_geometry,
                                  base_tolerance: 10.0, max_cell_budget: 64,
                                  max_face_budget: 128, max_runtime_budget: 10.0)
    constrained = prototype.run(state: state, feature_geometry: corridor_geometry,
                                base_tolerance: 10.0, max_cell_budget: 64,
                                max_face_budget: 128, max_runtime_budget: 10.0)

    assert_operator(constrained.dig(:mesh, :vertices).length, :>, 0)
    assert_operator(constrained.dig(:mesh, :triangles).length, :>, 0)
    assert_operator(constrained.fetch(:candidateCells).length, :>,
                    unconstrained.fetch(:candidateCells).length)
    assert_equal('mta23_intent_aware_adaptive_grid_prototype', constrained.fetch(:backend))
    assert_includes(constrained.dig(:metrics, :splitReasonHistogram).keys, 'firm_pressure_needed')
  end

  def test_stop_conditions_budget_statuses_failure_precedence_and_no_forbidden_fallbacks
    result = prototype.run(state: state, feature_geometry: anchor_geometry,
                           base_tolerance: 0.001, max_cell_budget: 1,
                           max_face_budget: 1, max_runtime_budget: 10.0)

    assert_equal('max_cell_budget_exceeded', result.fetch(:budgetStatus))
    assert_equal('hard_output_geometry_violation', result.fetch(:failureCategory))
    refute_includes(JSON.generate(result), 'delaunay')
    refute_includes(JSON.generate(result), 'breakline')
    refute_includes(JSON.generate(result), 'production')
  end

  def test_protected_region_crossings_classify_as_hard_output_geometry_violation
    result = prototype.run(state: state, feature_geometry: protected_region_geometry,
                           base_tolerance: 10.0, max_cell_budget: 64,
                           max_face_budget: 128, max_runtime_budget: 10.0)

    assert_operator(result.dig(:metrics, :protectedCrossingCount), :>, 0)
    assert_equal('hard_output_geometry_violation', result.fetch(:failureCategory))
  end

  def test_role_specific_residuals_and_topology_residuals_are_first_class_metrics
    result = prototype.run(state: state, feature_geometry: corridor_geometry,
                           base_tolerance: 1.0, max_cell_budget: 64,
                           max_face_budget: 128, max_runtime_budget: 10.0)

    %w[corridor_centerline corridor_side_band corridor_endpoint_cap survey_anchor
       planar_plane_fit].each do |role|
      assert_includes(result.dig(:metrics, :firmResidualsByRole).keys, role)
    end
    %w[corridor_endpoint_cap corridor_side_band protected_boundary general_terrain].each do |role|
      assert_includes(result.dig(:metrics, :topologyResiduals).keys, role)
    end
    assert_includes(result.dig(:metrics, :topologyChecks).keys, :maxNormalBreakDeg)
    assert_includes(result.dig(:metrics, :topologyChecks).keys, :nonManifoldEdgeCount)
    assert_includes(result.dig(:metrics, :topologyChecks).keys, :downFaceCount)
    assert_includes(JSON.generate(result.fetch(:limitations)),
                    'prototype_role_residuals_are_first_pass_metrics')
  end

  def test_feature_geometry_is_projected_to_grid_space_for_non_unit_spacing_split_policy
    result = prototype.run(
      state: large_spacing_state,
      feature_geometry: large_spacing_target_geometry,
      base_tolerance: 10.0,
      max_cell_budget: 256,
      max_face_budget: 512,
      max_runtime_budget: 10.0
    )

    assert_operator(cells_in_range(result, 18.0..30.0, 18.0..30.0).length,
                    :>, cells_in_range(result, 0.0...12.0, 0.0...12.0).length)
    assert_includes(result.dig(:metrics, :splitReasonHistogram).keys, 'soft_pressure_useful')
  end

  def test_unsplittable_off_grid_anchor_does_not_block_height_error_splits
    result = prototype.run(
      state: two_hotspot_state,
      feature_geometry: off_grid_anchor_geometry,
      base_tolerance: 0.05,
      max_cell_budget: 256,
      max_face_budget: 512,
      max_runtime_budget: 10.0
    )

    histogram = result.dig(:metrics, :splitReasonHistogram)
    assert_operator(histogram.fetch('height_error_exceeded', 0), :>, 0)
    assert_operator(result.fetch(:candidateCells).length, :>, 25)
    assert_operator(result.dig(:metrics, :maxHeightError), :<, 2.0)
  end

  private

  def prototype
    @prototype ||= SU_MCP::Terrain::IntentAwareEnhancedAdaptiveGridPrototype.new
  end

  def state
    elevations = Array.new(25) do |index|
      column = index % 5
      row = index / 5
      column == 2 && row == 2 ? 4.0 : 1.0
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 5, 'rows' => 5 },
      elevations: elevations,
      revision: 1,
      state_id: 'prototype-state'
    )
  end

  def large_spacing_state
    columns = 49
    rows = 49
    spacing = 2.5
    elevations = Array.new(columns * rows, 4.0)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => spacing, 'y' => spacing },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'prototype-large-spacing-state'
    )
  end

  def two_hotspot_state
    columns = 17
    rows = 17
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      hotspot = [[4, 12, 4.0], [12, 4, -3.0]].sum do |cx, cy, height|
        distance = Math.sqrt(((column - cx)**2) + ((row - cy)**2))
        distance <= 3.0 ? height * (1.0 - (distance / 3.5)) : 0.0
      end
      1.0 + hotspot
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'prototype-two-hotspot-state'
    )
  end

  def cells_in_range(result, column_range, row_range)
    result.fetch(:candidateCells).select do |cell|
      column, row = cell_center(cell)
      column_range.cover?(column) && row_range.cover?(row)
    end
  end

  def cell_center(cell)
    [
      (cell.fetch(:min_col) + cell.fetch(:max_col)) / 2.0,
      (cell.fetch(:min_row) + cell.fetch(:max_row)) / 2.0
    ]
  end

  def empty_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new
  end

  def corridor_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      pressureRegions: [
        { id: 'corridor-pressure', featureId: 'corridor', role: 'centerline', strength: 'firm',
          primitive: 'corridor', ownerLocalShape: { centerline: [[0.0, 2.0], [4.0, 2.0]],
                                                    width: 1.0, blendDistance: 1.0 },
          targetCellSize: 1 }
      ],
      referenceSegments: [
        { id: 'center', featureId: 'corridor', role: 'centerline', strength: 'firm',
          ownerLocalStart: [0.0, 2.0], ownerLocalEnd: [4.0, 2.0] },
        { id: 'side', featureId: 'corridor', role: 'side_transition', strength: 'firm',
          ownerLocalStart: [0.0, 1.0], ownerLocalEnd: [4.0, 1.0] },
        { id: 'cap', featureId: 'corridor', role: 'endpoint_cap', strength: 'firm',
          ownerLocalStart: [0.0, 1.0], ownerLocalEnd: [0.0, 3.0] }
      ]
    )
  end

  def anchor_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        { id: 'anchor', featureId: 'fixed', role: 'control', strength: 'hard',
          ownerLocalPoint: [2.25, 2.25], tolerance: 0.01 }
      ]
    )
  end

  def protected_region_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      protectedRegions: [
        { id: 'protected', featureId: 'preserve', role: 'protected', primitive: 'rectangle',
          ownerLocalBounds: [[1.5, 1.5], [3.5, 3.5]] }
      ]
    )
  end

  def off_grid_anchor_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        { id: 'off-grid-anchor', featureId: 'fixed', role: 'control', strength: 'hard',
          ownerLocalPoint: [8.4, 8.4], tolerance: 0.01 }
      ]
    )
  end

  def large_spacing_target_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      pressureRegions: [
        { id: 'target', featureId: 'target', role: 'target_support', strength: 'soft',
          primitive: 'circle', ownerLocalShape: [60.0, 60.0, 15.0], targetCellSize: 4 }
      ],
      affectedWindows: [
        { featureId: 'target', role: 'target_support', minCol: 18, minRow: 18, maxCol: 30,
          maxRow: 30, source: 'payload' }
      ]
    )
  end
end
