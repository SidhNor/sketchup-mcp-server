# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_request_logging'

class McpRuntimeRequestLoggingTest < Minitest::Test
  def teardown
    SU_MCP::RuntimeLogger.configure
  end

  def test_real_transport_logs_failure_then_success_with_request_ids
    completions = transport_completion_events

    assert_equal([41, 42], completions.map { |event| event['request_id'] })
    assert_equal(%w[error info], completions.map { |event| event['level'] })
    assert_equal(%w[failed succeeded], completions.map { |event| event['outcome'] })
    assert_equal(['eval_ruby'], completions.map { |event| event['tool'] }.uniq)
    assert(completions.all? { |event| event['duration_ms'] >= 0 })
    refute_includes(completions.to_json, 'visible = true')
  end

  def test_refusals_are_warnings_and_filters_apply_to_real_context
    SU_MCP::RuntimeLogger.configure(min_level: :warn, tools: ['eval_ruby'], request_ids: [42])
    stdout, = capture_io do
      log_result(41, success: false)
      log_result(42, success: true, outcome: 'refused')
    end
    events = stdout.lines.map { |line| JSON.parse(line.delete_prefix('SketchUp MCP: ')) }

    assert_equal(1, events.size)
    assert_equal('warn', events.first['level'])
    assert_equal('refused', events.first['outcome'])
  end

  def test_invalid_json_does_not_change_the_response
    response = '{"error":{"code":-32700}}'
    result = SU_MCP::McpRuntimeRequestLogging.new.call('bad json') { response }

    assert_equal(response, result)
  end

  def test_batch_records_each_tool_with_its_own_duration
    requests = [eval_request(41, '1 + 1'), eval_request(42, '2 + 2')]
    times = [0.0, 0.01, 0.01, 0.05]
    stdout, = capture_io do
      logger = SU_MCP::McpRuntimeRequestLogging.new(clock: -> { times.shift })
      logger.call(requests.to_json) do |payload|
        { id: JSON.parse(payload)['id'], result: { structuredContent: { success: true } } }.to_json
      end
    end
    events = parse_events(stdout)

    assert_equal([41, 42], events.map { |event| event['request_id'] })
    assert_equal([10.0, 40.0], events.map { |event| event['duration_ms'] })
  end

  def test_real_batch_preserves_sdk_responses_and_logs_failure_then_recovery
    loader = runtime_loader
    loader.load!
    handlers = { eval_ruby: SU_MCP::DeveloperCommands.new.method(:eval_ruby) }
    server = loader.send(:build_server, handlers: handlers)
    requests = [eval_request(41, '{ visible = true }'), eval_request(42, '1 + 1')]
    actual = expected = nil
    stdout, = capture_io do
      actual = SU_MCP::McpRuntimeRequestLogging.new.call(requests.to_json) do |payload|
        server.handle_json(payload)
      end
      expected = server.handle_json(requests.to_json)
    end
    completions = parse_events(stdout).select { |event| event['event'] == 'tool.completed' }

    assert_equal(JSON.parse(expected), JSON.parse(actual))
    assert_equal([41, 42], completions.map { |event| event['request_id'] })
    assert_equal(%w[failed succeeded], completions.map { |event| event['outcome'] })
  end

  def test_batch_notification_and_invalid_request_shapes_match_the_sdk
    loader = runtime_loader
    loader.load!
    server = loader.send(:build_server, handlers: {})
    notification = { jsonrpc: '2.0', method: 'notifications/initialized' }
    shapes = [[], [notification], [notification, { jsonrpc: '2.0', id: 1, method: 'tools/list' }],
              [{ id: 2, method: 'invalid' }, notification]]
    shapes.each do |requests|
      body = requests.to_json
      actual = SU_MCP::McpRuntimeRequestLogging.new.call(body) { |payload| server.handle_json(payload) }

      assert_equal(server.handle_json(body).to_s, actual.to_s)
    end
  end

  private

  def runtime_loader
    require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_loader'
    require_relative '../../../src/su_mcp/developer/developer_commands'
    loader = SU_MCP::McpRuntimeLoader.new(vendor_root: File.expand_path('../vendor/ruby', __dir__))
    skip('staged vendor runtime required') unless loader.available?

    loader
  end

  def transport_completion_events
    loader = runtime_loader
    commands = SU_MCP::DeveloperCommands.new
    transport = loader.build_transport(handlers: { eval_ruby: commands.method(:eval_ruby) })
    stdout, = capture_io do
      invoke(transport, 41, '{ visible = true }')
      invoke(transport, 42, '1 + 1')
    end
    events = parse_events(stdout)
    events.select { |event| event['event'] == 'tool.completed' }
  end

  def log_result(id, content)
    request = { id: id, method: 'tools/call', params: { name: 'eval_ruby' } }.to_json
    response = { result: { structuredContent: content } }.to_json
    SU_MCP::McpRuntimeRequestLogging.new.call(request) { response }
  end

  def invoke(transport, id, code)
    require 'stringio'
    request = eval_request(id, code).to_json
    transport.call(
      'REQUEST_METHOD' => 'POST', 'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream', 'rack.input' => StringIO.new(request)
    )
  end

  def eval_request(id, code)
    {
      jsonrpc: '2.0', id: id, method: 'tools/call',
      params: { name: 'eval_ruby', arguments: { code: code } }
    }
  end

  def parse_events(stdout)
    stdout.lines.map { |line| JSON.parse(line.delete_prefix('SketchUp MCP: ')) }
  end
end
