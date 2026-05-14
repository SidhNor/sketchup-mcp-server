# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/semantic_test_support'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'
require_relative '../../../src/su_mcp/terrain/commands/terrain_surface_commands'
require_relative '../../../src/su_mcp/terrain/output/cdt/patches/cdt_patch_policy'
require_relative '../../../src/su_mcp/terrain/output/cdt/patches/' \
                 'stable_domain_cdt_replacement_provider'

class TerrainSurfaceCommandsTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  include SemanticTestSupport

  def test_create_mode_commits_owner_metadata_state_output_and_json_safe_evidence
    model = build_semantic_model
    commands = build_commands(model: model)

    result = commands.create_terrain_surface(create_request)

    owner = model.active_entities.groups.first
    assert_equal([[:start_operation, 'Create Terrain Surface', true], [:commit_operation]],
                 model.operations)
    assert_equal('terrain-main', owner.get_attribute('su_mcp', 'sourceElementId'))
    assert_equal('managed_terrain_surface', owner.get_attribute('su_mcp', 'semanticType'))
    assert(owner.get_attribute('su_mcp_terrain', 'statePayload'))
    assert_equal('created', result.fetch(:outcome))
    refute_includes(JSON.generate(result), 'Sketchup::')
  end

  def test_create_mode_passes_feature_context_to_initial_output_generation
    model = build_semantic_model
    mesh_generator = RecordingMeshGenerator.new(cdt_enabled: true)
    commands = build_commands(
      model: model,
      state_builder: FeatureIntentStateBuilder.new,
      mesh_generator: mesh_generator,
      terrain_feature_planner: FullFallbackFeaturePlanner.new
    )

    result = commands.create_terrain_surface(create_request)

    assert_equal('created', result.fetch(:outcome))
    feature_context = mesh_generator.last_generate_args.fetch(:feature_context)
    assert_equal('digest-1', feature_context.fetch(:terrainStateDigest))
    assert_same(
      mesh_generator.last_generate_args.fetch(:state),
      feature_context.fetch(:terrainState),
      'production CDT must receive saved terrain state during initial generation'
    )
  end

  def test_create_mode_wires_adaptive_patch_policy_for_tiled_adaptive_output
    model = build_semantic_model
    mesh_generator = RecordingMeshGenerator.new
    commands = build_commands(
      model: model,
      state_builder: TiledStateBuilder.new,
      mesh_generator: mesh_generator
    )

    result = commands.create_terrain_surface(create_request)

    assert_equal('created', result.fetch(:outcome))
    plan = mesh_generator.last_generate_args.fetch(:output_plan)
    assert_equal(:adaptive_tin, plan.execution_strategy)
    assert_instance_of(
      SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy,
      plan.adaptive_patch_policy
    )
    assert_equal(
      'adaptive-patch-v1-c0-r0',
      plan.adaptive_patch_policy.patch_id_for(column: 0, row: 0)
    )
  end

  def test_create_mode_applies_optional_owner_placement_origin
    model = build_semantic_model
    length_converter = RecordingLengthConverter.new(multiplier: 10.0)
    commands = build_commands(model: model, length_converter: length_converter)

    commands.create_terrain_surface(create_request.merge(
                                      'placement' => {
                                        'origin' => { 'x' => 10.0, 'y' => 20.0, 'z' => 1.5 }
                                      }
                                    ))

    owner = model.active_entities.groups.first
    refute_nil(owner.transformation)
    assert_equal([10.0, 20.0, 1.5], length_converter.public_meter_values)
  end

  def test_adopt_mode_erases_source_only_after_managed_output_succeeds
    model = build_semantic_model
    source = model.active_entities.add_group
    sampler = RecordingAdoptionSampler.new(source: source)
    mesh_generator = RecordingMeshGenerator.new
    commands = build_commands(
      model: model,
      adoption_sampler: sampler,
      mesh_generator: mesh_generator
    )

    result = commands.create_terrain_surface(adopt_request)

    assert_equal('adopted', result.fetch(:outcome))
    assert_equal([:generate], mesh_generator.calls)
    assert(source.erased?)
    assert_equal([:derive], sampler.calls)
  end

  def test_adoption_refusal_returns_before_opening_a_model_operation
    model = build_semantic_model
    commands = build_commands(
      model: model,
      adoption_sampler: RefusingAdoptionSampler.new
    )

    result = commands.create_terrain_surface(adopt_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_empty(model.operations)
  end

  def test_repository_refusal_aborts_operation_and_does_not_return_success
    model = build_semantic_model
    commands = build_commands(model: model, repository: RefusingRepository.new)

    result = commands.create_terrain_surface(create_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_state_save_failed', result.dig(:refusal, :code))
    assert_equal([[:start_operation, 'Create Terrain Surface', true], [:abort_operation]],
                 model.operations)
  end

  def test_output_generation_failure_aborts_operation
    model = build_semantic_model
    commands = build_commands(model: model, mesh_generator: FailingMeshGenerator.new)

    assert_raises(RuntimeError) { commands.create_terrain_surface(create_request) }
    assert_includes(model.operations, [:abort_operation])
  end

  def test_edit_mode_loads_state_saves_edited_state_and_regenerates_output
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(owner, repository.loaded_owner)
    assert_equal(2, repository.saved_state.revision)
    assert_equal([:regenerate], mesh_generator.calls)
    assert_equal(
      [[:start_operation, 'Edit Terrain Surface', true], [:commit_operation]],
      model.operations
    )
  end

  def test_edit_mode_wires_adaptive_patch_policy_for_tiled_dirty_window_output
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(tiled_state_20x20),
      mesh_generator: mesh_generator,
      grade_editor: SU_MCP::Terrain::BoundedGradeEdit.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    plan = mesh_generator.last_regenerate_args.fetch(:output_plan)
    assert_equal(:dirty_window, plan.intent)
    assert_equal(:adaptive_tin, plan.execution_strategy)
    assert_instance_of(
      SU_MCP::Terrain::PatchLifecycle::PatchGridPolicy,
      plan.adaptive_patch_policy
    )
    assert_equal(
      'adaptive-patch-v1-c0-r0',
      plan.adaptive_patch_policy.patch_id_for(column: 0, row: 0)
    )
  end

  def test_edit_mode_wires_cdt_patch_policy_for_internal_cdt_output
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new(cdt_enabled: true)
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(tiled_state_20x20),
      mesh_generator: mesh_generator,
      grade_editor: SU_MCP::Terrain::BoundedGradeEdit.new,
      terrain_feature_planner: EligibleCdtFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    plan = mesh_generator.last_regenerate_args.fetch(:output_plan)
    assert_equal(:dirty_window, plan.intent)
    assert_kind_of(SU_MCP::Terrain::CdtPatchPolicy, plan.adaptive_patch_policy)
    assert_equal(0, plan.adaptive_patch_policy.conformance_ring)
    assert_equal(
      'cdt-patch-v1-c0-r0',
      plan.adaptive_patch_policy.patch_id_for(column: 0, row: 0)
    )
  end

  def test_edit_mode_resolves_top_level_managed_terrain_without_recursive_target_resolver
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    repository = EditRepository.new(state)
    commands = build_edit_commands(
      model: model,
      repository: repository,
      target_resolver: ExplodingTargetResolver.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(owner, repository.loaded_owner)
  end

  def test_edit_mode_reports_ambiguous_top_level_managed_terrain_reference
    model = build_semantic_model
    2.times { managed_terrain_owner(model) }
    commands = build_edit_commands(
      model: model,
      target_resolver: ExplodingTargetResolver.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_target_ambiguous', result.dig(:refusal, :code))
  end

  def test_target_height_edit_passes_dirty_window_output_plan_from_changed_region
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      mesh_generator: mesh_generator
    )

    commands.edit_terrain_surface(edit_request)

    assert_dirty_window_plan(mesh_generator.last_regenerate_args.fetch(:output_plan))
  end

  def test_corridor_transition_edit_passes_dirty_window_output_plan_from_changed_region
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      mesh_generator: mesh_generator,
      edit_request_validator: AcceptingCorridorEditValidator.new
    )

    commands.edit_terrain_surface(corridor_edit_request)

    assert_dirty_window_plan(mesh_generator.last_regenerate_args.fetch(:output_plan))
  end

  def test_local_fairing_edit_passes_dirty_window_output_plan_from_changed_region
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      mesh_generator: mesh_generator,
      edit_request_validator: AcceptingLocalFairingEditValidator.new,
      local_fairing_editor: RecordingLocalFairingEditor.new
    )

    commands.edit_terrain_surface(local_fairing_edit_request)

    assert_dirty_window_plan(mesh_generator.last_regenerate_args.fetch(:output_plan))
  end

  def test_edit_mode_does_not_leak_output_strategy_fields
    model = build_semantic_model
    managed_terrain_owner(model)
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      edit_evidence_builder: SU_MCP::Terrain::TerrainEditEvidenceBuilder.new
    )

    result = commands.edit_terrain_surface(edit_request)
    serialized = JSON.generate(result.fetch(:output))

    assert_includes(result.fetch(:output).keys, :derivedMesh)
    refute_includes(serialized, 'strategy')
    refute_includes(serialized, 'regeneration')
    refute_includes(serialized, 'bulk')
    refute_includes(serialized, 'candidate')
  end

  def test_target_height_edit_dispatches_to_grade_editor
    model = build_semantic_model
    managed_terrain_owner(model)
    grade_editor = RecordingGradeEditor.new
    corridor_editor = RecordingCorridorEditor.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      grade_editor: grade_editor,
      corridor_editor: corridor_editor
    )

    commands.edit_terrain_surface(edit_request)

    assert_equal(1, grade_editor.calls.length)
    assert_empty(corridor_editor.calls)
  end

  def test_corridor_transition_dispatches_to_corridor_editor_and_reuses_regeneration_flow
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    grade_editor = RecordingGradeEditor.new
    corridor_editor = RecordingCorridorEditor.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      grade_editor: grade_editor,
      corridor_editor: corridor_editor
    )

    result = commands.edit_terrain_surface(corridor_edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_empty(grade_editor.calls)
    assert_equal(1, corridor_editor.calls.length)
    assert_equal(2, repository.saved_state.revision)
    assert_equal([:regenerate], mesh_generator.calls)
  end

  def test_local_fairing_dispatches_to_local_fairing_editor_and_reuses_regeneration_flow
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    grade_editor = RecordingGradeEditor.new
    corridor_editor = RecordingCorridorEditor.new
    local_fairing_editor = RecordingLocalFairingEditor.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      grade_editor: grade_editor,
      corridor_editor: corridor_editor,
      local_fairing_editor: local_fairing_editor
    )

    result = commands.edit_terrain_surface(local_fairing_edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_empty(grade_editor.calls)
    assert_empty(corridor_editor.calls)
    assert_equal(1, local_fairing_editor.calls.length)
    assert_equal(2, repository.saved_state.revision)
    assert_equal([:regenerate], mesh_generator.calls)
  end

  def test_survey_point_constraint_dispatches_to_survey_editor_and_reuses_regeneration_flow
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    grade_editor = RecordingGradeEditor.new
    survey_editor = RecordingSurveyPointConstraintEditor.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      edit_request_validator: AcceptingSurveyEditValidator.new,
      grade_editor: grade_editor,
      survey_point_editor: survey_editor
    )

    result = commands.edit_terrain_surface(survey_edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_empty(grade_editor.calls)
    assert_equal(1, survey_editor.calls.length)
    assert_equal('survey_point_constraint',
                 survey_editor.calls.first.fetch(:request).dig('operation', 'mode'))
    assert_equal(2, repository.saved_state.revision)
    assert_equal([:regenerate], mesh_generator.calls)
  end

  def test_planar_region_fit_dispatches_to_planar_editor_and_reuses_regeneration_flow
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    grade_editor = RecordingGradeEditor.new
    planar_editor = RecordingPlanarRegionFitEditor.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      edit_request_validator: AcceptingPlanarRegionFitValidator.new,
      grade_editor: grade_editor,
      planar_region_fit_editor: planar_editor
    )

    result = commands.edit_terrain_surface(planar_region_fit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_empty(grade_editor.calls)
    assert_equal(1, planar_editor.calls.length)
    assert_equal('planar_region_fit',
                 planar_editor.calls.first.fetch(:request).dig('operation', 'mode'))
    assert_equal(2, repository.saved_state.revision)
    assert_equal([:regenerate], mesh_generator.calls)
  end

  def test_corridor_transition_refusal_happens_before_save_or_model_operation
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    commands = build_edit_commands(
      model: model,
      repository: repository,
      edit_request_validator: AcceptingCorridorEditValidator.new,
      corridor_editor: RefusingCorridorEditor.new
    )

    result = commands.edit_terrain_surface(corridor_edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_nil(repository.saved_state)
    assert_empty(model.operations)
  end

  def test_local_fairing_refusals_happen_before_save_or_model_operation
    %w[fairing_no_effect fixed_control_conflict].each do |code|
      model = build_semantic_model
      managed_terrain_owner(model)
      repository = EditRepository.new(state)
      mesh_generator = RecordingRegeneratingMeshGenerator.new
      commands = build_edit_commands(
        model: model,
        repository: repository,
        mesh_generator: mesh_generator,
        edit_request_validator: AcceptingLocalFairingEditValidator.new,
        local_fairing_editor: RefusingLocalFairingEditor.new(code)
      )

      result = commands.edit_terrain_surface(local_fairing_edit_request)

      assert_equal('refused', result.fetch(:outcome))
      assert_equal(code, result.dig(:refusal, :code))
      assert_nil(repository.saved_state)
      assert_empty(mesh_generator.calls)
      assert_empty(model.operations)
    end
  end

  def test_survey_point_constraint_refusal_happens_before_save_or_model_operation
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      edit_request_validator: AcceptingSurveyEditValidator.new,
      survey_point_editor: RefusingSurveyPointConstraintEditor.new
    )

    result = commands.edit_terrain_surface(survey_edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('survey_point_outside_support_region', result.dig(:refusal, :code))
    assert_nil(repository.saved_state)
    assert_empty(mesh_generator.calls)
    assert_empty(model.operations)
  end

  def test_planar_region_fit_refusal_happens_before_save_or_model_operation
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      edit_request_validator: AcceptingPlanarRegionFitValidator.new,
      planar_region_fit_editor: RefusingPlanarRegionFitEditor.new
    )

    result = commands.edit_terrain_surface(planar_region_fit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('non_coplanar_controls', result.dig(:refusal, :code))
    assert_nil(repository.saved_state)
    assert_empty(mesh_generator.calls)
    assert_empty(model.operations)
  end

  def test_edit_refusal_returns_before_opening_model_operation
    model = build_semantic_model
    commands = build_edit_commands(model: model, edit_request_validator: RefusingEditValidator.new)

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_empty(model.operations)
  end

  def test_edit_regeneration_refusal_aborts_operation_without_success
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    existing_face = owner.entities.add_face([0, 0, 0], [1, 0, 0], [1, 1, 0])
    existing_face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    repository = EditRepository.new(state)
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: RefusingRegeneratingMeshGenerator.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_contains_unsupported_entities', result.dig(:refusal, :code))
    assert_equal([[:start_operation, 'Edit Terrain Surface', true], [:abort_operation]],
                 model.operations)
    assert_instance_of(SU_MCP::Terrain::TiledHeightmapState, repository.saved_state)
    assert_includes(owner.entities.faces, existing_face)
  end

  def test_real_feature_planner_conflict_refusal_strips_internal_diagnostics_publicly
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    commands = build_edit_commands(
      model: model,
      repository: repository,
      terrain_feature_intent_emitter: ConflictFeatureIntentEmitter.new,
      terrain_feature_planner: SU_MCP::Terrain::TerrainFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_feature_conflict', result.dig(:refusal, :code))
    refute_includes(result.keys, :diagnostics)
    assert_nil(repository.saved_state)
    refute_feature_leak(result)
  end

  def test_feature_pre_save_refusal_happens_before_repository_save_and_regeneration
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: RecordingFeatureIntentEmitter.new,
      terrain_feature_planner: RefusingFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_feature_conflict', result.dig(:refusal, :code))
    assert_nil(repository.saved_state)
    assert_empty(mesh_generator.calls)
    assert_equal([[:start_operation, 'Edit Terrain Surface', true], [:abort_operation]],
                 model.operations)
    refute_feature_leak(result)
  end

  def test_feature_post_save_context_drives_full_regeneration_fallback_when_windows_do_not_reconcile
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: RecordingFeatureIntentEmitter.new,
      terrain_feature_planner: FullFallbackFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(:full_grid, mesh_generator.last_regenerate_args.fetch(:output_plan).intent)
    assert_nil(mesh_generator.last_regenerate_args.fetch(:feature_context))
  end

  def test_feature_context_expands_dirty_window_before_partial_regeneration
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state_4x4),
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: RecordingFeatureIntentEmitter.new,
      terrain_feature_planner: FeatureWindowPlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(
      SU_MCP::Terrain::SampleWindow.new(
        min_column: 0,
        min_row: 0,
        max_column: 2,
        max_row: 2
      ),
      mesh_generator.last_regenerate_args.fetch(:output_plan).window
    )
  end

  def test_cdt_state_coherence_uses_saved_feature_state_for_output_generation
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new(cdt_enabled: true)
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: RecordingFeatureIntentEmitter.new,
      terrain_feature_planner: FullFallbackFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(
      mesh_generator.last_regenerate_args.dig(:feature_context, :terrainStateDigest),
      mesh_generator.last_regenerate_args.fetch(:terrain_state_summary).fetch(:digest)
    )
    assert_respond_to(
      mesh_generator.last_regenerate_args.dig(:feature_context, :terrainState),
      :feature_intent,
      'production CDT must receive the saved feature-merged terrain state in its feature context'
    )
  end

  def test_cdt_feature_planning_receives_edit_relevance_window
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new(cdt_enabled: true)
    planner = RecordingSelectionWindowPlanner.new
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state_4x4),
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: RecordingFeatureIntentEmitter.new,
      terrain_feature_planner: planner
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(expected_changed_region_window, planner.selection_window)
    assert(mesh_generator.last_regenerate_args.fetch(:feature_context))
  end

  def test_cdt_feature_context_uses_patch_relevant_selector_geometry
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new(cdt_enabled: true)
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state_20x20),
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: PatchRelevantFeatureIntentEmitter.new,
      terrain_feature_planner: SU_MCP::Terrain::TerrainFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    feature_context = mesh_generator.last_regenerate_args.fetch(:feature_context)
    geometry = feature_context.fetch(:featureGeometry)
    diagnostics = feature_context.fetch(:featureSelectionDiagnostics)
    assert_empty(
      geometry.output_anchor_candidates,
      'far fixed hard control must not reach CDT feature geometry for this local patch'
    )
    assert_equal(1, geometry.pressure_regions.length)
    assert_equal({ hard: 0, firm: 0, soft: 1 }, diagnostics.fetch(:includedByStrength))
    assert_equal({ hard: 1, firm: 0, soft: 0 }, diagnostics.fetch(:excludedByStrength))
  end

  def test_valid_edit_succeeds_when_feature_planner_skips_cdt_participation
    model = build_semantic_model
    managed_terrain_owner(model)
    mesh_generator = RecordingRegeneratingMeshGenerator.new(cdt_enabled: true)
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state_4x4),
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: RecordingFeatureIntentEmitter.new,
      terrain_feature_planner: CdtSkippingFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal('skip', mesh_generator.last_regenerate_args
      .dig(:feature_context, :cdtParticipation, :status))
    refute_feature_leak(result)
    refute_includes(JSON.generate(result), 'patch_relevant_feature_geometry_failed')
  end

  def test_repeated_cdt_skips_do_not_expand_dirty_window_beyond_changed_region
    model = build_semantic_model
    managed_terrain_owner(model)
    repository = EditRepository.new(state_4x4)
    mesh_generator = RecordingRegeneratingMeshGenerator.new(cdt_enabled: true)
    commands = build_edit_commands(
      model: model,
      repository: repository,
      mesh_generator: mesh_generator,
      terrain_feature_intent_emitter: RecordingFeatureIntentEmitter.new,
      terrain_feature_planner: CdtSkippingFeaturePlanner.new
    )

    2.times { assert_equal('edited', commands.edit_terrain_surface(edit_request).fetch(:outcome)) }

    windows = mesh_generator.regenerate_args.map { |args| args.fetch(:output_plan).window }
    assert_equal([expected_changed_region_window, expected_changed_region_window], windows)
  end

  def test_edit_command_drives_eligible_feature_context_into_cdt_patch_replacement
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    patch_id = 'cdt-patch-v1-c0-r0'
    old_face = add_owned_cdt_patch_face(owner.entities, patch_id: patch_id, face_index: 0)
    write_cdt_registry(owner, patch_id: patch_id, face_count: 1)
    provider = RecordingPatchReplacementProvider.accepted(patch_id: patch_id)
    mesh_generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_patch_replacement_provider: provider
    )
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(tiled_state_20x20),
      mesh_generator: mesh_generator,
      terrain_feature_planner: EligibleCdtFeaturePlanner.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert_equal(1, provider.calls)
    refute_includes(owner.entities.faces, old_face)
    assert_cdt_patch_provider_received_eligible_dirty_window(provider)
    refute_cdt_patch_public_leak(result)
  end

  def test_edit_command_uses_real_feature_planner_and_provider_for_cdt_patch_mutation
    context = build_real_cdt_junction_context

    result = context.fetch(:commands).edit_terrain_surface(edit_request)

    assert_equal('edited', result.fetch(:outcome))
    assert(context.fetch(:mesh_generator).cdt_enabled?)
    assert_equal(1, context.fetch(:provider).calls)
    assert_equal(1, context.fetch(:solver).calls)
    assert_real_mta33_context_reached_provider(context.fetch(:provider))
    assert_real_provider_called_stable_domain_solver(context)
    assert_dirty_patch_batch_plan(context.fetch(:provider).last_build_args.fetch(:batch_plan))
    assert_real_cdt_junction_mutation(context)
    assert_real_cdt_timing_buckets(context)
    assert_equal('adaptive_tin', result.dig(:output, :derivedMesh, :meshType))
    refute_cdt_patch_public_leak(result)
  end

  def build_real_cdt_junction_context
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    patch_id = 'cdt-patch-v1-c0-r0'
    old_patch_face = add_owned_cdt_patch_face(
      owner.entities,
      patch_id: patch_id,
      face_index: 0,
      points: [[0.0, 0.0, 2.0], [16.0, 0.0, 2.0], [16.0, 16.0, 2.0]]
    )
    preserved_neighbor = add_owned_cdt_patch_face(
      owner.entities,
      patch_id: 'cdt-patch-v1-c1-r0',
      face_index: 0,
      border_side: 'west',
      points: [[16.0, 0.0, 2.0], [18.0, 0.0, 2.0], [16.0, 16.0, 2.0]]
    )
    write_cdt_registry(owner, patch_id: patch_id, face_count: 1)
    solver = RecordingStableDomainSolver.new
    provider = RecordingStableDomainCdtReplacementProvider.new(solver: solver)
    mesh_generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_patch_replacement_provider: provider
    )
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(tiled_state_20x20),
      mesh_generator: mesh_generator,
      edit_evidence_builder: SU_MCP::Terrain::TerrainEditEvidenceBuilder.new,
      terrain_feature_intent_emitter: PatchRelevantFeatureIntentEmitter.new,
      terrain_feature_planner: SU_MCP::Terrain::TerrainFeaturePlanner.new
    )

    {
      owner: owner,
      old_patch_face: old_patch_face,
      preserved_neighbor: preserved_neighbor,
      patch_id: patch_id,
      provider: provider,
      solver: solver,
      mesh_generator: mesh_generator,
      commands: commands
    }
  end

  def test_edit_aborts_operation_when_cdt_patch_mutation_fails_after_erase_begins
    model = build_semantic_model
    owner = managed_terrain_owner(model)
    patch_id = 'cdt-patch-v1-c0-r0'
    add_owned_cdt_patch_face(owner.entities, patch_id: patch_id, face_index: 0)
    write_cdt_registry(owner, patch_id: patch_id, face_count: 1)
    raise_once_on_next_face_add(owner.entities)
    mesh_generator = SU_MCP::Terrain::TerrainMeshGenerator.new(
      length_converter: ScalingLengthConverter.new(multiplier: 1.0),
      cdt_patch_replacement_provider: RecordingPatchReplacementProvider.accepted(
        patch_id: patch_id
      )
    )
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(tiled_state_20x20),
      mesh_generator: mesh_generator,
      terrain_feature_planner: EligibleCdtFeaturePlanner.new
    )

    assert_raises(RuntimeError) { commands.edit_terrain_surface(edit_request) }
    assert_equal(
      [[:start_operation, 'Edit Terrain Surface', true], [:abort_operation]],
      model.operations
    )
  end

  private

  def refute_feature_leak(result)
    serialized = JSON.generate(result)
    %w[
      feature: target_region affectedWindow FeatureIntentSet pointified rawTriangles
    ].each do |term|
      refute_includes(serialized, term)
    end
  end

  def assert_dirty_window_plan(plan)
    assert_instance_of(SU_MCP::Terrain::TerrainOutputPlan, plan)
    assert_equal(:dirty_window, plan.intent)
    assert_equal(:full_grid, plan.execution_strategy)
    assert_equal(expected_changed_region_window, plan.window)
    assert_equal([0, 0, 0, 0], bounds_for(plan.cell_window))
  end

  def assert_cdt_patch_provider_received_eligible_dirty_window(provider)
    batch_plan = provider.last_build_args.fetch(:batch_plan)
    assert_includes(batch_plan.replacement_patch_ids, 'cdt-patch-v1-c0-r0')
    assert_equal(
      'eligible',
      provider.last_build_args.fetch(:feature_context).dig(:cdtParticipation, :status)
    )
    assert_instance_of(
      SU_MCP::Terrain::TerrainFeatureGeometry,
      provider.last_build_args.fetch(:feature_geometry)
    )
  end

  def assert_real_mta33_context_reached_provider(provider)
    feature_context = provider.last_build_args.fetch(:feature_context)
    geometry = provider.last_build_args.fetch(:feature_geometry)
    diagnostics = feature_context.fetch(:featureSelectionDiagnostics)

    assert_instance_of(SU_MCP::Terrain::TerrainFeatureGeometry, geometry)
    assert_equal(
      geometry.feature_geometry_digest,
      feature_context.fetch(:featureGeometryDigest)
    )
    assert_equal('eligible', feature_context.dig(:cdtParticipation, :status))
    assert_equal({ hard: 0, firm: 0, soft: 1 }, diagnostics.fetch(:includedByStrength))
    assert_equal({ hard: 1, firm: 0, soft: 0 }, diagnostics.fetch(:excludedByStrength))
    assert_empty(geometry.output_anchor_candidates)
    assert_equal(1, geometry.pressure_regions.length)
  end

  def assert_real_provider_called_stable_domain_solver(context)
    provider_args = context.fetch(:provider).last_build_args
    solver_args = context.fetch(:solver).last_solve_args

    assert_same(provider_args.fetch(:state), solver_args.fetch(:state))
    assert_same(provider_args.fetch(:feature_geometry), solver_args.fetch(:feature_geometry))
    assert_equal(
      provider_args.fetch(:batch_plan).replacement_patches,
      solver_args.fetch(:replacement_patches)
    )
    refute_includes(JSON.generate(solver_args), 'PatchCdtDomain')
    refute_includes(JSON.generate(solver_args), 'debugMesh')
  end

  def assert_dirty_patch_batch_plan(batch_plan)
    assert_includes(batch_plan.affected_patch_ids, 'cdt-patch-v1-c0-r0')
    assert_includes(batch_plan.replacement_patch_ids, 'cdt-patch-v1-c0-r0')
    refute_empty(batch_plan.replacement_patches)
    feature_plan = batch_plan.feature_plan
    assert(feature_plan.key?(:selectedFeaturePool))
    refute_empty(feature_plan.fetch(:patchFeatureBundles))
    assert_match(/\A[a-f0-9]{64}\z/, feature_plan.fetch(:featureSelectionDigest))
    retained_spans = batch_plan.retained_boundary_spans
    refute_empty(retained_spans)
    assert_includes(
      retained_spans.map { |span| span.fetch(:patchId) },
      'cdt-patch-v1-c1-r0'
    )
  end

  def assert_real_cdt_junction_mutation(context)
    owner = context.fetch(:owner)
    preserved_neighbor = context.fetch(:preserved_neighbor)
    refute_includes(owner.entities.faces, context.fetch(:old_patch_face))
    assert_includes(owner.entities.faces, preserved_neighbor)
    replacement_faces = owner.entities.faces.reject { |face| face.equal?(preserved_neighbor) }

    assert_equal(2, replacement_faces.length)
    assert_replacement_faces_metadata(replacement_faces, context.fetch(:patch_id))
  end

  def assert_real_cdt_timing_buckets(context)
    buckets = context.fetch(:mesh_generator).last_cdt_patch_timing.fetch(:buckets)
    %i[
      command_prep
      feature_selection
      cdt_input_build
      retained_boundary_snapshot
      solve
      topology_validation
      ownership_lookup
      seam_validation
      mutation
      registry_write
      audit
      total
    ].each do |bucket|
      assert(buckets.key?(bucket), "missing #{bucket} timing bucket")
    end
  end

  def assert_replacement_faces_metadata(replacement_faces, patch_id)
    assert(replacement_faces.all? do |face|
      terrain_attribute(face, 'outputKind') == 'cdt_patch_face'
    end)
    assert(replacement_faces.all? do |face|
      terrain_attribute(face, 'cdtPatchId') == patch_id
    end)
    assert(replacement_faces.all? do |face|
      terrain_attribute(face, 'cdtReplacementBatchId')
    end)
    assert(replacement_faces.all? { |face| face.normal.z.positive? })
  end

  def terrain_attribute(entity, key)
    entity.get_attribute('su_mcp_terrain', key)
  end

  def refute_cdt_patch_public_leak(result)
    serialized = JSON.generate(result)
    %w[
      local_patch_replacement PatchCdtDomain debugMesh patchCdtReplacement
      patchDomainDigest replacementBatchId featureSelectionDiagnostics
      cdtParticipation rawTriangles fallbackCategory seamValidation
    ].each do |term|
      refute_includes(serialized, term)
    end
  end

  def bounds_for(window)
    [window.min_column, window.min_row, window.max_column, window.max_row]
  end

  def expected_changed_region_window
    SU_MCP::Terrain::SampleWindow.new(
      min_column: 0,
      min_row: 0,
      max_column: 1,
      max_row: 1
    )
  end

  def build_commands(model:, repository: RecordingRepository.new,
                     state_builder: StateBuilder.new,
                     mesh_generator: RecordingMeshGenerator.new,
                     adoption_sampler: RecordingAdoptionSampler.new,
                     length_converter: ScalingLengthConverter.new(multiplier: 10.0),
                     terrain_feature_planner: nil)
    options = {
      model: model,
      validator: AcceptingValidator.new,
      state_builder: state_builder,
      repository: repository,
      mesh_generator: mesh_generator,
      evidence_builder: EvidenceBuilder.new,
      adoption_sampler: adoption_sampler,
      length_converter: length_converter
    }
    options[:terrain_feature_planner] = terrain_feature_planner if terrain_feature_planner

    SU_MCP::Terrain::TerrainSurfaceCommands.new(
      **options
    )
  end

  def build_edit_commands(model:, repository: EditRepository.new(state),
                          mesh_generator: RecordingRegeneratingMeshGenerator.new,
                          edit_request_validator: AcceptingEditValidator.new,
                          grade_editor: RecordingGradeEditor.new,
                          corridor_editor: RecordingCorridorEditor.new,
                          local_fairing_editor: nil,
                          survey_point_editor: nil,
                          planar_region_fit_editor: nil,
                          target_resolver: RecordingTargetResolver.new,
                          edit_evidence_builder: EditEvidenceBuilder.new,
                          terrain_feature_intent_emitter: nil,
                          terrain_feature_planner: nil)
    options = {
      model: model,
      validator: AcceptingValidator.new,
      state_builder: StateBuilder.new,
      repository: repository,
      mesh_generator: mesh_generator,
      evidence_builder: EvidenceBuilder.new,
      adoption_sampler: RecordingAdoptionSampler.new,
      edit_request_validator: edit_request_validator,
      grade_editor: grade_editor,
      corridor_editor: corridor_editor,
      target_resolver: target_resolver,
      edit_evidence_builder: edit_evidence_builder
    }
    if terrain_feature_intent_emitter
      options[:terrain_feature_intent_emitter] = terrain_feature_intent_emitter
    end
    options[:terrain_feature_planner] = terrain_feature_planner if terrain_feature_planner
    options[:local_fairing_editor] = local_fairing_editor if local_fairing_editor
    options[:survey_point_editor] = survey_point_editor if survey_point_editor
    options[:planar_region_fit_editor] = planar_region_fit_editor if planar_region_fit_editor

    SU_MCP::Terrain::TerrainSurfaceCommands.new(**options)
  end

  def create_request
    { 'metadata' => { 'sourceElementId' => 'terrain-main', 'status' => 'existing' },
      'lifecycle' => { 'mode' => 'create' } }
  end

  def adopt_request
    { 'metadata' => { 'sourceElementId' => 'terrain-main', 'status' => 'existing' },
      'lifecycle' => { 'mode' => 'adopt', 'target' => { 'sourceElementId' => 'source' } } }
  end

  def edit_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => { 'mode' => 'target_height', 'targetElevation' => 12.5 },
      'region' => {
        'type' => 'rectangle',
        'bounds' => {
          'minX' => 0.0,
          'minY' => 0.0,
          'maxX' => 1.0,
          'maxY' => 1.0
        }
      }
    }
  end

  def corridor_edit_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => { 'mode' => 'corridor_transition' },
      'region' => {
        'type' => 'corridor',
        'startControl' => { 'point' => { 'x' => 0.0, 'y' => 1.0 }, 'elevation' => 1.0 },
        'endControl' => { 'point' => { 'x' => 2.0, 'y' => 1.0 }, 'elevation' => 3.0 },
        'width' => 1.0,
        'sideBlend' => { 'distance' => 0.0, 'falloff' => 'none' }
      }
    }
  end

  def local_fairing_edit_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => {
        'mode' => 'local_fairing',
        'strength' => 0.35,
        'neighborhoodRadiusSamples' => 2,
        'iterations' => 1
      },
      'region' => {
        'type' => 'rectangle',
        'bounds' => {
          'minX' => 0.0,
          'minY' => 0.0,
          'maxX' => 1.0,
          'maxY' => 1.0
        }
      }
    }
  end

  def survey_edit_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => {
        'mode' => 'survey_point_constraint',
        'correctionScope' => 'local'
      },
      'region' => {
        'type' => 'rectangle',
        'bounds' => {
          'minX' => 0.0,
          'minY' => 0.0,
          'maxX' => 1.0,
          'maxY' => 1.0
        }
      },
      'constraints' => {
        'surveyPoints' => [
          { 'id' => 'survey-1', 'point' => { 'x' => 1.0, 'y' => 1.0, 'z' => 2.0 } }
        ]
      }
    }
  end

  def planar_region_fit_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => { 'mode' => 'planar_region_fit' },
      'region' => {
        'type' => 'rectangle',
        'bounds' => {
          'minX' => 0.0,
          'minY' => 0.0,
          'maxX' => 1.0,
          'maxY' => 1.0
        }
      },
      'constraints' => {
        'planarControls' => [
          { 'id' => 'sw', 'point' => { 'x' => 0.0, 'y' => 0.0, 'z' => 1.0 } },
          { 'id' => 'se', 'point' => { 'x' => 1.0, 'y' => 0.0, 'z' => 1.0 } },
          { 'id' => 'nw', 'point' => { 'x' => 0.0, 'y' => 1.0, 'z' => 1.1 } }
        ]
      }
    }
  end

  def managed_terrain_owner(model)
    owner = model.active_entities.add_group
    owner.set_attribute('su_mcp', 'sourceElementId', 'terrain-main')
    owner.set_attribute('su_mcp', 'semanticType', 'managed_terrain_surface')
    owner
  end

  def add_owned_cdt_patch_face(entities, face_index:, patch_id:, points: nil, border_side: nil)
    face = entities.add_face(*(points || [[0.0, 0.0, 1.0], [2.0, 0.0, 1.0], [2.0, 2.0, 1.0]]))
    face.set_attribute('su_mcp_terrain', 'derivedOutput', true)
    face.set_attribute('su_mcp_terrain', 'outputKind', 'cdt_patch_face')
    face.set_attribute('su_mcp_terrain', 'cdtOwnershipSchemaVersion', 1)
    face.set_attribute('su_mcp_terrain', 'cdtPatchId', patch_id)
    face.set_attribute('su_mcp_terrain', 'cdtReplacementBatchId', 'old-batch')
    face.set_attribute('su_mcp_terrain', 'cdtPatchFaceIndex', face_index)
    face.set_attribute('su_mcp_terrain', 'cdtBorderSide', border_side) if border_side
    face
  end

  def write_cdt_registry(owner, patch_id:, face_count:)
    SU_MCP::Terrain::PatchLifecycle::PatchRegistryStore.new(
      registry_key: SU_MCP::Terrain::TerrainMeshGenerator::ADAPTIVE_PATCH_REGISTRY_KEY
    ).write!(
      owner: owner,
      registry: {
        outputPolicyFingerprint: nil,
        stateDigest: 'digest-1',
        stateRevision: 1,
        ownerTransformSignature: nil,
        patches: [
          {
            patchId: patch_id,
            bounds: { minColumn: 0, minRow: 0, maxColumn: 15, maxRow: 15 },
            outputBounds: { minColumn: 0, minRow: 0, maxColumn: 15, maxRow: 15 },
            replacementBatchId: 'old-batch',
            faceCount: face_count,
            status: 'valid'
          }
        ]
      }
    )
  end

  def raise_once_on_next_face_add(entities)
    original_add_face = entities.method(:add_face)
    raised = false
    entities.define_singleton_method(:add_face) do |*points|
      unless raised
        raised = true
        raise 'replacement emit failed'
      end

      original_add_face.call(*points)
    end
  end

  def state
    SU_MCP::Terrain::HeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 2, 'rows' => 2 },
      elevations: [1.0, 1.0, 1.0, 1.0],
      revision: 1,
      state_id: 'state-1'
    )
  end

  def state_4x4
    SU_MCP::Terrain::HeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 4, 'rows' => 4 },
      elevations: Array.new(16, 1.0),
      revision: 1,
      state_id: 'state-4x4'
    )
  end

  def state_20x20
    SU_MCP::Terrain::HeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 20, 'rows' => 20 },
      elevations: Array.new(400, 1.0),
      revision: 1,
      state_id: 'state-20x20'
    )
  end

  def tiled_state_20x20
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      },
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 20, 'rows' => 20 },
      elevations: Array.new(400, 1.0),
      revision: 1,
      state_id: 'tiled-state-20x20'
    )
  end

  class AcceptingValidator
    def validate(params)
      { outcome: 'ready', lifecycle_mode: params.dig('lifecycle', 'mode'), params: params }
    end
  end

  class StateBuilder
    def build_create_state(...)
      build_state
    end

    def build_adopted_state(...)
      build_state
    end

    private

    def build_state
      SU_MCP::Terrain::HeightmapState.new(
        basis: {
          'xAxis' => [1.0, 0.0, 0.0],
          'yAxis' => [0.0, 1.0, 0.0],
          'zAxis' => [0.0, 0.0, 1.0],
          'vertical' => 'z_up'
        },
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: { 'columns' => 2, 'rows' => 2 },
        elevations: [1.0, 1.0, 1.0, 1.0],
        revision: 1,
        state_id: 'state-1'
      )
    end
  end

  class FeatureIntentStateBuilder < StateBuilder
    def build_create_state(...)
      state = super
      state.define_singleton_method(:feature_intent) do
        SU_MCP::Terrain::FeatureIntentSet.default_h
      end
      state
    end
  end

  class TiledStateBuilder < StateBuilder
    def build_create_state(...)
      SU_MCP::Terrain::TiledHeightmapState.new(
        basis: {
          'xAxis' => [1.0, 0.0, 0.0],
          'yAxis' => [0.0, 1.0, 0.0],
          'zAxis' => [0.0, 0.0, 1.0],
          'vertical' => 'z_up'
        },
        origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
        spacing: { 'x' => 1.0, 'y' => 1.0 },
        dimensions: { 'columns' => 20, 'rows' => 20 },
        elevations: Array.new(400, 1.0),
        revision: 1,
        state_id: 'tiled-state-20x20'
      )
    end
  end

  class RecordingRepository
    def save(owner, state)
      owner.set_attribute('su_mcp_terrain', 'statePayload', '{"payloadKind":"heightmap_grid"}')
      { outcome: 'saved', state: state, summary: { digest: 'digest-1', serializedBytes: 120 } }
    end
  end

  class RefusingRepository
    def save(_owner, _state)
      {
        outcome: 'refused',
        refusal: { code: 'write_failed', message: 'no write' }
      }
    end
  end

  class EditRepository < RecordingRepository
    attr_reader :loaded_owner, :saved_state

    def initialize(state)
      super()
      @state = state
    end

    def load(owner)
      @loaded_owner = owner
      { outcome: 'loaded', state: @state, summary: { digest: 'digest-1' } }
    end

    def save(owner, state)
      @saved_state = state
      super
    end
  end

  class RecordingMeshGenerator
    attr_reader :calls, :last_generate_args

    def initialize(cdt_enabled: false)
      @calls = []
      @cdt_enabled = cdt_enabled
    end

    def cdt_enabled?
      @cdt_enabled
    end

    def generate(owner:, state:, terrain_state_summary:, output_plan: nil, feature_context: nil)
      @calls << :generate
      @last_generate_args = {
        owner: owner,
        state: state,
        terrain_state_summary: terrain_state_summary,
        output_plan: output_plan,
        feature_context: feature_context
      }
      { outcome: 'generated', summary: { derivedMesh: { derivedFromStateDigest: 'digest-1' } } }
    end
  end

  class RecordingRegeneratingMeshGenerator < RecordingMeshGenerator
    attr_reader :last_regenerate_args, :regenerate_args

    def initialize(...)
      super
      @regenerate_args = []
    end

    def regenerate(owner:, state:, terrain_state_summary:, output_plan: nil, feature_context: nil)
      @calls << :regenerate
      @last_regenerate_args = {
        owner: owner,
        state: state,
        terrain_state_summary: terrain_state_summary,
        output_plan: output_plan,
        feature_context: feature_context
      }
      @regenerate_args << @last_regenerate_args
      { outcome: 'generated', summary: { derivedMesh: { derivedFromStateDigest: 'digest-2' } } }
    end
  end

  class RefusingRegeneratingMeshGenerator
    def regenerate(...)
      {
        outcome: 'refused',
        refusal: {
          code: 'terrain_output_contains_unsupported_entities',
          message: 'Owner contains unsupported child output.'
        }
      }
    end
  end

  class RecordingFeatureIntentEmitter
    def emit(...)
      {
        'upsert_features' => [
          {
            'id' => 'feature:target_region:explicit_edit:region-a:aaaaaaaaaaaa',
            'kind' => 'target_region',
            'sourceMode' => 'explicit_edit',
            'roles' => ['boundary'],
            'priority' => 30,
            'payload' => { 'semanticScope' => 'region-a' },
            'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                                  'max' => { 'column' => 1, 'row' => 1 } },
            'provenance' => {
              'originClass' => 'edit_terrain_surface',
              'originOperation' => 'target_height',
              'createdAtRevision' => 2,
              'updatedAtRevision' => 2
            }
          }
        ]
      }
    end
  end

  class PatchRelevantFeatureIntentEmitter
    def emit(...)
      {
        'upsert_features' => [
          {
            'id' => 'feature:target_region:explicit_edit:local-target:aaaaaaaaaaaa',
            'kind' => 'target_region',
            'sourceMode' => 'explicit_edit',
            'semanticScope' => 'local-target',
            'roles' => %w[support falloff],
            'priority' => 30,
            'payload' => {
              'semanticScope' => 'local-target',
              'region' => {
                'type' => 'rectangle',
                'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 1.0, 'maxY' => 1.0 }
              }
            },
            'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                                  'max' => { 'column' => 1, 'row' => 1 } },
            'relevanceWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                                   'max' => { 'column' => 1, 'row' => 1 } },
            'provenance' => {
              'originClass' => 'edit_terrain_surface',
              'originOperation' => 'target_height',
              'createdAtRevision' => 2,
              'updatedAtRevision' => 2
            }
          },
          {
            'id' => 'feature:fixed_control:explicit_edit:far-fixed:bbbbbbbbbbbb',
            'kind' => 'fixed_control',
            'sourceMode' => 'explicit_edit',
            'semanticScope' => 'far-fixed',
            'strengthClass' => 'hard',
            'roles' => %w[control protected],
            'priority' => 80,
            'payload' => {
              'semanticScope' => 'far-fixed',
              'control' => { 'point' => { 'x' => 12.0, 'y' => 12.0 } }
            },
            'affectedWindow' => { 'min' => { 'column' => 12, 'row' => 12 },
                                  'max' => { 'column' => 12, 'row' => 12 } },
            'relevanceWindow' => { 'min' => { 'column' => 12, 'row' => 12 },
                                   'max' => { 'column' => 12, 'row' => 12 } },
            'provenance' => {
              'originClass' => 'edit_terrain_surface',
              'originOperation' => 'fixed_control',
              'createdAtRevision' => 2,
              'updatedAtRevision' => 2
            }
          }
        ]
      }
    end
  end

  class ConflictFeatureIntentEmitter
    def emit(...)
      fixed_id = 'feature:fixed_control:explicit_edit:fixed-a:aaaaaaaaaaaa'
      target_id = 'feature:target_region:explicit_edit:region-a:bbbbbbbbbbbb'
      {
        'upsert_features' => [
          feature(
            id: fixed_id,
            kind: 'fixed_control',
            roles: %w[control protected],
            payload: { 'semanticScope' => 'fixed-a' }
          ),
          feature(
            id: target_id,
            kind: 'target_region',
            roles: %w[boundary],
            payload: {
              'semanticScope' => 'region-a',
              'conflictsWithFeatureIds' => [fixed_id]
            }
          )
        ]
      }
    end

    private

    def feature(id:, kind:, roles:, payload:)
      {
        'id' => id,
        'kind' => kind,
        'sourceMode' => 'explicit_edit',
        'roles' => roles,
        'priority' => 50,
        'payload' => payload,
        'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                              'max' => { 'column' => 1, 'row' => 1 } },
        'provenance' => {
          'originClass' => 'edit_terrain_surface',
          'originOperation' => kind,
          'createdAtRevision' => 1,
          'updatedAtRevision' => 1
        }
      }
    end
  end

  class RefusingFeaturePlanner
    def pre_save(...)
      {
        outcome: 'refused',
        refusal: {
          code: 'terrain_feature_conflict',
          message: 'Terrain feature intent conflicts with protected terrain constraints.',
          details: { category: 'feature_conflict', featureCount: 2 }
        }
      }
    end
  end

  class FullFallbackFeaturePlanner
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
          constraintCount: 1,
          terrainStateDigest: terrain_state_summary.fetch(:digest)
        },
        outputWindowReconciliation: { mode: 'full_grid' }
      }
    end
  end

  class FeatureWindowPlanner
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
          constraintCount: 1,
          terrainStateDigest: terrain_state_summary.fetch(:digest),
          constraints: [
            {
              affectedWindow: {
                'min' => { 'column' => 0, 'row' => 0 },
                'max' => { 'column' => 2, 'row' => 2 }
              }
            }
          ]
        },
        outputWindowReconciliation: { mode: 'feature_window' }
      }
    end
  end

  class RecordingSelectionWindowPlanner
    attr_reader :selection_window

    def pre_save(state:)
      { outcome: 'ready', state: state }
    end

    def prepare(state:, terrain_state_summary:, include_feature_geometry: false,
                selection_window: nil)
      @selection_window = selection_window
      _include_feature_geometry = include_feature_geometry
      {
        outcome: 'prepared',
        state: state,
        context: {
          constraintCount: 1,
          terrainStateDigest: terrain_state_summary.fetch(:digest),
          featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new
        },
        outputWindowReconciliation: { mode: 'feature_window' }
      }
    end
  end

  class CdtSkippingFeaturePlanner
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
          constraintCount: 0,
          terrainStateDigest: terrain_state_summary.fetch(:digest),
          featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
          cdtParticipation: { status: 'skip' },
          featureSelectionDiagnostics: {
            cdtFallbackTriggers: { patch_relevant_feature_geometry_failed: 1 }
          }
        },
        outputWindowReconciliation: { mode: 'dirty_window' }
      }
    end
  end

  class EligibleCdtFeaturePlanner
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
          constraintCount: 1,
          terrainStateDigest: terrain_state_summary.fetch(:digest),
          featureGeometry: SU_MCP::Terrain::TerrainFeatureGeometry.new,
          cdtParticipation: { status: 'eligible' }
        },
        outputWindowReconciliation: { mode: 'dirty_window' }
      }
    end
  end

  class RecordingPatchReplacementProvider
    attr_reader :calls, :last_build_args

    def self.accepted(patch_id: nil, domain_digest: nil)
      new(accepted_patch_id: patch_id || domain_digest)
    end

    def initialize(accepted_patch_id:)
      @accepted_patch_id = accepted_patch_id
      @calls = 0
    end

    def build(batch_plan:, state:, feature_geometry:, feature_context:, **)
      @calls += 1
      @last_build_args = {
        batch_plan: batch_plan,
        state: state,
        feature_geometry: feature_geometry,
        feature_context: feature_context
      }
      PatchReplacementResultStub.accepted(
        patch_id: @accepted_patch_id,
        replacement_patch_ids: batch_plan.replacement_patch_ids,
        replacement_patches: batch_plan.replacement_patches
      )
    end
  end

  class RecordingStableDomainCdtReplacementProvider <
    SU_MCP::Terrain::StableDomainCdtReplacementProvider
    attr_reader :calls, :last_build_args

    def initialize(...)
      super
      @calls = 0
    end

    def build(batch_plan:, state:, feature_geometry:, feature_context:, **)
      @calls += 1
      @last_build_args = {
        batch_plan: batch_plan,
        state: state,
        feature_geometry: feature_geometry,
        feature_context: feature_context
      }
      super
    end
  end

  class RecordingStableDomainSolver
    attr_reader :calls, :last_solve_args

    def initialize
      @calls = 0
    end

    def solve(**arguments)
      @calls += 1
      @last_solve_args = arguments
      {
        status: 'accepted',
        topology: { passed: true },
        mesh: {
          vertices: [
            [0.0, 0.0, 2.0],
            [16.0, 0.0, 2.0],
            [16.0, 16.0, 2.0],
            [0.0, 16.0, 2.0]
          ],
          triangles: [[0, 1, 2], [0, 2, 3]]
        },
        borderSpans: [
          {
            side: 'east',
            spanId: 'east-0',
            patchId: 'cdt-patch-v1-c0-r0',
            fresh: true,
            protectedBoundaryCrossing: false,
            vertices: [[16.0, 0.0, 2.0], [16.0, 16.0, 2.0]]
          }
        ],
        residualQuality: { maxHeightError: 0.0 }
      }
    end
  end

  class PatchReplacementResultStub
    attr_reader :status, :mesh, :border_spans, :replacement_patch_ids, :replacement_patches,
                :replacement_batch_id, :state_digest, :policy_fingerprint

    def self.accepted(patch_id:, replacement_patch_ids:, replacement_patches:)
      new(patch_id, replacement_patch_ids, replacement_patches)
    end

    def initialize(patch_id, replacement_patch_ids, replacement_patches)
      @status = 'accepted'
      @replacement_patch_ids = replacement_patch_ids
      @replacement_patches = replacement_patches
      @replacement_batch_id = 'new-batch'
      @state_digest = 'digest-2'
      @policy_fingerprint = 'fingerprint-2'
      @mesh = {
        vertices: [
          [0.0, 0.0, 1.0],
          [2.0, 0.0, 1.0],
          [2.0, 2.0, 1.0],
          [0.0, 2.0, 1.0]
        ],
        triangles: [[0, 1, 2], [0, 2, 3]]
      }
      @border_spans = [
        {
          side: 'east',
          spanId: 'east-0',
          patchId: patch_id,
          fresh: true,
          protectedBoundaryCrossing: false,
          vertices: [[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]]
        }
      ]
    end

    def accepted?
      true
    end
  end

  class FailingMeshGenerator
    def generate(...)
      raise 'mesh failed'
    end
  end

  class EvidenceBuilder
    def build_success(outcome:, **_attributes)
      { success: true, outcome: outcome }
    end
  end

  class EditEvidenceBuilder
    def build_success(outcome:, **_attributes)
      { success: true, outcome: outcome }
    end
  end

  class AcceptingEditValidator
    def validate(params)
      { outcome: 'ready', params: params }
    end
  end

  class AcceptingCorridorEditValidator
    def validate(params)
      {
        outcome: 'ready',
        operation_mode: 'corridor_transition',
        region_type: 'corridor',
        params: params
      }
    end
  end

  class AcceptingLocalFairingEditValidator
    def validate(params)
      {
        outcome: 'ready',
        operation_mode: 'local_fairing',
        region_type: 'rectangle',
        params: params
      }
    end
  end

  class AcceptingSurveyEditValidator
    def validate(params)
      {
        outcome: 'ready',
        operation_mode: 'survey_point_constraint',
        region_type: 'rectangle',
        params: params
      }
    end
  end

  class AcceptingPlanarRegionFitValidator
    def validate(params)
      {
        outcome: 'ready',
        operation_mode: 'planar_region_fit',
        region_type: 'rectangle',
        params: params
      }
    end
  end

  class RefusingEditValidator
    def validate(_params)
      {
        success: true,
        outcome: 'refused',
        refusal: {
          code: 'unsupported_option',
          details: {
            field: 'operation.mode',
            value: 'smooth',
            allowedValues: ['target_height']
          }
        }
      }
    end
  end

  class RecordingGradeEditor
    attr_reader :calls

    def initialize
      @calls = []
    end

    def apply(state:, request:)
      @calls << { state: state, request: request }
      {
        outcome: 'edited',
        state: edited_state(state),
        diagnostics: diagnostics(request)
      }
    end

    private

    def edited_state(state)
      SU_MCP::Terrain::HeightmapState.new(
        basis: state.basis,
        origin: state.origin,
        spacing: state.spacing,
        dimensions: state.dimensions,
        elevations: state.elevations.map { |value| value.nil? ? nil : value + 1.0 },
        revision: state.revision + 1,
        state_id: state.state_id
      )
    end

    def diagnostics(request)
      {
        changedSampleCount: 4,
        changedRegion: {
          min: { column: 0, row: 0 },
          max: { column: 1, row: 1 }
        },
        request: request
      }
    end
  end

  class RecordingCorridorEditor < RecordingGradeEditor
  end

  class RecordingLocalFairingEditor < RecordingGradeEditor
    private

    def diagnostics(request)
      super.merge(
        fairing: {
          metric: 'mean_absolute_neighborhood_residual',
          beforeResidual: 1.0,
          afterResidual: 0.5,
          improved: true,
          strength: request.dig('operation', 'strength'),
          neighborhoodRadiusSamples: request.dig('operation', 'neighborhoodRadiusSamples'),
          iterations: request.dig('operation', 'iterations'),
          actualIterations: request.dig('operation', 'iterations'),
          changedSampleCount: 4,
          warnings: []
        },
        warnings: []
      )
    end
  end

  class RecordingSurveyPointConstraintEditor < RecordingGradeEditor
    private

    def diagnostics(request)
      super.merge(
        survey: {
          points: [
            {
              id: 'survey-1',
              requestedElevation: 2.0,
              beforeElevation: 1.0,
              afterElevation: 2.0,
              residual: 0.0,
              tolerance: 0.01,
              status: 'satisfied'
            }
          ],
          correction: {
            correctionScope: request.dig('operation', 'correctionScope'),
            supportRegionType: request.dig('region', 'type'),
            changedSampleCount: 4,
            maxSampleDelta: 1.0,
            warnings: []
          }
        },
        warnings: []
      )
    end
  end

  class RecordingPlanarRegionFitEditor < RecordingGradeEditor
    private

    def diagnostics(request)
      planar_controls = request.dig('constraints', 'planarControls')
      super.merge(
        planarFit: {
          plane: {
            equation: { form: 'z = ax + by + c', a: 0.0, b: 0.1, c: 1.0 },
            normal: { x: 0.0, y: -0.0995, z: 0.995 },
            point: { x: 0.0, y: 0.0, z: 1.0 }
          },
          controls: planar_controls.each_with_index.map do |control, index|
            {
              id: control['id'],
              index: index,
              point: control.fetch('point').slice('x', 'y'),
              requestedElevation: control.dig('point', 'z'),
              beforeElevation: 1.0,
              planeElevation: control.dig('point', 'z'),
              residual: 0.0,
              tolerance: control.fetch('tolerance', 0.03),
              status: 'satisfied'
            }
          end,
          quality: {
            maxResidual: 0.0,
            meanResidual: 0.0,
            rmseResidual: 0.0,
            normalizedMaxResidual: 0.0
          },
          supportRegionType: request.dig('region', 'type'),
          changedSampleCount: 4,
          fullWeightSampleCount: 4,
          blendSampleCount: 0,
          preservedSampleCount: 0,
          changedBounds: { min: { column: 0, row: 0 }, max: { column: 1, row: 1 } },
          maxSampleDelta: 0.5,
          grid: { warnings: [] },
          warnings: []
        },
        warnings: []
      )
    end
  end

  class RefusingCorridorEditor
    def apply(...)
      {
        success: true,
        outcome: 'refused',
        refusal: {
          code: 'invalid_corridor_geometry',
          details: { field: 'region' }
        }
      }
    end
  end

  class RefusingLocalFairingEditor
    def initialize(code)
      @code = code
    end

    def apply(...)
      {
        success: true,
        outcome: 'refused',
        refusal: {
          code: @code,
          details: { field: 'operation.mode' }
        }
      }
    end
  end

  class RefusingSurveyPointConstraintEditor
    def apply(...)
      {
        success: true,
        outcome: 'refused',
        refusal: {
          code: 'survey_point_outside_support_region',
          details: { field: 'constraints.surveyPoints[0]' }
        }
      }
    end
  end

  class RefusingPlanarRegionFitEditor
    def apply(...)
      {
        success: true,
        outcome: 'refused',
        refusal: {
          code: 'non_coplanar_controls',
          details: { field: 'constraints.planarControls' }
        }
      }
    end
  end

  class RecordingTargetResolver
    def resolve(_target)
      { outcome: 'resolved', target: { sourceElementId: 'terrain-main' } }
    end
  end

  class ExplodingTargetResolver
    def resolve(_target)
      raise 'recursive resolver should not be used'
    end
  end

  class RecordingAdoptionSampler
    attr_reader :calls

    def initialize(source: nil)
      @source = source
      @calls = []
    end

    def derive(_target)
      @calls << :derive
      {
        outcome: 'sampled',
        source_entity: @source,
        state_input: {},
        source_summary: { sourceAction: 'replaced' },
        sampling_summary: { sampleCount: 4 }
      }
    end
  end

  class RefusingAdoptionSampler
    def derive(_target)
      {
        success: true,
        outcome: 'refused',
        refusal: { code: 'source_not_sampleable', message: 'nope' }
      }
    end
  end

  class ScalingLengthConverter
    def initialize(multiplier:)
      @multiplier = multiplier
    end

    def public_meters_to_internal(value)
      value.to_f * @multiplier
    end
  end

  class RecordingLengthConverter < ScalingLengthConverter
    attr_reader :public_meter_values

    def initialize(multiplier:)
      super
      @public_meter_values = []
    end

    def public_meters_to_internal(value)
      @public_meter_values << value
      super
    end
  end
end
