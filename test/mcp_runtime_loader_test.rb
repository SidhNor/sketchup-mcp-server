# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'
require_relative '../src/su_mcp/mcp_runtime_loader'

class McpRuntimeLoaderTest < Minitest::Test
  def setup
    @vendor_root = File.expand_path('../vendor/ruby', __dir__)
    @loader = SU_MCP::McpRuntimeLoader.new(vendor_root: @vendor_root)
  end

  def test_available_is_false_when_staged_vendor_tree_is_absent
    Dir.mktmpdir do |empty_vendor_root|
      loader = SU_MCP::McpRuntimeLoader.new(vendor_root: empty_vendor_root)

      refute(loader.available?)
      assert_includes(loader.missing_gems, 'mcp')
    end
  end

  def test_load_registers_vendored_dependencies_and_runtime_load_paths
    skip_unless_staged_vendor_runtime!

    @loader.load!

    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/mcp-0.13.0/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/json-schema-6.2.0/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/rack-3.2.6/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/addressable-2.9.0/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/public_suffix-7.0.5/lib') })
    assert_equal(
      File.join(@vendor_root, 'json-schema-6.2.0'),
      Gem.loaded_specs.fetch('json-schema').full_gem_path
    )
  end

  # rubocop:disable Metrics/MethodLength
  def test_build_transport_handles_initialize_and_ping_over_stateless_http
    skip_unless_staged_vendor_runtime!

    transport = @loader.build_transport(
      ping_handler: -> { { success: true, message: 'pong' } },
      scene_info_handler: ->(_params) { { success: true, entities: [{ id: 101 }] } }
    )

    initialize_response = perform_json_request(
      transport,
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2025-03-26',
        capabilities: {},
        clientInfo: { name: 'codex-test', version: '1.0.0' }
      }
    )
    ping_response = perform_json_request(
      transport,
      id: 2,
      method: 'tools/call',
      params: { name: 'ping', arguments: {} }
    )
    scene_response = perform_json_request(
      transport,
      id: 3,
      method: 'tools/call',
      params: { name: 'get_scene_info', arguments: { 'entity_limit' => 1 } }
    )

    assert_equal(200, initialize_response[:status])
    assert_equal(200, ping_response[:status])
    assert_equal({ 'success' => true, 'message' => 'pong' },
                 ping_response[:body].dig('result', 'structuredContent'))
    assert_equal({ 'success' => true, 'entities' => [{ 'id' => 101 }] },
                 scene_response[:body].dig('result', 'structuredContent'))
  end
  # rubocop:enable Metrics/MethodLength

  def test_build_transport_handles_batched_initialized_and_tools_list_requests
    skip_unless_staged_vendor_runtime!

    transport = @loader.build_transport(
      ping_handler: -> { { success: true, message: 'pong' } },
      scene_info_handler: ->(_params) { { success: true, entities: [{ id: 101 }] } }
    )

    response = perform_raw_json_request(transport, batched_tools_list_payload)
    tools = response[:body].fetch('result').fetch('tools')

    assert_equal(200, response[:status])
    assert_equal(
      %w[get_scene_info ping],
      tools.map { |tool| tool.fetch('name') }.sort
    )
    scene_tool = tools.find { |tool| tool.fetch('name') == 'get_scene_info' }
    assert_equal(
      'integer',
      scene_tool.fetch('inputSchema').fetch('properties').fetch('entity_limit').fetch('type')
    )
  end

  def test_build_transport_returns_accepted_for_notification_only_posts
    skip_unless_staged_vendor_runtime!

    transport = @loader.build_transport(
      ping_handler: -> { { success: true, message: 'pong' } },
      scene_info_handler: ->(_params) { { success: true, entities: [{ id: 101 }] } }
    )

    response = perform_raw_json_request(
      transport,
      {
        jsonrpc: '2.0',
        method: 'notifications/initialized'
      }
    )

    assert_equal(202, response[:status])
    assert_equal('', response[:raw_body])
  end

  private

  # rubocop:disable Metrics/MethodLength
  def perform_json_request(transport, id:, method:, params:)
    require 'rack/mock_request'

    env = Rack::MockRequest.env_for(
      '/mcp',
      method: 'POST',
      'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream',
      input: {
        jsonrpc: '2.0',
        id: id,
        method: method,
        params: params
      }.to_json
    )

    status, headers, body = transport.call(env)
    payload = body.each.to_a.join

    {
      status: status,
      headers: headers,
      body: JSON.parse(payload)
    }
  ensure
    body.close if body.respond_to?(:close)
  end
  # rubocop:enable Metrics/MethodLength

  def perform_raw_json_request(transport, payload)
    require 'rack/mock_request'

    env = Rack::MockRequest.env_for(
      '/mcp',
      method: 'POST',
      'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream',
      input: JSON.generate(payload)
    )

    status, headers, body = transport.call(env)
    raw_body = body.each.to_a.join

    {
      status: status,
      headers: headers,
      raw_body: raw_body,
      body: raw_body.empty? ? nil : JSON.parse(raw_body)
    }
  ensure
    body.close if body.respond_to?(:close)
  end

  def batched_tools_list_payload
    [
      {
        jsonrpc: '2.0',
        method: 'notifications/initialized'
      },
      {
        jsonrpc: '2.0',
        id: 2,
        method: 'tools/list',
        params: {}
      }
    ]
  end

  def skip_unless_staged_vendor_runtime!
    return if @loader.available?

    skip('staged experimental vendor runtime not present in repo checkout')
  end
end
