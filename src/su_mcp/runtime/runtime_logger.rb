# frozen_string_literal: true

require 'json'
require 'time'

module SU_MCP
  # Shared logging and console filters for the SketchUp-hosted Ruby runtime.
  module RuntimeLogger
    LEVELS = { debug: 0, info: 1, warn: 2, error: 3 }.freeze
    CONTEXT_KEYS = %i[tool request_id duration_ms outcome].freeze

    module_function

    def configure(min_level: :info, components: nil, tools: nil, request_ids: nil,
                  since: nil, until_time: nil)
      LEVELS.fetch(min_level)
      @filters = {
        min_level: min_level, components: components, tools: tools, request_ids: request_ids,
        since: since, until_time: until_time
      }.freeze
    end

    def main(message, **options)
      emit(message, **options)
    end

    def emit(message, level: :info, component: 'runtime', event: 'message', output: $stdout,
             **context)
      timestamp = Time.now.utc
      record = {
        timestamp: timestamp.iso8601(3), level: level.to_s, component: component.to_s,
        event: event.to_s, message: message.to_s
      }.merge(context.slice(*CONTEXT_KEYS))
      return unless visible?(record, level, timestamp)

      output.write("SketchUp MCP: #{JSON.generate(record)}\n")
      output.flush if output.respond_to?(:flush)
      record
    rescue StandardError
      # Logging must not interrupt a SketchUp command, even when its output fails.
      nil
    end

    def visible?(record, level, timestamp)
      filters = @filters || { min_level: :info }
      return false if LEVELS.fetch(level) < LEVELS.fetch(filters.fetch(:min_level))
      return false if filters[:since] && timestamp < filters[:since]
      return false if filters[:until_time] && timestamp > filters[:until_time]

      { components: :component, tools: :tool, request_ids: :request_id }.all? do |filter, key|
        values = filters[filter]
        values.nil? || Array(values).map(&:to_s).include?(record[key].to_s)
      end
    end
    private_class_method :visible?
  end
end
