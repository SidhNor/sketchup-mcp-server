# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/transport/request_handler'

class RequestHandlerTest < Minitest::Test
  def setup
    @tool_calls = []
    @tool_executor = lambda do |tool_name, args|
      @tool_calls << [tool_name, args]
      { success: true, tool_name: tool_name, arguments: args }
    end
    @handler = SU_MCP::RequestHandler.new(
      tool_executor: @tool_executor,
      resource_lister: -> { [{ id: 1, type: 'group' }] },
      prompts_provider: -> { [] }
    )
  end

  def test_converts_direct_command_requests_to_tool_calls
    response = @handler.handle(
      'command' => 'get_scene_info',
      'parameters' => { 'include_hidden' => true },
      'id' => 11
    )

    assert_equal([['get_scene_info', { 'include_hidden' => true }]], @tool_calls)
    assert_equal('2.0', response[:jsonrpc])
    assert_equal(11, response[:id])
  end

  def test_handles_ping_requests
    response = @handler.handle('method' => 'ping', 'jsonrpc' => '2.0', 'id' => 5)

    assert_equal({ success: true, message: 'pong' }, response[:result])
    assert_equal(5, response[:id])
  end

  def test_handles_resources_list_requests
    response = @handler.handle('method' => 'resources/list', 'id' => 4)

    assert_equal([{ id: 1, type: 'group' }], response.dig(:result, :resources))
    assert_equal(true, response.dig(:result, :success))
  end

  def test_handles_prompts_list_requests
    response = @handler.handle('method' => 'prompts/list', 'id' => 8)

    assert_equal([], response.dig(:result, :prompts))
    assert_equal(true, response.dig(:result, :success))
  end

  def test_passes_through_tools_call_requests
    response = @handler.handle(
      'method' => 'tools/call',
      'params' => { 'name' => 'get_scene_info', 'arguments' => { 'limit' => 10 } },
      'id' => 12
    )

    assert_equal([['get_scene_info', { 'limit' => 10 }]], @tool_calls)
    assert_equal(true, response.dig(:result, :success))
    assert_equal(12, response[:id])
  end

  def test_returns_method_not_found_for_unknown_methods
    response = @handler.handle('method' => 'unknown/method', 'id' => 6)

    assert_equal(-32_601, response.dig(:error, :code))
    assert_equal(6, response[:id])
  end

  def test_maps_tool_exceptions_to_error_responses
    handler = SU_MCP::RequestHandler.new(
      tool_executor: ->(_tool_name, _args) { raise 'boom' },
      resource_lister: -> { [] }
    )

    response = handler.handle(tools_call_request(arguments: {}, id: 13))

    assert_equal(-32_603, response.dig(:error, :code))
    assert_equal('boom', response.dig(:error, :message))
    assert_equal(13, response[:id])
  end

  private

  def tools_call_request(arguments:, id:)
    {
      'method' => 'tools/call',
      'params' => { 'name' => 'get_scene_info', 'arguments' => arguments },
      'id' => id
    }
  end
end
