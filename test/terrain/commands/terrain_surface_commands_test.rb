# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/semantic_test_support'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/commands/terrain_surface_commands'

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
    attr_reader :last_regenerate_args

    def regenerate(owner:, state:, terrain_state_summary:, output_plan: nil, feature_context: nil)
      @calls << :regenerate
      @last_regenerate_args = {
        owner: owner,
        state: state,
        terrain_state_summary: terrain_state_summary,
        output_plan: output_plan,
        feature_context: feature_context
      }
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

    def prepare(state:, terrain_state_summary:, include_feature_geometry: false)
      _include_feature_geometry = include_feature_geometry
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

    def prepare(state:, terrain_state_summary:, include_feature_geometry: false)
      _include_feature_geometry = include_feature_geometry
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
