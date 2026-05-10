# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'

class PatchCdtDomainTest < Minitest::Test
  include PatchCdtTestSupport

  def test_derives_bounded_patch_domain_from_dirty_window_with_clipped_margin
    domain = SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: patch_state(columns: 9, rows: 9),
      window: patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5),
      margin_samples: 2
    )

    assert_equal(
      {
        minColumn: 1,
        minRow: 1,
        maxColumn: 7,
        maxRow: 7,
        dirty: { minColumn: 3, minRow: 3, maxColumn: 5, maxRow: 5 }
      },
      domain.sample_bounds
    )
    assert_equal({ minX: 1.0, minY: 1.0, maxX: 7.0, maxY: 7.0 }, domain.owner_local_bounds)
    assert_equal(49, domain.patch_sample_count)
    assert(domain.contains_sample?(column: 4, row: 4))
    refute(domain.contains_sample?(column: 8, row: 8))
    assert_json_safe(domain.to_h)
  end

  def test_margin_clips_to_source_dimensions_without_expanding_to_full_terrain_unnecessarily
    domain = SU_MCP::Terrain::PatchCdtDomain.from_window(
      state: patch_state(columns: 20, rows: 20),
      window: patch_window(min_column: 0, min_row: 0, max_column: 1, max_row: 1),
      margin_samples: 2
    )

    assert_equal(0, domain.sample_bounds.fetch(:minColumn))
    assert_equal(0, domain.sample_bounds.fetch(:minRow))
    assert_equal(3, domain.sample_bounds.fetch(:maxColumn))
    assert_equal(3, domain.sample_bounds.fetch(:maxRow))
    assert_operator(domain.patch_sample_count, :<, 20 * 20)
  end

  def test_empty_dirty_window_is_refused_before_domain_construction
    error = assert_raises(SU_MCP::Terrain::PatchCdtDomain::InvalidDomain) do
      SU_MCP::Terrain::PatchCdtDomain.from_window(
        state: patch_state,
        window: SU_MCP::Terrain::SampleWindow.new(empty: true)
      )
    end

    assert_equal('empty_dirty_window', error.reason)
  end
end
