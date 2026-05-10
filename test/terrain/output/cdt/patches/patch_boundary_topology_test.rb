# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_boundary_topology'

class PatchBoundaryTopologyTest < Minitest::Test
  include PatchCdtTestSupport

  def test_builds_stable_clockwise_hard_boundary_segments
    topology = build_topology(max_point_budget: 128)

    assert_equal(
      %w[
        patch_boundary:south
        patch_boundary:east
        patch_boundary:north
        patch_boundary:west
      ],
      topology.fetch(:segments).map { |segment| segment.fetch(:id) }
    )
    topology.fetch(:segments).each do |segment|
      assert_equal('hard', segment.fetch(:strength))
      assert_equal('patch_boundary', segment.fetch(:source))
    end
    assert_equal('ok', topology.fetch(:budgetStatus))
    assert_json_safe(topology)
  end

  def test_boundary_anchor_policy_uses_coarse_budgeted_anchors_not_every_perimeter_sample
    state = patch_state(columns: 65, rows: 65)
    domain = SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: state,
      window: patch_window(min_column: 8, min_row: 8, max_column: 56, max_row: 56)
    )
    topology = SU_MCP::Terrain::PatchBoundaryTopology.build(
      domain: domain,
      feature_geometry: empty_feature_geometry,
      max_point_budget: 512
    )

    perimeter_sample_count = ((domain.width_samples + domain.height_samples) * 2) - 4
    assert_operator(topology.fetch(:anchors).length, :<, perimeter_sample_count)
    assert_operator(topology.fetch(:anchors).length, :<=, 64)
    assert_operator(topology.fetch(:diagnostics).fetch(:maxSubdivisionsPerEdge), :<=, 8)
  end

  def test_boundary_budget_exceeded_returns_deterministic_fallback_evidence
    topology = build_topology(max_point_budget: 3)

    assert_equal('boundary_budget_exceeded', topology.fetch(:budgetStatus))
    assert_equal('boundary_budget_exceeded', topology.fetch(:fallbackReason))
    assert_operator(topology.fetch(:diagnostics).fetch(:requiredAnchorCount), :>,
                    topology.fetch(:diagnostics).fetch(:boundaryAnchorBudget))
  end

  def test_required_feature_boundary_intersections_are_counted_outside_coarse_budget
    topology = build_topology(feature_geometry: boundary_feature_geometry, max_point_budget: 128)

    assert_operator(topology.fetch(:diagnostics).fetch(:requiredFeatureIntersectionCount), :>, 0)
    assert(
      topology.fetch(:anchors).any? { |anchor| anchor.fetch(:source) == 'feature_intersection' },
      'expected clipped feature-boundary intersections to become mandatory anchors'
    )
  end

  private

  def build_topology(max_point_budget:, feature_geometry: empty_feature_geometry)
    SU_MCP::Terrain::PatchBoundaryTopology.build(
      domain: SU_MCP::Terrain::PatchCdtDomain.from_window(
        state: patch_state(columns: 11, rows: 11),
        window: patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5)
      ),
      feature_geometry: feature_geometry,
      max_point_budget: max_point_budget
    )
  end
end
