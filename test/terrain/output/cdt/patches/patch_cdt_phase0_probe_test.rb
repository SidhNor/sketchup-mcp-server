# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_local_cdt_proof'

class PatchCdtPhase0ProbeTest < Minitest::Test
  include PatchCdtTestSupport

  def test_phase0_probe_covers_required_fixture_classes_before_updater_hardening
    evidence = SU_MCP::Terrain::PatchLocalCdtProof.phase0_probe_evidence(
      fixtures: phase0_fixtures
    )

    assert_equal(
      %w[flat_smooth rough_high_relief boundary_constraint feature_intersection],
      evidence.fetch(:fixtureClasses).map { |item| item.fetch(:fixtureClass) }
    )
    assert_equal(true, evidence.fetch(:thresholdsFrozen))
    assert(evidence.fetch(:thresholds).key?(:maxPatchSeconds))
    assert_json_safe(evidence)
  end

  private

  def phase0_fixtures
    {
      flat_smooth: {
        state: flat_state,
        feature_geometry: empty_feature_geometry,
        output_plan: dirty_output_plan(state: flat_state)
      },
      rough_high_relief: {
        state: rough_state,
        feature_geometry: empty_feature_geometry,
        output_plan: dirty_output_plan(state: rough_state)
      },
      boundary_constraint: {
        state: patch_state,
        feature_geometry: boundary_feature_geometry,
        output_plan: dirty_output_plan(state: patch_state)
      },
      feature_intersection: {
        state: patch_state,
        feature_geometry: patch_feature_geometry,
        output_plan: dirty_output_plan(state: patch_state)
      }
    }
  end
end
