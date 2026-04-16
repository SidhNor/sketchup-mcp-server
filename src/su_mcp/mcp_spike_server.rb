# frozen_string_literal: true

module SU_MCP
  # Coordinates the experimental local-developer MCP spike runtime lifecycle.
  class McpSpikeServer
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
      logger.call("MCP spike failed to start: #{e.message}")
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
      {}.tap do |handlers|
        handlers[:ping] = facade.method(:ping) if facade.respond_to?(:ping)
        if facade.respond_to?(:get_scene_info)
          handlers[:get_scene_info] = facade.method(:get_scene_info)
        end
      end
    end
  end
end
