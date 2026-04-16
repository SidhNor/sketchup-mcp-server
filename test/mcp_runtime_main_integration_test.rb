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
end
