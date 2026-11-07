# frozen_string_literal: true

require_relative '../runtime_logger'

module SU_MCP
  # Records transport completion without retaining tool arguments or results.
  class McpRuntimeRequestLogging
    def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @clock = clock
    end

    def call(body, &dispatch)
      requests = batch_requests(body)
      return log_single(body, &dispatch) unless requests

      responses = requests.filter_map do |request|
        log_single(JSON.generate(request), &dispatch)
      end
      # Preserve the pinned SDK's single-response hoisting and notification behavior.
      return responses.first if responses.one?

      JSON.generate(responses.map { |response| JSON.parse(response) }) unless responses.empty?
    end

    private

    def batch_requests(body)
      request = JSON.parse(body)
      request if request.is_a?(Array) && !request.empty? && request.all?(Hash)
    rescue JSON::ParserError
      nil
    end

    def log_single(body)
      started = @clock.call
      response = yield(body)
      record(body, response, started)
      response
    end

    def record(body, response, started)
      request = JSON.parse(body)
      result = response && JSON.parse(response)
      return unless request.is_a?(Hash) && request['method'] == 'tools/call'

      failed = result.is_a?(Hash) && (result.key?('error') || result.dig('result', 'isError'))
      content = result.is_a?(Hash) && result.dig('result', 'structuredContent')
      outcome = tool_outcome(content, failed)
      RuntimeLogger.emit(
        'Tool request completed',
        level: outcome == 'failed' ? :error : severity(outcome),
        component: 'tools', event: 'tool.completed', tool: request.dig('params', 'name'),
        request_id: request['id'], outcome: outcome,
        duration_ms: ((@clock.call - started) * 1000).round(3)
      )
    rescue StandardError
      nil
    end

    def tool_outcome(content, failed)
      return 'failed' if failed || (content.is_a?(Hash) && content['success'] == false)
      return 'refused' if content.is_a?(Hash) && content['outcome'] == 'refused'

      'succeeded'
    end

    def severity(outcome)
      outcome == 'refused' ? :warn : :info
    end
  end
end
