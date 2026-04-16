# frozen_string_literal: true

require 'sketchup'
require 'json'
require 'socket'
require 'fileutils'
require 'tmpdir'
require_relative 'adapters/model_adapter'
require_relative 'developer_commands'
require_relative 'editing_commands'
require_relative 'modeling_support'
require_relative 'request_handler'
require_relative 'request_processor'
require_relative 'response_helpers'
require_relative 'runtime_command_factory'
require_relative 'runtime_logger'
require_relative 'scene_query_commands'
require_relative 'semantic_commands'
require_relative 'solid_modeling_commands'
require_relative 'tool_dispatcher'

module SU_MCP
  # JSON-RPC socket bridge that dispatches Ruby-owned SketchUp tool behavior.
  class SocketServer
    DEFAULT_HOST = '0.0.0.0'
    DEFAULT_PORT = 9876

    def initialize(host: DEFAULT_HOST, port: DEFAULT_PORT)
      @host = host
      @port = port
      @server = nil
      @running = false
      @timer_id = nil

      show_console
    end

    def log(msg)
      RuntimeLogger.bridge(msg)
    end

    def start
      return if @running

      begin
        log "Starting server on #{@host}:#{@port}..."
        @server = TCPServer.new(@host, @port)
        log "Server created on #{@host}:#{@port}"
        @running = true
        @timer_id = UI.start_timer(0.1, true) { poll_for_connections }
        log 'Server started and listening'
      rescue StandardError => e
        log "Error: #{e.message}"
        log e.backtrace.join("\n")
        stop
      end
    end

    def stop
      log 'Stopping server...'
      @running = false
      UI.stop_timer(@timer_id) if @timer_id
      @timer_id = nil
      @server&.close
      @server = nil
      log 'Server stopped'
    end

    def running?
      @running
    end

    def status
      {
        host: @host,
        port: @port,
        running: @running
      }
    end

    private

    def show_console
      SKETCHUP_CONSOLE.show
    rescue StandardError
      begin
        Sketchup.send_action('showRubyPanel:')
      rescue StandardError
        UI.start_timer(0) { SKETCHUP_CONSOLE.show }
      end
    end

    def poll_for_connections
      return unless @running
      return unless @server.wait_readable(0)

      log 'Connection waiting...'
      client = @server.accept_nonblock
      log 'Client accepted'
      process_client(client)
    rescue IO::WaitReadable
      nil
    rescue StandardError => e
      log "Timer error: #{e.message}"
      log e.backtrace.join("\n")
    end

    def handle_jsonrpc_request(request)
      request_handler.handle(request)
    end

    def request_processor
      @request_processor ||= RequestProcessor.new(
        request_handler: method(:handle_jsonrpc_request),
        logger: method(:log)
      )
    end

    def request_handler
      @request_handler ||= RequestHandler.new(
        tool_executor: method(:dispatch_tool_call),
        resource_lister: -> { scene_query_commands.list_resources },
        prompts_provider: -> { [] },
        logger: method(:log)
      )
    end

    def tool_dispatcher
      @tool_dispatcher ||= ToolDispatcher.new(
        command_targets: runtime_command_factory.build_command_targets
      )
    end

    def scene_query_commands
      runtime_command_factory.scene_query_commands
    end

    def semantic_commands
      runtime_command_factory.semantic_commands
    end

    def editing_commands
      runtime_command_factory.editing_commands
    end

    def modeling_support
      @modeling_support ||= runtime_command_factory.send(:modeling_support)
    end

    def solid_modeling_commands
      runtime_command_factory.solid_modeling_commands
    end

    def developer_commands
      runtime_command_factory.developer_commands
    end

    def model_adapter
      @model_adapter ||= Adapters::ModelAdapter.new
    end

    def runtime_command_factory
      @runtime_command_factory ||= RuntimeCommandFactory.new(
        logger: method(:log),
        model_adapter: model_adapter
      )
    end

    def dispatch_tool_call(tool_name, args)
      log "Handling tool call: #{tool_name.inspect} with args: #{args.inspect}"
      result = tool_dispatcher.call(tool_name, args)
      log "Tool call result: #{result.inspect}"
      result
    end

    def process_client(client)
      data = client.gets
      response = request_processor.process(data) if data
      write_response(client, response) if response
    ensure
      client.close
      log 'Client closed'
    end

    def write_response(client, response)
      response_json = "#{response.to_json}\n"

      log "Sending response: #{response_json.strip}"
      client.write(response_json)
      client.flush
      log 'Response sent'
    end
  end
end
