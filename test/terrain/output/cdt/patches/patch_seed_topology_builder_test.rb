# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_boundary_topology'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_seed_topology_builder'

class PatchSeedTopologyBuilderTest < Minitest::Test
  include PatchCdtTestSupport

  def test_builds_seed_topology_from_patch_boundary_and_relevant_features
    seed = SU_MCP::Terrain::PatchSeedTopologyBuilder.build(
      domain: domain,
      boundary_topology: boundary_topology,
      feature_geometry: patch_feature_geometry
    )

    assert_operator(seed.fetch(:points).length, :>, boundary_topology.fetch(:anchors).length)
    assert_operator(seed.fetch(:segments).length, :>=, 4)
    assert_equal(1, seed.dig(:featureParticipation, :includedAnchorCount))
    assert_equal(1, seed.dig(:featureParticipation, :excludedAnchorCount))
    assert_equal(1, seed.dig(:featureParticipation, :intersectingSegmentCount))
    assert_json_safe(seed)
  end

  def test_seed_topology_does_not_import_full_terrain_corners_or_all_patch_perimeter_samples
    seed = SU_MCP::Terrain::PatchSeedTopologyBuilder.build(
      domain: domain,
      boundary_topology: boundary_topology,
      feature_geometry: empty_feature_geometry
    )

    full_terrain_corners = [[0.0, 0.0], [10.0, 0.0], [10.0, 10.0], [0.0, 10.0]]
    full_terrain_corners.each { |point| refute_includes(seed.fetch(:points), point) }
    assert_operator(seed.fetch(:points).length, :<, domain.patch_sample_count)
  end

  private

  def domain
    @domain ||= SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: patch_state(columns: 11, rows: 11),
      window: patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5)
    )
  end

  def boundary_topology
    @boundary_topology ||= SU_MCP::Terrain::PatchBoundaryTopology.build(
      domain: domain,
      feature_geometry: patch_feature_geometry,
      max_point_budget: 128
    )
  end
end
