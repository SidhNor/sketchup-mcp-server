# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/scene_query_test_support'
require_relative '../src/su_mcp/scene_query_commands'
require_relative '../src/su_mcp/mcp_runtime_facade'

class McpRuntimeFacadeTest < Minitest::Test
  include SceneQueryTestSupport

  class RecordingSceneQueryCommands
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def get_scene_info(params = {})
      @calls << params
      @result
    end
  end

  def setup
    Sketchup.active_model_override = build_scene_query_model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_ping_returns_the_minimal_runtime_payload
    facade = SU_MCP::McpRuntimeFacade.new(
      scene_query_commands: RecordingSceneQueryCommands.new(result: {})
    )

    assert_equal({ success: true, message: 'pong' }, facade.ping)
  end

  def test_get_scene_info_reuses_the_existing_scene_query_response_shape
    expected = SU_MCP::SceneQueryCommands.new.get_scene_info('entity_limit' => 1)
    commands = RecordingSceneQueryCommands.new(result: expected)
    facade = SU_MCP::McpRuntimeFacade.new(scene_query_commands: commands)

    result = facade.get_scene_info('entity_limit' => 1)

    assert_equal([{ 'entity_limit' => 1 }], commands.calls)
    assert_equal(expected, result)
  end
end
