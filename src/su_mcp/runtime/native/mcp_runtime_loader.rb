# frozen_string_literal: true

require 'json'
require 'stringio'

require_relative 'tool_definition'

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
          classification: entry.fetch(:classification),
          &build_tool_handler(entry.fetch(:handler_key), handler_map)
        )
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
    def build_tool(
      name:,
      title:,
      description:,
      annotations:,
      input_schema:,
      classification:,
      &handler
    )
      normalizer = method(:stringify_keys)
      invoker = method(:invoke_tool_handler)

      MCP::Tool.define(
        name: name,
        title: title,
        description: description,
        annotations: annotations,
        input_schema: input_schema
      ) do |**kwargs|
        arguments = kwargs.dup
        arguments.delete(:server_context)

        result = invoker.call(
          handler,
          normalizer.call(arguments),
          tool_name: name,
          classification: classification
        )
        MCP::Tool::Response.new(
          [{ type: 'text', text: JSON.generate(result) }],
          structured_content: result
        )
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists

    def stringify_keys(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, nested_value), result|
          result[key.to_s] = stringify_keys(nested_value)
        end
      when Array
        value.map { |item| stringify_keys(item) }
      else
        value
      end
    end

    def build_tool_handler(handler_key, handler_map)
      lambda do |arguments|
        handler = handler_map.fetch(handler_key) do
          raise "No native runtime handler registered for #{handler_key}"
        end

        if arguments.empty?
          handler.call
        else
          handler.call(arguments)
        end
      end
    end

    def invoke_tool_handler(handler, arguments, tool_name:, classification:)
      result = handler.call(arguments)
      normalize_tool_result(result, classification: classification)
    rescue StandardError => e
      translated_error = translate_tool_failure(e, tool_name: tool_name)
      translated_error.set_backtrace(e.backtrace)
      raise translated_error
    end

    def normalize_tool_result(result, classification:)
      return result if classification == 'escape_hatch'

      result
    end

    # rubocop:disable Metrics/MethodLength
    def primary_tool_catalog
      [
        tool_entry(
          name: 'ping',
          title: 'Runtime Health Check',
          description: 'Local SketchUp MCP runtime health check',
          handler_key: :ping,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            properties: {},
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'get_scene_info',
          title: 'Get Scene Summary',
          description: 'Get a structured summary of the current SketchUp scene for broad ' \
                       'grounding before more targeted inspection tools are used.',
          handler_key: :get_scene_info,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            properties: {
              entity_limit: integer_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'list_entities',
          title: 'List Entities In Scope',
          description: 'Inventory entities within a known scope such as the current ' \
                       'selection, top-level model context, or children of an explicit ' \
                       'target. This tool is for scoped inventory, not predicate search.',
          handler_key: :list_entities,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: ['scopeSelector'],
            properties: {
              scopeSelector: scope_selector_schema,
              outputOptions: list_entities_output_options_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'find_entities',
          title: 'Find Target Entities',
          description: 'Resolve entities by exact-match identity, attributes, or supported ' \
                       'metadata predicates. This tool is for predicate targeting, not ' \
                       'scoped inventory.',
          handler_key: :find_entities,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: ['targetSelector'],
            properties: {
              targetSelector: target_selector_schema
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
          title: 'Sample Target Surface Elevation',
          description: 'Sample world-space surface elevation from an explicit target at ' \
                       'one or more XY points in meters. Callers must provide the target ' \
                       'and sample points; this is not broad scene discovery.',
          handler_key: :sample_surface_z,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
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
              visibleOnly: boolean_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'get_entity_info',
          title: 'Get Entity Information',
          description: 'Get structured information for a specific SketchUp entity by id.',
          handler_key: :get_entity_info,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: ['id'],
            properties: {
              id: string_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'create_site_element',
          title: 'Create Semantic Site Element',
          description: 'Create a managed semantic site element in SketchUp. Current support ' \
                       'is limited to structure, pad, path, retaining_edge, ' \
                       'planting_mass, and tree_proxy creation.',
          handler_key: :create_site_element,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: create_site_element_schema
        ),
        tool_entry(
          name: 'set_entity_metadata',
          title: 'Set Entity Metadata',
          description: 'Update semantic metadata on an existing managed object in ' \
                       'SketchUp. Current support is limited to status updates for ' \
                       'managed objects and structureCategory updates for managed ' \
                       'structure objects.',
          handler_key: :set_entity_metadata,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: set_entity_metadata_schema
        ),
        tool_entry(
          name: 'create_group',
          title: 'Create Group Container',
          description: 'Create a group container for semantic hierarchy-maintenance ' \
                       'work. Optionally relocate supported child groups or components ' \
                       'into the new container.',
          handler_key: :create_group,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: create_group_schema
        ),
        tool_entry(
          name: 'reparent_entities',
          title: 'Reparent Supported Entities',
          description: 'Reparent supported group or component entities under an explicit ' \
                       'parent group or to model root as a narrow hierarchy-maintenance ' \
                       'operation.',
          handler_key: :reparent_entities,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: reparent_entities_schema
        )
      ]
    end

    def mutation_tool_catalog
      [
        tool_entry(
          name: 'delete_entities',
          title: 'Delete Supported Entities',
          description: 'Delete one supported group or component instance resolved from an ' \
                       'explicit target reference. This tool is for explicit single-target ' \
                       'deletion, not broad search or batch cleanup.',
          handler_key: :delete_entities,
          annotations: { read_only_hint: false, destructive_hint: true },
          classification: 'first_class',
          input_schema: delete_entities_schema
        ),
        tool_entry(
          name: 'transform_entities',
          title: 'Transform Entities',
          description: "Transform a supported entity's position, rotation, or scale.",
          handler_key: :transform_entities,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: ['id'],
            properties: {
              id: string_schema,
              position: numeric_array_schema,
              rotation: numeric_array_schema,
              scale: numeric_array_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'get_selection',
          title: 'Get Selection Details',
          description: 'Get detailed information about the current selection.',
          handler_key: :get_selection,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            properties: {},
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'set_material',
          title: 'Set Entity Material',
          description: 'Set the material for a SketchUp entity.',
          handler_key: :set_material,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: %w[id material],
            properties: {
              id: string_schema,
              material: string_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'boolean_operation',
          title: 'Run Boolean Operation',
          description: 'Run a boolean operation between two SketchUp groups/components.',
          handler_key: :boolean_operation,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: %w[target_id tool_id operation],
            properties: {
              target_id: string_schema,
              tool_id: string_schema,
              operation: string_schema,
              delete_originals: boolean_schema
            },
            additionalProperties: false
          }
        )
      ]
    end

    def developer_tool_catalog
      [
        tool_entry(
          name: 'eval_ruby',
          title: 'Evaluate Ruby',
          description: 'Evaluate arbitrary Ruby code inside SketchUp.',
          handler_key: :eval_ruby,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'escape_hatch',
          input_schema: {
            type: 'object',
            required: ['code'],
            properties: {
              code: string_schema
            },
            additionalProperties: false
          }
        )
      ]
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/ParameterLists
    def tool_entry(
      name:,
      title:,
      description:,
      annotations:,
      handler_key:,
      classification:,
      input_schema: default_object_schema
    )
      NativeToolDefinition.build(
        name: name,
        title: title,
        description: description,
        annotations: annotations,
        handler_key: handler_key,
        input_schema: input_schema,
        classification: classification
      )
    end
    # rubocop:enable Metrics/ParameterLists

    def translate_tool_failure(exception, tool_name:)
      RuntimeError.new("Native MCP tool #{tool_name} failed: #{exception.message}")
    end

    def default_object_schema
      {
        type: 'object',
        properties: {},
        additionalProperties: true
      }
    end

    def string_schema
      { type: 'string' }
    end

    def boolean_schema
      { type: 'boolean' }
    end

    def integer_schema
      { type: 'integer' }
    end

    def number_schema
      { type: 'number' }
    end

    def numeric_array_schema
      {
        type: 'array',
        items: number_schema
      }
    end

    def integer_array_schema
      {
        type: 'array',
        items: integer_schema
      }
    end

    def string_array_schema
      {
        type: 'array',
        items: string_schema
      }
    end

    def identifier_object_schema(identifier_name)
      {
        type: 'object',
        required: [identifier_name],
        properties: {
          identifier_name.to_sym => string_schema
        },
        additionalProperties: false
      }
    end

    def target_reference_schema
      {
        type: 'object',
        properties: {
          sourceElementId: string_schema,
          persistentId: string_schema,
          entityId: string_schema
        },
        additionalProperties: false
      }
    end

    def enum_schema(*values)
      {
        type: 'string',
        enum: values.flatten
      }
    end

    def scope_selector_schema
      {
        type: 'object',
        required: ['mode'],
        properties: {
          mode: enum_schema('top_level', 'selection', 'children_of_target'),
          targetReference: target_reference_schema
        },
        additionalProperties: false
      }
    end

    def list_entities_output_options_schema
      {
        type: 'object',
        properties: {
          limit: integer_schema,
          includeHidden: boolean_schema
        },
        additionalProperties: false
      }
    end

    def identity_selector_schema
      {
        type: 'object',
        properties: {
          sourceElementId: string_schema,
          persistentId: string_schema,
          entityId: string_schema
        },
        additionalProperties: false
      }
    end

    def attribute_selector_schema
      {
        type: 'object',
        properties: {
          name: string_schema,
          tag: string_schema,
          material: string_schema
        },
        additionalProperties: false
      }
    end

    def metadata_selector_schema
      {
        type: 'object',
        properties: {
          managedSceneObject: boolean_schema,
          semanticType: string_schema,
          status: string_schema,
          state: string_schema,
          structureCategory: string_schema
        },
        additionalProperties: false
      }
    end

    def target_selector_schema
      {
        type: 'object',
        properties: {
          identity: identity_selector_schema,
          attributes: attribute_selector_schema,
          metadata: metadata_selector_schema
        },
        additionalProperties: false
      }
    end

    def delete_entities_constraints_schema
      {
        type: 'object',
        properties: {
          ambiguityPolicy: enum_schema('fail')
        },
        additionalProperties: false
      }
    end

    def delete_entities_output_options_schema
      {
        type: 'object',
        properties: {
          responseFormat: enum_schema('concise')
        },
        additionalProperties: false
      }
    end

    def delete_entities_schema
      {
        type: 'object',
        required: ['targetReference'],
        properties: {
          targetReference: target_reference_schema,
          constraints: delete_entities_constraints_schema,
          outputOptions: delete_entities_output_options_schema
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
            x: number_schema,
            y: number_schema
          },
          additionalProperties: false
        }
      }
    end

    def xy_point_array_schema
      {
        type: 'array',
        items: numeric_array_schema
      }
    end

    def path_payload_schema
      {
        type: 'object',
        required: %w[centerline width],
        properties: {
          centerline: xy_point_array_schema,
          width: number_schema,
          elevation: number_schema,
          thickness: number_schema
        },
        additionalProperties: false
      }
    end

    def retaining_edge_payload_schema
      {
        type: 'object',
        required: %w[polyline height thickness],
        properties: {
          polyline: xy_point_array_schema,
          height: number_schema,
          thickness: number_schema,
          elevation: number_schema
        },
        additionalProperties: false
      }
    end

    def planting_mass_payload_schema
      {
        type: 'object',
        required: %w[boundary averageHeight],
        properties: {
          boundary: xy_point_array_schema,
          averageHeight: number_schema,
          plantingCategory: string_schema,
          elevation: number_schema
        },
        additionalProperties: false
      }
    end

    # rubocop:disable Metrics/MethodLength
    def tree_proxy_payload_schema
      {
        type: 'object',
        required: %w[position canopyDiameterX height trunkDiameter],
        properties: {
          position: {
            type: 'object',
            required: %w[x y],
            properties: {
              x: number_schema,
              y: number_schema,
              z: number_schema
            },
            additionalProperties: false
          },
          canopyDiameterX: number_schema,
          canopyDiameterY: number_schema,
          height: number_schema,
          trunkDiameter: number_schema,
          speciesHint: string_schema
        },
        additionalProperties: false
      }
    end

    # rubocop:disable Metrics/AbcSize
    def create_site_element_schema
      {
        type: 'object',
        required: %w[elementType metadata definition hosting placement representation lifecycle],
        properties: {
          elementType: string_schema,
          metadata: {
            type: 'object',
            properties: {
              sourceElementId: string_schema,
              status: string_schema
            },
            additionalProperties: false
          },
          sceneProperties: {
            type: 'object',
            properties: {
              name: string_schema,
              tag: string_schema
            },
            additionalProperties: false
          },
          definition: {
            type: 'object',
            properties: {
              mode: string_schema,
              footprint: xy_point_array_schema,
              elevation: number_schema,
              height: number_schema,
              thickness: number_schema,
              structureCategory: string_schema,
              centerline: xy_point_array_schema,
              width: number_schema,
              polyline: xy_point_array_schema,
              boundary: xy_point_array_schema,
              averageHeight: number_schema,
              plantingCategory: string_schema,
              position: {
                type: 'object',
                required: %w[x y],
                properties: {
                  x: number_schema,
                  y: number_schema,
                  z: number_schema
                },
                additionalProperties: false
              },
              canopyDiameterX: number_schema,
              canopyDiameterY: number_schema,
              trunkDiameter: number_schema,
              speciesHint: string_schema
            },
            additionalProperties: false
          },
          hosting: {
            type: 'object',
            properties: {
              mode: string_schema,
              target: target_reference_schema
            },
            additionalProperties: false
          },
          placement: {
            type: 'object',
            properties: {
              mode: string_schema,
              parent: target_reference_schema
            },
            additionalProperties: false
          },
          representation: {
            type: 'object',
            properties: {
              mode: string_schema,
              material: string_schema
            },
            additionalProperties: false
          },
          lifecycle: {
            type: 'object',
            properties: {
              mode: string_schema,
              target: target_reference_schema
            },
            additionalProperties: false
          }
        },
        additionalProperties: false
      }
    end
    # rubocop:enable Metrics/AbcSize

    def set_entity_metadata_schema
      {
        type: 'object',
        required: ['target'],
        properties: {
          target: target_reference_schema,
          set: {
            type: 'object',
            properties: {
              status: string_schema,
              structureCategory: string_schema
            },
            additionalProperties: false
          },
          clear: string_array_schema
        },
        additionalProperties: false
      }
    end

    def create_group_schema
      {
        type: 'object',
        properties: {
          parent: target_reference_schema,
          children: {
            type: 'array',
            items: target_reference_schema
          }
        },
        additionalProperties: false
      }
    end

    def reparent_entities_schema
      {
        type: 'object',
        required: ['entities'],
        properties: {
          parent: target_reference_schema,
          entities: {
            type: 'array',
            items: target_reference_schema
          }
        },
        additionalProperties: false
      }
    end

    # rubocop:enable Metrics/MethodLength

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
