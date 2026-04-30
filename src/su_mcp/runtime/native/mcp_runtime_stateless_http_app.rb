# frozen_string_literal: true

require 'json'
require 'stringio'

module SU_MCP
  # Rack-compatible stateless Streamable HTTP app for the native MCP server.
  class McpRuntimeStatelessHttpApp
    CONTENT_TYPE_HEADER = 'Content-Type'
    JSON_CONTENT_TYPE = 'application/json'
    POST_ACCEPT_TYPES = [JSON_CONTENT_TYPE, 'text/event-stream'].freeze

    def initialize(server)
      @server = server
    end

    def call(env)
      request_method = env.fetch('REQUEST_METHOD', '')

      case request_method
      when 'POST'
        handle_post(env)
      when 'DELETE'
        [200, { CONTENT_TYPE_HEADER => JSON_CONTENT_TYPE }, [JSON.generate(success: true)]]
      else
        [
          405,
          { CONTENT_TYPE_HEADER => JSON_CONTENT_TYPE },
          [JSON.generate(error: 'Method not allowed')]
        ]
      end
    end

    private

    attr_reader :server

    def handle_post(env)
      accept_error = validate_accept_header(env.fetch('HTTP_ACCEPT', nil))
      return accept_error if accept_error

      content_type_error = validate_content_type(env.fetch('CONTENT_TYPE', nil))
      return content_type_error if content_type_error

      body = env.fetch('rack.input', StringIO.new('')).read.to_s
      response = server.handle_json(body)

      if response
        [200, { CONTENT_TYPE_HEADER => JSON_CONTENT_TYPE }, [response]]
      else
        [202, {}, []]
      end
    end

    def validate_accept_header(header)
      return not_acceptable_response unless header

      accepted_types = header.split(',').map { |part| part.split(';').first.strip }
      return nil if accepted_types.include?('*/*')
      return nil if (POST_ACCEPT_TYPES - accepted_types).empty?

      not_acceptable_response
    end

    def validate_content_type(content_type)
      media_type = content_type.to_s.split(';').first.to_s.strip.downcase
      return nil if media_type == JSON_CONTENT_TYPE

      [415, { CONTENT_TYPE_HEADER => JSON_CONTENT_TYPE },
       [JSON.generate(error: "Unsupported Media Type: Content-Type must be #{JSON_CONTENT_TYPE}")]]
    end

    def not_acceptable_response
      message = "Not Acceptable: Accept header must include #{POST_ACCEPT_TYPES.join(' and ')}"
      [406, { CONTENT_TYPE_HEADER => JSON_CONTENT_TYPE },
       [JSON.generate(error: message)]]
    end
  end
end
