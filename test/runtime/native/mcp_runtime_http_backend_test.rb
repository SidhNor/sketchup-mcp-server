# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_http_backend'

class McpRuntimeHttpBackendTest < Minitest::Test
  class FakeTcpServer
    attr_reader :host, :port
    attr_accessor :closed

    def initialize(host, port)
      @host = host
      @port = port
      @closed = false
      @clients = []
    end

    def enqueue(client)
      @clients << client
    end

    # rubocop:disable Naming/PredicateMethod
    def wait_readable(_timeout)
      !@clients.empty?
    end
    # rubocop:enable Naming/PredicateMethod

    def accept_nonblock
      raise IO::WaitReadable if @clients.empty?

      @clients.shift
    end

    def close
      @closed = true
    end

    def closed?
      @closed
    end
  end

  class FakeClient
    attr_reader :writes
    attr_accessor :closed

    def initialize(
      request_text = '',
      read_chunk_size: nil,
      write_chunk_size: nil,
      max_write_bytes: nil
    )
      @request_text = request_text
      @writes = []
      @closed = false
      @position = 0
      @read_chunk_size = read_chunk_size
      @write_chunk_size = write_chunk_size
      @max_write_bytes = max_write_bytes
    end

    def feed(text)
      @request_text << text
    end

    # rubocop:disable Naming/PredicateMethod
    def wait_readable(_timeout)
      @position < @request_text.bytesize
    end
    # rubocop:enable Naming/PredicateMethod

    def read_nonblock(max_length)
      raise IO::WaitReadable unless wait_readable(0)

      length = [max_length, @request_text.bytesize - @position, @read_chunk_size || max_length].min
      chunk = @request_text.byteslice(@position, length)
      @position += chunk.bytesize
      chunk
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

    # rubocop:disable Naming/PredicateMethod
    def wait_writable(_timeout)
      true
    end
    # rubocop:enable Naming/PredicateMethod

    def write_nonblock(data)
      raise Errno::EMSGSIZE if @max_write_bytes && data.bytesize > @max_write_bytes

      length = [data.bytesize, @write_chunk_size || data.bytesize].min
      @writes << data.byteslice(0, length)
      length
    end

    def flush; end

    def close
      @closed = true
    end

    def closed?
      @closed
    end
  end

  class ClosingApp
    attr_reader :calls
    attr_accessor :closed

    def initialize
      @calls = []
      @closed = false
    end

    def call(env)
      @calls << env
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end

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
      logger: ->(_message, **_context) {}
    )

    backend.start(host: '127.0.0.1', port: 9877, handlers: { ping: -> { { success: true } } })

    assert_equal(true, backend.running?)
    assert_equal('127.0.0.1', backend.status[:host])
    assert_equal(9877, backend.status[:port])
    assert_equal(1, started_timers.length)
  end

  # rubocop:disable Metrics/AbcSize
  def test_poll_translates_http_into_a_rack_call_and_writes_a_response
    app_calls = []
    app = lambda do |env|
      app_calls << env
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end
    timer_blocks = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message, **_context) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    client = FakeClient.new(http_post_request('{"jsonrpc":"2.0","id":1,"method":"ping"}'))
    tcp_server.enqueue(client)

    timer_blocks.first.call

    assert_equal('POST', app_calls.first['REQUEST_METHOD'])
    assert_equal('/mcp', app_calls.first['PATH_INFO'])
    assert_equal('application/json', app_calls.first['CONTENT_TYPE'])
    assert_includes(app_calls.first['HTTP_ACCEPT'], 'application/json')
    assert_includes(client.writes.join, 'HTTP/1.1 200 OK')
    assert_includes(client.writes.join, '{"ok":true}')
    assert_equal(true, client.closed)
  end
  # rubocop:enable Metrics/AbcSize

  def test_poll_reads_lowercase_content_length_headers
    app_calls = []
    app = lambda do |env|
      app_calls << env
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end
    timer_blocks = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message, **_context) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    client = FakeClient.new(http_post_request('{"jsonrpc":"2.0","id":1}', lowercase_headers: true))
    tcp_server.enqueue(client)

    timer_blocks.first.call

    assert_equal('application/json', app_calls.first['CONTENT_TYPE'])
    assert_equal('{"jsonrpc":"2.0","id":1}', app_calls.first['rack.input'].read)
  end

  def test_poll_writes_large_responses_in_bounded_nonblocking_chunks
    chunk_bytes = SU_MCP::McpRuntimeHttpBackend::WRITE_CHUNK_BYTES
    body = 'x' * ((chunk_bytes * 2) + 123)
    app = ->(_env) { [200, { 'Content-Type' => 'application/json' }, [body]] }
    timer_blocks = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message, **_context) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    client = FakeClient.new(
      http_post_request('{"jsonrpc":"2.0","id":1}'),
      max_write_bytes: chunk_bytes
    )
    tcp_server.enqueue(client)

    timer_blocks.first.call

    assert_equal(true, client.closed)
    assert(
      client.writes.all? { |write| write.bytesize <= chunk_bytes }
    )
    assert_includes(client.writes.join, body)
  end

  def test_poll_does_not_idle_close_a_client_while_request_dispatch_is_in_progress
    timer_blocks = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    client = FakeClient.new(http_post_request('{"jsonrpc":"2.0","id":1}'))
    closed_during_dispatch = nil
    app = lambda do |_env|
      timer_blocks.first.call
      closed_during_dispatch = client.closed
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message, **_context) {}
    )
    monotonic_times = [0.0, 0.0, 10.0]
    backend.define_singleton_method(:monotonic_time) { monotonic_times.shift || 10.0 }
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    tcp_server.enqueue(client)

    timer_blocks.first.call

    assert_equal(false, closed_during_dispatch)
    assert_equal(true, client.closed)
    assert_includes(client.writes.join, '{"ok":true}')
  end

  def test_poll_reads_chunked_request_bodies
    app_calls = []
    app = lambda do |env|
      app_calls << env
      [200, { 'Content-Type' => 'application/json' }, ['{"ok":true}']]
    end
    timer_blocks = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message, **_context) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    client = FakeClient.new(http_chunked_post_request('{"jsonrpc":"2.0","id":1,"method":"ping"}'))
    tcp_server.enqueue(client)

    timer_blocks.first.call

    assert_equal('chunked', app_calls.first['HTTP_TRANSFER_ENCODING'])
    assert_equal('{"jsonrpc":"2.0","id":1,"method":"ping"}', app_calls.first['rack.input'].read)
  end

  def test_poll_keeps_partial_requests_without_blocking_the_timer
    app = ClosingApp.new
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend, timer_blocks = build_polled_backend(app: app, tcp_server: tcp_server)
    request = http_post_request('{"jsonrpc":"2.0","id":1}')
    split_index = request.index("\r\n\r\n") + 4
    client = FakeClient.new(request.byteslice(0, split_index))
    tcp_server.enqueue(client)
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})

    timer_blocks.first.call
    client.feed(request.byteslice(split_index..))
    timer_blocks.first.call

    assert_equal(1, app.calls.length)
    assert_equal(true, client.closed)
    assert_includes(client.writes.join, 'HTTP/1.1 200 OK')
  end

  def test_poll_closes_client_when_app_dispatch_raises
    timer_blocks = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { ->(_env) { raise 'rack failure' } },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message, **_context) {}
    )
    client = FakeClient.new(http_post_request('{"jsonrpc":"2.0","id":1}'))
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    tcp_server.enqueue(client)

    timer_blocks.first.call

    assert_equal(true, client.closed)
  end

  def test_stop_closes_socket_and_timer
    stopped = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { ->(_env) { [200, {}, ['']] } },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: ->(_interval, _repeat, &_block) { :timer_one },
      timer_stopper: ->(timer_id) { stopped << timer_id },
      logger: ->(_message, **_context) {}
    )
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})

    backend.stop

    assert_equal(false, backend.running?)
    assert_equal([:timer_one], stopped)
    assert_equal(true, tcp_server.closed)
  end

  def test_stop_closes_active_clients_and_the_rack_app
    stopped = []
    app = ClosingApp.new
    timer_blocks = []
    tcp_server = FakeTcpServer.new('127.0.0.1', 9877)
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(timer_id) { stopped << timer_id },
      logger: ->(_message, **_context) {}
    )
    client = FakeClient.new("POST /mcp HTTP/1.1\r\n")
    backend.start(host: '127.0.0.1', port: 9877, handlers: {})
    tcp_server.enqueue(client)
    timer_blocks.first.call

    backend.stop

    assert_equal([:timer_one], stopped)
    assert_equal(true, tcp_server.closed)
    assert_equal(true, client.closed)
    assert_equal(true, app.closed)
  end

  private

  def build_backend(app_builder:, server_factory:, timer_starter:, timer_stopper:, logger:)
    SU_MCP::McpRuntimeHttpBackend.new(
      app_builder: app_builder,
      server_factory: server_factory,
      timer_starter: timer_starter,
      timer_stopper: timer_stopper,
      logger: logger
    )
  end

  def build_polled_backend(app:, tcp_server:)
    timer_blocks = []
    backend = build_backend(
      app_builder: ->(_handlers) { app },
      server_factory: ->(_host, _port) { tcp_server },
      timer_starter: lambda do |_interval, _repeat, &block|
        timer_blocks << block
        :timer_one
      end,
      timer_stopper: ->(_timer_id) {},
      logger: ->(_message, **_context) {}
    )

    [backend, timer_blocks]
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
