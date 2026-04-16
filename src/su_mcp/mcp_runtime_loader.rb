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
      @tool_catalog ||= (
        primary_tool_catalog +
        scene_tool_catalog +
        mutation_tool_catalog +
        joinery_tool_catalog +
        developer_tool_catalog
      ).freeze
    end

    private

    attr_reader :logger

    def build_server(handlers:)
      MCP::Server.new(
        name: 'sketchup_mcp_runtime',
        tools: build_tools(handlers),
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

    def build_tools(handler_map)
      tool_catalog.map do |entry|
        build_tool(
          name: entry.fetch(:name),
          title: entry.dig(:metadata, :title),
          description: entry.fetch(:description),
          annotations: entry.dig(:metadata, :annotations),
          input_schema: runtime_input_schema(entry.fetch(:input_schema)),
          &build_tool_handler(entry.fetch(:handler_key), handler_map)
        )
      end
    end

    # rubocop:disable Metrics/MethodLength
    def build_tool(name:, title:, description:, annotations:, input_schema:, &handler)
      normalizer = method(:stringify_keys)

      MCP::Tool.define(
        name: name,
        title: title,
        description: description,
        annotations: annotations,
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
    # rubocop:enable Metrics/MethodLength

    def stringify_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_s] = value
      end
    end

    def build_tool_handler(handler_key, handler_map)
      lambda do |arguments|
        handler = handler_map.fetch(handler_key) do
          raise NotImplementedError, "No native runtime handler registered for #{handler_key}"
        end

        if arguments.empty?
          handler.call
        else
          handler.call(arguments)
        end
      end
    end

    # rubocop:disable Metrics/MethodLength
    def primary_tool_catalog
      [
        tool_entry(
          name: 'ping',
          description: 'Local SketchUp MCP runtime health check',
          handler_key: :ping,
          input_schema: {
            type: 'object',
            properties: {},
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'get_scene_info',
          description: 'Return SketchUp scene information from the active model',
          handler_key: :get_scene_info,
          input_schema: {
            type: 'object',
            properties: {
              entity_limit: { type: 'integer' }
            },
            additionalProperties: true
          }
        ),
        tool_entry(
          name: 'list_entities',
          description: 'List top-level SketchUp model entities.',
          handler_key: :list_entities,
          input_schema: {
            type: 'object',
            properties: {
              limit: { type: 'integer' },
              include_hidden: { type: 'boolean' }
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'find_entities',
          description: 'Find scene entities using supported targeting fields.',
          handler_key: :find_entities,
          metadata: {
            title: 'Find Scene Entities',
            annotations: { read_only_hint: true, destructive_hint: false }
          },
          input_schema: {
            type: 'object',
            required: ['query'],
            properties: {
              query: {
                type: 'object',
                properties: {
                  sourceElementId: { type: 'string' },
                  persistentId: { type: 'string' },
                  entityId: { type: 'string' },
                  name: { type: 'string' },
                  tag: { type: 'string' },
                  material: { type: 'string' }
                },
                additionalProperties: false
              }
            },
            additionalProperties: false
          }
        )
      ]
    end

    def scene_tool_catalog
      [
        tool_entry(
          name: 'sample_surface_z',
          description: 'Sample target surface elevation.',
          handler_key: :sample_surface_z,
          metadata: {
            title: 'Sample Target Surface Elevation',
            annotations: { read_only_hint: true, destructive_hint: false }
          },
          input_schema: {
            type: 'object',
            required: %w[target samplePoints],
            properties: {
              target: target_reference_schema,
              samplePoints: sample_points_schema,
              ignoreTargets: {
                type: 'array',
                items: target_reference_schema
              },
              visibleOnly: { type: 'boolean' }
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'get_entity_info',
          description: 'Get structured information for a specific entity.',
          handler_key: :get_entity_info,
          metadata: {
            title: 'Get Entity Information',
            annotations: { read_only_hint: true, destructive_hint: false }
          },
          input_schema: {
            type: 'object',
            required: ['id'],
            properties: {
              id: { type: 'string' }
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'create_site_element',
          description: 'Create a managed semantic site element.',
          handler_key: :create_site_element
        ),
        tool_entry(
          name: 'set_entity_metadata',
          description: 'Update semantic metadata on a managed object.',
          handler_key: :set_entity_metadata
        )
      ]
    end

    def mutation_tool_catalog
      [
        tool_entry(
          name: 'create_component',
          description: 'Create a new component in SketchUp.',
          handler_key: :create_component,
          metadata: {
            annotations: { read_only_hint: false, destructive_hint: false }
          },
          input_schema: {
            type: 'object',
            properties: {
              type: { type: 'string' },
              position: { type: 'array' },
              dimensions: { type: 'array' }
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'delete_component',
          description: 'Delete a component by ID.',
          handler_key: :delete_component
        ),
        tool_entry(
          name: 'transform_component',
          description: 'Transform a component.',
          handler_key: :transform_component
        ),
        tool_entry(
          name: 'get_selection',
          description: 'Get detailed information about the current selection.',
          handler_key: :get_selection
        ),
        tool_entry(
          name: 'set_material',
          description: 'Set the material for an entity.',
          handler_key: :set_material
        ),
        tool_entry(
          name: 'export_scene',
          description: 'Export the current SketchUp scene.',
          handler_key: :export_scene
        ),
        tool_entry(
          name: 'boolean_operation',
          description: 'Run a boolean operation between entities.',
          handler_key: :boolean_operation
        ),
        tool_entry(
          name: 'chamfer_edges',
          description: 'Create a chamfer on selected edges.',
          handler_key: :chamfer_edges
        ),
        tool_entry(
          name: 'fillet_edges',
          description: 'Create a fillet on selected edges.',
          handler_key: :fillet_edges
        )
      ]
    end

    def joinery_tool_catalog
      [
        tool_entry(
          name: 'create_mortise_tenon',
          description: 'Create a mortise and tenon joint.',
          handler_key: :create_mortise_tenon
        ),
        tool_entry(
          name: 'create_dovetail',
          description: 'Create a dovetail joint.',
          handler_key: :create_dovetail
        ),
        tool_entry(
          name: 'create_finger_joint',
          description: 'Create a finger joint.',
          handler_key: :create_finger_joint
        )
      ]
    end

    def developer_tool_catalog
      [
        tool_entry(
          name: 'eval_ruby',
          description: 'Evaluate arbitrary Ruby code inside SketchUp.',
          handler_key: :eval_ruby
        )
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def tool_entry(
      name:,
      description:,
      handler_key:,
      input_schema: default_object_schema,
      metadata: {}
    )
      {
        name: name,
        description: description,
        handler_key: handler_key,
        input_schema: input_schema,
        metadata: {
          title: metadata[:title],
          annotations: {
            read_only_hint: metadata.dig(:annotations, :read_only_hint) || false,
            destructive_hint: metadata.dig(:annotations, :destructive_hint) || false
          }
        }
      }
    end

    def default_object_schema
      {
        type: 'object',
        properties: {},
        additionalProperties: true
      }
    end

    def target_reference_schema
      {
        type: 'object',
        properties: {
          sourceElementId: { type: 'string' },
          persistentId: { type: 'string' },
          entityId: { type: 'string' }
        },
        additionalProperties: false
      }
    end

    def sample_points_schema
      {
        type: 'array',
        items: {
          type: 'object',
          required: %w[x y],
          properties: {
            x: { type: 'number' },
            y: { type: 'number' }
          },
          additionalProperties: false
        }
      }
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
