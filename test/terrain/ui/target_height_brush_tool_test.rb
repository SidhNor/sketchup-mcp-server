# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/target_height_brush_tool'

class TerrainUiTargetHeightBrushToolTest < Minitest::Test
  def test_mouse_move_updates_status_without_applying_edit
    session = RecordingSession.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(valid: true))
    view = FakeView.new

    tool.onMouseMove(0, 10, 15, view)

    assert_empty(session.applied_points)
    assert_equal('Click a managed terrain surface to apply target height.', view.status_text)
  end

  def test_mouse_move_uses_active_tool_status_text
    session = RecordingSession.new(active_tool: 'local_fairing')
    tool = build_tool(session: session, input_point: FakeInputPoint.new(valid: true))
    view = FakeView.new

    tool.onMouseMove(0, 10, 15, view)

    assert_equal('Click a managed terrain surface to apply local fairing.', view.status_text)
  end

  def test_mouse_move_updates_overlay_from_valid_input_point
    session = RecordingSession.new
    point = Struct.new(:x, :y, :z).new(1.0, 2.0, 3.0)
    overlay = RecordingOverlay.new
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(valid: true, position: point),
      overlay: overlay
    )
    view = FakeView.new

    tool.onMouseMove(0, 10, 15, view)

    assert_equal([[point, view]], overlay.hover_updates)
    assert_empty(session.applied_points)
  end

  def test_mouse_move_clears_overlay_when_pick_fails
    overlay = RecordingOverlay.new
    tool = build_tool(
      session: RecordingSession.new,
      input_point: FakeInputPoint.new(valid: false),
      overlay: overlay
    )
    view = FakeView.new

    tool.onMouseMove(0, 10, 15, view)

    assert_equal([view], overlay.cleared_views)
    assert_equal('Pick a valid terrain point before applying the brush.', view.status_text)
  end

  def test_draw_and_extents_delegate_to_overlay
    overlay = RecordingOverlay.new
    tool = build_tool(
      session: RecordingSession.new,
      input_point: FakeInputPoint.new(valid: true),
      overlay: overlay
    )
    view = FakeView.new

    tool.draw(view)
    extents = tool.getExtents

    assert_equal([view], overlay.draw_views)
    assert_equal(:overlay_extents, extents)
  end

  def test_mouse_leave_and_deactivate_clear_overlay
    overlay = RecordingOverlay.new
    session = RecordingSession.new
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(valid: true),
      overlay: overlay
    )
    view = FakeView.new

    tool.onMouseLeave(view)
    tool.deactivate(view)

    assert_equal([view, view], overlay.cleared_views)
    assert_equal(%i[deactivate], session.lifecycle)
  end

  def test_left_click_refuses_when_input_point_pick_fails
    session = RecordingSession.new
    tool = build_tool(session: session, input_point: FakeInputPoint.new(valid: false))

    result = tool.onLButtonDown(0, 10, 15, FakeView.new)

    assert_equal('refused', result.fetch(:outcome))
    assert_empty(session.applied_points)
  end

  def test_left_click_delegates_valid_input_point_position_to_session
    session = RecordingSession.new
    point = Struct.new(:x, :y, :z).new(1.0, 2.0, 3.0)
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(valid: true, position: point)
    )

    tool.onLButtonDown(0, 10, 15, FakeView.new)

    assert_equal([point], session.applied_points)
  end

  def test_left_click_runs_after_apply_callback_for_dialog_status_push
    calls = []
    session = RecordingSession.new
    point = Struct.new(:x, :y, :z).new(1.0, 2.0, 3.0)
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(valid: true, position: point),
      after_apply: -> { calls << :pushed }
    )

    tool.onLButtonDown(0, 10, 15, FakeView.new)

    assert_equal([:pushed], calls)
  end

  def test_left_click_marks_overlay_dirty_after_apply
    session = RecordingSession.new
    overlay = RecordingOverlay.new
    point = Struct.new(:x, :y, :z).new(1.0, 2.0, 3.0)
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(valid: true, position: point),
      overlay: overlay
    )
    view = FakeView.new

    tool.onLButtonDown(0, 10, 15, view)

    assert_equal([view], overlay.dirty_views)
  end

  def test_activate_and_deactivate_track_session_state_for_toolbar_toggle
    calls = []
    session = RecordingSession.new
    tool = build_tool(
      session: session,
      input_point: FakeInputPoint.new(valid: true),
      after_state_change: -> { calls << :refreshed }
    )

    tool.activate
    tool.deactivate(FakeView.new)

    assert_equal(%i[activate deactivate], session.lifecycle)
    assert_equal(%i[refreshed refreshed], calls)
  end

  private

  class FakeView
    attr_accessor :status_text
  end

  class RecordingOverlay
    attr_reader :hover_updates, :cleared_views, :draw_views, :dirty_views

    def initialize
      @hover_updates = []
      @cleared_views = []
      @draw_views = []
      @dirty_views = []
    end

    def update_hover(point, view:)
      @hover_updates << [point, view]
      { outcome: 'ready', status: 'valid', message: 'Managed terrain target ready.' }
    end

    def clear(view:)
      @cleared_views << view
      { outcome: 'cleared' }
    end

    def draw(view)
      @draw_views << view
    end

    def extents
      :overlay_extents
    end

    def mark_dirty(view:)
      @dirty_views << view
    end
  end

  class FakeInputPoint
    attr_reader :position

    def initialize(valid:, position: nil)
      @valid = valid
      @position = position
    end

    def pick(_view, _x, _y)
      @valid
    end
  end

  class RecordingSession
    attr_reader :active_tool, :applied_points, :lifecycle

    def initialize(active_tool: 'target_height')
      @active_tool = active_tool
      @applied_points = []
      @lifecycle = []
    end

    def activate
      @lifecycle << :activate
    end

    def deactivate
      @lifecycle << :deactivate
    end

    def apply_click(point)
      @applied_points << point
      { outcome: 'edited' }
    end

    def state_snapshot
      { activeTool: @active_tool }
    end
  end

  def build_tool(session:, input_point:, after_apply: nil, after_state_change: nil, overlay: nil)
    kwargs = {
      session: session,
      input_point_factory: -> { input_point },
      after_apply: after_apply,
      after_state_change: after_state_change
    }
    kwargs[:overlay] = overlay if overlay
    SU_MCP::Terrain::UI::TargetHeightBrushTool.new(**kwargs)
  end
end
