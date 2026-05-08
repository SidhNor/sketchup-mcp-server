# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/terrain_output_planning_diagnostics'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/evidence/terrain_edit_evidence_builder'
require_relative '../../../src/su_mcp/terrain/storage/terrain_state_serializer'

class TerrainContractStabilityTest < Minitest::Test
  include TerrainOutputPlanningDiagnostics

  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_serialized_terrain_state_is_v3_heightmap_grid_without_expanded_feature_or_chunk_state
    parsed = JSON.parse(serializer.serialize(build_state))

    assert_equal('heightmap_grid', parsed.fetch('payloadKind'))
    assert_equal(3, parsed.fetch('schemaVersion'))
    assert_includes(parsed.keys, 'featureIntent')
    assert_includes(parsed.keys, 'tiles')
    refute_includes(parsed.keys, 'sampleWindows')
    refute_includes(parsed.keys, 'outputRegions')
    refute_includes(parsed.keys, 'chunks')
    refute_includes(JSON.generate(parsed.fetch('featureIntent')), 'pointified')
    refute_includes(JSON.generate(parsed.fetch('featureIntent')), 'rawTriangle')
  end

  def test_public_evidence_does_not_expose_feature_constraint_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        featureIntent: { id: 'feature:target_region:explicit_edit:a:aaaaaaaaaaaa' },
        featureConstraints: [{ kind: 'linear_corridor', affectedWindow: {} }],
        FeatureIntentSet: true,
        pointifiedLanes: [[0, 0]],
        rawTriangles: [[0, 1, 2]],
        solverMatrix: [[1.0]]
      )
    )

    %w[featureIntent feature: linear_corridor affectedWindow FeatureIntentSet pointified
       rawTriangles solverMatrix].each do |term|
      refute_includes(JSON.generate(result), term)
    end
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
      diagnostics: edit_diagnostics.merge(private_output_planning_diagnostics).merge(
        splitColumns: [0, 1],
        splitRows: [0, 1],
        splitGrid: [[0, 0], [1, 0]],
        adaptiveBoundaryLines: { columns: [0, 1], rows: [0, 1] },
        conformingGrid: true,
        boundaryVertices: [[0, 0], [1, 0]],
        fanCenter: [0.5, 0.5],
        emissionTriangles: [[[0.5, 0.5], [0, 0], [1, 0]]],
        adaptiveCell: { splitColumns: [0, 1], splitRows: [0, 1] },
        rawVertices: [[0.0, 0.0, 0.0]],
        rawTriangles: [[0, 1, 2]],
        stitch: { triangles: [[0, 1, 2]] }
      )
    )

    assert_includes(result.fetch(:output).keys, :derivedMesh)
    assert_equal('full', result.dig(:operation, :regeneration))
    refute_internal_output_vocabulary(result)
  end

  def test_public_output_vocabulary_does_not_expose_mta23_candidate_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        candidateRow: { backend: 'mta23_intent_aware_adaptive_grid_prototype' },
        terrainFeatureGeometry: { outputAnchorCandidates: [], protectedRegions: [] },
        featureGeometryDigest: 'abc',
        referenceGeometryDigest: 'def',
        candidateVertices: [[0.0, 0.0, 0.0]],
        candidateTriangles: [[0, 1, 2]],
        firmResidualsByRole: {},
        topologyResiduals: {},
        splitReasonHistogram: {},
        solverVocabulary: 'intent_aware_adaptive_grid'
      )
    )

    refute_internal_output_vocabulary(result)
    %w[
      mta23 candidateRow terrainFeatureGeometry outputAnchorCandidates protectedRegions
      featureGeometryDigest referenceGeometryDigest candidateVertices candidateTriangles
      firmResidualsByRole topologyResiduals splitReasonHistogram intent_aware_adaptive_grid
    ].each { |term| refute_includes(JSON.generate(result), term) }
  end

  def test_public_output_vocabulary_does_not_expose_mta24_cdt_candidate_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        cdt: { constrainedEdgeCoverage: 1.0 },
        constrainedDelaunay: true,
        breakline: true,
        candidateRow: { backend: 'mta24_constrained_delaunay_cdt_prototype' },
        rawTriangles: [[0, 1, 2]],
        expandedConstraints: [{ start: [0, 0], end: [1, 1] }],
        solverPredicates: { incircle: 0.0, orientation: 1.0 },
        constraintGraph: { edges: [] },
        delaunayViolationCount: 0,
        triangulatorKind: 'ruby_bowyer_watson_constraint_recovery',
        triangulatorVersion: 'mta24-ruby-cdt-prototype-0'
      )
    )

    refute_internal_output_vocabulary(result)
    %w[
      cdt constrainedDelaunay breakline mta24 constrained_delaunay rawTriangles
      expandedConstraints solverPredicates constraintGraph delaunayViolationCount
      triangulatorKind triangulatorVersion ruby_bowyer_watson
    ].each { |term| refute_includes(JSON.generate(result), term) }
  end

  def test_public_fairing_evidence_does_not_expose_output_or_generated_entity_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        private_output_planning_diagnostics,
        fairing: {
          metric: 'mean_absolute_neighborhood_residual',
          beforeResidual: 1.0,
          afterResidual: 0.5,
          improved: true,
          strength: 0.35,
          neighborhoodRadiusSamples: 2,
          iterations: 1,
          actualIterations: 1,
          changedSampleCount: 1,
          warnings: []
        }
      ),
      edit_summary: edit_summary.merge(mode: 'local_fairing')
    )

    assert_equal('local_fairing', result.dig(:operation, :mode))
    assert_equal('mean_absolute_neighborhood_residual', result.dig(:evidence, :fairing, :metric))
    refute_internal_output_vocabulary(result)
  end

  def test_public_survey_evidence_does_not_expose_solver_or_generated_entity_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        private_output_planning_diagnostics,
        survey: {
          points: [
            {
              id: 'survey-1',
              requestedElevation: 1.5,
              beforeElevation: 1.0,
              afterElevation: 1.5,
              residual: 0.0,
              tolerance: 0.01,
              status: 'satisfied'
            }
          ],
          correction: {
            correctionScope: 'regional',
            supportRegionType: 'rectangle',
            changedSampleCount: 9,
            maxSampleDelta: 0.5,
            detailPreservation: { outsideInfluenceRatio: 1.0 },
            distortion: { slopeProxy: { maxIncrease: 0.0 } },
            warnings: []
          }
        }
      ),
      edit_summary: edit_summary.merge(mode: 'survey_point_constraint')
    )
    serialized = JSON.generate(result)

    assert_equal('survey_point_constraint', result.dig(:operation, :mode))
    assert_equal('regional', result.dig(:evidence, :survey, :correction, :correctionScope))
    refute_internal_output_vocabulary(result)
    %w[retained_detail stencil matrix lambda SurveyCorrectionEvaluation outputPlan faceId
       vertexId].each do |term|
      refute_includes(serialized, term)
    end
  end

  def test_public_planar_fit_evidence_does_not_expose_solver_or_generated_entity_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        private_output_planning_diagnostics,
        planarFit: {
          plane: {
            equation: { form: 'z = ax + by + c', a: 0.0, b: 0.1, c: 1.0 },
            normal: { x: -0.0995, y: 0.0, z: 0.995 },
            point: { x: 1.0, y: 1.0, z: 1.1 }
          },
          controls: [
            {
              id: 'sw',
              index: 0,
              point: { x: 0.0, y: 0.0 },
              requestedElevation: 1.0,
              beforeElevation: 0.0,
              planeElevation: 1.0,
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
          changedSampleCount: 1,
          fullWeightSampleCount: 1,
          blendSampleCount: 0,
          preservedSampleCount: 0,
          changedBounds: { min: { column: 0, row: 0 }, max: { column: 0, row: 0 } },
          maxSampleDelta: 1.0,
          grid: { warnings: [] },
          warnings: []
        }
      ),
      edit_summary: edit_summary.merge(mode: 'planar_region_fit')
    )
    serialized = JSON.generate(result)

    assert_equal('planar_region_fit', result.dig(:operation, :mode))
    assert_equal('z = ax + by + c', result.dig(:evidence, :planarFit, :plane, :equation, :form))
    refute_internal_output_vocabulary(result)
    %w[normalEquations matrix stencil outputPlan faceId vertexId MTA-13 MTA-14].each do |term|
      refute_includes(serialized, term)
    end
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

  def edit_evidence_result(diagnostics: edit_diagnostics, edit_summary: nil)
    SU_MCP::Terrain::TerrainEditEvidenceBuilder.new.build_success(
      owner_reference: { sourceElementId: 'terrain-main' },
      terrain_state_summary: terrain_state_summary,
      output_summary: { derivedMesh: derived_mesh_summary },
      edit_summary: edit_summary || self.edit_summary,
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
      splitColumns splitRows splitGrid adaptiveBoundaryLines conformingGrid
      boundaryVertices fanCenter edgeSplits centerFan emissionTriangles
      densified adaptiveCell adaptiveCells emissionStrategy sourceGridSubcell
      sourceGridSubcells classification rawVertices rawTriangles stitch
      candidateRow terrainFeatureGeometry outputAnchorCandidates protectedRegions
      featureGeometryDigest referenceGeometryDigest candidateVertices candidateTriangles
      firmResidualsByRole topologyResiduals splitReasonHistogram
      cdt constrainedDelaunay breakline constrained_delaunay expandedConstraints
      solverPredicates constraintGraph delaunayViolationCount triangulatorKind
      triangulatorVersion ruby_bowyer_watson
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
