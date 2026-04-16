# frozen_string_literal: true

require 'json'
require 'stringio'

module SU_MCP
  # Loader for the staged Ruby-native MCP runtime.
  # rubocop:disable Metrics/ClassLength
  class McpRuntimeLoader
    JSON_SCHEMA_SPEC = 'json-schema'
    POST_ACCEPT_TYPES = ['application/json', 'text/event-stream'].freeze
    REQUIRED_GEMS = %w[public_suffix addressable rack mcp json-schema].freeze
    BASE_DIR = begin
      dir = __dir__.dup
      dir.force_encoding('UTF-8') if dir.respond_to?(:force_encoding)
      dir
    end.freeze

    def initialize(vendor_root: default_vendor_root, logger: nil)
      @vendor_root = vendor_root
      @logger = logger
    end

    attr_reader :vendor_root

    def available?
      missing_gems.empty?
    end

    def missing_gems
      REQUIRED_GEMS.reject { |name| Dir.exist?(find_gem_dir(name, raise_on_missing: false).to_s) }
    end

    def load!
      add_lib_path(find_gem_dir('public_suffix'))
      add_lib_path(find_gem_dir('addressable'))
      add_lib_path(find_gem_dir('rack'))
      add_lib_path(find_gem_dir('mcp'))
      json_schema_dir = find_gem_dir(JSON_SCHEMA_SPEC)
      add_lib_path(json_schema_dir)
      register_loaded_spec(JSON_SCHEMA_SPEC, json_schema_dir)

      require 'mcp'
      require 'mcp/server/transports/streamable_http_transport'
    end

    def build_transport(ping_handler:, scene_info_handler:)
      load!

      server = build_server(ping_handler: ping_handler, scene_info_handler: scene_info_handler)
      build_stateless_http_app(server)
    end

    private

    attr_reader :logger

    def build_server(ping_handler:, scene_info_handler:)
      MCP::Server.new(
        name: 'sketchup_mcp_runtime',
        tools: build_tools(ping_handler: ping_handler, scene_info_handler: scene_info_handler),
        configuration: MCP::Configuration.new(
          validate_tool_call_arguments: false,
          exception_reporter: method(:report_exception)
        )
      )
    end

    def build_stateless_http_app(server)
      lambda do |env|
        request_method = env.fetch('REQUEST_METHOD', '')

        case request_method
        when 'POST'
          handle_post(server, env)
        when 'DELETE'
          [200, { 'Content-Type' => 'application/json' }, [JSON.generate(success: true)]]
        else
          [
            405,
            { 'Content-Type' => 'application/json' },
            [JSON.generate(error: 'Method not allowed')]
          ]
        end
      end
    end

    def handle_post(server, env)
      accept_error = validate_accept_header(env.fetch('HTTP_ACCEPT', nil))
      return accept_error if accept_error

      content_type_error = validate_content_type(env.fetch('CONTENT_TYPE', nil))
      return content_type_error if content_type_error

      body = env.fetch('rack.input', StringIO.new('')).read.to_s
      response = server.handle_json(body)

      if response
        [200, { 'Content-Type' => 'application/json' }, [response]]
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
      return nil if media_type == 'application/json'

      [415, { 'Content-Type' => 'application/json' },
       [JSON.generate(error: 'Unsupported Media Type: Content-Type must be application/json')]]
    end

    def not_acceptable_response
      message = "Not Acceptable: Accept header must include #{POST_ACCEPT_TYPES.join(' and ')}"
      [406, { 'Content-Type' => 'application/json' },
       [JSON.generate(error: message)]]
    end

    def default_vendor_root
      [
        File.expand_path('vendor/ruby', BASE_DIR),
        File.expand_path('../../vendor/ruby', BASE_DIR)
      ].find { |path| Dir.exist?(path) } || File.expand_path('vendor/ruby', BASE_DIR)
    end

    # rubocop:disable Metrics/MethodLength
    def build_tools(ping_handler:, scene_info_handler:)
      [
        build_tool(
          name: 'ping',
          description: 'Local SketchUp MCP runtime health check',
          input_schema: runtime_input_schema(
            type: 'object',
            properties: {},
            additionalProperties: false
          ),
          &lambda do |_arguments|
            ping_handler.call
          end
        ),
        build_tool(
          name: 'get_scene_info',
          description: 'Return SketchUp scene information from the active model',
          input_schema: runtime_input_schema(
            type: 'object',
            properties: {
              entity_limit: {
                type: 'integer'
              }
            },
            additionalProperties: true
          ),
          &lambda do |arguments|
            scene_info_handler.call(arguments)
          end
        )
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def build_tool(name:, description:, input_schema:, &handler)
      normalizer = method(:stringify_keys)

      MCP::Tool.define(
        name: name,
        description: description,
        input_schema: input_schema
      ) do |**kwargs|
        arguments = kwargs.dup
        arguments.delete(:server_context)

        result = handler.call(normalizer.call(arguments))
        MCP::Tool::Response.new(
          [{ type: 'text', text: JSON.generate(result) }],
          structured_content: result
        )
      end
    end

    def stringify_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_s] = value
      end
    end

    def runtime_input_schema(schema)
      runtime_input_schema_class.new(schema)
    end

    def runtime_input_schema_class
      @runtime_input_schema_class ||= Class.new(MCP::Tool::InputSchema) do
        private

        def validate_schema!
          nil
        end
      end
    end

    def add_lib_path(gem_dir)
      lib_path = File.join(gem_dir, 'lib')
      $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
    end

    def register_loaded_spec(name, gem_dir)
      Gem.loaded_specs[name] = Struct.new(:full_gem_path).new(gem_dir)
    end

    def report_exception(exception, server_context)
      return unless logger

      request = server_context[:request]
      message = "MCP runtime request error: #{exception.class}: #{exception.message}"
      message += " request=#{JSON.generate(request)}" if request
      logger.call(message)
    rescue StandardError
      nil
    end

    def find_gem_dir(name, raise_on_missing: true)
      matches = Dir.glob(File.join(vendor_root, "#{name}-*")).sort
      if matches.empty?
        return nil unless raise_on_missing

        raise LoadError, "Missing vendored gem for #{name.inspect} under #{vendor_root}"
      end

      matches.last
    end
  end
  # rubocop:enable Metrics/ClassLength
end
