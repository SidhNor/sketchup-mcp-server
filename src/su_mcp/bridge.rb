module SU_MCP
  module Bridge
    DEFAULT_TRANSPORT = "stdio".freeze
    DEFAULT_HTTP_HOST = "127.0.0.1".freeze
    DEFAULT_HTTP_PORT = 8000

    module_function

    def transport
      env_or_default("SKETCHUP_MCP_TRANSPORT", DEFAULT_TRANSPORT).downcase
    end

    def http_host
      env_or_default("SKETCHUP_MCP_HTTP_HOST", DEFAULT_HTTP_HOST)
    end

    def http_port
      Integer(env_or_default("SKETCHUP_MCP_HTTP_PORT", DEFAULT_HTTP_PORT.to_s))
    rescue ArgumentError
      DEFAULT_HTTP_PORT
    end

    def endpoint
      return "stdio" if transport == "stdio"

      "http://#{http_host}:#{http_port}/mcp"
    end

    def status_message
      lines = []
      lines << "SketchUp MCP is loaded."
      lines << "Configured transport: #{transport}"
      lines << "Configured endpoint: #{endpoint}"

      if transport == "stdio"
        lines << "Start the FastMCP server from the client or via `uv run sketchup-mcp-server`."
      else
        lines << "Set SKETCHUP_MCP_TRANSPORT=stdio to use a local stdio-launched server."
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
