# frozen_string_literal: true

require_relative '../../test_helper'

class TerrainCdtStructureTest < Minitest::Test
  OUTPUT_ROOT = File.expand_path('../../../src/su_mcp/terrain/output', __dir__)
  CDT_ROOT = File.join(OUTPUT_ROOT, 'cdt')
  PROBES_ROOT = File.expand_path('../../../src/su_mcp/terrain/probes', __dir__)

  def test_cdt_facade_files_remain_flat_and_patch_proof_has_named_ownership
    assert_equal(
      %w[
        cdt_height_error_meter.rb
        cdt_terrain_point_planner.rb
        cdt_triangulator.rb
        residual_cdt_engine.rb
        terrain_cdt_backend.rb
        terrain_cdt_primitive_request.rb
        terrain_cdt_result.rb
        terrain_triangulation_adapter.rb
      ],
      basenames_under(CDT_ROOT)
    )
    assert_equal(
      %w[
        patch_affected_region_updater.rb
        patch_boundary_topology.rb
        patch_cdt_domain.rb
        patch_debug_mesh_renderer.rb
        patch_height_error_meter.rb
        patch_local_cdt_proof.rb
        patch_residual_candidate_tracker.rb
        patch_seed_topology_builder.rb
        patch_topology_quality_meter.rb
      ],
      basenames_under(File.join(CDT_ROOT, 'patches'))
    )
  end

  def test_cdt_sources_only_use_the_blessed_patch_subfolder
    nested_sources = Dir[File.join(CDT_ROOT, '**', '*.rb')].reject do |path|
      [CDT_ROOT, File.join(CDT_ROOT, 'patches')].include?(File.dirname(path))
    end

    assert_empty(nested_sources)
  end

  def test_output_root_no_longer_mixes_cdt_runtime_or_mta24_validation_files
    root_files = basenames_under(OUTPUT_ROOT)

    %w[
      cdt_height_error_meter.rb
      cdt_terrain_candidate_backend.rb
      cdt_terrain_point_planner.rb
      cdt_triangulator.rb
      residual_cdt_engine.rb
      terrain_cdt_primitive_request.rb
      terrain_production_cdt_backend.rb
      terrain_production_cdt_result.rb
      terrain_triangulation_adapter.rb
    ].each { |basename| refute_includes(root_files, basename) }
  end

  def test_mta24_cdt_candidate_wrapper_is_probe_owned
    assert_path_exists(File.join(PROBES_ROOT, 'mta24_cdt_candidate_backend.rb'))
    refute_path_exists(File.join(OUTPUT_ROOT, 'cdt_terrain_candidate_backend.rb'))
  end

  def test_cdt_facade_sources_do_not_use_production_or_probe_vocabulary
    facade_files = %w[
      residual_cdt_engine.rb
      terrain_cdt_backend.rb
      terrain_cdt_primitive_request.rb
      terrain_cdt_result.rb
      terrain_triangulation_adapter.rb
    ]
    serialized = facade_files.map do |basename|
      path = File.join(CDT_ROOT, basename)
      File.read(path, encoding: 'utf-8')
    end.join("\n")

    %w[
      TerrainProductionCdt ProductionCdt production_cdt
      Mta24 mta24 candidateRow candidateRows comparisonRows HostedBakeoff ThreeWay
      from_candidate_row candidate_row
    ].each { |term| refute_includes(serialized, term) }
  end

  def test_public_facing_sources_do_not_expose_patch_cdt_proof_vocabulary
    public_files = %w[
      terrain_cdt_backend.rb
      terrain_cdt_primitive_request.rb
      terrain_cdt_result.rb
      terrain_triangulation_adapter.rb
      ../terrain_mesh_generator.rb
    ]
    serialized = public_files.map do |basename|
      path = File.expand_path(File.join(CDT_ROOT, basename))
      File.read(path, encoding: 'utf-8')
    end.join("\n")

    %w[
      PatchCdtDomain affectedRegionUpdate recomputationScope patchLocalResidual
      patch_local_incremental_residual_cdt_proof residualQueue
    ].each { |term| refute_includes(serialized, term) }
  end

  private

  def basenames_under(directory)
    Dir[File.join(directory, '*.rb')].map { |path| File.basename(path) }.sort
  end
end
