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
end
