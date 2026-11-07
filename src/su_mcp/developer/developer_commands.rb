# frozen_string_literal: true

module SU_MCP
  # Shared developer-oriented commands used by both runtime paths.
  class DeveloperCommands
    # Ruby Console writes are slow for large text, so logs carry only a preview.
    LOG_PREVIEW_CHARS = 200
    LOG_BACKTRACE_LINES = 10

    def initialize(logger: nil, binding_provider: -> { TOPLEVEL_BINDING.dup })
      @logger = logger
      @binding_provider = binding_provider
    end

    def eval_ruby(params)
      code = params.fetch('code')
      log "Evaluating Ruby code with length: #{code.length}"
      result = eval(code, binding_provider.call) # rubocop:disable Security/Eval
      text = result.to_s
      log "Code evaluation completed with #{result.class} result " \
          "(#{text.length} chars): #{preview(text)}"

      {
        success: true,
        result: text
      }
    # SyntaxError is a ScriptError, so malformed input needs an explicit rescue.
    rescue StandardError, SyntaxError => e
      log "Error in eval_ruby: #{preview(e.message)}"
      log Array(e.backtrace).first(LOG_BACKTRACE_LINES).join("\n")
      raise "Ruby evaluation error: #{e.message}"
    end

    private

    attr_reader :logger, :binding_provider

    def log(message)
      logger&.call(message)
    end

    def preview(text)
      return text.inspect if text.length <= LOG_PREVIEW_CHARS

      "#{text[0, LOG_PREVIEW_CHARS].inspect}... (truncated)"
    end
  end
end
