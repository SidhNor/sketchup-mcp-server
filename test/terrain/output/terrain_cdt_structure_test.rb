# frozen_string_literal: true

require_relative '../../test_helper'

class TerrainCdtStructureTest < Minitest::Test
  OUTPUT_ROOT = File.expand_path('../../../src/su_mcp/terrain/output', __dir__)
  CDT_ROOT = File.join(OUTPUT_ROOT, 'cdt')
  PROBES_ROOT = File.expand_path('../../../src/su_mcp/terrain/probes', __dir__)

  def test_cdt_files_have_flat_output_ownership
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
  end

  def test_cdt_sources_do_not_use_nested_subfolders_before_full_productization
    nested_sources = Dir[File.join(CDT_ROOT, '**', '*.rb')].reject do |path|
      File.dirname(path) == CDT_ROOT
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

  private

  def basenames_under(directory)
    Dir[File.join(directory, '*.rb')].map { |path| File.basename(path) }.sort
  end
end
