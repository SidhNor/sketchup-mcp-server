# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_boundary_topology'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_topology_quality_meter'

class PatchTopologyQualityMeterTest < Minitest::Test
  include PatchCdtTestSupport

  def test_accepts_contained_boundary_preserving_patch_mesh
    result = meter.measure(domain: domain, boundary: boundary, mesh: regular_mesh)

    assert(result.fetch(:passed))
    assert_equal(0, result.fetch(:outOfDomainVertexCount))
    assert_equal(0, result.fetch(:degenerateTriangleCount))
    assert_equal(0, result.fetch(:nonManifoldEdgeCount))
    assert_in_delta(1.0, result.fetch(:areaCoverageRatio), 0.001)
  end

  def test_rejects_folded_or_overlapping_patch_mesh
    result = meter.measure(domain: domain, boundary: boundary, mesh: folded_mesh)

    refute(result.fetch(:passed))
    assert_operator(result.fetch(:areaCoverageRatio), :>, 1.02)
  end

  private

  def meter
    SU_MCP::Terrain::PatchTopologyQualityMeter.new
  end

  def domain
    @domain ||= SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: patch_state(columns: 9, rows: 9),
      window: patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5)
    )
  end

  def boundary
    @boundary ||= SU_MCP::Terrain::PatchBoundaryTopology.build(
      domain: domain,
      feature_geometry: empty_feature_geometry,
      max_point_budget: 128
    )
  end

  def regular_mesh
    vertices = []
    (1..7).each do |row|
      (1..7).each { |column| vertices << [column.to_f, row.to_f, 0.0] }
    end
    triangles = []
    (0...6).each do |row|
      (0...6).each do |column|
        lower_left = (row * 7) + column
        lower_right = lower_left + 1
        upper_left = lower_left + 7
        upper_right = upper_left + 1
        triangles << [lower_left, lower_right, upper_right]
        triangles << [lower_left, upper_right, upper_left]
      end
    end
    { vertices: vertices, triangles: triangles }
  end

  def folded_mesh
    {
      vertices: [[1.0, 1.0, 0.0], [7.0, 1.0, 0.0], [7.0, 7.0, 0.0], [1.0, 7.0, 0.0]],
      triangles: [[0, 1, 2], [0, 1, 2], [0, 2, 3]]
    }
  end
end
