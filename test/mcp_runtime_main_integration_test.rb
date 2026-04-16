# frozen_string_literal: true

require_relative 'test_helper'

def file_loaded?(_filename)
  true
end

require_relative '../src/su_mcp/main'

class McpRuntimeMainIntegrationTest < Minitest::Test
  def test_menu_actions_include_explicit_runtime_controls
    labels = SU_MCP::Main.send(:menu_actions).map(&:first)

    assert_includes(labels, 'Native MCP Runtime Status')
    assert_includes(labels, 'Start Native MCP Runtime')
    assert_includes(labels, 'Restart Native MCP Runtime')
    assert_includes(labels, 'Stop Native MCP Runtime')
  end

  def test_native_runtime_server_uses_the_shared_runtime_command_factory
    server = SU_MCP::Main.send(:build_native_runtime_server)
    facade = server.instance_variable_get(:@facade)
    runtime_command_factory = facade.instance_variable_get(:@runtime_command_factory)

    assert_instance_of(SU_MCP::RuntimeCommandFactory, runtime_command_factory)
  end
end
