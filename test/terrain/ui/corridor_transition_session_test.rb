# frozen_string_literal: true

require 'json'
require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/ui/corridor_transition_session'

class TerrainUiCorridorTransitionSessionTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  Point = Struct.new(:x, :y, :z)
  Owner = Struct.new(:source_element_id)
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_activation_reports_corridor_tool_state_and_json_safe_snapshot
    session = build_session

    snapshot = session.activate

    assert_equal('corridor_transition', snapshot.fetch(:activeTool))
    assert_equal('terrain-main', snapshot.fetch(:selectedTerrain))
    assert_includes(snapshot.fetch(:toolOptions), 'corridor_transition')
    refute_includes(JSON.generate(snapshot), 'Sketchup::')
  end

  def test_first_and_second_capture_store_owner_local_xyz_with_sampled_provenance
    session = build_session(sampler: RecordingSampler.new(2.25))

    session.capture_point(point(10.0, 20.0, 30.0))
    snapshot = session.capture_point(point(14.0, 22.0, 30.0))

    assert_equal(
      { x: 1.0, y: 2.0, elevation: 2.25, elevationProvenance: 'sampled' },
      snapshot.fetch(:corridor).fetch(:startControl)
    )
    assert_equal(
      { x: 1.4, y: 2.2, elevation: 2.25, elevationProvenance: 'sampled' },
      snapshot.fetch(:corridor).fetch(:endControl)
    )
  end

  def test_numeric_endpoint_updates_mark_elevation_manual_and_recenter_slider_range
    session = build_session
    session.capture_point(point(10.0, 20.0, 30.0))

    snapshot = session.update_settings(
      'selectedEndpoint' => 'start',
      'startControl' => { 'elevation' => 8.5 }
    )

    start = snapshot.fetch(:corridor).fetch(:startControl)
    assert_equal(8.5, start.fetch(:elevation))
    assert_equal('manual', start.fetch(:elevationProvenance))
    assert_equal('start', snapshot.fetch(:corridor).fetch(:selectedEndpoint))
    assert_operator(snapshot.fetch(:corridor).fetch(:elevationSliderRange).fetch(:min), :<, 8.5)
    assert_operator(snapshot.fetch(:corridor).fetch(:elevationSliderRange).fetch(:max), :>, 8.5)
  end

  def test_endpoint_slider_ranges_are_independent_for_start_and_end_elevations
    session = ready_session
    snapshot = session.update_settings(
      'startControl' => { 'elevation' => 12.0 },
      'endControl' => { 'elevation' => -4.0 }
    )

    ranges = snapshot.fetch(:corridor).fetch(:elevationSliderRanges)
    assert_equal(12.0, ranges.fetch(:start).fetch(:mid))
    assert_equal(-4.0, ranges.fetch(:end).fetch(:mid))
    refute_equal(ranges.fetch(:start), ranges.fetch(:end))
  end

  def test_recapture_preserves_manual_elevation_but_updates_xy
    session = build_session
    session.capture_point(point(10.0, 20.0, 30.0))
    session.update_settings('startControl' => { 'elevation' => 9.75 })
    session.start_recapture('start')

    snapshot = session.capture_point(point(30.0, 40.0, 1.0))

    start = snapshot.fetch(:corridor).fetch(:startControl)
    assert_equal(3.0, start.fetch(:x))
    assert_equal(4.0, start.fetch(:y))
    assert_equal(9.75, start.fetch(:elevation))
    assert_equal('manual', start.fetch(:elevationProvenance))
  end

  def test_sample_terrain_resets_endpoint_elevation_and_provenance
    session = build_session(sampler: RecordingSampler.new(1.2, 4.4))
    session.capture_point(point(10.0, 20.0, 30.0))
    session.update_settings('startControl' => { 'elevation' => 9.75 })

    snapshot = session.sample_terrain('start')

    start = snapshot.fetch(:corridor).fetch(:startControl)
    assert_equal(4.4, start.fetch(:elevation))
    assert_equal('sampled', start.fetch(:elevationProvenance))
  end

  def test_apply_refuses_missing_or_invalid_corridor_state_before_command_invocation
    commands = RecordingCommands.new
    session = build_session(commands: commands)

    result = session.apply

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('missing_required_field', result.dig(:refusal, :code))
    assert_empty(commands.calls)
  end

  def test_positive_side_blend_defaults_to_supported_falloff_for_minimal_ui_apply
    commands = RecordingCommands.new
    session = ready_session(commands: commands)
    session.update_settings('sideBlend' => { 'distance' => 1.0, 'falloff' => 'none' })

    result = session.apply

    assert_equal('edited', result.fetch(:outcome))
    request = commands.calls.fetch(0)
    assert_equal(1.0, request.dig('region', 'sideBlend', 'distance'))
    assert_equal('cosine', request.dig('region', 'sideBlend', 'falloff'))
  end

  def test_apply_refuses_unsupported_side_blend_falloff_with_allowed_values
    commands = RecordingCommands.new
    session = ready_session(commands: commands)
    session.update_settings('sideBlend' => { 'distance' => 1.0, 'falloff' => 'smooth' })

    result = session.apply

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal(%w[none cosine], result.dig(:refusal, :details, :allowedValues))
    assert_empty(commands.calls)
  end

  def test_apply_refuses_near_collapsed_projected_xy_before_command_invocation
    commands = RecordingCommands.new
    session = ready_session(commands: commands)
    session.update_settings(
      'startControl' => { 'point' => { 'x' => 1.0, 'y' => 1.0 }, 'elevation' => 3.0 },
      'endControl' => { 'point' => { 'x' => 1.000001, 'y' => 1.000001 }, 'elevation' => 4.0 }
    )

    result = session.apply

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('invalid_corridor_geometry', result.dig(:refusal, :code))
    assert_empty(commands.calls)
  end

  def test_valid_apply_builds_existing_corridor_transition_request_without_ui_metadata
    commands = RecordingCommands.new
    session = ready_session(commands: commands)
    session.update_settings(
      'selectedEndpoint' => 'end',
      'recaptureTarget' => 'start',
      'overlayCue' => 'centerline'
    )

    result = session.apply

    assert_equal('edited', result.fetch(:outcome))
    request = commands.calls.fetch(0)
    assert_equal('corridor_transition', request.dig('operation', 'mode'))
    assert_equal('corridor', request.dig('region', 'type'))
    assert_equal({ 'x' => 1.0, 'y' => 2.0 }, request.dig('region', 'startControl', 'point'))
    assert_equal(7.5, request.dig('region', 'startControl', 'elevation'))
    assert_equal({ 'x' => 5.0, 'y' => 2.0 }, request.dig('region', 'endControl', 'point'))
    assert_equal(0.0, request.dig('region', 'sideBlend', 'distance'))
    assert_request_excludes_ui_metadata(request)
  end

  def test_manual_z_more_than_two_meters_from_sampled_height_drives_request
    commands = RecordingCommands.new
    session = ready_session(commands: commands, sampler: RecordingSampler.new(1.0))
    session.update_settings(
      'startControl' => { 'elevation' => 5.5 },
      'endControl' => { 'elevation' => -2.25 }
    )

    session.apply

    request = commands.calls.fetch(0)
    assert_equal(5.5, request.dig('region', 'startControl', 'elevation'))
    assert_equal(-2.25, request.dig('region', 'endControl', 'elevation'))
  end

  def test_command_refusal_is_mapped_to_visible_feedback_and_status
    feedback = RecordingFeedback.new
    session = ready_session(
      commands: RecordingCommands.new(refusal_response),
      feedback: feedback
    )

    result = session.apply

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('edit_region_has_no_affected_samples', feedback.messages.last.dig(:refusal, :code))
    assert_equal('Command refused the corridor transition.', session.state_snapshot.fetch(:status))
  end

  def test_preview_context_exposes_actual_endpoint_z_without_command_invocation
    commands = RecordingCommands.new
    session = ready_session(commands: commands, sampler: RecordingSampler.new(1.0))
    session.update_settings(
      'startControl' => { 'elevation' => 5.5 },
      'endControl' => { 'elevation' => -2.25 }
    )

    context = session.preview_context

    assert_equal('ready', context.fetch(:outcome))
    assert_equal(5.5, context.dig(:corridor, :startControl, :elevation))
    assert_equal(-2.25, context.dig(:corridor, :endControl, :elevation))
    assert_empty(commands.calls)
  end

  def test_preview_context_includes_sampled_elevations_for_3d_overlay_sides
    session = ready_session(sampler: RecordingSampler.new(7.5, 8.25, 1.25, 2.5))

    context = session.preview_context

    assert_equal(1.25, context.dig(:corridor, :sampledElevations, :start))
    assert_equal(2.5, context.dig(:corridor, :sampledElevations, :end))
  end

  def test_preview_context_keeps_cached_terrain_when_dialog_focus_loses_selection
    resolver = SequenceResolver.new(
      RecordingResolver.new.resolve,
      RecordingResolver.new.resolve,
      selection_refusal
    )
    session = build_session(resolver: resolver, sampler: RecordingSampler.new(7.5, 8.25, 1.25, 2.5))
    session.capture_point(point(10.0, 20.0, 10.0))
    session.capture_point(point(50.0, 20.0, 10.0))

    context = session.preview_context

    assert_equal('ready', context.fetch(:outcome))
    assert_equal('Cached terrain', context.fetch(:selectedTerrain))
    assert_equal(1.25, context.dig(:corridor, :sampledElevations, :start))
  end

  def test_preview_sampling_reuses_repository_sampler_for_hover_performance
    repository = RecordingRepository.new(loaded_state)
    session = build_session(repository: repository, sampler: nil)
    session.capture_point(point(10.0, 20.0, 10.0))
    session.capture_point(point(30.0, 20.0, 10.0))

    3.times { session.preview_context(point(35.0, 20.0, 10.0)) }

    assert_equal(1, repository.loads)
  end

  def test_hover_preview_uses_cursor_as_temporary_missing_end_without_mutating_state
    commands = RecordingCommands.new
    session = build_session(commands: commands, sampler: RecordingSampler.new(3.0))
    session.capture_point(point(10.0, 20.0, 30.0))

    context = session.preview_context(point(40.0, 25.0, 9.0))

    assert_equal('ready', context.fetch(:outcome))
    assert_equal(4.0, context.dig(:corridor, :endControl, :x))
    assert_equal(2.5, context.dig(:corridor, :endControl, :y))
    assert_equal(3.0, context.dig(:corridor, :endControl, :elevation))
    assert_nil(session.state_snapshot.dig(:corridor, :endControl))
    assert_empty(commands.calls)
  end

  private

  class RecordingCommands
    attr_reader :calls

    def initialize(response = { outcome: 'edited' })
      @response = response
      @calls = []
    end

    def edit_terrain_surface(request)
      @calls << request
      @response
    end
  end

  class RecordingResolver
    def resolve
      {
        outcome: 'resolved',
        owner: Owner.new('terrain-main'),
        targetReference: { 'sourceElementId' => 'terrain-main' },
        selectedTerrain: 'terrain-main'
      }
    end
  end

  class SequenceResolver
    def initialize(*results)
      @results = results
      @calls = 0
    end

    def resolve
      result = @results.fetch([@calls, @results.length - 1].min)
      @calls += 1
      result
    end
  end

  class RecordingConverter
    def owner_local_xyz(point, owner:)
      raise 'owner required' unless owner

      { 'x' => point.x / 10.0, 'y' => point.y / 10.0, 'z' => point.z / 10.0 }
    end
  end

  class RecordingSampler
    def initialize(*elevations)
      @elevations = elevations.empty? ? [7.5] : elevations
      @calls = 0
    end

    def elevation_at(_point)
      elevation = @elevations.fetch([@calls, @elevations.length - 1].min)
      @calls += 1
      elevation
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

  class RecordingRepository
    attr_reader :loads

    def initialize(result)
      @result = result
      @loads = 0
    end

    def load(_owner)
      @loads += 1
      @result
    end
  end

  def build_session(
    resolver: RecordingResolver.new,
    commands: RecordingCommands.new,
    feedback: RecordingFeedback.new,
    sampler: RecordingSampler.new,
    converter: RecordingConverter.new,
    repository: nil
  )
    kwargs = {
      resolver: resolver,
      commands: commands,
      feedback: feedback,
      elevation_sampler: sampler,
      coordinate_converter: converter
    }
    kwargs[:repository] = repository if repository
    SU_MCP::Terrain::UI::CorridorTransitionSession.new(**kwargs)
  end

  def ready_session(commands: RecordingCommands.new, feedback: RecordingFeedback.new,
                    sampler: RecordingSampler.new)
    build_session(commands: commands, feedback: feedback, sampler: sampler).tap do |session|
      session.capture_point(point(10.0, 20.0, 10.0))
      session.capture_point(point(50.0, 20.0, 10.0))
      session.update_settings(
        'startControl' => { 'elevation' => 7.5 },
        'endControl' => { 'elevation' => 8.25 },
        'width' => 2.0,
        'sideBlend' => { 'distance' => 0.0, 'falloff' => 'none' }
      )
    end
  end

  def point(x_value, y_value, z_value)
    Point.new(x_value, y_value, z_value)
  end

  def refusal_response
    {
      outcome: 'refused',
      refusal: { code: 'edit_region_has_no_affected_samples' }
    }
  end

  def loaded_state
    { outcome: 'loaded', state: heightmap_state }
  end

  def heightmap_state
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 8, 'rows' => 8 },
      elevations: Array.new(64, 1.0),
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  def selection_refusal
    {
      outcome: 'refused',
      refusal: {
        code: 'managed_terrain_selection_required',
        message: 'Select one managed terrain surface.',
        details: { field: 'selection' }
      }
    }
  end

  def assert_request_excludes_ui_metadata(request)
    assert_equal(
      %w[constraints operation outputOptions region targetReference],
      request.keys.sort
    )
    assert_equal(
      %w[endControl sideBlend startControl type width],
      request.fetch('region').keys.sort
    )
    assert_equal(%w[point elevation].sort, request.dig('region', 'startControl').keys.sort)
    assert_equal(%w[point elevation].sort, request.dig('region', 'endControl').keys.sort)
    serialized = JSON.generate(request)
    %w[
      elevationProvenance
      selectedEndpoint
      recaptureTarget
      overlayCue
      markerState
    ].each do |metadata_key|
      refute_includes(serialized, metadata_key)
    end
  end
end
