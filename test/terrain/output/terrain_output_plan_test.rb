# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/regions/sample_window'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_cell_window'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_plan'

class TerrainOutputPlanTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_full_grid_plan_uses_window_vocabulary_without_changing_public_mesh_summary
    plan = SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: state,
      terrain_state_summary: { digest: 'digest-1' }
    )

    assert_equal(:full_grid, plan.intent)
    assert_equal(:full_grid, plan.execution_strategy)
    assert_equal(SU_MCP::Terrain::SampleWindow.full_grid(state), plan.window)
    assert_equal(
      SU_MCP::Terrain::TerrainOutputCellWindow.from_sample_window(
        window: SU_MCP::Terrain::SampleWindow.full_grid(state),
        state: state
      ),
      plan.cell_window
    )
    assert_equal(
      {
        derivedMesh: {
          meshType: 'regular_grid',
          vertexCount: 12,
          faceCount: 12,
          derivedFromStateDigest: 'digest-1'
        }
      },
      plan.to_summary
    )
  end

  def test_dirty_window_plan_records_internal_intent_without_changing_public_mesh_summary
    window = SU_MCP::Terrain::SampleWindow.new(
      min_column: 1,
      min_row: 0,
      max_column: 2,
      max_row: 1
    )

    plan = SU_MCP::Terrain::TerrainOutputPlan.dirty_window(
      state: state,
      terrain_state_summary: { digest: 'digest-2' },
      window: window
    )

    assert_equal(:dirty_window, plan.intent)
    assert_equal(:full_grid, plan.execution_strategy)
    assert_equal(window, plan.window)
    assert_equal(
      SU_MCP::Terrain::TerrainOutputCellWindow.from_sample_window(window: window, state: state),
      plan.cell_window
    )
    assert_equal(expected_summary('digest-2'), plan.to_summary)
    refute_includes(JSON.generate(plan.to_summary), 'dirtyWindow')
    refute_includes(JSON.generate(plan.to_summary), 'sampleWindow')
  end

  def test_dirty_window_plan_rejects_empty_windows_as_internal_invalid_plan
    error = assert_raises(ArgumentError) do
      SU_MCP::Terrain::TerrainOutputPlan.dirty_window(
        state: state,
        terrain_state_summary: { digest: 'digest-2' },
        window: SU_MCP::Terrain::SampleWindow.new(empty: true)
      )
    end

    assert_match(/dirty window/i, error.message)
  end

  def test_v2_full_grid_plan_reports_adaptive_tin_summary
    v2_state = build_v2_state(columns: 4, rows: 3, elevations: Array.new(12, 1.0))

    plan = SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )

    assert_equal(:adaptive_tin, plan.execution_strategy)
    assert_equal(
      {
        meshType: 'adaptive_tin',
        vertexCount: 4,
        faceCount: 2,
        derivedFromStateDigest: 'digest-v2',
        sourceSpacing: { x: 1.0, y: 1.0 },
        simplificationTolerance: 0.01,
        maxSimplificationError: 0.0,
        seamCheck: { status: 'passed', maxGap: 0.0 }
      },
      plan.to_summary.fetch(:derivedMesh)
    )
  end

  def test_v2_adaptive_plan_adds_boundary_vertices_where_mixed_resolution_edges_would_hang
    plan = adaptive_plan(mixed_resolution_state)
    split_cell = plan.adaptive_cells.find { |cell| cell_bounds(cell) == [0, 0, 2, 2] }

    assert_equal(
      [[0, 0], [2, 0], [2, 1], [2, 2], [0, 2]],
      split_cell.fetch(:boundary_vertices)
    )
    assert_equal([1.0, 1.0], split_cell.fetch(:fan_center))
    assert(
      boundary_fan_cells(plan).any?,
      'expected at least one adaptive cell to use a boundary fan'
    )
    assert(rectangular_cells(plan).any?, 'expected some adaptive cells to remain single rectangles')
  end

  def test_v2_adaptive_boundary_plan_has_no_unsplit_intermediate_axis_vertices
    plan = adaptive_plan(mixed_resolution_state)

    assert_no_hanging_axis_edges(plan.adaptive_cells)
  end

  def test_v2_adaptive_boundary_vertices_are_ordered_as_simple_cell_cycles
    plan = adaptive_plan(mixed_resolution_state)

    plan.adaptive_cells.each { |cell| assert_simple_cell_boundary(cell) }
  end

  def test_v2_adaptive_plan_reports_conforming_counts_from_boundary_triangles
    state = mixed_resolution_state
    plan = adaptive_plan(state)
    derived_mesh = plan.to_summary.fetch(:derivedMesh)

    assert_equal(planned_vertex_count(plan.adaptive_cells), derived_mesh.fetch(:vertexCount))
    assert_equal(planned_face_count(plan.adaptive_cells), derived_mesh.fetch(:faceCount))
    assert_operator(derived_mesh.fetch(:faceCount), :<=, full_grid_face_count(state))
  end

  def test_v2_adaptive_boundary_plan_keeps_representative_mixed_resolution_fixtures_compact
    {
      one_spike: one_spike_state,
      smooth_hill: smooth_hill_state,
      plateau: plateau_state,
      gentle_wave: gentle_wave_state
    }.each do |name, state|
      plan = adaptive_plan(state)
      ratio = planned_face_count(plan.adaptive_cells).to_f / full_grid_face_count(state)

      assert_operator(ratio, :<, 0.5, "expected #{name} ratio to remain materially compact")
    end
  end

  def test_v2_adaptive_summary_does_not_expose_conformity_internals
    plan = adaptive_plan(mixed_resolution_state)
    serialized = JSON.generate(plan.to_summary)

    %w[
      splitColumns splitRows splitGrid adaptiveBoundaryLines conformingGrid
      densified adaptiveCell adaptiveCells emissionStrategy sourceGridSubcell
      sourceGridSubcells classification rawVertices rawTriangles stitch
    ].each do |term|
      refute_includes(serialized, term)
    end
  end

  private

  def expected_summary(digest)
    {
      derivedMesh: {
        meshType: 'regular_grid',
        vertexCount: 12,
        faceCount: 12,
        derivedFromStateDigest: digest
      }
    }
  end

  def state
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 4, 'rows' => 3 },
      elevations: Array.new(12, 1.0),
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  def adaptive_plan(v2_state)
    SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: v2_state,
      terrain_state_summary: { digest: 'digest-v2', revision: 1 }
    )
  end

  def build_v2_state(columns:, rows:, elevations:)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  def mixed_resolution_state
    build_v2_state(
      columns: 6,
      rows: 6,
      elevations: [
        0.0, 0.0, 0.0, 0.05, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.05,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.05, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.1, 0.0
      ]
    )
  end

  def one_spike_state
    elevations = Array.new(17 * 17, 0.0)
    elevations[(4 * 17) + 4] = 1.0
    build_v2_state(columns: 17, rows: 17, elevations: elevations)
  end

  def smooth_hill_state
    build_v2_state(columns: 17, rows: 17, elevations: gaussian_elevations(17, amplitude: 0.2))
  end

  def plateau_state
    elevations = Array.new(17 * 17, 0.0)
    (0...17).each do |row|
      (0...17).each do |column|
        elevations[(row * 17) + column] = 0.04 if column < 8 && row < 8
      end
    end
    build_v2_state(columns: 17, rows: 17, elevations: elevations)
  end

  def gentle_wave_state
    elevations = Array.new(17 * 17, 0.0)
    (0...17).each do |row|
      (0...17).each do |column|
        elevations[(row * 17) + column] = (Math.sin(column / 4.0) * 0.02) +
                                          (Math.cos(row / 5.0) * 0.02)
      end
    end
    build_v2_state(columns: 17, rows: 17, elevations: elevations)
  end

  def gaussian_elevations(size, amplitude:)
    center = size / 2
    Array.new(size * size) do |index|
      column = index % size
      row = index / size
      dx = (column - center).to_f / center
      dy = (row - center).to_f / center
      amplitude * Math.exp(-4 * ((dx * dx) + (dy * dy)))
    end
  end

  def boundary_fan_cells(plan)
    plan.adaptive_cells.select do |cell|
      cell.fetch(:fan_center)
    end
  end

  def rectangular_cells(plan)
    plan.adaptive_cells.select do |cell|
      cell.fetch(:fan_center).nil?
    end
  end

  def cell_bounds(cell)
    [
      cell.fetch(:min_column),
      cell.fetch(:min_row),
      cell.fetch(:max_column),
      cell.fetch(:max_row)
    ]
  end

  def planned_vertex_count(cells)
    planned_vertices(cells).length
  end

  def planned_face_count(cells)
    cells.sum do |cell|
      cell.fetch(:emission_triangles).length
    end
  end

  def planned_vertices(cells)
    cells.flat_map do |cell|
      cell.fetch(:boundary_vertices) + optional_vertex(cell[:fan_center])
    end.uniq
  end

  def optional_vertex(vertex)
    vertex ? [vertex] : []
  end

  def assert_no_hanging_axis_edges(cells)
    vertices = planned_vertices(cells)
    emitted_axis_edges(cells).each do |from, to|
      interior = vertices.find { |point| point_strictly_inside_axis_edge?(point, from, to) }
      refute(interior, "expected edge #{from.inspect}->#{to.inspect} to be split at #{interior}")
    end
  end

  def emitted_axis_edges(cells)
    cells.flat_map do |cell|
      planned_cell_triangles(cell).flat_map do |triangle|
        triangle.zip(triangle.rotate).select do |from, to|
          from[0] == to[0] || from[1] == to[1]
        end
      end
    end
  end

  def planned_cell_triangles(cell)
    cell.fetch(:emission_triangles)
  end

  def assert_simple_cell_boundary(cell)
    vertices = cell.fetch(:boundary_vertices)

    assert_equal(vertices.length, vertices.uniq.length)
    vertices.zip(vertices.rotate).each do |from, to|
      assert(
        same_boundary_axis?(from, to) && point_on_cell_boundary?(from, cell),
        "expected #{from.inspect}->#{to.inspect} to follow boundary"
      )
    end
  end

  def same_boundary_axis?(from, to)
    from[0] == to[0] || from[1] == to[1]
  end

  def point_on_cell_boundary?(point, cell)
    point[0] == cell.fetch(:min_column) ||
      point[0] == cell.fetch(:max_column) ||
      point[1] == cell.fetch(:min_row) ||
      point[1] == cell.fetch(:max_row)
  end

  def point_strictly_inside_axis_edge?(point, from, to)
    return false if point == from || point == to

    if from[1] == to[1]
      point[1] == from[1] && point[0].between?(*sorted_exclusive_bounds(from[0], to[0]))
    else
      point[0] == from[0] && point[1].between?(*sorted_exclusive_bounds(from[1], to[1]))
    end
  end

  def sorted_exclusive_bounds(first, second)
    min, max = [first, second].sort
    [min + 1, max - 1]
  end

  def full_grid_face_count(state)
    (state.dimensions.fetch('columns') - 1) * (state.dimensions.fetch('rows') - 1) * 2
  end
end
