# frozen_string_literal: true

require 'socket'
require 'stringio'

module SU_MCP
  # Experimental local-developer HTTP listener for the staged Ruby-native MCP spike.
  # rubocop:disable Metrics/ClassLength
  class McpSpikeHttpBackend
    DEFAULT_POLL_INTERVAL = 0.1

    def initialize(app_builder:, server_factory:, timer_starter:, timer_stopper:, logger:)
      @app_builder = app_builder
      @server_factory = server_factory
      @timer_starter = timer_starter
      @timer_stopper = timer_stopper
      @logger = logger
      @running = false
      @server = nil
      @app = nil
      @timer_id = nil
      @host = nil
      @port = nil
    end

    def start(host:, port:, handlers:)
      return if running?

      @host = host
      @port = port
      @app = app_builder.call(handlers)
      @server = server_factory.call(host, port)
      @running = true
      @timer_id = timer_starter.call(DEFAULT_POLL_INTERVAL, true) { poll_for_connections }
      log "MCP spike listening on #{host}:#{port}"
    end

    def stop
      return unless @server || @timer_id || @running

      timer_stopper.call(@timer_id) if @timer_id
      @timer_id = nil
      @server&.close
      @server = nil
      @app = nil
      @running = false
      log 'MCP spike stopped'
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

    attr_reader :app_builder, :server_factory, :timer_starter, :timer_stopper, :logger

    def log(message)
      logger.call(message)
    end

    def poll_for_connections
      return unless running?
      return unless @server&.wait_readable(0)

      client = @server.accept_nonblock
      process_client(client)
    rescue IO::WaitReadable
      nil
    rescue StandardError => e
      log "MCP spike poll error: #{e.message}"
    end

    def process_client(client)
      request = read_request(client)
      return unless request

      status, headers, body = @app.call(build_env(request))
      response_body = collect_body(body)
      write_response(client, status, headers, response_body)
    ensure
      client.close
    end

    def read_request(client)
      request_line = client.gets("\r\n")
      return nil unless request_line

      method, target, _http_version = request_line.strip.split(' ', 3)
      headers = read_headers(client)
      body = read_body(client, headers)

      {
        method: method,
        target: target,
        headers: headers,
        body: body
      }
    end

    def read_headers(client)
      {}.tap do |headers|
        loop do
          line = client.gets("\r\n")
          break if line.nil? || line == "\r\n"

          key, value = line.sub(/\r\n\z/, '').split(':', 2)
          headers[key.downcase] = value.strip
        end
      end
    end

    def read_body(client, headers)
      return read_chunked_body(client) if headers['transfer-encoding'] == 'chunked'

      length = headers.fetch('content-length', '0').to_i
      return '' if length <= 0

      client.read(length)
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

    def read_chunked_body(client)
      chunks = []

      loop do
        size_line = client.gets("\r\n")
        break if size_line.nil?

        size = size_line.strip.to_i(16)
        break if size.zero?

        chunks << client.read(size)
        client.read(2)
      end

      consume_trailer_headers(client)
      chunks.join
    end

    def consume_trailer_headers(client)
      loop do
        line = client.gets("\r\n")
        break if line.nil? || line == "\r\n"
      end
    end

    def collect_body(body)
      body.each.to_a.join
    ensure
      body.close if body.respond_to?(:close)
    end

    def write_response(client, status, headers, body)
      response_headers = headers.merge(
        'Content-Length' => body.bytesize.to_s,
        'Connection' => 'close'
      )

      client.write("HTTP/1.1 #{status} #{reason_phrase(status)}\r\n")
      response_headers.each do |key, value|
        client.write("#{key}: #{value}\r\n")
      end
      client.write("\r\n")
      client.write(body)
      client.flush
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
  # rubocop:enable Metrics/ClassLength
end
