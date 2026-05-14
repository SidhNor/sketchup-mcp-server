# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/cdt_patch_policy'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/stable_domain_cdt_solver'

class StableDomainCdtSolverTest < Minitest::Test
  Call = Struct.new(:state, :feature_geometry, keyword_init: true)

  def test_solves_replacement_patch_through_cdt_backend
    backend = RecordingPatchBackend.new
    solver = SU_MCP::Terrain::StableDomainCdtSolver.new(cdt_backend: backend)

    result = solver.solve(
      state: state,
      replacement_patches: [patch],
      retained_boundary_spans: [
        { side: 'west', patchId: 'cdt-patch-v1-c1-r0', fresh: true,
          vertices: [[16.0, 0.0, 1.0], [16.0, 16.0, 1.0]] }
      ],
      feature_geometry: Object.new
    )

    assert_equal('accepted', result.fetch(:status))
    assert_equal(1, backend.calls.length)
    assert_equal({ 'columns' => 17, 'rows' => 17 }, backend.calls.first.state.dimensions)
    assert_equal({ 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 }, backend.calls.first.state.origin)
    assert_equal([[0, 1, 2], [0, 2, 3]], result.fetch(:mesh).fetch(:triangles))
    assert(
      result.fetch(:borderSpans).any? do |span|
        span.fetch(:side) == 'east' && span.fetch(:patchId) == 'cdt-patch-v1-c0-r0'
      end
    )
  end

  def test_failed_backend_result_returns_failed_solver_result
    solver = SU_MCP::Terrain::StableDomainCdtSolver.new(
      cdt_backend: RecordingPatchBackend.new(status: 'fallback')
    )

    result = solver.solve(
      state: state,
      replacement_patches: [patch],
      retained_boundary_spans: [],
      feature_geometry: Object.new
    )

    assert_equal('failed', result.fetch(:status))
    assert_equal('topology_gate_failed', result.fetch(:stopReason))
    assert_empty(result.fetch(:mesh).fetch(:vertices))
  end

  def test_retained_boundary_spans_only_emit_adjacent_replacement_sides
    solver = SU_MCP::Terrain::StableDomainCdtSolver.new(
      cdt_backend: RecordingPatchBackend.new
    )

    result = solver.solve(
      state: state,
      replacement_patches: [patch_at(1, 1), patch_at(2, 1)],
      retained_boundary_spans: [
        { side: 'east', patchId: 'cdt-patch-v1-c0-r1', fresh: true,
          vertices: [[16.0, 20.0, 1.0], [16.0, 28.0, 1.0]] },
        { side: 'east', patchId: 'cdt-patch-v1-c0-r1', fresh: true,
          vertices: [[16.0, 16.0, 1.0], [16.0, 32.0, 1.0]] },
        { side: 'west', patchId: 'cdt-patch-v1-c3-r1', fresh: true,
          vertices: [[48.0, 16.0, 1.0], [48.0, 32.0, 1.0]] }
      ],
      feature_geometry: Object.new
    )

    spans = result.fetch(:borderSpans)
    assert_equal(
      [
        %w[cdt-patch-v1-c1-r1 west],
        %w[cdt-patch-v1-c2-r1 east]
      ],
      spans.map { |span| [span.fetch(:patchId), span.fetch(:side)] }
    )
    refute(
      spans.flat_map { |span| span.fetch(:vertices).each_cons(2).to_a }
           .any? { |first, second| [first.fetch(0), second.fetch(0)] == [32.0, 32.0] },
      'internal shared replacement edge must not be emitted as a retained-boundary span'
    )
  end

  def test_filters_patch_local_feature_geometry_per_replacement_patch
    backend = RecordingPatchBackend.new
    solver = SU_MCP::Terrain::StableDomainCdtSolver.new(cdt_backend: backend)
    feature_geometry = SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        {
          'id' => 'anchor-west',
          'role' => 'survey_anchor',
          'strength' => 'firm',
          'ownerLocalPoint' => [4.0, 4.0],
          'gridPoint' => [4, 4]
        },
        {
          'id' => 'anchor-east',
          'role' => 'survey_anchor',
          'strength' => 'firm',
          'ownerLocalPoint' => [20.0, 4.0],
          'gridPoint' => [20, 4]
        }
      ],
      referenceSegments: [
        {
          'id' => 'local-segment',
          'ownerLocalStart' => [0.0, 8.0],
          'ownerLocalEnd' => [12.0, 8.0],
          'strength' => 'firm'
        },
        {
          'id' => 'far-segment',
          'ownerLocalStart' => [40.0, 8.0],
          'ownerLocalEnd' => [45.0, 8.0],
          'strength' => 'firm'
        }
      ]
    )

    solver.solve(
      state: state,
      replacement_patches: [patch_at(0, 0), patch_at(1, 0)],
      retained_boundary_spans: [],
      feature_geometry: feature_geometry
    )

    anchors_by_call = backend.calls.map do |call|
      source_anchor_ids(call.feature_geometry)
    end
    segments_by_call = backend.calls.map do |call|
      call.feature_geometry.reference_segments.map { |segment| segment.fetch('id') }
    end
    assert_equal([['anchor-west'], ['anchor-east']], anchors_by_call)
    assert_equal([['local-segment'], []], segments_by_call)
  end

  def test_replacement_patch_solves_get_matching_boundary_sample_anchors
    backend = RecordingPatchBackend.new
    solver = SU_MCP::Terrain::StableDomainCdtSolver.new(cdt_backend: backend)

    solver.solve(
      state: state,
      replacement_patches: [patch_at(0, 0), patch_at(1, 0)],
      retained_boundary_spans: [],
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
    )

    west_patch, east_patch = backend.calls.map(&:feature_geometry)
    west_boundary = boundary_anchor_points(west_patch).select do |point|
      near?(point.fetch(0), 16.0)
    end
    east_boundary = boundary_anchor_points(east_patch).select do |point|
      near?(point.fetch(0), 16.0)
    end
    assert_equal(2, backend.calls.length)
    assert_equal((0..16).map { |row| [16.0, row.to_f] }, west_boundary)
    assert_equal(west_boundary, east_boundary)
  end

  def test_internal_replacement_boundaries_are_resolved_from_actual_patch_vertices
    backend = BoundaryEchoBackend.new(extra_first_pass_boundary_point: [16.0, 2.5, 1.0])
    solver = SU_MCP::Terrain::StableDomainCdtSolver.new(cdt_backend: backend)

    solver.solve(
      state: state,
      replacement_patches: [patch_at(0, 0), patch_at(1, 0)],
      retained_boundary_spans: [],
      feature_geometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
    )

    assert_operator(backend.calls.length, :>=, 4)
    final_west, final_east = backend.calls.last(2).map(&:feature_geometry)
    assert_includes(boundary_anchor_points(final_west), [16.0, 2.5])
    assert_includes(boundary_anchor_points(final_east), [16.0, 2.5])
  end

  def test_patch_local_feature_filter_uses_state_origin_and_spacing
    backend = RecordingPatchBackend.new
    solver = SU_MCP::Terrain::StableDomainCdtSolver.new(cdt_backend: backend)
    shifted_state = state_with_origin_and_spacing(
      origin: { 'x' => 100.0, 'y' => 200.0, 'z' => 0.0 },
      spacing: { 'x' => 2.0, 'y' => 3.0 }
    )
    feature_geometry = SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        {
          'id' => 'shifted-local',
          'role' => 'survey_anchor',
          'strength' => 'firm',
          'ownerLocalPoint' => [110.0, 212.0],
          'gridPoint' => [5, 4]
        },
        {
          'id' => 'shifted-far',
          'role' => 'survey_anchor',
          'strength' => 'firm',
          'ownerLocalPoint' => [155.0, 212.0],
          'gridPoint' => [27, 4]
        }
      ]
    )

    solver.solve(
      state: shifted_state,
      replacement_patches: [
        patch_at(0, 0, shifted_state),
        patch_at(1, 0, shifted_state)
      ],
      retained_boundary_spans: [],
      feature_geometry: feature_geometry
    )

    assert_equal(
      [['shifted-local'], ['shifted-far']],
      backend.calls.map do |call|
        source_anchor_ids(call.feature_geometry)
      end
    )
  end

  private

  def state
    @state ||= SU_MCP::Terrain::TiledHeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z'
      },
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 50, 'rows' => 50 },
      elevations: Array.new(2500, 1.0),
      revision: 1,
      state_id: 'solver-state'
    )
  end

  def patch
    patch_at(0, 0)
  end

  def state_with_origin_and_spacing(origin:, spacing:)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z'
      },
      origin: origin,
      spacing: spacing,
      dimensions: { 'columns' => 50, 'rows' => 50 },
      elevations: Array.new(2500, 1.0),
      revision: 1,
      state_id: 'shifted-solver-state'
    )
  end

  def patch_at(column, row, source_state = state)
    SU_MCP::Terrain::CdtPatchPolicy.new.patch_domain(column, row, source_state.dimensions)
  end

  def source_anchor_ids(feature_geometry)
    feature_geometry.output_anchor_candidates
                    .reject { |anchor| anchor.fetch('role') == 'patch_boundary' }
                    .map { |anchor| anchor.fetch('id') }
  end

  def boundary_anchor_points(feature_geometry)
    feature_geometry.output_anchor_candidates
                    .select { |anchor| anchor.fetch('role') == 'patch_boundary' }
                    .map { |anchor| anchor.fetch('ownerLocalPoint') }
                    .sort_by { |point| [point.fetch(0), point.fetch(1)] }
  end

  def near?(actual, expected)
    (actual - expected).abs <= 1e-9
  end

  class RecordingPatchBackend
    attr_reader :calls

    def initialize(status: 'accepted')
      @status = status
      @calls = []
    end

    def build(state:, feature_geometry:, **)
      @calls << Call.new(state: state, feature_geometry: feature_geometry)
      return fallback_result unless @status == 'accepted'

      x0 = state.origin.fetch('x')
      y0 = state.origin.fetch('y')
      x1 = x0 + ((state.dimensions.fetch('columns') - 1) * state.spacing.fetch('x'))
      y1 = y0 + ((state.dimensions.fetch('rows') - 1) * state.spacing.fetch('y'))
      {
        status: 'accepted',
        mesh: {
          vertices: [
            [x0, y0, 1.0],
            [x1, y0, 1.0],
            [x1, y1, 1.0],
            [x0, y1, 1.0]
          ],
          triangles: [[0, 1, 2], [0, 2, 3]]
        },
        metrics: { maxHeightError: 0.0 }
      }
    end

    def fallback_result
      {
        status: 'fallback',
        fallbackReason: 'topology_gate_failed',
        mesh: { vertices: [], triangles: [] }
      }
    end
  end

  class BoundaryEchoBackend
    attr_reader :calls

    def initialize(extra_first_pass_boundary_point:)
      @extra_first_pass_boundary_point = extra_first_pass_boundary_point
      @calls = []
    end

    def build(state:, feature_geometry:, **)
      calls << Call.new(state: state, feature_geometry: feature_geometry)
      vertices = rectangle_vertices(state)
      vertices << @extra_first_pass_boundary_point if calls.length == 1
      vertices.concat(boundary_anchor_vertices(state, feature_geometry))
      vertices.uniq!
      {
        status: 'accepted',
        mesh: {
          vertices: vertices,
          triangles: [[0, 1, 2], [0, 2, 3]]
        },
        metrics: { maxHeightError: 0.0 }
      }
    end

    private

    def rectangle_vertices(state)
      x0 = state.origin.fetch('x')
      y0 = state.origin.fetch('y')
      x1 = x0 + ((state.dimensions.fetch('columns') - 1) * state.spacing.fetch('x'))
      y1 = y0 + ((state.dimensions.fetch('rows') - 1) * state.spacing.fetch('y'))
      [[x0, y0, 1.0], [x1, y0, 1.0], [x1, y1, 1.0], [x0, y1, 1.0]]
    end

    def boundary_anchor_vertices(state, feature_geometry)
      bounds = rectangle_vertices(state)
      x_values = bounds.map { |point| point.fetch(0) }
      y_values = bounds.map { |point| point.fetch(1) }
      min_x, max_x = x_values.minmax
      min_y, max_y = y_values.minmax
      feature_geometry.output_anchor_candidates.filter_map do |anchor|
        point = anchor.fetch('ownerLocalPoint')
        next unless near?(point.fetch(0), min_x) || near?(point.fetch(0), max_x) ||
                    near?(point.fetch(1), min_y) || near?(point.fetch(1), max_y)

        [point.fetch(0), point.fetch(1), 1.0]
      end
    end

    def near?(actual, expected)
      (actual - expected).abs <= 1e-9
    end
  end
end
