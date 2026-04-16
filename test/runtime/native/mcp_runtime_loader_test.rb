# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_loader'

# rubocop:disable Metrics/ClassLength
class McpRuntimeLoaderTest < Minitest::Test
  CANONICAL_NATIVE_TOOL_NAMES = %w[
    ping
    get_scene_info
    list_entities
    find_entities
    sample_surface_z
    get_entity_info
    create_site_element
    set_entity_metadata
    create_component
    delete_component
    transform_component
    get_selection
    set_material
    export_scene
    boolean_operation
    chamfer_edges
    fillet_edges
    eval_ruby
  ].freeze

  def setup
    @vendor_root = File.expand_path('../vendor/ruby', __dir__)
    @loader = SU_MCP::McpRuntimeLoader.new(vendor_root: @vendor_root)
  end

  def test_available_is_false_when_staged_vendor_tree_is_absent
    Dir.mktmpdir do |empty_vendor_root|
      loader = SU_MCP::McpRuntimeLoader.new(vendor_root: empty_vendor_root)

      refute(loader.available?)
      assert_includes(loader.missing_gems, 'mcp')
    end
  end

  def test_load_registers_vendored_dependencies_and_runtime_load_paths
    skip_unless_staged_vendor_runtime!

    @loader.load!

    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/mcp-0.13.0/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/json-schema-6.2.0/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/rack-3.2.6/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/addressable-2.9.0/lib') })
    assert($LOAD_PATH.any? { |path| path.end_with?('/vendor/ruby/public_suffix-7.0.5/lib') })
    assert_equal(
      File.join(@vendor_root, 'json-schema-6.2.0'),
      Gem.loaded_specs.fetch('json-schema').full_gem_path
    )
  end

  # rubocop:disable Metrics/MethodLength
  def test_build_transport_handles_initialize_and_ping_over_stateless_http
    skip_unless_staged_vendor_runtime!

    transport = @loader.build_transport(
      ping_handler: -> { { success: true, message: 'pong' } },
      scene_info_handler: ->(_params) { { success: true, entities: [{ id: 101 }] } }
    )

    initialize_response = perform_json_request(
      transport,
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2025-03-26',
        capabilities: {},
        clientInfo: { name: 'codex-test', version: '1.0.0' }
      }
    )
    ping_response = perform_json_request(
      transport,
      id: 2,
      method: 'tools/call',
      params: { name: 'ping', arguments: {} }
    )
    scene_response = perform_json_request(
      transport,
      id: 3,
      method: 'tools/call',
      params: { name: 'get_scene_info', arguments: { 'entity_limit' => 1 } }
    )

    assert_equal(200, initialize_response[:status])
    assert_equal(200, ping_response[:status])
    assert_equal({ 'success' => true, 'message' => 'pong' },
                 ping_response[:body].dig('result', 'structuredContent'))
    assert_equal({ 'success' => true, 'entities' => [{ 'id' => 101 }] },
                 scene_response[:body].dig('result', 'structuredContent'))
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def test_build_transport_handles_batched_initialized_and_tools_list_requests
    skip_unless_staged_vendor_runtime!

    transport = @loader.build_transport(
      ping_handler: -> { { success: true, message: 'pong' } },
      scene_info_handler: ->(_params) { { success: true, entities: [{ id: 101 }] } }
    )

    response = perform_raw_json_request(transport, batched_tools_list_payload)
    tools = response[:body].fetch('result').fetch('tools')

    assert_equal(200, response[:status])
    assert_equal(
      CANONICAL_NATIVE_TOOL_NAMES,
      tools.map { |tool| tool.fetch('name') }
    )
    scene_tool = tools.find { |tool| tool.fetch('name') == 'get_scene_info' }
    assert_equal('Get Scene Summary', scene_tool.fetch('title'))
    assert_equal(true, scene_tool.fetch('annotations').fetch('readOnlyHint'))
    assert_equal(
      'integer',
      scene_tool.fetch('inputSchema').fetch('properties').fetch('entity_limit').fetch('type')
    )

    list_entities_tool = tools.find { |tool| tool.fetch('name') == 'list_entities' }
    assert_equal('List Top-Level Entities', list_entities_tool.fetch('title'))
    assert_equal(true, list_entities_tool.fetch('annotations').fetch('readOnlyHint'))

    find_entities_tool = tools.find { |tool| tool.fetch('name') == 'find_entities' }
    assert_equal('Find Scene Entities', find_entities_tool.fetch('title'))
    assert_equal(true, find_entities_tool.fetch('annotations').fetch('readOnlyHint'))

    sample_surface_z_tool = tools.find { |tool| tool.fetch('name') == 'sample_surface_z' }
    assert_equal(
      %w[target samplePoints],
      sample_surface_z_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      sample_surface_z_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('target')
        .fetch('properties')
        .keys
        .sort
    )

    get_entity_info_tool = tools.find { |tool| tool.fetch('name') == 'get_entity_info' }
    assert_equal(
      ['id'],
      get_entity_info_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      ['id'],
      get_entity_info_tool.fetch('inputSchema').fetch('properties').keys
    )

    create_site_element_tool = tools.find { |tool| tool.fetch('name') == 'create_site_element' }
    assert_equal('Create Semantic Site Element', create_site_element_tool.fetch('title'))
    assert_equal(
      %w[elementType sourceElementId status],
      create_site_element_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[
        elementType elevation footprint height material name path planting_mass
        retaining_edge sourceElementId status structureCategory tag thickness
        tree_proxy
      ],
      create_site_element_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    set_entity_metadata_tool = tools.find { |tool| tool.fetch('name') == 'set_entity_metadata' }
    assert_equal('Set Entity Metadata', set_entity_metadata_tool.fetch('title'))
    assert_equal(
      ['target'],
      set_entity_metadata_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[clear set target],
      set_entity_metadata_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    transform_component_tool = tools.find { |tool| tool.fetch('name') == 'transform_component' }
    assert_equal(
      ['id'],
      transform_component_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[id position rotation scale],
      transform_component_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    boolean_operation_tool = tools.find { |tool| tool.fetch('name') == 'boolean_operation' }
    assert_equal(
      %w[target_id tool_id operation],
      boolean_operation_tool.fetch('inputSchema').fetch('required')
    )

    eval_ruby_tool = tools.find { |tool| tool.fetch('name') == 'eval_ruby' }
    assert_equal(
      ['code'],
      eval_ruby_tool.fetch('inputSchema').fetch('required')
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def test_build_transport_returns_accepted_for_notification_only_posts
    skip_unless_staged_vendor_runtime!

    transport = @loader.build_transport(
      ping_handler: -> { { success: true, message: 'pong' } },
      scene_info_handler: ->(_params) { { success: true, entities: [{ id: 101 }] } }
    )

    response = perform_raw_json_request(
      transport,
      {
        jsonrpc: '2.0',
        method: 'notifications/initialized'
      }
    )

    assert_equal(202, response[:status])
    assert_equal('', response[:raw_body])
  end

  # rubocop:disable Metrics/MethodLength
  def test_build_transport_calls_a_representative_migrated_handler_from_the_handler_map
    skip_unless_staged_vendor_runtime!

    transport = @loader.build_transport(
      handlers: {
        ping: -> { { success: true, message: 'pong' } },
        get_scene_info: ->(_params) { { success: true, entities: [{ id: 101 }] } },
        create_component: lambda do |arguments|
          { success: true, created: true, type: arguments.fetch('type') }
        end
      }
    )

    response = perform_json_request(
      transport,
      id: 4,
      method: 'tools/call',
      params: { name: 'create_component', arguments: { 'type' => 'cube' } }
    )

    assert_equal(200, response[:status])
    assert_equal(
      { 'success' => true, 'created' => true, 'type' => 'cube' },
      response[:body].dig('result', 'structuredContent')
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_tool_catalog_exposes_the_canonical_native_tool_inventory
    catalog = @loader.tool_catalog

    assert_equal(CANONICAL_NATIVE_TOOL_NAMES, catalog.map { |tool| tool.fetch(:name) })
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def test_tool_catalog_exposes_representative_metadata_and_schema
    catalog = @loader.tool_catalog

    find_entities = catalog.find { |tool| tool.fetch(:name) == 'find_entities' }
    sample_surface_z = catalog.find { |tool| tool.fetch(:name) == 'sample_surface_z' }
    get_entity_info = catalog.find { |tool| tool.fetch(:name) == 'get_entity_info' }
    create_site_element = catalog.find { |tool| tool.fetch(:name) == 'create_site_element' }
    set_entity_metadata = catalog.find { |tool| tool.fetch(:name) == 'set_entity_metadata' }
    transform_component = catalog.find { |tool| tool.fetch(:name) == 'transform_component' }
    boolean_operation = catalog.find { |tool| tool.fetch(:name) == 'boolean_operation' }
    create_component = catalog.find { |tool| tool.fetch(:name) == 'create_component' }
    get_selection = catalog.find { |tool| tool.fetch(:name) == 'get_selection' }
    eval_ruby = catalog.find { |tool| tool.fetch(:name) == 'eval_ruby' }

    scene_info = catalog.find { |tool| tool.fetch(:name) == 'get_scene_info' }
    list_entities = catalog.find { |tool| tool.fetch(:name) == 'list_entities' }

    assert_equal('Get Scene Summary', scene_info.dig(:metadata, :title))
    assert_equal('List Top-Level Entities', list_entities.dig(:metadata, :title))
    assert_equal('Find Scene Entities', find_entities.dig(:metadata, :title))
    assert_equal(true, find_entities.dig(:metadata, :annotations, :read_only_hint))
    assert_equal('object', find_entities.dig(:input_schema, :type))
    assert_equal('query', find_entities.dig(:input_schema, :required)&.first)

    assert_equal(false, create_component.dig(:metadata, :annotations, :read_only_hint))
    assert_equal('object', create_component.dig(:input_schema, :type))
    assert_equal('Sample Target Surface Elevation', sample_surface_z.dig(:metadata, :title))
    assert_equal(%w[target samplePoints], sample_surface_z.dig(:input_schema, :required))
    assert_equal(%i[entityId persistentId sourceElementId],
                 sample_surface_z.dig(:input_schema, :properties, :target, :properties).keys.sort)
    assert_equal('Get Entity Information', get_entity_info.dig(:metadata, :title))
    assert_equal(['id'], get_entity_info.dig(:input_schema, :required))
    assert_equal('Create Semantic Site Element', create_site_element.dig(:metadata, :title))
    assert_equal(%w[elementType sourceElementId status],
                 create_site_element.dig(:input_schema, :required))
    assert_equal('Set Entity Metadata', set_entity_metadata.dig(:metadata, :title))
    assert_equal(['target'], set_entity_metadata.dig(:input_schema, :required))
    assert_equal(['id'], transform_component.dig(:input_schema, :required))
    assert_equal(%w[target_id tool_id operation], boolean_operation.dig(:input_schema, :required))
    assert_equal(true, get_selection.dig(:metadata, :annotations, :read_only_hint))
    assert_equal(['code'], eval_ruby.dig(:input_schema, :required))
    assert_equal(:eval_ruby, eval_ruby.fetch(:handler_key))
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

  def test_tool_catalog_tracks_the_runtime_handler_key_for_representative_tools
    catalog = @loader.tool_catalog
    representative_tools = %w[get_scene_info create_site_element export_scene eval_ruby]
    matching_tools = catalog.select { |tool| representative_tools.include?(tool.fetch(:name)) }

    assert_equal(
      representative_tools,
      matching_tools.map { |tool| tool.fetch(:handler_key).to_s }
    )
  end

  private

  # rubocop:disable Metrics/MethodLength
  def perform_json_request(transport, id:, method:, params:)
    require 'rack/mock_request'

    env = Rack::MockRequest.env_for(
      '/mcp',
      method: 'POST',
      'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream',
      input: {
        jsonrpc: '2.0',
        id: id,
        method: method,
        params: params
      }.to_json
    )

    status, headers, body = transport.call(env)
    payload = body.each.to_a.join

    {
      status: status,
      headers: headers,
      body: JSON.parse(payload)
    }
  ensure
    body.close if body.respond_to?(:close)
  end
  # rubocop:enable Metrics/MethodLength

  def perform_raw_json_request(transport, payload)
    require 'rack/mock_request'

    env = Rack::MockRequest.env_for(
      '/mcp',
      method: 'POST',
      'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream',
      input: JSON.generate(payload)
    )

    status, headers, body = transport.call(env)
    raw_body = body.each.to_a.join

    {
      status: status,
      headers: headers,
      raw_body: raw_body,
      body: raw_body.empty? ? nil : JSON.parse(raw_body)
    }
  ensure
    body.close if body.respond_to?(:close)
  end

  def batched_tools_list_payload
    [
      {
        jsonrpc: '2.0',
        method: 'notifications/initialized'
      },
      {
        jsonrpc: '2.0',
        id: 2,
        method: 'tools/list',
        params: {}
      }
    ]
  end

  def skip_unless_staged_vendor_runtime!
    return if @loader.available?

    skip('staged experimental vendor runtime not present in repo checkout')
  end
end
# rubocop:enable Metrics/ClassLength
