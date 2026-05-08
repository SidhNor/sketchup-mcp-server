# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/brush_edit_session'

class TerrainUiBrushEditSessionTest < Minitest::Test
  Point = Struct.new(:x, :y, :z)
  Owner = Struct.new(:source_element_id)

  def test_activation_marks_session_active_and_reports_json_safe_state
    session = build_session

    session.activate
    snapshot = session.state_snapshot

    assert_equal(true, session.active?)
    assert_equal('target_height', snapshot.fetch(:mode))
    assert_equal('terrain-main', snapshot.fetch(:selectedTerrain))
    refute_includes(JSON.generate(snapshot), 'Sketchup::')
  end

  def test_activation_reports_invalid_selection_in_dialog_status_state
    session = build_session(
      resolver: DriftResolver.new([
                                    refusal(
                                      'managed_terrain_selection_required',
                                      'Select one managed terrain surface.'
                                    )
                                  ])
    )

    snapshot = session.activate

    assert_equal('No terrain selected', snapshot.fetch(:selectedTerrain))
    assert_equal('Select one managed terrain surface.', snapshot.fetch(:status))
  end

  def test_refresh_selection_updates_selected_terrain_state_without_apply
    resolver = DriftResolver.new([
                                   resolved(owner('terrain-initial')),
                                   resolved(owner('terrain-current'))
                                 ])
    session = build_session(resolver: resolver)

    session.activate
    snapshot = session.refresh_selection

    assert_equal('terrain-current', snapshot.fetch(:selectedTerrain))
    assert_equal(2, resolver.calls)
  end

  def test_deactivation_clears_active_state_for_toolbar_validation
    session = build_session

    session.activate
    snapshot = session.deactivate

    assert_equal(false, session.active?)
    assert_equal(false, snapshot.fetch(:active))
  end

  def test_apply_click_resolves_selection_at_apply_time_not_activation_time
    resolver = DriftResolver.new([
                                   resolved(owner('terrain-initial')),
                                   resolved(owner('terrain-current'))
                                 ])
    commands = RecordingCommands.new(success_response)
    session = build_session(resolver: resolver, commands: commands)
    session.update_settings(valid_settings)

    session.activate
    session.apply_click(point(1.0, 2.0, 0.0))

    assert_equal(2, resolver.calls)
    assert_equal({ 'sourceElementId' => 'terrain-current' },
                 commands.calls.first.fetch('targetReference'))
  end

  def test_apply_click_builds_exact_target_height_circle_request
    commands = RecordingCommands.new(success_response)
    session = build_session(commands: commands)
    session.update_settings(valid_settings.merge('blendDistance' => 0.5, 'falloff' => 'smooth'))

    session.apply_click(point(1.0, 2.0, 0.0))

    assert_equal(
      {
        'targetReference' => { 'sourceElementId' => 'terrain-main' },
        'operation' => { 'mode' => 'target_height', 'targetElevation' => 1.25 },
        'region' => {
          'type' => 'circle',
          'center' => { 'x' => 1.0, 'y' => 2.0 },
          'radius' => 2.0,
          'blend' => { 'distance' => 0.5, 'falloff' => 'smooth' }
        },
        'constraints' => { 'fixedControls' => [], 'preserveZones' => [] },
        'outputOptions' => { 'includeSampleEvidence' => false, 'sampleEvidenceLimit' => 20 }
      },
      commands.calls.first
    )
  end

  def test_invalid_settings_refuse_before_command_invocation
    commands = RecordingCommands.new(success_response)
    session = build_session(commands: commands)
    session.update_settings(valid_settings.merge('blendDistance' => 1.0, 'falloff' => 'none'))

    result = session.apply_click(point(1.0, 2.0, 0.0))

    assert_equal('refused', result.fetch(:outcome))
    assert_empty(commands.calls)
  end

  def test_command_refusal_is_mapped_to_visible_feedback
    feedback = RecordingFeedback.new
    result = build_session(
      commands: RecordingCommands.new(refusal_response),
      feedback: feedback
    ).tap { |session| session.update_settings(valid_settings) }
     .apply_click(point(1.0, 2.0, 0.0))

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('Command refused the terrain edit.', feedback.messages.last.fetch(:message))
  end

  def test_selection_refusal_uses_specific_visible_feedback_message
    feedback = RecordingFeedback.new
    session = build_session(
      resolver: DriftResolver.new([
                                    refusal(
                                      'managed_terrain_selection_required',
                                      'Select one managed terrain surface.'
                                    )
                                  ]),
      feedback: feedback
    )
    session.update_settings(valid_settings)

    result = session.apply_click(point(1.0, 2.0, 0.0))

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('Select one managed terrain surface.', feedback.messages.last.fetch(:message))
    assert_equal('No terrain selected', session.state_snapshot.fetch(:selectedTerrain))
  end

  def test_success_is_mapped_to_visible_feedback
    feedback = RecordingFeedback.new
    result = build_session(
      commands: RecordingCommands.new(success_response),
      feedback: feedback
    ).tap { |session| session.update_settings(valid_settings) }
     .apply_click(point(1.0, 2.0, 0.0))

    assert_equal('edited', result.fetch(:outcome))
    assert_equal('Managed terrain edit applied.', feedback.messages.last.fetch(:message))
  end

  def test_ui_session_does_not_start_its_own_model_operation
    model = RecordingModel.new
    session = build_session(model: model)
    session.update_settings(valid_settings)

    session.apply_click(point(1.0, 2.0, 0.0))

    assert_empty(model.operations)
  end

  def test_preview_context_returns_read_only_hover_inputs_without_command_invocation
    commands = RecordingCommands.new(success_response)
    session = build_session(commands: commands)
    session.update_settings(valid_settings)

    result = session.preview_context(point(1.0, 2.0, 0.0))

    assert_equal('ready', result.fetch(:outcome))
    assert_equal(owner('terrain-main'), result.fetch(:owner))
    assert_equal({ 'x' => 1.0, 'y' => 2.0 }, result.fetch(:center))
    assert_equal(2.0, result.fetch(:settings).fetch(:radius))
    assert_empty(commands.calls)
  end

  def test_preview_context_refuses_invalid_settings_before_selection_resolution
    resolver = DriftResolver.new([resolved(owner('terrain-main'))])
    session = build_session(resolver: resolver)
    session.update_settings(valid_settings.merge('blendDistance' => 1.0, 'falloff' => 'none'))

    result = session.preview_context(point(1.0, 2.0, 0.0))

    assert_equal('refused', result.fetch(:outcome))
    assert_equal(0, resolver.calls)
  end

  private

  class RecordingModel
    attr_reader :operations

    def initialize
      @operations = []
    end

    # rubocop:disable Style/OptionalBooleanParameter
    def start_operation(name, disable_ui = true)
      @operations << [:start_operation, name, disable_ui]
    end
    # rubocop:enable Style/OptionalBooleanParameter
  end

  class RecordingCommands
    attr_reader :calls

    def initialize(response)
      @response = response
      @calls = []
    end

    def edit_terrain_surface(request)
      @calls << request
      @response
    end
  end

  class DriftResolver
    attr_reader :calls

    def initialize(results)
      @results = results
      @calls = 0
    end

    def resolve
      result = @results.fetch([@calls, @results.length - 1].min)
      @calls += 1
      result
    end
  end

  class RecordingFeedback
    attr_reader :messages

    def initialize
      @messages = []
    end

    def show(payload)
      @messages << payload
    end
  end

  def build_session(
    model: RecordingModel.new,
    resolver: DriftResolver.new([resolved(owner('terrain-main'))]),
    commands: RecordingCommands.new(success_response),
    feedback: RecordingFeedback.new
  )
    converter = lambda do |point, owner:|
      raise "unexpected owner #{owner.inspect}" unless owner

      { 'x' => point.x, 'y' => point.y }
    end
    SU_MCP::Terrain::UI::BrushEditSession.new(
      model: model,
      resolver: resolver,
      coordinate_converter: converter,
      commands: commands,
      feedback: feedback
    )
  end

  def valid_settings
    {
      'targetElevation' => 1.25,
      'radius' => 2.0,
      'blendDistance' => 0.0,
      'falloff' => 'none'
    }
  end

  def point(x_value, y_value, z_value)
    Point.new(x_value, y_value, z_value)
  end

  def owner(source_element_id)
    Owner.new(source_element_id)
  end

  def resolved(owner)
    {
      outcome: 'resolved',
      owner: owner,
      targetReference: { 'sourceElementId' => owner.source_element_id },
      selectedTerrain: owner.source_element_id
    }
  end

  def refusal(code, message)
    {
      outcome: 'refused',
      refusal: { code: code, message: message }
    }
  end

  def success_response
    { outcome: 'edited', success: true }
  end

  def refusal_response
    {
      outcome: 'refused',
      refusal: { code: 'edit_region_has_no_affected_samples' }
    }
  end
end
