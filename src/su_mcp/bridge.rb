module SU_MCP
  module Bridge
    DEFAULT_MCP_TRANSPORT = "stdio".freeze
    DEFAULT_SOCKET_BIND_HOST = "0.0.0.0".freeze
    DEFAULT_SOCKET_PORT = 9876

    module_function

    def mcp_transport
      env_or_default("SKETCHUP_MCP_TRANSPORT", DEFAULT_MCP_TRANSPORT).downcase
    end

    def socket_bind_host
      env_or_default("SKETCHUP_BIND_HOST", DEFAULT_SOCKET_BIND_HOST)
    end

    def socket_port
      Integer(env_or_default("SKETCHUP_PORT", DEFAULT_SOCKET_PORT.to_s))
    rescue ArgumentError
      DEFAULT_SOCKET_PORT
    end

    def socket_endpoint
      "#{socket_bind_host}:#{socket_port}"
    end

    def status_message(server_status = {})
      lines = []
      lines << "SketchUp MCP is loaded."
      lines << "Python MCP transport default: #{mcp_transport}"
      lines << "SketchUp socket bridge: #{server_status[:host] || socket_bind_host}:#{server_status[:port] || socket_port}"
      lines << "Bridge running: #{server_status[:running] ? 'yes' : 'no'}"

      if mcp_transport == "stdio"
        lines << "Start the FastMCP server from the MCP client or via `uv run sketchup-mcp-server`."
      else
        lines << "Set SKETCHUP_MCP_TRANSPORT=stdio to keep the Python MCP server on stdio by default."
      end

      lines.join("\n")
    end

    def env_or_default(name, default)
      value = ENV[name]
      return default if value.nil? || value.empty?

      value
    end
    private_class_method :env_or_default
  end
end
