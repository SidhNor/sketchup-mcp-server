# frozen_string_literal: true

require_relative '../../test_helper'

class TerrainRepositoryHostedSmokeTest < Minitest::Test
  def test_hosted_smoke_matrix_is_recorded_for_terrain_repository_persistence
    skip(
      'Manual SketchUp-hosted smoke required for MTA-02: create a real terrain owner group, ' \
      'save a supported heightmap payload through SU_MCP::Terrain::TerrainRepository, verify ' \
      'payload storage under su_mcp_terrain/statePayload and not su_mcp, save and reopen the ' \
      'model or equivalent hosted persistence cycle, then verify repository load and owner ' \
      'transform mismatch refusal. Record completion status in MTA-02 summary.md.'
    )
  end
end
