# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/terrain_output_cell_window'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_grid_policy'
require_relative '../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_window_resolver'

class PatchWindowResolverTest < Minitest::Test
  def test_dirty_window_maps_to_configured_patch_kind_and_ring
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_cell_size: 4,
      conformance_ring: 1,
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    resolver = SU_MCP::Terrain::PatchLifecycle::PatchWindowResolver.new(
      policy: policy,
      dimensions: { 'columns' => 12, 'rows' => 12 }
    )

    result = resolver.resolve(cell_window: cell_window(5, 5, 5, 5))

    assert_equal(['cdt-patch-v1-c1-r1'], result.fetch(:affectedPatchIds))
    assert_includes(result.fetch(:replacementPatchIds), 'cdt-patch-v1-c0-r0')
    assert_includes(result.fetch(:replacementPatchIds), 'cdt-patch-v1-c2-r2')
  end

  private

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
