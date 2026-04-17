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
          description: 'Get a structured summary of the current SketchUp scene for broad ' \
                       'grounding before more targeted inspection tools are used.',
          handler_key: :get_scene_info,
          metadata: {
            title: 'Get Scene Summary',
            annotations: { read_only_hint: true, destructive_hint: false }
          },
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
          description: 'List top-level SketchUp model entities with an optional limit and ' \
                       'optional hidden-entity inclusion.',
          handler_key: :list_entities,
          metadata: {
            title: 'List Top-Level Entities',
            annotations: { read_only_hint: true, destructive_hint: false }
          },
          input_schema: {
            type: 'object',
            properties: {
              limit: integer_schema,
              include_hidden: boolean_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'find_entities',
          description: 'Find scene entities using the supported MVP targeting fields and ' \
                       'return explicit match summaries. Supports identity references, ' \
                       'name, tag, and material only.',
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
                  sourceElementId: string_schema,
                  persistentId: string_schema,
                  entityId: string_schema,
                  name: string_schema,
                  tag: string_schema,
                  material: string_schema
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
          description: 'Sample world-space surface elevation from an explicit target at ' \
                       'one or more XY points in meters. Callers must provide the target ' \
                       'and sample points; this is not broad scene discovery.',
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
              visibleOnly: boolean_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'get_entity_info',
          description: 'Get structured information for a specific SketchUp entity by id.',
          handler_key: :get_entity_info,
          metadata: {
            title: 'Get Entity Information',
            annotations: { read_only_hint: true, destructive_hint: false }
          },
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
          description: 'Create a managed semantic site element in SketchUp. Current support ' \
                       'is limited to structure, pad, path, retaining_edge, ' \
                       'planting_mass, and tree_proxy creation.',
          handler_key: :create_site_element,
          metadata: {
            title: 'Create Semantic Site Element',
            annotations: { read_only_hint: false, destructive_hint: false }
          },
          input_schema: create_site_element_schema
        ),
        tool_entry(
          name: 'set_entity_metadata',
          description: 'Update semantic metadata on an existing managed object in ' \
                       'SketchUp. Current support is limited to status updates for ' \
                       'managed objects and structureCategory updates for managed ' \
                       'structure objects.',
          handler_key: :set_entity_metadata,
          metadata: {
            title: 'Set Entity Metadata',
            annotations: { read_only_hint: false, destructive_hint: false }
          },
          input_schema: set_entity_metadata_schema
        ),
        tool_entry(
          name: 'create_group',
          description: 'Create a group container for semantic hierarchy-maintenance ' \
                       'work. Optionally relocate supported child groups or components ' \
                       'into the new container.',
          handler_key: :create_group,
          metadata: {
            title: 'Create Group Container',
            annotations: { read_only_hint: false, destructive_hint: false }
          },
          input_schema: create_group_schema
        ),
        tool_entry(
          name: 'reparent_entities',
          description: 'Reparent supported group or component entities under an explicit ' \
                       'parent group or to model root as a narrow hierarchy-maintenance ' \
                       'operation.',
          handler_key: :reparent_entities,
          metadata: {
            title: 'Reparent Supported Entities',
            annotations: { read_only_hint: false, destructive_hint: false }
          },
          input_schema: reparent_entities_schema
        )
      ]
    end

    # rubocop:disable Metrics/AbcSize
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
              type: string_schema,
              position: numeric_array_schema,
              dimensions: numeric_array_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'delete_component',
          description: 'Delete a component by ID.',
          handler_key: :delete_component,
          input_schema: identifier_object_schema('id')
        ),
        tool_entry(
          name: 'transform_component',
          description: "Transform a component's position, rotation, or scale.",
          handler_key: :transform_component,
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
          description: 'Get detailed information about the current selection.',
          handler_key: :get_selection,
          metadata: {
            annotations: { read_only_hint: true, destructive_hint: false }
          },
          input_schema: {
            type: 'object',
            properties: {},
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'set_material',
          description: 'Set the material for a SketchUp entity.',
          handler_key: :set_material,
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
          name: 'export_scene',
          description: 'Export the current SketchUp scene.',
          handler_key: :export_scene,
          input_schema: {
            type: 'object',
            properties: {
              format: string_schema,
              width: integer_schema,
              height: integer_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'boolean_operation',
          description: 'Run a boolean operation between two SketchUp groups/components.',
          handler_key: :boolean_operation,
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
        ),
        tool_entry(
          name: 'chamfer_edges',
          description: 'Create a chamfer on selected edges of a group or component.',
          handler_key: :chamfer_edges,
          input_schema: {
            type: 'object',
            required: ['entity_id'],
            properties: {
              entity_id: string_schema,
              distance: number_schema,
              edge_indices: integer_array_schema,
              delete_original: boolean_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'fillet_edges',
          description: 'Create a fillet on selected edges of a group or component.',
          handler_key: :fillet_edges,
          input_schema: {
            type: 'object',
            required: ['entity_id'],
            properties: {
              entity_id: string_schema,
              radius: number_schema,
              segments: integer_schema,
              edge_indices: integer_array_schema,
              delete_original: boolean_schema
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
          description: 'Evaluate arbitrary Ruby code inside SketchUp.',
          handler_key: :eval_ruby,
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
    # rubocop:enable Metrics/AbcSize
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
