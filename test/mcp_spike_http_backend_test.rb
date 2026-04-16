# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/mcp_spike_http_backend'

class McpSpikeHttpBackendTest < Minitest::Test
  class FakeTcpServer
    attr_reader :host, :port
    attr_accessor :closed

    def initialize(host, port)
      @host = host
      @port = port
      @closed = false
    end

    def close
      @closed = true
    end
  end

  class FakeClient
    attr_reader :writes
    attr_accessor :closed

    def initialize(request_text)
      @request_text = request_text
      @writes = []
      @closed = false
      @position = 0
    end

    def gets(separator = $INPUT_RECORD_SEPARATOR)
      index = @request_text.index(separator, @position)
      return nil unless index

      chunk = @request_text[@position..(index + separator.length - 1)]
      @position = index + separator.length
      chunk
    end

    def read(length)
      chunk = @request_text[@position, length]
      @position += chunk.length
      chunk
    end

    def write(data)
      @writes << data
    end

    def flush; end

    def close
      @closed = true
    end
  end

  def test_start_builds_app_opens_socket_and_marks_running
    started_timers = []
    backend = build_backend(
      app_builder: ->(handlers) { { handlers: handlers } },
      server_factory: ->(host, port) { FakeTcpServer.new(host, port) },
      timer_starter: lambda do |interval, repeat, &block|
        started_timers << [interval, repeat, block]
        :timer_one
      end,
      timer_stopper: ->(_timer_id) { flunk 'stop should not run during start' },
      logger: ->(_message) {}
    )

    backend.start(host: '127.0.0.1', port: 9877, handlers: { ping: -> { { success: true } } })

    assert_equal(true, backend.running?)
    assert_equal('127.0.0.1', backend.status[:host])
    assert_equal(9877, backend.status[:port])
    assert_equal(1, started_timers.length)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def test_process_client_translates_http_into_a_rack_call_and_writes_a_response
    app_calls = []
    app = lambda do |env|
      app_calls << env
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(host, port) { FakeTcpServer.new(host, port) },
      timer_starter: ->(_interval, _repeat, &_block) { :timer_one },
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    client = FakeClient.new(http_post_request('{"jsonrpc":"2.0","id":1,"method":"ping"}'))

    backend.send(:process_client, client)

    assert_equal('POST', app_calls.first['REQUEST_METHOD'])
    assert_equal('/mcp', app_calls.first['PATH_INFO'])
    assert_equal('application/json', app_calls.first['CONTENT_TYPE'])
    assert_includes(app_calls.first['HTTP_ACCEPT'], 'application/json')
    assert_includes(client.writes.join, 'HTTP/1.1 200 OK')
    assert_includes(client.writes.join, '{"ok":true}')
    assert_equal(true, client.closed)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def test_process_client_reads_lowercase_content_length_headers
    app_calls = []
    app = lambda do |env|
      app_calls << env
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(host, port) { FakeTcpServer.new(host, port) },
      timer_starter: ->(_interval, _repeat, &_block) { :timer_one },
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    client = FakeClient.new(http_post_request('{"jsonrpc":"2.0","id":1}', lowercase_headers: true))

    backend.send(:process_client, client)

    assert_equal('application/json', app_calls.first['CONTENT_TYPE'])
    assert_equal('{"jsonrpc":"2.0","id":1}', app_calls.first['rack.input'].read)
  end

  def test_process_client_reads_chunked_request_bodies
    app_calls = []
    app = lambda do |env|
      app_calls << env
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(host, port) { FakeTcpServer.new(host, port) },
      timer_starter: ->(_interval, _repeat, &_block) { :timer_one },
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    client = FakeClient.new(http_chunked_post_request('{"jsonrpc":"2.0","id":1,"method":"ping"}'))

    backend.send(:process_client, client)

    assert_equal('chunked', app_calls.first['HTTP_TRANSFER_ENCODING'])
    assert_equal('{"jsonrpc":"2.0","id":1,"method":"ping"}', app_calls.first['rack.input'].read)
  end

  def test_stop_closes_socket_and_timer
    stopped = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { ->(_env) { [200, {}, ['']] } },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: ->(_interval, _repeat, &_block) { :timer_one },
      timer_stopper: ->(timer_id) { stopped << timer_id },
      logger: ->(_message) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})

    backend.stop

    assert_equal(false, backend.running?)
    assert_equal([:timer_one], stopped)
    assert_equal(true, tcp_server.closed)
  end

  private

  def build_backend(app_builder:, server_factory:, timer_starter:, timer_stopper:, logger:)
    SU_MCP::McpSpikeHttpBackend.new(
      app_builder: app_builder,
      server_factory: server_factory,
      timer_starter: timer_starter,
      timer_stopper: timer_stopper,
      logger: logger
    )
  end

  def http_post_request(body, lowercase_headers: false)
    content_type = lowercase_headers ? 'content-type' : 'Content-Type'
    accept = lowercase_headers ? 'accept' : 'Accept'
    content_length = lowercase_headers ? 'content-length' : 'Content-Length'

    <<~HTTP.gsub("\n", "\r\n")
      POST /mcp HTTP/1.1
      Host: 127.0.0.1:9877
      #{content_type}: application/json
      #{accept}: application/json, text/event-stream
      #{content_length}: #{body.bytesize}

      #{body}
    HTTP
  end

  def http_chunked_post_request(body)
    <<~HTTP.gsub("\n", "\r\n")
      POST /mcp HTTP/1.1
      Host: 127.0.0.1:9877
      Content-Type: application/json
      Accept: application/json, text/event-stream
      Transfer-Encoding: chunked

      #{body.bytesize.to_s(16)}
      #{body}
      0

    HTTP
  end
end
