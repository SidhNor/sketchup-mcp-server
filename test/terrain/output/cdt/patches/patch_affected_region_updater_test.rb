# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
# rubocop:disable Layout/LineLength
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_affected_region_updater'
# rubocop:enable Layout/LineLength
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_boundary_topology'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'

class PatchAffectedRegionUpdaterTest < Minitest::Test
  include PatchCdtTestSupport

  def test_inserts_point_by_retriangulating_only_affected_local_cavity
    result = SU_MCP::Terrain::PatchAffectedRegionUpdater.new.insert(
      triangulation: triangulation,
      point: [4.0, 4.0],
      domain: domain,
      boundary_segments: boundary_topology.fetch(:segments)
    )
    diagnostics = result.fetch(:diagnostics)

    assert_equal('accepted', result.fetch(:status))
    assert_equal(false, diagnostics.fetch(:rebuildDetected))
    assert_equal('affected', diagnostics.fetch(:recomputationScope))
    assert_operator(diagnostics.fetch(:affectedTriangleCount), :>, 0)
    assert_operator(diagnostics.fetch(:removedTriangleCount), :>, 0)
    assert_operator(diagnostics.fetch(:createdTriangleCount), :>, 0)
    assert_equal(4, diagnostics.fetch(:beforePointCount))
    assert_equal(5, diagnostics.fetch(:afterPointCount))
    assert_json_safe(result)
  end

  def test_rejects_out_of_domain_insertions_with_boundary_failure_evidence
    result = SU_MCP::Terrain::PatchAffectedRegionUpdater.new.insert(
      triangulation: triangulation,
      point: [99.0, 99.0],
      domain: domain,
      boundary_segments: boundary_topology.fetch(:segments)
    )

    assert_equal('fallback', result.fetch(:status))
    assert_equal('out_of_domain_vertex', result.fetch(:reason))
    assert_equal('out_of_domain_vertex', result.dig(:diagnostics, :boundaryViolationReason))
  end

  def test_detects_full_patch_rebuild_as_failure_not_success_evidence
    result = SU_MCP::Terrain::PatchAffectedRegionUpdater.new.insert(
      triangulation: triangulation,
      point: [4.0, 4.0],
      domain: domain,
      boundary_segments: boundary_topology.fetch(:segments),
      force_rebuild_detection: true
    )

    assert_equal('fallback', result.fetch(:status))
    assert_equal('affected_region_update_failed', result.fetch(:reason))
    assert_equal(true, result.dig(:diagnostics, :rebuildDetected))
  end

  private

  def domain
    @domain ||= SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: patch_state(columns: 9, rows: 9),
      window: patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5)
    )
  end

  def boundary_topology
    @boundary_topology ||= SU_MCP::Terrain::PatchBoundaryTopology.build(
      domain: domain,
      feature_geometry: empty_feature_geometry,
      max_point_budget: 128
    )
  end

  def triangulation
    bounds = domain.owner_local_bounds
    {
      vertices: [
        [bounds.fetch(:minX), bounds.fetch(:minY)],
        [bounds.fetch(:maxX), bounds.fetch(:minY)],
        [bounds.fetch(:maxX), bounds.fetch(:maxY)],
        [bounds.fetch(:minX), bounds.fetch(:maxY)]
      ],
      triangles: [[0, 1, 2], [0, 2, 3]],
      constrainedEdges: [],
      constrainedEdgeCoverage: 1.0,
      limitations: []
    }
  end
end
