# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/corridor_transition_tool'
require_relative '../../../src/su_mcp/terrain/ui/corridor_overlay_preview'

class TerrainUiCorridorTransitionToolTest < Minitest::Test
  Point = Struct.new(:x, :y, :z)

  def test_first_and_second_click_capture_start_and_end_controls
    session = RecordingSession.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)))
    view = FakeView.new

    tool.onLButtonDown(0, 10, 15, view)
    tool.onLButtonDown(0, 20, 25, view)

    assert_equal([point(1.0, 2.0, 3.0), point(1.0, 2.0, 3.0)], session.captured_points)
    assert_equal(2, view.invalidations)
  end

  def test_invalid_pick_refuses_without_changing_session
    session = RecordingSession.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(nil))

    result = tool.onLButtonDown(0, 10, 15, FakeView.new)

    assert_equal('refused', result.fetch(:outcome))
    assert_empty(session.captured_points)
  end

  def test_panel_recapture_target_routes_next_click_to_session
    session = RecordingSession.new(recapture_target: 'start')
    tool = build_tool(session: session, input_point: FakeInputPoint.new(point(4.0, 5.0, 6.0)))

    tool.onLButtonDown(0, 10, 15, FakeView.new)

    assert_equal(['start'], session.recapture_started)
    assert_equal([point(4.0, 5.0, 6.0)], session.captured_points)
  end

  def test_apply_shortcut_delegates_to_session_and_pushes_panel_state
    callbacks = []
    session = RecordingSession.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)),
                      after_apply: -> { callbacks << :pushed })

    tool.onKeyDown(13, 0, 0, FakeView.new)

    assert_equal(1, session.apply_calls)
    assert_equal([:pushed], callbacks)
  end

  def test_reset_shortcut_clears_session_and_overlay
    session = RecordingSession.new
    overlay = RecordingOverlay.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)),
                      overlay: overlay)
    view = FakeView.new

    tool.onKeyDown(27, 0, 0, view)

    assert_equal(1, session.reset_calls)
    assert_equal([view], overlay.cleared_views)
  end

  def test_mouse_move_updates_corridor_overlay_preview_without_applying
    session = RecordingSession.new
    overlay = RecordingOverlay.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)),
                      overlay: overlay)
    view = FakeView.new

    tool.onMouseMove(0, 10, 15, view)

    assert_equal([point(1.0, 2.0, 3.0)], overlay.hover_points)
    assert_equal(0, session.apply_calls)
  end

  def test_mouse_leave_keeps_corridor_overlay_visible_for_dialog_focus
    session = RecordingSession.new
    overlay = RecordingOverlay.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)),
                      overlay: overlay)
    view = FakeView.new

    tool.onMouseLeave(view)

    assert_empty(overlay.cleared_views)
    assert_equal(1, view.invalidations)
  end

  def test_default_tool_creates_corridor_overlay_preview
    tool = SU_MCP::Terrain::UI::CorridorTransitionTool.new(session: RecordingSession.new)

    assert_instance_of(
      SU_MCP::Terrain::UI::CorridorOverlayPreview,
      tool.instance_variable_get(:@overlay)
    )
  end

  def test_valid_capture_updates_default_overlay_immediately
    session = RecordingSession.new
    overlay = RecordingOverlay.new
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)),
      overlay: overlay
    )
    view = FakeView.new

    tool.onLButtonDown(0, 10, 15, view)

    assert_equal([view], overlay.update_views)
  end

  def test_suspend_deactivate_and_reactivate_keep_panel_overlay_and_apply_state_in_sync
    session = RecordingSession.new
    overlay = RecordingOverlay.new
    state_changes = []
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)),
      overlay: overlay,
      after_state_change: -> { state_changes << session.state_snapshot }
    )
    view = FakeView.new

    tool.activate
    session.update_settings('startControl' => { 'elevation' => 5.5 })
    tool.suspend(view)
    tool.resume(view)

    assert_equal(%i[activate resume], session.lifecycle)
    assert_equal([view], overlay.cleared_views)
    assert_equal(2, state_changes.length)
    assert_equal(5.5, state_changes.last.dig(:corridor, :startControl, :elevation))
  end

  def test_draw_and_extents_delegate_to_corridor_overlay
    overlay = RecordingOverlay.new
    tool = build_tool(session: RecordingSession.new,
                      input_point: FakeInputPoint.new(point(1.0, 2.0, 3.0)),
                      overlay: overlay)
    view = FakeView.new

    tool.draw(view)

    assert_equal([view], overlay.draw_views)
    assert_equal(:overlay_extents, tool.getExtents)
  end

  private

  class RecordingSession
    attr_reader :captured_points, :recapture_started, :apply_calls, :reset_calls, :lifecycle

    def initialize(recapture_target: nil)
      @recapture_target = recapture_target
      @captured_points = []
      @recapture_started = []
      @apply_calls = 0
      @reset_calls = 0
      @lifecycle = []
      @state = { corridor: { startControl: { elevation: nil } } }
    end

    def activate
      @lifecycle << :activate
    end

    def resume
      @lifecycle << :resume
    end

    def capture_point(point)
      @captured_points << point
      { outcome: 'ready' }
    end

    def start_recapture(endpoint)
      @recapture_started << endpoint
    end

    def apply
      @apply_calls += 1
      { outcome: 'edited' }
    end

    def reset
      @reset_calls += 1
      { outcome: 'ready' }
    end

    def update_settings(payload)
      @state[:corridor][:startControl][:elevation] = payload.dig('startControl', 'elevation')
    end

    def state_snapshot
      @state.merge(corridor: @state.fetch(:corridor).merge(recaptureTarget: @recapture_target))
    end
  end

  class RecordingOverlay
    attr_reader :hover_points, :cleared_views, :draw_views, :update_views

    def initialize
      @hover_points = []
      @cleared_views = []
      @draw_views = []
      @update_views = []
    end

    def update_hover(point, view:)
      @hover_points << point
      view.invalidate
    end

    def update(view:)
      @update_views << view
    end

    def clear(view:)
      @cleared_views << view
    end

    def draw(view)
      @draw_views << view
    end

    def extents
      :overlay_extents
    end
  end

  class FakeInputPoint
    attr_reader :position

    def initialize(position)
      @position = position
    end

    def pick(_view, _x, _y) # rubocop:disable Naming/PredicateMethod
      !position.nil?
    end
  end

  class FakeView
    attr_accessor :status_text
    attr_reader :invalidations

    def initialize
      @invalidations = 0
    end

    def invalidate
      @invalidations += 1
    end
  end

  def build_tool(session:, input_point:, overlay: RecordingOverlay.new, after_apply: nil,
                 after_state_change: nil)
    SU_MCP::Terrain::UI::CorridorTransitionTool.new(
      session: session,
      input_point_factory: -> { input_point },
      overlay: overlay,
      after_apply: after_apply,
      after_state_change: after_state_change
    )
  end

  def point(x_value, y_value, z_value)
    Point.new(x_value, y_value, z_value)
  end
end
