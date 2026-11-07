# frozen_string_literal: true

require 'socket'
require 'stringio'

require_relative 'mcp_runtime_http_request_parser'
require_relative 'mcp_runtime_poll_timer'

module SU_MCP
  # Local HTTP listener for the staged Ruby-native MCP runtime.
  class McpRuntimeHttpBackend
    DEFAULT_POLL_INTERVAL = McpRuntimePollTimer::IDLE_INTERVAL
    ACTIVE_POLL_INTERVAL = McpRuntimePollTimer::ACTIVE_INTERVAL
    # Keep polling fast briefly after traffic so the next call in a burst is quick.
    ACTIVE_POLL_GRACE_SECONDS = 2.0
    CLIENT_IDLE_TIMEOUT = 5.0
    MAX_ACCEPTS_PER_POLL = 4
    MAX_ACTIVE_CLIENTS = 16
    READ_CHUNK_BYTES = 16 * 1024
    WRITE_CHUNK_BYTES = 64 * 1024
    MAX_WRITE_CHUNKS_PER_POLL = 64

    def initialize(app_builder:, server_factory:, timer_starter:, timer_stopper:, logger:)
      @app_builder = app_builder
      @server_factory = server_factory
      @logger = logger
      @poll_timer = McpRuntimePollTimer.new(
        timer_starter: timer_starter, timer_stopper: timer_stopper,
        on_stop_error: ->(e) { log("MCP runtime timer stop failed: #{e.message}", level: :error) }
      )
      @running = false
      @server = nil
      @app = nil
      @last_activity_at = nil
      @host = nil
      @port = nil
      @clients = {}
      @request_parser = McpRuntimeHttpRequestParser.new
    end

    def start(host:, port:, handlers:)
      return if running?

      @host = host
      @port = port
      @clients = {}
      @app = app_builder.call(handlers)
      @server = server_factory.call(host, port)
      @running = true
      @last_activity_at = nil
      @poll_timer.start { poll_for_connections }
      log "MCP runtime listening on #{host}:#{port}"
    end

    def stop
      return unless @server || @poll_timer.running? || @running || @app || @clients.any?

      @poll_timer.stop
      close_socket(@server)
      @server = nil
      close_clients
      close_app
      @running = false
      log 'MCP runtime stopped'
    end

    def running?
      @running
    end

    def status
      {
        host: @host,
        port: @port,
        running: running?
      }
    end

    private

    attr_reader :app_builder, :server_factory, :logger

    def log(message, level: :info)
      logger.call(message, level: level, component: 'transport')
    end

    def active?
      return true if @clients.any?

      @last_activity_at && monotonic_time - @last_activity_at < ACTIVE_POLL_GRACE_SECONDS
    end

    def mark_activity
      @last_activity_at = monotonic_time
    end

    def poll_for_connections
      return unless running?

      accept_pending_clients
      service_clients
      close_idle_clients
      @poll_timer.pace(active: active?) if running?
    rescue StandardError => e
      log("MCP runtime poll error: #{e.message}", level: :error)
    end

    def accept_pending_clients
      accepted = 0

      while accepted < MAX_ACCEPTS_PER_POLL && @server&.wait_readable(0)
        client = @server.accept_nonblock
        accepted += 1
        register_client(client)
      end
    rescue IO::WaitReadable
      nil
    end

    def register_client(client)
      if @clients.length >= MAX_ACTIVE_CLIENTS
        close_socket(client)
        return
      end

      @clients[client] = {
        input: ''.b,
        output: nil,
        output_offset: 0,
        dispatching: false,
        last_active_at: mark_activity
      }
    end

    def service_clients
      @clients.each_key.to_a.each do |client|
        state = @clients[client]
        next unless state

        state[:output] ? flush_client_output(client, state) : read_client_input(client, state)
      end
    end

    def read_client_input(client, state)
      return unless client.wait_readable(0)

      loop do
        state[:input] << client.read_nonblock(READ_CHUNK_BYTES)
        state[:last_active_at] = monotonic_time
        request = @request_parser.parse(state[:input])
        next unless request

        dispatch_request_safely(client, state, request)
        return
      end
    rescue IO::WaitReadable
      nil
    rescue IOError, SystemCallError
      close_client(client)
    end

    def dispatch_request_safely(client, state, request)
      dispatch_request(client, state, request)
    rescue StandardError
      close_client(client)
      raise
    end

    def dispatch_request(client, state, request)
      state[:dispatching] = true
      status, headers, body = @app.call(build_env(request))
      response_body = collect_body(body)
      state[:output] = response_text(status, headers, response_body)
      state[:output_offset] = 0
      state[:last_active_at] = monotonic_time
      flush_client_output(client, state)
    ensure
      state[:dispatching] = false
    end

    def build_env(request)
      path, query = request.fetch(:target).split('?', 2)
      {
        'REQUEST_METHOD' => request.fetch(:method),
        'SCRIPT_NAME' => '',
        'PATH_INFO' => path,
        'QUERY_STRING' => query.to_s,
        'SERVER_NAME' => @host.to_s.empty? ? '127.0.0.1' : @host,
        'SERVER_PORT' => @port.to_s,
        'rack.version' => [3, 0],
        'rack.url_scheme' => 'http',
        'rack.input' => StringIO.new(request.fetch(:body)),
        'rack.errors' => $stderr,
        'CONTENT_LENGTH' => request.fetch(:body).bytesize.to_s
      }.merge(header_env(request.fetch(:headers)))
    end

    def header_env(headers)
      headers.each_with_object({}) do |(key, value), env|
        normalized = key.upcase.tr('-', '_')
        env_key = case normalized
                  when 'CONTENT_TYPE', 'CONTENT_LENGTH'
                    normalized
                  else
                    "HTTP_#{normalized}"
                  end
        env[env_key] = value
      end
    end

    def collect_body(body)
      body.each.to_a.join
    ensure
      body.close if body.respond_to?(:close)
    end

    def response_text(status, headers, body)
      response_headers = headers.merge(
        'Content-Length' => body.bytesize.to_s,
        'Connection' => 'close'
      )

      response = +"HTTP/1.1 #{status} #{reason_phrase(status)}\r\n"
      response_headers.each do |key, value|
        response << "#{key}: #{value}\r\n"
      end
      response << "\r\n"
      response << body
    end

    def flush_client_output(client, state)
      return unless state[:output]
      return unless client.wait_writable(0)

      chunks_written = 0
      while state.fetch(:output_offset) < state[:output].bytesize
        chunk = state[:output].byteslice(state[:output_offset], WRITE_CHUNK_BYTES)
        written = client.write_nonblock(chunk)
        return unless written.positive?

        state[:output_offset] += written
        state[:last_active_at] = monotonic_time
        chunks_written += 1
        return if chunks_written >= MAX_WRITE_CHUNKS_PER_POLL
        return unless client.wait_writable(0)
      end

      close_client(client)
    rescue IO::WaitWritable
      nil
    rescue IOError, SystemCallError
      close_client(client)
    end

    def close_idle_clients
      now = monotonic_time
      @clients.each_pair.to_a.each do |client, state|
        next if state[:dispatching]

        close_client(client) if now - state.fetch(:last_active_at) > CLIENT_IDLE_TIMEOUT
      end
    end

    def close_clients
      @clients.each_key.to_a.each { |client| close_client(client) }
    end

    def close_client(client)
      mark_activity if @clients.delete(client)
      close_socket(client)
    end

    def close_socket(socket)
      socket&.close unless socket&.closed?
    rescue IOError, SystemCallError
      nil
    end

    def close_app
      @app.close if @app.respond_to?(:close)
    rescue StandardError => e
      log("MCP runtime app close failed: #{e.message}", level: :error)
    ensure
      @app = nil
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def reason_phrase(status)
      {
        200 => 'OK',
        202 => 'Accepted',
        400 => 'Bad Request',
        405 => 'Method Not Allowed',
        406 => 'Not Acceptable',
        415 => 'Unsupported Media Type',
        500 => 'Internal Server Error'
      }.fetch(status, 'OK')
    end
  end
end
