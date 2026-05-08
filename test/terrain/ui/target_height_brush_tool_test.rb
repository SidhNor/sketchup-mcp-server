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
    attr_reader :applied_points, :lifecycle

    def initialize
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
  end

  def build_tool(session:, input_point:, after_apply: nil, after_state_change: nil)
    SU_MCP::Terrain::UI::TargetHeightBrushTool.new(
      session: session,
      input_point_factory: -> { input_point },
      after_apply: after_apply,
      after_state_change: after_state_change
    )
  end
end
