# frozen_string_literal: true

require 'json'
require_relative '../runtime_logger'

module SU_MCP
  # Records transport completion without retaining tool arguments or results.
  #
  # Parses the request body once and dispatches parsed requests through the
  # server's hash API, so logging can inspect results without re-parsing
  # response JSON. Batch and parse-error behavior mirrors JsonRpcHandler.
  class McpRuntimeRequestLogging
    def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @clock = clock
    end

    # Returns the JSON-RPC response as a JSON string, or nil for notifications.
    def call(body, server)
      request = parse(body)
      return server.handle_json(body) if request.equal?(UNPARSEABLE)

      response = if batch?(request)
                   hoist(request.filter_map { |item| dispatch(item, server) })
                 else
                   dispatch(request, server)
                 end
      response&.to_json
    end

    private

    UNPARSEABLE = Object.new.freeze
    private_constant :UNPARSEABLE

    def parse(body)
      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError
      UNPARSEABLE
    end

    def batch?(request)
      request.is_a?(Array) && !request.empty? && request.all?(Hash)
    end

    # Matches the pinned SDK: one response is hoisted, none yields nil.
    def hoist(responses)
      return responses.first if responses.one?

      responses if responses.any?
    end

    def dispatch(request, server)
      started = @clock.call
      response = server.handle(request)
      record(request, response, started)
      response
    end

    def record(request, response, started)
      return unless request.is_a?(Hash) && request[:method] == 'tools/call'

      outcome = tool_outcome(response)
      RuntimeLogger.emit(
        'Tool request completed',
        level: outcome == 'failed' ? :error : severity(outcome),
        component: 'tools', event: 'tool.completed', tool: field(request[:params], :name),
        request_id: request[:id], outcome: outcome,
        duration_ms: ((@clock.call - started) * 1000).round(3)
      )
    rescue StandardError
      nil
    end

    def tool_outcome(response)
      return 'succeeded' unless response.is_a?(Hash)

      result = field(response, :result)
      content = field(result, :structuredContent)
      failed = field(response, :error) || field(result, :isError)
      return 'failed' if failed || field(content, :success) == false
      return 'refused' if field(content, :outcome) == 'refused'

      'succeeded'
    end

    # Tool results may carry string or symbol keys depending on the handler.
    def field(hash, key)
      return nil unless hash.is_a?(Hash)

      hash.key?(key) ? hash[key] : hash[key.to_s]
    end

    def severity(outcome)
      outcome == 'refused' ? :warn : :info
    end
  end
end
