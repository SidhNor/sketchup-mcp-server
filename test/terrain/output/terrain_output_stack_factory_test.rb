# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_stack_factory'

class TerrainOutputStackFactoryTest < Minitest::Test
  def test_default_stack_keeps_cdt_disabled
    generator = SU_MCP::Terrain::TerrainOutputStackFactory.new(mode: 'adaptive').mesh_generator

    refute(generator.cdt_enabled?)
  end

  def test_cdt_patch_mode_builds_real_cdt_collaborators
    generator = SU_MCP::Terrain::TerrainOutputStackFactory.new(mode: 'cdt_patch').mesh_generator

    assert(generator.cdt_enabled?)
    refute(generator.send(:fallback_on_cdt_failure?))
    assert_instance_of(
      SU_MCP::Terrain::TerrainCdtBackend,
      generator.send(:cdt_backend)
    )
    assert_instance_of(
      SU_MCP::Terrain::StableDomainCdtReplacementProvider,
      generator.send(:cdt_patch_replacement_provider)
    )
  end

  def test_reads_private_simplifier_switch_from_environment
    factory = SU_MCP::Terrain::TerrainOutputStackFactory.new(
      env: { 'SKETCHUP_MCP_TERRAIN_SIMPLIFIER' => 'cdt_patch' }
    )

    assert(factory.mesh_generator.cdt_enabled?)
  end
end
