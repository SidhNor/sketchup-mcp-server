# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/terrain_output_cell_window'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_policy'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_resolver'

class AdaptivePatchResolverTest < Minitest::Test
  def test_dirty_window_maps_to_affected_patch_and_immediate_conformance_ring
    result = resolver(patch_cell_size: 4, conformance_ring: 1, columns: 12, rows: 12)
             .resolve(cell_window: cell_window(5, 5, 5, 5))

    assert_equal(['adaptive-patch-v1-c1-r1'], result.fetch(:affectedPatchIds))
    assert_equal(
      %w[
        adaptive-patch-v1-c0-r0 adaptive-patch-v1-c1-r0 adaptive-patch-v1-c2-r0
        adaptive-patch-v1-c0-r1 adaptive-patch-v1-c1-r1 adaptive-patch-v1-c2-r1
        adaptive-patch-v1-c0-r2 adaptive-patch-v1-c1-r2 adaptive-patch-v1-c2-r2
      ].sort,
      result.fetch(:replacementPatchIds).sort
    )
  end

  def test_patch_boundary_dirty_window_selects_both_overlapped_stable_patches
    result = resolver(patch_cell_size: 4, columns: 12, rows: 12)
             .resolve(cell_window: cell_window(3, 1, 4, 1))

    assert_equal(
      %w[adaptive-patch-v1-c0-r0 adaptive-patch-v1-c1-r0],
      result.fetch(:affectedPatchIds).sort
    )
  end

  def test_corner_window_clips_conformance_ring_to_output_grid
    result = resolver(patch_cell_size: 4, conformance_ring: 1, columns: 8, rows: 8)
             .resolve(cell_window: cell_window(0, 0, 0, 0))

    assert_equal(['adaptive-patch-v1-c0-r0'], result.fetch(:affectedPatchIds))
    assert_equal(
      %w[
        adaptive-patch-v1-c0-r0 adaptive-patch-v1-c1-r0
        adaptive-patch-v1-c0-r1 adaptive-patch-v1-c1-r1
      ].sort,
      result.fetch(:replacementPatchIds).sort
    )
  end

  private

  def resolver(patch_cell_size:, columns:, rows:, conformance_ring: 1)
    policy = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchPolicy.new(
      patch_cell_size: patch_cell_size,
      conformance_ring: conformance_ring
    )
    SU_MCP::Terrain::AdaptivePatches::AdaptivePatchResolver.new(
      policy: policy,
      dimensions: { 'columns' => columns, 'rows' => rows }
    )
  end

  def cell_window(min_column, min_row, max_column, max_row)
    SU_MCP::Terrain::TerrainOutputCellWindow.new(
      {
        min_column: min_column,
        min_row: min_row,
        max_column: max_column,
        max_row: max_row
      },
      full_bounds: { max_column: 10, max_row: 10 }
    )
  end
end
