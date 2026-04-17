# frozen_string_literal: true

require 'stringio'

require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/runtime_logger'

class RuntimeLoggerTest < Minitest::Test
  class FailingConsole
    def write(_message)
      raise 'no console write'
    end
  end

  class ShowingConsole
    attr_reader :shown

    def initialize
      @shown = false
    end

    def show
      @shown = true
    end
  end

  def test_bridge_logger_entrypoint_is_retired
    refute_respond_to(SU_MCP::RuntimeLogger, :bridge)
  end

  def test_main_logger_shows_console_and_writes_to_output
    console = ShowingConsole.new
    output = StringIO.new

    SU_MCP::RuntimeLogger.main('loaded', console: console, output: output)

    assert_equal(true, console.shown)
    assert_equal("SketchUp MCP: loaded\n", output.string)
  end
end
