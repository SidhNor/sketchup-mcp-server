# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_height_error_meter'
# rubocop:disable Layout/LineLength
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_residual_candidate_tracker'
# rubocop:enable Layout/LineLength

class PatchResidualCandidateTrackerTest < Minitest::Test
  include PatchCdtTestSupport

  def test_initial_and_final_scans_may_scan_full_patch_for_quality_evidence
    tracker = tracker_for(rough_state)

    initial = tracker.initial_scan(mesh: flat_mesh)
    final = tracker.final_scan(mesh: flat_mesh)

    assert_equal(domain.patch_sample_count, initial.fetch(:scanSampleCount))
    assert_equal(domain.patch_sample_count, final.fetch(:scanSampleCount))
    assert_equal('full_patch_initial', initial.fetch(:recomputationScope))
    assert_equal('full_patch_final', final.fetch(:recomputationScope))
  end

  def test_after_insertion_recomputation_is_bounded_by_affected_triangle_multiplier
    tracker = tracker_for(rough_state)
    result = tracker.recompute_after_update(
      mesh: flat_mesh,
      affected_triangles: [[0, 1, 2], [0, 2, 3]],
      update_diagnostics: { affectedTriangleCount: 2, recomputationScope: 'affected' }
    )

    assert_equal('affected', result.fetch(:recomputationScope))
    assert_operator(result.fetch(:recomputedSampleCount), :<=, 4)
    refute(result.fetch(:fallback))
  end

  def test_full_patch_recomputation_after_insertion_returns_failure_evidence
    tracker = tracker_for(rough_state)
    result = tracker.recompute_after_update(
      mesh: flat_mesh,
      affected_triangles: [],
      update_diagnostics: { affectedTriangleCount: 2, recomputationScope: 'full' }
    )

    assert(result.fetch(:fallback))
    assert_equal('affected_region_update_failed', result.fetch(:fallbackReason))
    assert_equal('full', result.fetch(:recomputationScope))
  end

  private

  def tracker_for(state)
    SU_MCP::Terrain::PatchResidualCandidateTracker.new(
      state: state,
      domain: domain,
      meter: SU_MCP::Terrain::PatchHeightErrorMeter.new,
      base_tolerance: 0.05,
      feature_geometry: empty_feature_geometry
    )
  end

  def domain
    @domain ||= SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: rough_state,
      window: patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5)
    )
  end

  def flat_mesh
    bounds = domain.owner_local_bounds
    {
      vertices: [
        [bounds.fetch(:minX), bounds.fetch(:minY), 0.0],
        [bounds.fetch(:maxX), bounds.fetch(:minY), 0.0],
        [bounds.fetch(:maxX), bounds.fetch(:maxY), 0.0],
        [bounds.fetch(:minX), bounds.fetch(:maxY), 0.0]
      ],
      triangles: [[0, 1, 2], [0, 2, 3]]
    }
  end
end
