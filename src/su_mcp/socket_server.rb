# frozen_string_literal: true

require 'sketchup'
require 'json'
require 'socket'
require 'fileutils'
require 'tmpdir'
require_relative 'adapters/model_adapter'
require_relative 'editing_commands'
require_relative 'joinery_commands'
require_relative 'modeling_support'
require_relative 'request_handler'
require_relative 'request_processor'
require_relative 'response_helpers'
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
        command_targets: [
          scene_query_commands,
          semantic_commands,
          editing_commands,
          solid_modeling_commands,
          joinery_commands,
          self
        ]
      )
    end

    def scene_query_commands
      @scene_query_commands ||= SceneQueryCommands.new(logger: method(:log), adapter: model_adapter)
    end

    def semantic_commands
      @semantic_commands ||= SemanticCommands.new(model: Sketchup.active_model)
    end

    def editing_commands
      @editing_commands ||= EditingCommands.new(
        model_adapter: model_adapter,
        logger: method(:log),
        active_model_provider: -> { Sketchup.active_model }
      )
    end

    def modeling_support
      @modeling_support ||= ModelingSupport.new
    end

    def solid_modeling_commands
      @solid_modeling_commands ||= SolidModelingCommands.new(
        model_provider: -> { Sketchup.active_model },
        logger: method(:log),
        support: modeling_support
      )
    end

    def joinery_commands
      @joinery_commands ||= JoineryCommands.new(
        model_provider: -> { Sketchup.active_model },
        logger: method(:log),
        support: modeling_support
      )
    end

    def model_adapter
      @model_adapter ||= Adapters::ModelAdapter.new
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

    def eval_ruby(params)
      log "Evaluating Ruby code with length: #{params['code'].length}"

      begin
        # Create a safe binding for evaluation
        binding = TOPLEVEL_BINDING.dup

        # Evaluate the Ruby code
        log 'Starting code evaluation...'
        # rubocop:disable Security/Eval
        result = eval(params['code'], binding)
        # rubocop:enable Security/Eval
        log "Code evaluation completed with result: #{result.inspect}"

        # Return success with the result as a string
        {
          success: true,
          result: result.to_s
        }
      rescue StandardError => e
        log "Error in eval_ruby: #{e.message}"
        log e.backtrace.join("\n")
        raise "Ruby evaluation error: #{e.message}"
      end
    end
  end
end
