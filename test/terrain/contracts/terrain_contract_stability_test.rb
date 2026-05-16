# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/semantic_test_support'
require_relative '../../support/terrain_output_planning_diagnostics'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/commands/terrain_surface_commands'
require_relative '../../../src/su_mcp/terrain/evidence/terrain_edit_evidence_builder'
require_relative '../../../src/su_mcp/terrain/output/terrain_mesh_generator'
require_relative '../../../src/su_mcp/terrain/storage/terrain_state_serializer'

class TerrainContractStabilityTest < Minitest::Test
  include SemanticTestSupport
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

  def test_full_edit_response_path_hides_each_internal_cdt_fallback_reason
    internal_reasons = %w[
      cdt_disabled feature_geometry_failed native_unavailable native_input_violation
      input_normalization_failed unsupported_constraint_shape intersecting_constraints
      pre_triangulate_budget_exceeded point_budget_exceeded face_budget_exceeded
      runtime_budget_exceeded residual_gate_failed constraint_recovery_failed
      hard_geometry_gate_failed topology_gate_failed invalid_mesh adapter_exception
    ]

    internal_reasons.each do |reason|
      result = full_public_edit_response_for_internal_cdt_result(
        status: 'fallback',
        fallback_reason: reason
      )
      serialized = JSON.generate(result)

      refute_includes(serialized, reason)
      refute_internal_output_vocabulary(result)
    end
  end

  def test_public_response_hides_patch_relevant_feature_selection_diagnostics
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        featureSelectionDiagnostics: {
          selectionMode: 'patch_relevant',
          patchWindow: { minColumn: 2, minRow: 2, maxColumn: 7, maxRow: 7 },
          cdtFallbackTriggers: {
            patch_relevant_feature_geometry_failed: 1,
            patch_relevant_hard_primitive_unsupported: 1,
            patch_relevant_hard_clip_degenerate: 1
          },
          includedByReason: { intersects_patch: 1 },
          excludedByReason: { outside_patch_relevance: 1 },
          featureIds: ['feature:fixed_control:explicit_edit:a:aaaaaaaaaaaa']
        },
        cdtParticipation: { status: 'skip' }
      )
    )
    serialized = JSON.generate(result)

    %w[
      featureSelectionDiagnostics patch_relevant patchWindow cdtParticipation
      patch_relevant_feature_geometry_failed patch_relevant_hard_primitive_unsupported
      patch_relevant_hard_clip_degenerate intersects_patch outside_patch_relevance feature:
    ].each { |term| refute_includes(serialized, term) }
    refute_internal_output_vocabulary(result)
  end

  def test_public_response_hides_cdt_patch_replacement_and_seam_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        patchCdtReplacement: {
          mutationMode: 'local_patch_replacement',
          patchDomainDigest: 'patch-a',
          replacementBatchId: 'batch-1',
          cdtPatchOwnership: { missing: 0, duplicate: 0 },
          seamValidation: { status: 'failed', reason: 'seam_mismatch' },
          fallbackReason: 'ownership_integrity_mismatch',
          rawTriangles: [[0, 1, 2]]
        }
      )
    )
    serialized = JSON.generate(result)

    %w[
      patchCdtReplacement local_patch_replacement patchDomainDigest replacementBatchId
      cdtPatchOwnership seamValidation seam_mismatch ownership_integrity_mismatch rawTriangles
    ].each { |term| refute_includes(serialized, term) }
    refute_internal_output_vocabulary(result)
  end

  def test_full_edit_response_path_hides_accepted_cdt_details
    result = full_public_edit_response_for_internal_cdt_result(
      status: 'accepted',
      fallback_reason: nil
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_includes(result.fetch(:output).keys, :derivedMesh)
    refute_internal_output_vocabulary(result)
  end

  def test_cdt_attempt_does_not_change_public_refusal_envelope
    attempted = public_refusal_with_cdt_attempted
    disabled = public_refusal_with_cdt_disabled

    assert_equal(disabled, attempted)
  end

  def test_public_response_hides_adaptive_patch_lifecycle_registry_timing_and_fallback_internals
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        adaptivePatchLifecycle: {
          selectedPatchIds: %w[adaptive-patch-v1-c0-r0],
          replacementPatchIds: %w[adaptive-patch-v1-c0-r0 adaptive-patch-v1-c1-r0],
          registryStatus: 'stale',
          fallbackCategory: 'registry_integrity_mismatch',
          replacementBatchId: 'batch-2',
          timingBuckets: {
            dirtyWindowMapping: 0.001,
            adaptivePlanning: 0.002,
            conformance: 0.003,
            mutation: 0.004
          }
        },
        adaptivePatchRegistry: {
          outputPolicyFingerprint: 'fingerprint-a',
          patches: [{ patchId: 'adaptive-patch-v1-c0-r0' }]
        },
        adaptivePatchFaceIndex: 3
      )
    )

    refute_internal_output_vocabulary(result)
    %w[
      adaptivePatch adaptivePatchLifecycle adaptivePatchRegistry adaptive-patch-v1
      selectedPatchIds replacementPatchIds registryStatus fallbackCategory
      registry_integrity_mismatch timingBuckets dirtyWindowMapping adaptivePlanning
      conformance mutation outputPolicyFingerprint patchId adaptivePatchFaceIndex
    ].each { |term| refute_includes(JSON.generate(result), term) }
  end

  def test_public_response_hides_feature_output_policy_diagnostics
    result = edit_evidence_result(
      diagnostics: edit_diagnostics.merge(
        featureOutputPolicyDiagnostics: {
          schemaVersion: 1,
          featureViewDigest: 'feature-view-digest',
          policyFingerprint: 'policy-fingerprint',
          selectedFeatureKinds: { target_region: 1 },
          selectedStrengthCounts: { soft: 1 },
          intersectionSummary: { hasIntersectingFeatureContext: true },
          localTolerancePolicy: { mode: 'default_fixed' },
          diagnosticOnly: true
        }
      )
    )
    serialized = JSON.generate(result)

    refute_internal_output_vocabulary(result)
    %w[
      featureOutputPolicyDiagnostics featureViewDigest policyFingerprint selectedFeatureKinds
      selectedStrengthCounts intersectionSummary localTolerancePolicy diagnosticOnly
    ].each { |term| refute_includes(serialized, term) }
  end

  private

  def full_public_edit_response_for_internal_cdt_result(status:, fallback_reason:)
    model = build_semantic_model
    managed_terrain_owner(model)
    commands = cdt_contract_commands(
      model: model,
      cdt_backend: ContractCdtBackend.new(status: status, fallback_reason: fallback_reason)
    )

    commands.edit_terrain_surface(contract_edit_request)
  end

  def public_refusal_with_cdt_attempted
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    owner.entities.add_group
    commands = cdt_contract_commands(
      model: model,
      cdt_backend: ContractCdtBackend.new(status: 'accepted', fallback_reason: nil)
    )

    commands.edit_terrain_surface(contract_edit_request)
  end

  def public_refusal_with_cdt_disabled
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    owner.entities.add_group
    commands = cdt_contract_commands(model: model, cdt_backend: nil)

    commands.edit_terrain_surface(contract_edit_request)
  end

  def cdt_contract_commands(model:, cdt_backend:)
    SU_MCP::Terrain::TerrainSurfaceCommands.new(
      model: model,
      repository: ContractRepository.new(build_state),
      mesh_generator: SU_MCP::Terrain::TerrainMeshGenerator.new(cdt_backend: cdt_backend),
      edit_request_validator: ContractEditValidator.new,
      grade_editor: ContractGradeEditor.new,
      terrain_feature_intent_emitter: ContractFeatureIntentEmitter.new,
      terrain_feature_planner: ContractFeaturePlanner.new
    )
  end

  def managed_terrain_owner(model)
    owner = model.active_entities.add_group
    owner.set_attribute('su_mcp', 'sourceElementId', 'terrain-main')
    owner.set_attribute('su_mcp', 'semanticType', 'managed_terrain_surface')
    owner
  end

  def contract_edit_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => { 'mode' => 'target_height', 'targetElevation' => 2.0 },
      'region' => {
        'type' => 'rectangle',
        'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 1.0, 'maxY' => 1.0 }
      }
    }
  end

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

  class ContractRepository
    def initialize(state)
      @state = state
    end

    def load(_owner)
      { outcome: 'loaded', state: @state, summary: { digest: 'digest-before', revision: 1 } }
    end

    def save(_owner, state)
      { outcome: 'saved', state: state, summary: { digest: 'digest-after', revision: 2 } }
    end
  end

  class ContractEditValidator
    def validate(params)
      { outcome: 'ready', params: params }
    end
  end

  class ContractGradeEditor
    def apply(state:, request:)
      _request = request
      {
        outcome: 'edited',
        state: SU_MCP::Terrain::HeightmapState.new(
          basis: state.basis,
          origin: state.origin,
          spacing: state.spacing,
          dimensions: state.dimensions,
          elevations: state.elevations.map { |value| value + 1.0 },
          revision: state.revision + 1,
          state_id: state.state_id
        ),
        diagnostics: {
          changedRegion: { min: { column: 0, row: 0 }, max: { column: 1, row: 1 } },
          samples: [],
          fixedControls: { controls: [] },
          preserveZones: {},
          warnings: []
        }
      }
    end
  end

  class ContractFeatureIntentEmitter
    def emit(...)
      {}
    end
  end

  class ContractFeaturePlanner
    def pre_save(state:)
      { outcome: 'ready', state: state }
    end

    def prepare(state:, terrain_state_summary:, include_feature_geometry: false,
                selection_window: nil)
      _include_feature_geometry = include_feature_geometry
      _selection_window = selection_window
      {
        outcome: 'prepared',
        state: state,
        context: {
          terrainStateDigest: terrain_state_summary.fetch(:digest),
          primitiveRequest: { points: [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]] }
        },
        outputWindowReconciliation: { mode: 'full_grid' }
      }
    end
  end

  class ContractCdtBackend
    def initialize(status:, fallback_reason:)
      @status = status
      @fallback_reason = fallback_reason
    end

    def build(...)
      return accepted if @status == 'accepted'

      {
        status: 'fallback',
        fallbackReason: @fallback_reason,
        metrics: { timing: { internal: true } },
        limitations: [{ category: 'native_unavailable' }]
      }
    end

    def accepted
      {
        status: 'accepted',
        mesh: {
          vertices: [[0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0]],
          triangles: [[0, 1, 2]]
        },
        metrics: { triangulatorKind: 'ruby_bowyer_watson_constraint_recovery' },
        limitations: [{ category: 'rawTriangles' }]
      }
    end
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
      triangulatorVersion ruby_bowyer_watson featureSelectionDiagnostics
      cdtParticipation patch_relevant patchWindow outside_patch_relevance
      patchCdtReplacement local_patch_replacement patchDomainDigest replacementBatchId
      cdtPatchOwnership seamValidation seam_mismatch ownership_integrity_mismatch
      adaptivePatch adaptivePatchLifecycle adaptivePatchRegistry adaptive-patch-v1
      selectedPatchIds replacementPatchIds registryStatus fallbackCategory timingBuckets
      dirtyWindowMapping adaptivePlanning conformance registryLookup ownershipLookup
      registryWrites outputPolicyFingerprint adaptivePatchFaceIndex adaptivePatchId
      featureOutputPolicyDiagnostics featureViewDigest policyFingerprint selectedFeatureKinds
      selectedStrengthCounts intersectionSummary localTolerancePolicy diagnosticOnly
      featureAwareAdaptivePolicy adaptivePolicySummary toleranceRange densityHitCount
      hardProtectedToleranceHitCount fallbackCounts targetCellSize targetDensity
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
