# frozen_string_literal: true

module SU_MCP
  # Bridge configuration helpers shared by the Ruby runtime and Python adapter.
  module Bridge
    DEFAULT_MCP_TRANSPORT = 'stdio'
    DEFAULT_SOCKET_BIND_HOST = '0.0.0.0'
    DEFAULT_SOCKET_PORT = 9876

    module_function

    def mcp_transport
      env_or_default('SKETCHUP_MCP_TRANSPORT', DEFAULT_MCP_TRANSPORT).downcase
    end

    def socket_bind_host
      env_or_default('SKETCHUP_BIND_HOST', DEFAULT_SOCKET_BIND_HOST)
    end

    def socket_port
      Integer(env_or_default('SKETCHUP_PORT', DEFAULT_SOCKET_PORT.to_s))
    rescue ArgumentError
      DEFAULT_SOCKET_PORT
    end

    def socket_endpoint
      "#{socket_bind_host}:#{socket_port}"
    end

    def status_message(server_status = {})
      [
        'SketchUp MCP is loaded.',
        "Python MCP transport default: #{mcp_transport}",
        "SketchUp socket bridge: #{bridge_endpoint(server_status)}",
        "Bridge running: #{server_status[:running] ? 'yes' : 'no'}",
        transport_hint
      ].join("\n")
    end

    def env_or_default(name, default)
      value = ENV.fetch(name, nil)
      return default if value.nil? || value.empty?

      value
    end

    def bridge_endpoint(server_status)
      host = server_status[:host] || socket_bind_host
      port = server_status[:port] || socket_port

      "#{host}:#{port}"
    end

    def transport_hint
      if mcp_transport == 'stdio'
        'Start the FastMCP server from the MCP client or via `uv run sketchup-mcp-server`.'
      else
        'Set SKETCHUP_MCP_TRANSPORT=stdio to keep the Python MCP server ' \
          'on stdio by default.'
      end
    end

    private_class_method :bridge_endpoint, :env_or_default, :transport_hint
  end
end
