# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/scene_query_test_support'
require_relative '../src/su_mcp/request_handler'
require_relative '../src/su_mcp/request_processor'
require_relative '../src/su_mcp/scene_query_commands'
require_relative '../src/su_mcp/semantic_commands'
require_relative '../src/su_mcp/tool_dispatcher'
require_relative '../src/su_mcp/socket_server'

class SocketServerTest < Minitest::Test
  include SceneQueryTestSupport

  class FakeClient
    attr_reader :writes, :flush_count
    attr_accessor :read_data, :closed

    def initialize(read_data)
      @read_data = read_data
      @writes = []
      @flush_count = 0
      @closed = false
    end

    def gets
      @read_data
    end

    def write(data)
      @writes << data
    end

    def flush
      @flush_count += 1
    end

    def close
      @closed = true
    end
  end

  def setup
    @server = SU_MCP::SocketServer.new
    Sketchup.active_model_override = build_scene_query_model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_builds_request_handler_from_extracted_runtime_seams
    handler = @server.send(:request_handler)

    assert_instance_of(SU_MCP::RequestHandler, handler)
  end

  def test_builds_tool_dispatcher_from_socket_server_command_target
    dispatcher = @server.send(:tool_dispatcher)

    assert_instance_of(SU_MCP::ToolDispatcher, dispatcher)
  end

  def test_builds_scene_query_commands_for_read_only_bridge_commands
    commands = @server.send(:scene_query_commands)

    assert_instance_of(SU_MCP::SceneQueryCommands, commands)
  end

  def test_builds_semantic_commands_for_semantic_bridge_commands
    commands = @server.send(:semantic_commands)

    assert_instance_of(SU_MCP::SemanticCommands, commands)
  end

  def test_builds_request_processor_for_raw_socket_payloads
    processor = @server.send(:request_processor)

    assert_instance_of(SU_MCP::RequestProcessor, processor)
  end

  def test_handles_tool_calls_via_request_handler_and_dispatcher
    response = @server.send(:handle_jsonrpc_request, tools_call_request)

    assert_equal(true, response.dig(:result, :success))
    assert_equal(2, response.dig(:result, :counts, :top_level_entities))
    assert_equal([101], response.dig(:result, :entities).map { |entity| entity[:id] })
    assert_equal(21, response[:id])
  end

  def test_process_client_reads_processes_writes_and_closes
    client = FakeClient.new(tools_call_request_json)

    @server.send(:process_client, client)

    assert_processed_client(client)
  end

  def test_handles_resources_list_using_real_scene_query_commands
    response = @server.send(:handle_jsonrpc_request, resources_list_request)

    assert_equal(true, response.dig(:result, :success))
    assert_equal([101, 102], response.dig(:result, :resources).map { |resource| resource[:id] })
  end

  private

  def tools_call_request
    {
      'method' => 'tools/call',
      'params' => { 'name' => 'get_scene_info', 'arguments' => { 'entity_limit' => 1 } },
      'id' => 21
    }
  end

  def tools_call_request_json
    '{"method":"tools/call","params":{"name":"get_scene_info",' \
      '"arguments":{"entity_limit":1}},"id":7}'
  end

  def resources_list_request
    { 'method' => 'resources/list', 'id' => 12 }
  end

  def assert_processed_client(client)
    assert_equal 1, client.writes.length
    assert_includes client.writes.first, '"id":7'
    assert_includes client.writes.first, '"top_level_entities":2'
    assert_includes client.writes.first, '"id":101'
    assert_equal 1, client.flush_count
    assert_equal true, client.closed
  end
end
