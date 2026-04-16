# frozen_string_literal: true

module SU_MCP
  # Shared developer-oriented commands used by both runtime paths.
  class DeveloperCommands
    def initialize(logger: nil, binding_provider: -> { TOPLEVEL_BINDING.dup })
      @logger = logger
      @binding_provider = binding_provider
    end

    def eval_ruby(params)
      code = params.fetch('code')
      log "Evaluating Ruby code with length: #{code.length}"
      result = eval(code, binding_provider.call) # rubocop:disable Security/Eval
      log "Code evaluation completed with result: #{result.inspect}"

      {
        success: true,
        result: result.to_s
      }
    rescue StandardError => e
      log "Error in eval_ruby: #{e.message}"
      log e.backtrace.join("\n")
      raise "Ruby evaluation error: #{e.message}"
    end

    private

    attr_reader :logger, :binding_provider

    def log(message)
      logger&.call(message)
    end
  end
end
