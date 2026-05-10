# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_height_error_meter'

class PatchHeightErrorMeterTest < Minitest::Test
  include PatchCdtTestSupport

  def test_measures_only_patch_samples_and_reports_quality_metrics
    state = patch_state(columns: 9, rows: 9)
    domain = SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: state,
      window: patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5),
      margin_samples: 0
    )
    metrics = SU_MCP::Terrain::PatchHeightErrorMeter.new.measure(
      state: state,
      domain: domain,
      mesh: flat_mesh_for(domain),
      base_tolerance: 0.05,
      feature_geometry: empty_feature_geometry
    )

    assert_equal(9, metrics.fetch(:scanSampleCount))
    assert_operator(metrics.fetch(:maxHeightError), :>, 0.0)
    assert_operator(metrics.fetch(:rmsError), :>, 0.0)
    assert_operator(metrics.fetch(:p95Error), :>, 0.0)
    assert_operator(metrics.fetch(:denseRatio), :<, 1.0)
    assert_equal([4, 4], metrics.fetch(:worstSamples).first.fetch(:sample))
    assert_json_safe(metrics)
  end

  private

  def flat_mesh_for(domain)
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
