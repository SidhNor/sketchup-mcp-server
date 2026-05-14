# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../src/su_mcp/terrain/output/terrain_output_cell_window'
require_relative '../../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_grid_policy'
require_relative '../../../../../src/su_mcp/terrain/output/patch_lifecycle/patch_window_resolver'

begin
  require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/cdt_patch_batch_plan'
rescue LoadError
  # Skeleton phase: implementation must introduce this PatchLifecycle-native boundary.
end

class CdtPatchBatchPlanTest < Minitest::Test
  def test_batch_plan_is_built_from_patch_lifecycle_resolution
    assert(defined?(SU_MCP::Terrain::CdtPatchBatchPlan), 'CdtPatchBatchPlan must exist')

    plan = SU_MCP::Terrain::CdtPatchBatchPlan.from_lifecycle_resolution(
      lifecycle_resolution: lifecycle_resolution,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      feature_plan: { selectedFeaturePool: [], patchFeatureBundles: {} },
      retained_boundary_spans: []
    )

    assert_equal(['cdt-patch-v1-c0-r0'], plan.affected_patch_ids)
    assert_includes(plan.replacement_patch_ids, 'cdt-patch-v1-c1-r1')
    assert_equal('cdt-patch-v1-c0-r0', plan.affected_patches.first.fetch(:patchId))
    assert_json_safe(plan.to_h)
    refute_includes(JSON.generate(plan.to_h), 'patchDomainDigest')
    refute_includes(JSON.generate(plan.to_h), 'rawTriangles')
  end

  def test_batch_plan_cannot_become_a_second_lifecycle_or_registry_owner
    assert(defined?(SU_MCP::Terrain::CdtPatchBatchPlan), 'CdtPatchBatchPlan must exist')

    plan = SU_MCP::Terrain::CdtPatchBatchPlan.from_lifecycle_resolution(
      lifecycle_resolution: lifecycle_resolution,
      terrain_state_summary: { digest: 'digest-1', revision: 1 },
      feature_plan: { selectedFeaturePool: [], patchFeatureBundles: {} },
      retained_boundary_spans: []
    )

    refute_respond_to(plan, :patch_id_for)
    refute_respond_to(plan, :write_registry)
    refute_respond_to(plan, :write_registry!)
    refute_respond_to(plan, :mark_face_ownership)
    refute_respond_to(plan, :persist!)
  end

  private

  def lifecycle_resolution
    policy = SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy.new(
      patch_id_prefix: 'cdt-patch',
      fingerprint_kind: 'cdt-patch'
    )
    resolver = SU_MCP::Terrain::PatchLifecycle::PatchWindowResolver.new(
      policy: policy,
      dimensions: { 'columns' => 50, 'rows' => 50 }
    )
    resolver.resolve(
      cell_window: SU_MCP::Terrain::TerrainOutputCellWindow.new(
        { min_column: 0, min_row: 0, max_column: 1, max_row: 1 }
      )
    )
  end

  def assert_json_safe(value)
    JSON.parse(JSON.generate(value))
  end
end
