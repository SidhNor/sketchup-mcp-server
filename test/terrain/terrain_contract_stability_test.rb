# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/terrain_output_planning_diagnostics'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/terrain_edit_evidence_builder'
require_relative '../../src/su_mcp/terrain/terrain_state_serializer'

class TerrainContractStabilityTest < Minitest::Test
  include TerrainOutputPlanningDiagnostics

  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_serialized_heightmap_state_remains_v1_without_window_or_chunk_state
    parsed = JSON.parse(serializer.serialize(build_state))

    assert_equal('heightmap_grid', parsed.fetch('payloadKind'))
    assert_equal(1, parsed.fetch('schemaVersion'))
    refute_includes(parsed.keys, 'sampleWindows')
    refute_includes(parsed.keys, 'outputRegions')
    refute_includes(parsed.keys, 'chunks')
    refute_includes(parsed.keys, 'tiles')
  end

  def test_edit_evidence_keeps_public_changed_region_vocabulary_without_generated_ids
    result = edit_evidence_result

    evidence = result.fetch(:evidence)
    assert_includes(evidence.keys, :changedRegion)
    assert_includes(evidence.keys, :samples)
    assert_includes(evidence.keys, :sampleSummary)
    refute_includes(evidence.keys, :sampleWindow)
    refute_includes(JSON.generate(result), 'faceId')
    refute_includes(JSON.generate(result), 'vertexId')
  end

  def test_public_output_vocabulary_does_not_expose_bulk_or_candidate_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(private_output_planning_diagnostics)
    )

    assert_includes(result.fetch(:output).keys, :derivedMesh)
    assert_equal('full', result.dig(:operation, :regeneration))
    refute_internal_output_vocabulary(result)
  end

  private

  def serializer
    @serializer ||= SU_MCP::Terrain::TerrainStateSerializer.new
  end

  def build_state
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 10.0, 'y' => 20.0, 'z' => 0.0 },
      spacing: { 'x' => 2.0, 'y' => 3.0 },
      dimensions: { 'columns' => 3, 'rows' => 2 },
      elevations: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  def edit_evidence_result(diagnostics: edit_diagnostics)
    SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary,
      diagnostics: diagnostics,
      sample_limit: 20
    )
  end

  def refute_internal_output_vocabulary(result)
    serialized = JSON.generate(result)
    serialized_output = JSON.generate(result.fetch(:output))

    %w[
      validationOnly bulk candidate strategy sampleWindow outputPlan dirtyWindow
      outputRegions chunks tiles faceId vertexId outputSchemaVersion
      terrainStateRevision gridCellColumn gridCellRow gridTriangleIndex
    ].each { |term| refute_includes(serialized, term) }
    refute_includes(serialized_output, 'regeneration')
  end

  def terrain_state_summary
    {
      stateId: 'state-2',
      payloadKind: 'heightmap_grid',
      schemaVersion: 1,
      revision: 2,
      digest: 'digest-2'
    }
  end

  def derived_mesh_summary
    {
      meshType: 'regular_grid',
      vertexCount: 4,
      faceCount: 2,
      derivedFromStateDigest: 'digest-2'
    }
  end

  def edit_summary
    {
      mode: 'target_height',
      region: { type: 'rectangle' },
      changedRegion: { min: { column: 0, row: 0 }, max: { column: 1, row: 1 } }
    }
  end

  def edit_diagnostics
    {
      samples: [{ column: 0, row: 0, before: 1.0, after: 2.0 }],
      fixedControls: { controls: [] },
      preserveZones: { protectedSampleCount: 0 },
      warnings: []
    }
  end
end
