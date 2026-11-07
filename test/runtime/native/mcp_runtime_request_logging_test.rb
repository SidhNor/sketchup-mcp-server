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
    assert_operator(completions.last.fetch('response_chars'), :>, 0)
    refute_includes(completions.to_json, 'visible = true')
  end

  def test_usage_log_receives_client_sessions_and_tool_sizes_without_arguments
    usage_log = record_usage_for_session(result_text: JSON.generate(success: true, value: 'secret'))

    assert_equal(%w[client.initialized tool.completed], usage_log.records.map { |r| r[:event] })
    assert_equal('codex-mcp-client/0.50.0', usage_log.records.first[:client])
    tool_record = usage_log.records.last
    assert_equal('eval_ruby', tool_record[:tool])
    assert_equal(JSON.generate(success: true, value: 'secret').length, tool_record[:response_chars])
    assert(usage_log.records.all? { |record| record[:timestamp].is_a?(String) })
    refute_match(/secret/, usage_log.records.to_json)
  end

  def test_real_transport_logs_estimated_tokens
    completions = transport_completion_events

    assert(completions.all? { |event| event['request_tokens_est'].positive? })
    assert_operator(completions.last.fetch('response_tokens_est'), :>, 0)
  end

  def test_usage_log_records_estimated_tokens
    tool_record = record_usage_for_session(result_text: 'x' * 33).records.last

    assert_equal(7, tool_record[:response_tokens_est]) # 33 chars / 4.9
    assert_equal(4, tool_record[:request_tokens_est]) # {"code":"secret_code"} is 22 chars
  end

  def test_console_tool_events_show_estimated_tokens
    server = StubServer.new do |request|
      { id: request[:id], result: { content: [{ type: 'text', text: 'x' * 490 }] } }
    end
    stdout, = capture_io do
      SU_MCP::McpRuntimeRequestLogging.new.call(eval_request(7, '1 + 1').to_json, server)
    end
    event = parse_events(stdout).first

    assert_equal(100, event.fetch('response_tokens_est'))
    assert_equal(490, event.fetch('response_chars'))
    assert_equal(3, event.fetch('request_tokens_est'))
  end

  def test_initialize_without_client_info_is_still_a_session_boundary
    usage_log = RecordingUsageLog.new
    server = StubServer.new { { result: {} } }
    capture_io do
      SU_MCP::McpRuntimeRequestLogging.new(usage_log: usage_log)
                                      .call({ id: 1, method: 'initialize' }.to_json, server)
    end

    assert_equal(['client.initialized'], usage_log.records.map { |record| record[:event] })
    refute(usage_log.records.first.key?(:client))
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
    server = StubServer.new(json: response)
    result = SU_MCP::McpRuntimeRequestLogging.new.call('bad json', server)

    assert_equal(response, result)
    assert_equal(['bad json'], server.json_calls)
  end

  def test_batch_records_each_tool_with_its_own_duration
    requests = [eval_request(41, '1 + 1'), eval_request(42, '2 + 2')]
    times = [0.0, 0.01, 0.01, 0.05]
    stdout, = capture_io do
      logger = SU_MCP::McpRuntimeRequestLogging.new(clock: -> { times.shift })
      server = StubServer.new do |request|
        { id: request[:id], result: { structuredContent: { success: true } } }
      end
      logger.call(requests.to_json, server)
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
      actual = SU_MCP::McpRuntimeRequestLogging.new.call(requests.to_json, server)
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
      actual = SU_MCP::McpRuntimeRequestLogging.new.call(body, server)

      assert_equal(server.handle_json(body).to_s, actual.to_s)
    end
  end

  def test_non_tool_requests_are_not_logged
    server = StubServer.new { { result: { tools: [] } } }
    stdout, = capture_io do
      SU_MCP::McpRuntimeRequestLogging.new.call({ id: 1, method: 'tools/list' }.to_json, server)
    end

    assert_empty(stdout)
  end

  # Collects usage records in memory instead of writing a file.
  class RecordingUsageLog
    attr_reader :records

    def initialize
      @records = []
    end

    def append(record)
      @records << record
      nil
    end
  end

  # Records calls to the server's hash and JSON entrypoints.
  class StubServer
    attr_reader :json_calls

    def initialize(json: nil, &handler)
      @json = json
      @handler = handler
      @json_calls = []
    end

    def handle(request)
      @handler.call(request)
    end

    def handle_json(body)
      @json_calls << body
      @json
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
    server = StubServer.new do
      { result: { 'structuredContent' => content.transform_keys(&:to_s) } }
    end
    SU_MCP::McpRuntimeRequestLogging.new.call(request, server)
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

  def record_usage_for_session(result_text:)
    usage_log = RecordingUsageLog.new
    logging = SU_MCP::McpRuntimeRequestLogging.new(usage_log: usage_log)
    server = StubServer.new do |request|
      next { id: request[:id], result: { protocolVersion: '2025-06-18' } } if request[:id] == 1

      { id: request[:id], result: { content: [{ type: 'text', text: result_text }] } }
    end
    capture_io do
      logging.call(initialize_request(1, name: 'codex-mcp-client', version: '0.50.0').to_json,
                   server)
      logging.call(eval_request(2, 'secret_code').to_json, server)
    end
    usage_log
  end

  def initialize_request(id, name:, version:)
    {
      jsonrpc: '2.0', id: id, method: 'initialize',
      params: { protocolVersion: '2025-06-18', clientInfo: { name: name, version: version } }
    }
  end

  def parse_events(stdout)
    stdout.lines.map { |line| JSON.parse(line.delete_prefix('SketchUp MCP: ')) }
  end
end
