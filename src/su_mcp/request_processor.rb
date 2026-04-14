# frozen_string_literal: true

require 'json'

require_relative 'response_helpers'

module SU_MCP
  # Parses raw socket payloads and maps them into JSON-RPC responses.
  class RequestProcessor
    def initialize(request_handler:, logger: nil)
      @request_handler = request_handler
      @logger = logger
    end

    def process(data)
      log("Raw data: #{data.inspect}")
      request = parse_request(data)
      @request_handler.call(request)
    rescue JSON::ParserError => e
      parse_error_response(e, data)
    rescue StandardError => e
      request_error_response(e, request, data)
    end

    private

    def parse_request(data)
      original_id = extract_original_id(data)
      request = JSON.parse(data)
      log("Raw parsed request: #{request.inspect}")
      request['id'] ||= original_id
      log("Processed request: #{request.inspect}")
      request
    end

    def extract_original_id(data)
      match = data.match(/"id":\s*(\d+)/)
      return nil unless match

      match[1].to_i
    end

    def parse_error_response(error, data)
      log("JSON parse error: #{error.message}")
      ResponseHelpers.parse_error(id: extract_original_id(data))
    end

    def request_error_response(error, request, data)
      log("Request error: #{error.message}")
      ResponseHelpers.error(-32_603, error.message,
                            id: request ? request['id'] : extract_original_id(data))
    end

    def log(message)
      @logger&.call(message)
    end
  end
end
