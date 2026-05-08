# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/terrain_output_planning_diagnostics'
require_relative '../../../src/su_mcp/terrain/evidence/terrain_edit_evidence_builder'

class TerrainEditEvidenceBuilderTest < Minitest::Test
  include TerrainOutputPlanningDiagnostics

  def test_builds_edit_success_payload_with_capped_json_safe_evidence
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

  def test_includes_compact_survey_evidence_without_solver_internals
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary.merge(mode: 'survey_point_constraint'),
      diagnostics: diagnostics.merge(survey: survey_diagnostics),
      sample_limit: 0
    )

    survey = result.dig(:evidence, :survey)
    assert_equal('local', survey.dig(:correction, :correctionScope))
    assert_equal('rectangle', survey.dig(:correction, :supportRegionType))
    assert_equal('survey-1', survey.fetch(:points).first.fetch(:id))
    assert_equal('satisfied', survey.fetch(:points).first.fetch(:status))
    serialized = JSON.generate(result)
    %w[retained_detail stencil matrix lambda test/support SurveyCorrectionEvaluation].each do |term|
      refute_includes(serialized, term)
    end
  end

  def test_includes_compact_planar_fit_evidence_without_solver_internals
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary.merge(mode: 'planar_region_fit'),
      diagnostics: diagnostics.merge(planarFit: planar_fit_diagnostics),
      sample_limit: 0
    )

    planar = result.dig(:evidence, :planarFit)
    assert_equal('z = ax + by + c', planar.dig(:plane, :equation, :form))
    assert_equal('sw', planar.fetch(:controls).first.fetch(:id))
    assert_equal('satisfied', planar.fetch(:controls).first.fetch(:status))
    serialized = JSON.generate(result)
    forbidden_terms = %w[
      matrix normalEquations stencil outputPlan faceId vertexId SurveyCorrectionEvaluation
    ]
    forbidden_terms.each do |term|
      refute_includes(serialized, term)
    end
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

  def test_nested_private_feature_diagnostics_do_not_leak_from_compact_evidence
    result = SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary.merge(mode: 'corridor_transition', region: corridor_region),
      diagnostics: diagnostics.merge(
        transition: transition_diagnostics.merge(
          featureIntent: { id: 'feature:linear_corridor:explicit_edit:a:aaaaaaaaaaaa' },
          featureConstraints: [{ kind: 'linear_corridor', affectedWindow: {} }],
          rawTriangles: [[0, 1, 2]]
        )
      ),
      sample_limit: 0
    )
    serialized = JSON.generate(result)

    assert_equal('corridor_transition', result.dig(:evidence, :transition, :mode))
    %w[featureIntent feature: linear_corridor affectedWindow rawTriangles].each do |term|
      refute_includes(serialized, term)
    end
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

  def planar_fit_diagnostics
    {
      plane: {
        equation: { form: 'z = ax + by + c', a: 0.0, b: 0.05, c: 1.2 },
        normal: { x: 0.0, y: -0.0499376, z: 0.998752 },
        point: { x: 10.0, y: 5.0, z: 1.45 }
      },
      controls: [
        {
          id: 'sw',
          index: 0,
          point: { x: 0.0, y: 0.0 },
          requestedElevation: 1.2,
          beforeElevation: 1.0,
          planeElevation: 1.2,
          residual: 0.0,
          tolerance: 0.03,
          status: 'satisfied'
        }
      ],
      quality: {
        maxResidual: 0.0,
        meanResidual: 0.0,
        rmseResidual: 0.0,
        normalizedMaxResidual: 0.0
      },
      supportRegionType: 'rectangle',
      changedSampleCount: 4,
      fullWeightSampleCount: 4,
      blendSampleCount: 0,
      preservedSampleCount: 0,
      changedBounds: { min: { column: 1, row: 1 }, max: { column: 2, row: 2 } },
      maxSampleDelta: 0.42,
      grid: { warnings: [] },
      warnings: []
    }
  end

  def survey_diagnostics
    {
      points: [
        {
          id: 'survey-1',
          point: { x: 2.0, y: 2.0 },
          requestedElevation: 1.75,
          beforeElevation: 1.0,
          afterElevation: 1.75,
          residual: 0.0,
          tolerance: 0.01,
          status: 'satisfied'
        }
      ],
      correction: {
        correctionScope: 'local',
        supportRegionType: 'rectangle',
        changedSampleCount: 4,
        changedBounds: { min: { column: 1, row: 1 }, max: { column: 2, row: 2 } },
        maxSampleDelta: 0.75,
        detailPreservation: { outsideInfluenceRatio: 1.0 },
        distortion: {
          slopeProxy: { maxIncrease: 0.0 },
          curvatureProxy: { maxIncrease: 0.0 }
        },
        warnings: []
      }
    }
  end

  def private_planning_diagnostics
    private_output_planning_diagnostics
  end
end
