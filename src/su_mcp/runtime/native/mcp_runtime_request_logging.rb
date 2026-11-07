# frozen_string_literal: true

require 'json'
require 'time'
require_relative '../runtime_logger'
require_relative '../token_estimate'
require_relative '../usage_log'

module SU_MCP
  # Records transport completion without retaining tool arguments or results.
  #
  # Parses the request body once and dispatches parsed requests through the
  # server's hash API, so logging can inspect results without re-parsing
  # response JSON. Batch and parse-error behavior mirrors JsonRpcHandler.
  #
  # Each record goes to the Ruby Console and, when enabled, to the usage log.
  # In stateless HTTP mode `initialize` is the only session boundary, so it is
  # recorded with the client name for offline session analysis.
  class McpRuntimeRequestLogging
    def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
                   usage_log: UsageLog.new)
      @clock = clock
      @usage_log = usage_log
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
      return unless request.is_a?(Hash)

      case request[:method]
      when 'tools/call' then record_tool_call(request, response, started)
      when 'initialize' then record_client(request)
      end
    rescue StandardError
      nil
    end

    def record_tool_call(request, response, started)
      outcome = tool_outcome(response)
      result_chars = response_chars(response)
      context = {
        tool: field(request[:params], :name), request_id: request[:id], outcome: outcome,
        duration_ms: ((@clock.call - started) * 1000).round(3),
        response_chars: result_chars,
        request_tokens_est: TokenEstimate.from_chars(arguments_chars(request)),
        response_tokens_est: TokenEstimate.from_chars(result_chars)
      }.compact
      RuntimeLogger.emit(
        'Tool request completed',
        level: outcome == 'failed' ? :error : severity(outcome),
        component: 'tools', event: 'tool.completed', **context
      )
      append_usage('tool.completed', context)
    end

    def record_client(request)
      context = { client: client_label(field(request[:params], :clientInfo)) }.compact
      RuntimeLogger.emit(
        'MCP client initialized', component: 'transport', event: 'client.initialized', **context
      )
      append_usage('client.initialized', context)
    end

    def append_usage(event, context)
      @usage_log.append({ timestamp: Time.now.utc.iso8601(3), event: event }.merge(context))
    end

    # Size of the text block the client receives; the server builder always
    # puts the serialized result first, so no extra serialization is needed.
    def response_chars(response)
      content = field(field(response, :result), :content)
      text = field(content.first, :text) if content.is_a?(Array)
      text.length if text.is_a?(String)
    end

    # Size of the arguments the model wrote; only the length is kept.
    def arguments_chars(request)
      arguments = field(request[:params], :arguments)
      JSON.generate(arguments).length if arguments.is_a?(Hash)
    end

    def client_label(client_info)
      name = field(client_info, :name)
      return nil unless name.is_a?(String) && !name.empty?

      version = field(client_info, :version)
      version.is_a?(String) && !version.empty? ? "#{name}/#{version}" : name
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
