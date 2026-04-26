# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/terrain_surface_commands'

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
    managed_terrain_owner(model)
    commands = build_edit_commands(
      model: model,
      repository: EditRepository.new(state),
      mesh_generator: RefusingRegeneratingMeshGenerator.new
    )

    result = commands.edit_terrain_surface(edit_request)

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_output_contains_unsupported_entities', result.dig(:refusal, :code))
    assert_equal([[:start_operation, 'Edit Terrain Surface', true], [:abort_operation]],
                 model.operations)
  end

  private

  def build_commands(model:, repository: RecordingRepository.new,
                     mesh_generator: RecordingMeshGenerator.new,
                     adoption_sampler: RecordingAdoptionSampler.new,
                     length_converter: ScalingLengthConverter.new(multiplier: 10.0))
    SU_MCP::Terrain::TerrainSurfaceCommands.new(
      model: model,
      validator: AcceptingValidator.new,
      state_builder: StateBuilder.new,
      repository: repository,
      mesh_generator: mesh_generator,
      evidence_builder: EvidenceBuilder.new,
      adoption_sampler: adoption_sampler,
      length_converter: length_converter
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def build_edit_commands(model:, repository: EditRepository.new(state),
                          mesh_generator: RecordingRegeneratingMeshGenerator.new,
                          edit_request_validator: AcceptingEditValidator.new,
                          grade_editor: RecordingGradeEditor.new,
                          corridor_editor: RecordingCorridorEditor.new,
                          target_resolver: RecordingTargetResolver.new,
                          edit_evidence_builder: EditEvidenceBuilder.new)
    SU_MCP::Terrain::TerrainSurfaceCommands.new(
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
    )
  end
  # rubocop:enable Metrics/ParameterLists

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
    attr_reader :calls

    def initialize
      @calls = []
    end

    def generate(...)
      @calls << :generate
      { outcome: 'generated', summary: { derivedMesh: { derivedFromStateDigest: 'digest-1' } } }
    end
  end

  class RecordingRegeneratingMeshGenerator < RecordingMeshGenerator
    def regenerate(...)
      @calls << :regenerate
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
        state: SU_MCP::Terrain::HeightmapState.new(
          basis: state.basis,
          origin: state.origin,
          spacing: state.spacing,
          dimensions: state.dimensions,
          elevations: state.elevations.map { |value| value.nil? ? nil : value + 1.0 },
          revision: state.revision + 1,
          state_id: state.state_id
        ),
        diagnostics: { changedSampleCount: 4, request: request }
      }
    end
  end

  class RecordingCorridorEditor < RecordingGradeEditor
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

  class RecordingTargetResolver
    def resolve(_target)
      { outcome: 'resolved', target: { sourceElementId: 'terrain-main' } }
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
