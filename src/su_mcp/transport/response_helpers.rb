# frozen_string_literal: true

module SU_MCP
  # Shared JSON-RPC response construction for the Ruby bridge runtime.
  module ResponseHelpers
    module_function

    def success(result, jsonrpc: '2.0', id: nil)
      {
        jsonrpc: jsonrpc,
        result: result,
        id: id
      }
    end

    def error(code, message, jsonrpc: '2.0', id: nil, data: nil)
      payload = {
        code: code,
        message: message
      }
      payload[:data] = data unless data.nil?

      {
        jsonrpc: jsonrpc,
        error: payload,
        id: id
      }
    end

    def parse_error(id: nil, jsonrpc: '2.0')
      error(-32_700, 'Parse error', jsonrpc: jsonrpc, id: id)
    end

    def method_not_found(id: nil, jsonrpc: '2.0')
      error(-32_601, 'Method not found', jsonrpc: jsonrpc, id: id, data: { success: false })
    end
  end
end
