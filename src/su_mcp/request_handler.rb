# frozen_string_literal: true

require_relative 'response_helpers'

module SU_MCP
  # Normalizes incoming bridge requests and returns JSON-RPC responses.
  class RequestHandler
    def initialize(tool_executor:, resource_lister:, prompts_provider: -> { [] }, logger: nil)
      @tool_executor = tool_executor
      @resource_lister = resource_lister
      @prompts_provider = prompts_provider
      @logger = logger
    end

    def handle(request)
      log("Handling JSONRPC request: #{request.inspect}")

      normalized_request = normalize_request(request)
      return ping_response(normalized_request) if normalized_request['method'] == 'ping'
      return handle_tool_call(normalized_request) if normalized_request['method'] == 'tools/call'
      if normalized_request['method'] == 'resources/list'
        return resources_response(normalized_request)
      end
      return prompts_response(normalized_request) if normalized_request['method'] == 'prompts/list'

      ResponseHelpers.method_not_found(id: normalized_request['id'],
                                       jsonrpc: jsonrpc_version(normalized_request))
    end

    private

    def normalize_request(request)
      return request unless request['command']

      build_tool_request(
        request['command'],
        request['parameters'],
        id: request['id'],
        jsonrpc: jsonrpc_version(request)
      ).tap do |tool_request|
        log("Converting to tool request: #{tool_request.inspect}")
      end
    end

    def build_tool_request(command_name, arguments, id:, jsonrpc:)
      {
        'method' => 'tools/call',
        'params' => {
          'name' => command_name,
          'arguments' => arguments
        },
        'jsonrpc' => jsonrpc,
        'id' => id
      }
    end

    def handle_tool_call(request)
      tool_name = request.dig('params', 'name')
      args = request.dig('params', 'arguments') || {}
      result = @tool_executor.call(tool_name, args)

      return success_response(result, request) if result[:success]

      tool_failure_response(request)
    rescue StandardError => e
      exception_response(e, request)
    end

    def jsonrpc_version(request)
      request['jsonrpc'] || '2.0'
    end

    def ping_response(request)
      success_response({ success: true, message: 'pong' }, request)
    end

    def resources_response(request)
      success_response({ resources: @resource_lister.call, success: true }, request)
    end

    def prompts_response(request)
      success_response({ prompts: @prompts_provider.call, success: true }, request)
    end

    def success_response(result, request)
      ResponseHelpers.success(result, jsonrpc: jsonrpc_version(request), id: request['id'])
    end

    def tool_failure_response(request)
      ResponseHelpers.error(-32_603, 'Operation failed',
                            jsonrpc: jsonrpc_version(request),
                            id: request['id'],
                            data: { success: false })
    end

    def exception_response(error, request)
      ResponseHelpers.error(-32_603, error.message,
                            jsonrpc: jsonrpc_version(request),
                            id: request['id'],
                            data: { success: false })
    end

    def log(message)
      @logger&.call(message)
    end
  end
end
