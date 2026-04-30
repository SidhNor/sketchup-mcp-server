# frozen_string_literal: true

require 'json'

require_relative 'mcp_runtime_server_builder'
require_relative 'mcp_runtime_stateless_http_app'
require_relative 'native_tool_catalog'
require_relative 'prompt_catalog'

module SU_MCP
  # Loader for the staged Ruby-native MCP runtime.
  class McpRuntimeLoader
    JSON_SCHEMA_SPEC = 'json-schema'
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

      # Loaded only after vendored runtime paths have been added.
      require 'mcp' # NOSONAR
      require 'mcp/server/transports/streamable_http_transport' # NOSONAR
    end

    def build_transport(handlers: nil, ping_handler: nil, scene_info_handler: nil)
      load!

      server = build_server(
        handlers: handlers || {
          ping: ping_handler,
          get_scene_info: scene_info_handler
        }.compact
      )
      build_stateless_http_app(server)
    end

    def tool_catalog
      @tool_catalog ||= NativeToolCatalog.new.entries
    end

    def prompt_catalog
      @prompt_catalog ||= PromptCatalog.new
    end

    private

    attr_reader :logger

    def build_server(handlers:)
      server_builder.build(handlers: handlers)
    end

    def build_stateless_http_app(server)
      McpRuntimeStatelessHttpApp.new(server)
    end

    def default_vendor_root
      [
        File.expand_path('vendor/ruby', BASE_DIR),
        File.expand_path('../../vendor/ruby', BASE_DIR)
      ].find { |path| Dir.exist?(path) } || File.expand_path('vendor/ruby', BASE_DIR)
    end

    def build_tools(handler_map)
      server_builder.send(:build_tools, handler_map)
    end

    def build_prompts
      server_builder.send(:build_prompts)
    end

    def build_prompt(entry)
      server_builder.send(:build_prompt, entry)
    end

    def build_prompt_message(message)
      server_builder.send(:build_prompt_message, message)
    end

    def build_tool(
      name:,
      title:,
      description:,
      annotations:,
      input_schema:,
      classification:,
      &handler
    )
      server_builder.build_tool(
        name: name,
        title: title,
        description: description,
        annotations: annotations,
        input_schema: input_schema,
        classification: classification,
        &handler
      )
    end

    def stringify_keys(value)
      server_builder.stringify_keys(value)
    end

    def build_tool_handler(handler_key, handler_map)
      server_builder.build_tool_handler(handler_key, handler_map)
    end

    def invoke_tool_handler(handler, arguments, tool_name:, classification:)
      server_builder.send(
        :invoke_tool_handler,
        handler,
        arguments,
        tool_name: tool_name,
        classification: classification
      )
    end

    def normalize_tool_result(result, classification:)
      server_builder.send(:normalize_tool_result, result, classification: classification)
    end

    def translate_tool_failure(exception, tool_name:)
      server_builder.translate_tool_failure(exception, tool_name: tool_name)
    end

    def runtime_input_schema(schema)
      server_builder.send(:runtime_input_schema, schema)
    end

    def runtime_input_schema_class
      server_builder.send(:runtime_input_schema_class)
    end

    def server_builder
      @server_builder ||= McpRuntimeServerBuilder.new(
        tool_catalog: tool_catalog,
        prompt_catalog: prompt_catalog,
        exception_reporter: method(:report_exception)
      )
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
end
