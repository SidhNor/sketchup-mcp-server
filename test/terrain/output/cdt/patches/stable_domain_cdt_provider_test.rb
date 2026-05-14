# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/terrain_output_cell_window'
require_relative '../../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_grid_policy'
require_relative '../../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_window_resolver'

begin
  require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/cdt_patch_batch_plan'
  require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/' \
                   'stable_domain_cdt_replacement_provider'
rescue LoadError
  # Skeleton phase: implementation must introduce these PatchLifecycle-native seams.
end

class StableDomainCdtProviderTest < Minitest::Test
  include PatchCdtTestSupport

  def test_accepted_replacement_uses_lifecycle_batch_plan
    assert(defined?(SU_MCP::Terrain::CdtPatchBatchPlan), 'CdtPatchBatchPlan must exist')
    assert(
      defined?(SU_MCP::Terrain::StableDomainCdtReplacementProvider),
      'StableDomainCdtReplacementProvider must exist'
    )

    solver = RecordingStableDomainSolver.new(mesh: accepted_mesh)
    result = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(solver: solver).build(
      batch_plan: cdt_batch_plan,
      state: state,
      feature_geometry: patch_feature_geometry
    )

    assert(result.accepted?)
    assert_equal(['cdt-patch-v1-c0-r0'], result.affected_patch_ids)
    assert_includes(result.replacement_patch_ids, 'cdt-patch-v1-c1-r1')
    assert_equal(cdt_batch_plan.replacement_patches, solver.last_input.fetch(:replacement_patches))
    refute_includes(JSON.generate(result.to_h), 'patchDomainDigest')
    refute_includes(JSON.generate(result.to_h), 'debugMesh')
  end

  def test_provider_declines_solver_acceptance_with_duplicate_triangles
    solver = RecordingStableDomainSolver.new(
      mesh: accepted_mesh.merge(triangles: [[0, 1, 2], [2, 1, 0]])
    )

    result = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(solver: solver).build(
      batch_plan: cdt_batch_plan,
      state: state,
      feature_geometry: patch_feature_geometry
    )

    refute(result.accepted?)
    assert_equal('duplicate_triangles', result.stop_reason)
  end

  def test_provider_declines_solver_acceptance_with_out_of_domain_vertices
    solver = RecordingStableDomainSolver.new(
      mesh: accepted_mesh.merge(
        vertices: [
          [0.0, 0.0, 0.0],
          [100.0, 0.0, 0.0],
          [100.0, 16.0, 0.0]
        ],
        triangles: [[0, 1, 2]]
      )
    )

    result = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(solver: solver).build(
      batch_plan: cdt_batch_plan,
      state: state,
      feature_geometry: patch_feature_geometry
    )

    refute(result.accepted?)
    assert_equal('out_of_domain_geometry', result.stop_reason)
  end

  def test_provider_acceptance_uses_state_origin_and_spacing_for_domain_bounds
    shifted_state = SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 100.0, 'y' => 200.0, 'z' => 0.0 },
      spacing: { 'x' => 2.0, 'y' => 3.0 },
      dimensions: { 'columns' => 50, 'rows' => 50 },
      elevations: Array.new(2500, 0.0),
      revision: 1,
      state_id: 'shifted-state'
    )
    solver = RecordingStableDomainSolver.new(
      mesh: {
        vertices: [[100.0, 200.0, 0.0], [132.0, 200.0, 0.0], [132.0, 248.0, 0.0]],
        triangles: [[0, 1, 2]]
      }
    )

    result = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(solver: solver).build(
      batch_plan: cdt_batch_plan(state: shifted_state),
      state: shifted_state,
      feature_geometry: patch_feature_geometry
    )

    assert(result.accepted?)
  end

  def test_provider_declines_duplicate_boundary_edges_before_mutation
    solver = RecordingStableDomainSolver.new(
      mesh: accepted_mesh,
      border_spans: [
        border_span([[16.0, 0.0, 0.0], [16.0, 16.0, 0.0]]),
        border_span([[16.0, 16.0, 0.0], [16.0, 0.0, 0.0]], span_id: 'east-1')
      ]
    )

    result = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(solver: solver).build(
      batch_plan: cdt_batch_plan,
      state: state,
      feature_geometry: patch_feature_geometry
    )

    refute(result.accepted?)
    assert_equal('duplicate_boundary_edges', result.stop_reason)
  end

  def test_provider_declines_stale_retained_boundary_evidence
    solver = RecordingStableDomainSolver.new(mesh: accepted_mesh)

    result = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(solver: solver).build(
      batch_plan: cdt_batch_plan(
        retained_boundary_spans: [border_span([[16.0, 0.0, 0.0], [16.0, 16.0, 0.0]],
                                              fresh: false)]
      ),
      state: state,
      feature_geometry: patch_feature_geometry
    )

    refute(result.accepted?)
    assert_equal('stale_retained_faces', result.stop_reason)
  end

  def test_provider_declines_solver_reported_seam_z_mismatch
    solver = RecordingStableDomainSolver.new(
      mesh: accepted_mesh,
      seam_validation: { status: 'failed', reason: 'z_tolerance_exceeded', maxZGap: 0.2 }
    )

    result = SU_MCP::Terrain::StableDomainCdtReplacementProvider.new(solver: solver).build(
      batch_plan: cdt_batch_plan,
      state: state,
      feature_geometry: patch_feature_geometry
    )

    refute(result.accepted?)
    assert_equal('seam_z_mismatch', result.stop_reason)
  end

  private

  def cdt_batch_plan(state: self.state, retained_boundary_spans: [])
    SU_MCP::Terrain::CdtPatchBatchPlan.from_lifecycle_resolution(
      lifecycle_resolution: lifecycle_resolution(state),
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      feature_plan: { selectedFeaturePool: [], patchFeatureBundles: {} },
      retained_boundary_spans: retained_boundary_spans
    )
  end

  def lifecycle_resolution(state = self.state)
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    resolver = SU_MCP::Terrain::PatchLifecycle::PatchWindowResolver.new(
      policy: policy,
      dimensions: state.dimensions
    )
    resolver.resolve(
      cell_window: SU_MCP::Terrain::TerrainOutputCellWindow.new(
        { min_column: 0, min_row: 0, max_column: 1, max_row: 1 }
      )
    )
  end

  def state
    @state ||= patch_state(columns: 50, rows: 50)
  end

  def accepted_mesh
    {
      vertices: [
        [0.0, 0.0, 0.0],
        [16.0, 0.0, 0.0],
        [16.0, 16.0, 0.0],
        [0.0, 16.0, 0.0]
      ],
      triangles: [[0, 1, 2], [0, 2, 3]]
    }
  end

  def border_span(vertices, fresh: true, span_id: 'east-0')
    {
      side: 'east',
      spanId: span_id,
      patchId: 'cdt-patch-v1-c0-r0',
      fresh: fresh,
      vertices: vertices
    }
  end

  class RecordingStableDomainSolver
    attr_reader :last_input

    def initialize(mesh:, border_spans: [], seam_validation: nil)
      @mesh = mesh
      @border_spans = border_spans
      @seam_validation = seam_validation
    end

    def solve(**input)
      @last_input = input
      result = {
        status: 'accepted',
        mesh: @mesh,
        topology: { passed: true },
        residualQuality: { maxHeightError: 0.0 },
        borderSpans: @border_spans
      }
      result[:seamValidation] = @seam_validation if @seam_validation
      result
    end
  end
end
