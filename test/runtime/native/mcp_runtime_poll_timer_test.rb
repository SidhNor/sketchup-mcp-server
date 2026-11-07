# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_poll_timer'

class McpRuntimePollTimerTest < Minitest::Test
  def setup
    @started = []
    @stopped = []
    @errors = []
    @timer = SU_MCP::McpRuntimePollTimer.new(
      timer_starter: lambda do |interval, repeat, &block|
        @started << [interval, repeat, block]
        :"timer#{@started.length}"
      end,
      timer_stopper: ->(timer_id) { @stopped << timer_id },
      on_stop_error: ->(error) { @errors << error }
    )
  end

  def test_start_schedules_a_repeating_idle_timer_that_runs_the_tick
    ticks = 0
    @timer.start { ticks += 1 }
    @started.first.last.call

    assert_equal([SU_MCP::McpRuntimePollTimer::IDLE_INTERVAL, true], @started.first.first(2))
    assert_equal(1, ticks)
    assert_predicate(@timer, :running?)
  end

  def test_pace_restarts_only_when_the_interval_changes
    @timer.start { nil }

    @timer.pace(active: false)
    @timer.pace(active: true)
    @timer.pace(active: true)
    @timer.pace(active: false)

    intervals = @started.map(&:first)
    assert_equal(
      [SU_MCP::McpRuntimePollTimer::IDLE_INTERVAL, SU_MCP::McpRuntimePollTimer::ACTIVE_INTERVAL,
       SU_MCP::McpRuntimePollTimer::IDLE_INTERVAL],
      intervals
    )
    assert_equal(%i[timer1 timer2], @stopped)
  end

  def test_pace_does_nothing_after_stop
    @timer.start { nil }
    @timer.stop

    @timer.pace(active: true)

    assert_equal(1, @started.length)
    refute_predicate(@timer, :running?)
  end

  def test_stop_reports_host_timer_errors_and_clears_state
    timer = SU_MCP::McpRuntimePollTimer.new(
      timer_starter: ->(_interval, _repeat, &_block) { :timer1 },
      timer_stopper: ->(_timer_id) { raise 'boom' },
      on_stop_error: ->(error) { @errors << error.message }
    )
    timer.start { nil }

    timer.stop

    assert_equal(['boom'], @errors)
    refute_predicate(timer, :running?)
  end
end
