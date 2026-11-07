# frozen_string_literal: true

module SU_MCP
  # SketchUp application observer that closes the MCP runtime during host shutdown.
  class McpRuntimeLifecycleObserver < Sketchup::AppObserver
    QUIT_REASON = 'SketchUp quit'

    def initialize(extension_name:, shutdown_callback:, logger:)
      super()
      @extension_name = extension_name
      @shutdown_callback = shutdown_callback
      @logger = logger
    end

    # rubocop:disable Naming/MethodName
    def onQuit
      shutdown(QUIT_REASON)
    end

    def onUnloadExtension(extension_name)
      return unless extension_name == @extension_name

      shutdown('extension unload')
    end
    # rubocop:enable Naming/MethodName

    private

    def shutdown(reason)
      @shutdown_callback.call(reason)
    rescue StandardError => e
      @logger.call("MCP runtime shutdown failed during #{reason}: #{e.message}")
    end
  end
end
