# frozen_string_literal: true

require_relative 'test_helper'

def file_loaded?(_filename)
  true
end

require_relative '../src/su_mcp/main'

class McpSpikeMainIntegrationTest < Minitest::Test
  def test_menu_actions_include_explicit_spike_controls
    labels = SU_MCP::Main.send(:menu_actions).map(&:first)

    assert_includes(labels, 'Experimental MCP Spike Status')
    assert_includes(labels, 'Start Experimental MCP Spike')
    assert_includes(labels, 'Restart Experimental MCP Spike')
    assert_includes(labels, 'Stop Experimental MCP Spike')
  end
end
