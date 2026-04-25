# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/terrain_surface_evidence_builder'

class TerrainSurfaceEvidenceBuilderTest < Minitest::Test
  def test_builds_create_success_payload_without_raw_sketchup_identity
    result = SU_MCP::Terrain::TerrainSurfaceEvidenceBuilder.new.build_success(
      outcome: 'created',
      lifecycle_mode: 'create',
      owner_reference: { sourceElementId: 'terrain-main', persistentId: '5001' },
      metadata: { semanticType: 'managed_terrain_surface', status: 'existing', state: 'Created' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      request_summary: { definitionKind: 'heightmap_grid' },
      source_summary: nil,
      sampling_summary: nil
    )

    assert_equal(true, result.fetch(:success))
    assert_equal('created', result.fetch(:outcome))
    assert_equal('create', result.dig(:operation, :lifecycleMode))
    assert_nil(result.dig(:evidence, :sourceSummary))
    refute_includes(JSON.generate(result), 'Sketchup::')
    refute_includes(JSON.generate(result), 'faceId')
    refute_includes(JSON.generate(result), 'vertexId')
  end

  def test_builds_adoption_evidence_with_source_replacement_and_sampling_summary
    result = SU_MCP::Terrain::TerrainSurfaceEvidenceBuilder.new.build_success(
      outcome: 'adopted',
      lifecycle_mode: 'adopt',
      owner_reference: { sourceElementId: 'terrain-main', persistentId: '5001' },
      metadata: { semanticType: 'managed_terrain_surface', status: 'existing', state: 'Adopted' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      request_summary: { lifecycleMode: 'adopt' },
      source_summary: { sourceElementId: 'source-terrain', sourceAction: 'replaced' },
      sampling_summary: { sampleCount: 6, maxSamples: 10_000 }
    )

    assert_equal('adopted', result.fetch(:outcome))
    assert_equal('replaced', result.dig(:evidence, :sourceSummary, :sourceAction))
    assert_equal(6, result.dig(:evidence, :samplingSummary, :sampleCount))
    assert_equal('digest-1', result.dig(:output, :derivedMesh, :derivedFromStateDigest))
  end

  private

  def terrain_state_summary
    {
      stateId: 'state-1',
      payloadKind: 'heightmap_grid',
      schemaVersion: 1,
      revision: 1,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 2, 'rows' => 2 },
      digestAlgorithm: 'sha256',
      digest: 'digest-1',
      serializedBytes: 123
    }
  end

  def derived_mesh_summary
    {
      meshType: 'regular_grid',
      vertexCount: 4,
      faceCount: 2,
      derivedFromStateDigest: 'digest-1'
    }
  end
end
