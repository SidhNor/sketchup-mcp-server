# frozen_string_literal: true

require 'stringio'

require_relative 'test_helper'
require_relative '../src/su_mcp/runtime_logger'

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

  def test_bridge_logs_to_console_when_available
    console = SketchupConsoleStub.new
    output = StringIO.new

    SU_MCP::RuntimeLogger.bridge('hello', console: console, output: output)

    assert_equal(["MCP: hello\n"], console.messages)
    assert_equal('', output.string)
  end

  def test_bridge_falls_back_to_output_when_console_write_fails
    output = StringIO.new

    SU_MCP::RuntimeLogger.bridge('fallback', console: FailingConsole.new, output: output)

    assert_equal("MCP: fallback\n", output.string)
  end

  def test_main_logger_shows_console_and_writes_to_output
    console = ShowingConsole.new
    output = StringIO.new

    SU_MCP::RuntimeLogger.main('loaded', console: console, output: output)

    assert_equal(true, console.shown)
    assert_equal("SketchUp MCP: loaded\n", output.string)
  end
end
