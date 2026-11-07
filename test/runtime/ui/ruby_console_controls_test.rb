# frozen_string_literal: true

require 'stringio'
require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/ui/ruby_console_controls'

class RubyConsoleControlsTest < Minitest::Test
  class FakeUi
    attr_accessor :answer

    def inputbox(*)
      answer
    end
  end

  class FakeConsole
    attr_reader :cleared

    def clear
      @cleared = true
    end
  end

  def setup
    @ui = FakeUi.new
    @console = FakeConsole.new
    controls = SU_MCP::RubyConsoleControls.new(ui: @ui, console: @console)
    @actions = controls.menu_actions.to_h
  end

  def teardown
    SU_MCP::RuntimeLogger.configure
  end

  def test_menu_can_clear_the_native_console
    @actions.fetch('Clear Ruby Console').call

    assert(@console.cleared)
  end

  def test_filter_dialog_filters_real_log_events_and_reset_restores_defaults
    @ui.answer = %w[error tools eval_ruby 42]
    @actions.fetch('Filter Ruby Console Logs...').call
    output = StringIO.new
    SU_MCP::RuntimeLogger.emit('hidden', output: output)
    SU_MCP::RuntimeLogger.emit('matched', level: :error, component: 'tools',
                                          tool: 'eval_ruby', request_id: 42, output: output)
    assert_equal(1, output.string.lines.size)
    assert_includes(output.string, 'matched')

    @actions.fetch('Reset Ruby Console Log Filters').call
    SU_MCP::RuntimeLogger.emit('restored', output: output)
    assert_equal(2, output.string.lines.size)
  end

  def test_cancel_keeps_existing_filter
    SU_MCP::RuntimeLogger.configure(min_level: :error)
    @ui.answer = false
    @actions.fetch('Filter Ruby Console Logs...').call
    output = StringIO.new
    SU_MCP::RuntimeLogger.emit('hidden', output: output)

    assert_empty(output.string)
  end
end
