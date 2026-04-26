# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/terrain_output_planning_diagnostics'
require_relative '../../src/su_mcp/terrain/terrain_edit_evidence_builder'

class TerrainEditEvidenceBuilderTest < Minitest::Test
  include TerrainOutputPlanningDiagnostics

  def test_builds_edit_success_payload_with_capped_json_safe_evidence # rubocop:disable Metrics/AbcSize
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main', persistentId: '5001' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary,
      diagnostics: diagnostics,
      metadata: { status: 'existing', state: 'Adopted' },
      sample_limit: 2
    )

    assert_equal(true, result.fetch(:success))
    assert_equal('edited', result.fetch(:outcome))
    assert_equal('edit_terrain_surface', result.dig(:operation, :name))
    assert_equal('target_height', result.dig(:operation, :mode))
    assert_equal('existing', result.dig(:managedTerrain, :status))
    assert_equal('Adopted', result.dig(:managedTerrain, :state))
    assert_equal(2, result.dig(:evidence, :samples).length)
    assert_equal(4, result.dig(:evidence, :sampleSummary, :totalSampleCount))
    refute_includes(JSON.generate(result), 'Sketchup::')
    refute_includes(JSON.generate(result), 'faceId')
    refute_includes(JSON.generate(result), 'vertexId')
  end

  def test_reports_controls_preserve_zones_and_warnings_without_raw_entities
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary,
      diagnostics: diagnostics.merge(warnings: ['large edit region']),
      sample_limit: 8
    )

    assert_equal([{ id: 'control-1', status: 'preserved' }],
                 result.dig(:evidence, :fixedControls))
    assert_equal(3, result.dig(:evidence, :preserveZones, :protectedSampleCount))
    assert_equal(['large edit region'], result.dig(:evidence, :warnings))
    refute_includes(JSON.generate(result), 'Sketchup::')
  end

  def test_omits_sample_rows_when_sample_limit_is_zero
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary,
      diagnostics: diagnostics,
      sample_limit: 0
    )

    assert_empty(result.dig(:evidence, :samples))
    assert_equal(4, result.dig(:evidence, :sampleSummary, :totalSampleCount))
    assert_equal(0, result.dig(:evidence, :sampleSummary, :returnedSampleCount))
  end

  def test_includes_compact_transition_evidence_when_supplied
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary.merge(mode: 'corridor_transition', region: corridor_region),
      diagnostics: diagnostics.merge(transition: transition_diagnostics),
      sample_limit: 0
    )

    transition = result.dig(:evidence, :transition)
    assert_equal('corridor_transition', transition.fetch(:mode))
    assert_equal(2.0, transition.fetch(:width))
    assert_equal({ 'distance' => 1.0, 'falloff' => 'cosine' }, transition.fetch(:sideBlend))
    assert_includes(transition.keys, :endpointDeltas)
    assert_includes(transition.keys, :deltaSummary)
  end

  def test_includes_compact_fairing_evidence_when_supplied
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary.merge(mode: 'local_fairing'),
      diagnostics: diagnostics.merge(fairing: fairing_diagnostics),
      sample_limit: 0
    )

    fairing = result.dig(:evidence, :fairing)
    assert_equal('mean_absolute_neighborhood_residual', fairing.fetch(:metric))
    assert_equal(1.0, fairing.fetch(:beforeResidual))
    assert_equal(0.4, fairing.fetch(:afterResidual))
    assert_equal(true, fairing.fetch(:improved))
    assert_equal(2, fairing.fetch(:actualIterations))
  end

  def test_private_output_planning_diagnostics_do_not_leak_into_public_payload
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary,
      diagnostics: diagnostics.merge(private_planning_diagnostics),
      sample_limit: 2
    )
    serialized = JSON.generate(result)

    assert_equal('full', result.dig(:operation, :regeneration))
    refute_includes(JSON.generate(result.fetch(:output)), 'regeneration')
    refute_includes(serialized, 'sampleWindow')
    refute_includes(serialized, 'outputPlan')
    refute_includes(serialized, 'dirtyWindow')
    refute_includes(serialized, 'outputRegions')
    refute_includes(serialized, 'chunks')
    refute_includes(serialized, 'tiles')
  end

  private

  def terrain_state_summary
    {
      stateId: 'state-2',
      payloadKind: 'heightmap_grid',
      schemaVersion: 1,
      revision: 2,
      digest: 'digest-2',
      serializedBytes: 234
    }
  end

  def derived_mesh_summary
    {
      meshType: 'regular_grid',
      vertexCount: 16,
      faceCount: 18,
      derivedFromStateDigest: 'digest-2'
    }
  end

  def edit_summary
    {
      mode: 'target_height',
      region: { type: 'rectangle' },
      changedRegion: { min: { column: 1, row: 1 }, max: { column: 2, row: 2 } }
    }
  end

  def diagnostics
    {
      samples: [
        { column: 1, row: 1, before: 1.0, after: 4.0 },
        { column: 2, row: 1, before: 1.0, after: 4.0 },
        { column: 1, row: 2, before: 1.0, after: 4.0 },
        { column: 2, row: 2, before: 1.0, after: 4.0 }
      ],
      fixedControls: [{ id: 'control-1', status: 'preserved' }],
      preserveZones: { protectedSampleCount: 3 },
      warnings: []
    }
  end

  def corridor_region
    {
      type: 'corridor',
      startControl: { point: { x: 0.0, y: 1.0 }, elevation: 1.0 },
      endControl: { point: { x: 4.0, y: 1.0 }, elevation: 3.0 },
      width: 2.0,
      sideBlend: { distance: 1.0, falloff: 'cosine' }
    }
  end

  def transition_diagnostics
    {
      mode: 'corridor_transition',
      width: 2.0,
      sideBlend: { 'distance' => 1.0, 'falloff' => 'cosine' },
      endpointDeltas: { start: 0.0, end: 0.0 },
      deltaSummary: { min: 0.0, max: 2.0 }
    }
  end

  def fairing_diagnostics
    {
      metric: 'mean_absolute_neighborhood_residual',
      beforeResidual: 1.0,
      afterResidual: 0.4,
      improved: true,
      strength: 0.35,
      neighborhoodRadiusSamples: 2,
      iterations: 3,
      actualIterations: 2,
      changedSampleCount: 8,
      warnings: []
    }
  end

  def private_planning_diagnostics
    private_output_planning_diagnostics
  end
end
