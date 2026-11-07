# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/developer/developer_commands'

class DeveloperCommandsTest < Minitest::Test
  def setup
    @commands = SU_MCP::DeveloperCommands.new
  end

  def test_malformed_ruby_uses_the_command_error_path
    error = assert_raises(RuntimeError) { @commands.eval_ruby('code' => '{ visible = true }') }

    assert_match(/Ruby evaluation error:.*syntax error/m, error.message)
    assert_instance_of(SyntaxError, error.cause)
    assert_equal({ success: true, result: '2' }, @commands.eval_ruby('code' => '1 + 1'))
  end

  def test_runtime_errors_keep_the_existing_message
    error = assert_raises(RuntimeError) do
      @commands.eval_ruby('code' => 'raise "Points are not planar"')
    end

    assert_equal('Ruby evaluation error: Points are not planar', error.message)
  end

  def test_process_exit_is_not_swallowed
    assert_raises(SystemExit) { @commands.eval_ruby('code' => 'exit') }
  end

  def test_large_results_are_returned_in_full_but_logged_as_a_short_preview
    messages = []
    commands = SU_MCP::DeveloperCommands.new(logger: ->(message) { messages << message })

    result = commands.eval_ruby('code' => "'x' * 5_000_000")

    assert_equal(5_000_000, result.fetch(:result).length)
    assert(messages.all? { |message| message.length < 500 })
    assert_includes(messages.last, 'String result (5000000 chars)')
    assert_includes(messages.last, '(truncated)')
  end

  def test_small_results_are_logged_without_truncation
    messages = []
    commands = SU_MCP::DeveloperCommands.new(logger: ->(message) { messages << message })

    commands.eval_ruby('code' => '1 + 1')

    assert_equal('Code evaluation completed with Integer result (1 chars): "2"', messages.last)
  end

  def test_error_logs_cap_the_message_and_backtrace
    messages = []
    commands = SU_MCP::DeveloperCommands.new(logger: ->(message) { messages << message })

    assert_raises(RuntimeError) { commands.eval_ruby('code' => "raise 'y' * 100_000") }

    assert(messages.all? { |message| message.length < 5_000 })
    assert_operator(messages.last.lines.length, :<=, SU_MCP::DeveloperCommands::LOG_BACKTRACE_LINES)
  end
end
