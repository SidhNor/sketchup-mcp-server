# frozen_string_literal: true

module SU_MCP
  # Coordinates the Ruby-native MCP runtime lifecycle.
  class McpRuntimeServer
    def initialize(config:, runtime_loader:, backend:, facade:, logger:)
      @config = config
      @runtime_loader = runtime_loader
      @backend = backend
      @facade = facade
      @logger = logger
      @running = false
    end

    def start
      return if running?

      runtime_loader.load!
      backend.start(host: config.host, port: config.port, handlers: handler_map)
      @running = true
    rescue StandardError, LoadError => e
      @running = false
      logger.call("MCP runtime failed to start: #{e.message}")
      raise
    end

    def stop
      backend.stop
      @running = false
    end

    def running?
      @running
    end

    def status
      {
        host: config.host,
        port: config.port,
        running: running?,
        available: runtime_loader.available?,
        missing_gems: runtime_loader.missing_gems,
        vendor_root: runtime_loader.vendor_root
      }
    end

    private

    attr_reader :config, :runtime_loader, :backend, :facade, :logger

    def handler_map
      handler_keys.each_with_object({}) do |handler_key, handlers|
        next unless facade.respond_to?(handler_key)

        handlers[handler_key] = facade.method(handler_key)
      end
    end

    def handler_keys
      if runtime_loader.respond_to?(:tool_catalog)
        return runtime_loader.tool_catalog.map { |entry| entry.fetch(:handler_key) }.uniq
      end

      facade.public_methods(false)
    end
  end
end
