# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../../src/su_mcp/runtime/tool_response'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_loader'

# rubocop:disable Metrics/ClassLength
class McpRuntimeLoaderTest < Minitest::Test
  FORBIDDEN_TOP_LEVEL_SCHEMA_KEYS = %i[oneOf anyOf allOf enum not].freeze

  CANONICAL_NATIVE_TOOL_NAMES = %w[
    ping
    get_scene_info
    list_entities
    find_entities
    validate_scene_update
    measure_scene
    sample_surface_z
    get_entity_info
    create_site_element
    set_entity_metadata
    create_group
    reparent_entities
    delete_entities
    transform_entities
    get_selection
    set_material
    boolean_operation
    eval_ruby
  ].freeze

  def setup
    @vendor_root = File.expand_path('../vendor/ruby', __dir__)
    @loader = SU_MCP::McpRuntimeLoader.new(vendor_root: @vendor_root)
  end

  def test_public_tool_schemas_are_provider_compatible_at_the_top_level
    @loader.tool_catalog.each do |tool|
      input_schema = tool.fetch(:input_schema)

      assert_equal(
        'object',
        input_schema.fetch(:type),
        "#{tool.fetch(:name)} schema must be object"
      )
      FORBIDDEN_TOP_LEVEL_SCHEMA_KEYS.each do |key|
        assert_equal(
          false,
          input_schema.key?(key),
          "#{tool.fetch(:name)} must not use top-level #{key}"
        )
      end
    end
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
    assert_equal('List Entities In Scope', list_entities_tool.fetch('title'))
    assert_equal(true, list_entities_tool.fetch('annotations').fetch('readOnlyHint'))
    assert_equal(
      ['scopeSelector'],
      list_entities_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[outputOptions scopeSelector],
      list_entities_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    find_entities_tool = tools.find { |tool| tool.fetch('name') == 'find_entities' }
    assert_equal('Find Target Entities', find_entities_tool.fetch('title'))
    assert_equal(true, find_entities_tool.fetch('annotations').fetch('readOnlyHint'))
    assert_equal(
      ['targetSelector'],
      find_entities_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[attributes identity metadata],
      find_entities_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('targetSelector')
        .fetch('properties')
        .keys
        .sort
    )

    validate_scene_update_tool = tools.find do |tool|
      tool.fetch('name') == 'validate_scene_update'
    end
    assert_equal('Validate Scene Update', validate_scene_update_tool.fetch('title'))
    assert_equal(true, validate_scene_update_tool.fetch('annotations').fetch('readOnlyHint'))
    assert_equal(
      ['expectations'],
      validate_scene_update_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      ['expectations'],
      validate_scene_update_tool.fetch('inputSchema').fetch('properties').keys
    )
    assert_equal(
      %w[
        geometryRequirements materialRequirements metadataRequirements mustExist
        mustPreserve tagRequirements
      ],
      validate_scene_update_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('expectations')
        .fetch('properties')
        .keys
        .sort
    )

    measure_scene_tool = tools.find { |tool| tool.fetch('name') == 'measure_scene' }
    assert_equal('Measure Scene', measure_scene_tool.fetch('title'))
    assert_equal(true, measure_scene_tool.fetch('annotations').fetch('readOnlyHint'))
    assert_equal(
      %w[mode kind],
      measure_scene_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[from kind mode outputOptions target to],
      measure_scene_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    sample_surface_z_tool = tools.find { |tool| tool.fetch('name') == 'sample_surface_z' }
    assert_equal(
      %w[target sampling],
      sample_surface_z_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[ignoreTargets sampling target visibleOnly],
      sample_surface_z_tool.fetch('inputSchema').fetch('properties').keys.sort
    )
    refute(sample_surface_z_tool.fetch('inputSchema').fetch('properties').key?('samplePoints'))
    assert_equal(
      %w[intervalMeters path points sampleCount type],
      sample_surface_z_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('sampling')
        .fetch('properties')
        .keys
        .sort
    )
    assert_equal(
      %w[points profile],
      sample_surface_z_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('sampling')
        .fetch('properties')
        .fetch('type')
        .fetch('enum')
    )
    assert_includes(
      sample_surface_z_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('sampling')
        .fetch('properties')
        .fetch('type')
        .fetch('description'),
      'capped at 200 samples'
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
      %w[elementType metadata definition hosting placement representation lifecycle],
      create_site_element_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[
        definition elementType hosting lifecycle metadata placement representation
        sceneProperties
      ],
      create_site_element_tool.fetch('inputSchema').fetch('properties').keys.sort
    )
    assert_equal(
      SU_MCP::Semantic::RequestValidator::SUPPORTED_ELEMENT_TYPES,
      create_site_element_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('elementType')
        .fetch('enum')
    )
    assert_equal(
      SU_MCP::Semantic::RequestValidator::SUPPORTED_DEFINITION_MODES.values.flatten,
      create_site_element_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('definition')
        .fetch('properties')
        .fetch('mode')
        .fetch('enum')
    )
    assert_equal(
      SU_MCP::Semantic::RequestValidator::SUPPORTED_LIFECYCLE_MODES,
      create_site_element_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('lifecycle')
        .fetch('properties')
        .fetch('mode')
        .fetch('enum')
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

    create_group_tool = tools.find { |tool| tool.fetch('name') == 'create_group' }
    assert_equal('Create Group Container', create_group_tool.fetch('title'))
    assert_equal(
      %w[children parent],
      create_group_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    reparent_entities_tool = tools.find { |tool| tool.fetch('name') == 'reparent_entities' }
    assert_equal('Reparent Supported Entities', reparent_entities_tool.fetch('title'))
    assert_equal(
      ['entities'],
      reparent_entities_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[entities parent],
      reparent_entities_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    delete_entities_tool = tools.find { |tool| tool.fetch('name') == 'delete_entities' }
    assert_equal('Delete Supported Entities', delete_entities_tool.fetch('title'))
    assert_equal(true, delete_entities_tool.fetch('annotations').fetch('destructiveHint'))
    assert_equal(
      ['targetReference'],
      delete_entities_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[constraints outputOptions targetReference],
      delete_entities_tool.fetch('inputSchema').fetch('properties').keys.sort
    )

    transform_entities_tool = tools.find { |tool| tool.fetch('name') == 'transform_entities' }
    refute(transform_entities_tool.fetch('inputSchema').key?('required'))
    assert_equal(
      %w[id position rotation scale targetReference],
      transform_entities_tool.fetch('inputSchema').fetch('properties').keys.sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      transform_entities_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('targetReference')
        .fetch('properties')
        .keys
        .map(&:to_s)
        .sort
    )

    boolean_operation_tool = tools.find { |tool| tool.fetch('name') == 'boolean_operation' }
    assert_equal(
      %w[target_id tool_id operation],
      boolean_operation_tool.fetch('inputSchema').fetch('required')
    )
    assert_equal(
      %w[difference intersection union],
      boolean_operation_tool
        .fetch('inputSchema')
        .fetch('properties')
        .fetch('operation')
        .fetch('enum')
        .sort
    )

    eval_ruby_tool = tools.find { |tool| tool.fetch('name') == 'eval_ruby' }
    assert_equal(
      ['code'],
      eval_ruby_tool.fetch('inputSchema').fetch('required')
    )
  end

  def test_create_site_element_tool_schema_keeps_a_canonical_sectioned_branch
    create_site_element_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'create_site_element'
    end
    input_schema = create_site_element_tool.fetch(:input_schema)

    assert_equal(
      %w[elementType metadata definition hosting placement representation lifecycle],
      input_schema.fetch(:required)
    )
    assert_equal(
      %w[
        definition elementType hosting lifecycle metadata placement representation sceneProperties
      ],
      input_schema.fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      SU_MCP::Semantic::RequestValidator::SUPPORTED_ELEMENT_TYPES,
      input_schema.fetch(:properties).fetch(:elementType).fetch(:enum)
    )
    assert_equal(
      SU_MCP::Semantic::RequestValidator::SUPPORTED_DEFINITION_MODES.values.flatten,
      input_schema
        .fetch(:properties)
        .fetch(:definition)
        .fetch(:properties)
        .fetch(:mode)
        .fetch(:enum)
    )
    assert_equal(
      SU_MCP::Semantic::RequestValidator::SUPPORTED_LIFECYCLE_MODES,
      input_schema.fetch(:properties).fetch(:lifecycle).fetch(:properties).fetch(:mode).fetch(:enum)
    )
    refute(input_schema.fetch(:properties).key?(:sourceElementId))
    refute(input_schema.fetch(:properties).key?(:path))
    refute(input_schema.fetch(:properties).key?(:material))
  end

  def test_create_group_tool_schema_uses_compact_target_references_only
    create_group_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'create_group'
    end
    refute_nil(create_group_tool)
    input_schema = create_group_tool.fetch(:input_schema)

    assert_equal(
      %w[children metadata parent sceneProperties],
      input_schema.fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      input_schema.fetch(:properties).fetch(:parent).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      input_schema
        .fetch(:properties)
        .fetch(:children)
        .fetch(:items)
        .fetch(:properties)
        .keys
        .map(&:to_s)
        .sort
    )
    refute(input_schema.fetch(:properties).key?(:editContext))
    refute(input_schema.fetch(:properties).key?(:id))
  end

  def test_validate_scene_update_tool_schema_reuses_shared_target_shapes
    validation_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'validate_scene_update'
    end
    refute_nil(validation_tool)

    input_schema = validation_tool.fetch(:input_schema)
    expectations_schema = input_schema.fetch(:properties).fetch(:expectations).fetch(:properties)
    must_exist_item = expectations_schema.fetch(:mustExist).fetch(:items).fetch(:properties)
    metadata_requirement_item = expectations_schema
                                .fetch(:metadataRequirements)
                                .fetch(:items)
                                .fetch(:properties)
    geometry_requirement_item = expectations_schema
                                .fetch(:geometryRequirements)
                                .fetch(:items)
                                .fetch(:properties)

    assert_equal(
      %w[entityId persistentId sourceElementId],
      must_exist_item.fetch(:targetReference).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[attributes identity metadata],
      metadata_requirement_item.fetch(:targetSelector).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[
        anchorSelector constraints expectationId kind surfaceReference
        targetReference targetSelector
      ],
      geometry_requirement_item.keys.map(&:to_s).sort
    )
  end

  def test_validate_scene_update_tool_schema_exposes_surface_offset_geometry_requirements
    validation_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'validate_scene_update'
    end
    refute_nil(validation_tool)

    geometry_requirement_item = validation_tool
                                .fetch(:input_schema)
                                .fetch(:properties)
                                .fetch(:expectations)
                                .fetch(:properties)
                                .fetch(:geometryRequirements)
                                .fetch(:items)
                                .fetch(:properties)

    assert_equal(
      %w[mustBeValidSolid mustHaveGeometry mustNotBeNonManifold surfaceOffset].sort,
      geometry_requirement_item.fetch(:kind).fetch(:enum).map(&:to_s).sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      geometry_requirement_item.fetch(:surfaceReference).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      ['anchor'],
      geometry_requirement_item.fetch(:anchorSelector).fetch(:properties).keys.map(&:to_s)
    )
    assert_equal(
      %w[
        approximate_bottom_bounds_center
        approximate_bottom_bounds_corners
        approximate_top_bounds_center
        approximate_top_bounds_corners
      ],
      geometry_requirement_item
        .fetch(:anchorSelector)
        .fetch(:properties)
        .fetch(:anchor)
        .fetch(:enum)
    )
    assert_equal(
      %w[expectedOffset tolerance],
      geometry_requirement_item.fetch(:constraints).fetch(:properties).keys.map(&:to_s).sort
    )
  end

  def test_validate_scene_update_descriptions_expose_metadata_vs_geometry_boundary
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'validate_scene_update' }
    input_schema = tool.fetch(:input_schema)
    expectations_schema = input_schema.fetch(:properties).fetch(:expectations)
    expectation_properties = expectations_schema.fetch(:properties)
    metadata_requirement_item = expectation_properties
                                .fetch(:metadataRequirements)
                                .fetch(:items)
                                .fetch(:properties)
    geometry_requirement_item = expectation_properties
                                .fetch(:geometryRequirements)
                                .fetch(:items)
                                .fetch(:properties)

    assert_includes(
      tool.fetch(:description),
      'not broad discovery or raw semantic property inspection'
    )
    assert_includes(
      expectations_schema.fetch(:description),
      'exactly one of targetReference or targetSelector'
    )
    assert_includes(
      expectation_properties.fetch(:metadataRequirements).fetch(:description),
      'Not the public path for width, height, thickness'
    )
    assert_includes(
      metadata_requirement_item.fetch(:requiredKeys).fetch(:description),
      'do not use for width, height, thickness'
    )
    assert_includes(
      expectation_properties.fetch(:geometryRequirements).fetch(:description),
      'Use this family for geometry evidence'
    )
    assert_includes(
      geometry_requirement_item.fetch(:kind).fetch(:description),
      'Measured dimension or tolerance checks are a later follow-on'
    )
  end

  def test_measure_scene_tool_schema_exposes_supported_modes_and_kinds
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'measure_scene' }
    refute_nil(tool)

    input_schema = tool.fetch(:input_schema)

    assert_equal(
      %i[from kind mode outputOptions sampling samplingPolicy target to],
      input_schema.fetch(:properties).keys.sort
    )
    assert_equal(%w[kind mode], input_schema.fetch(:required).sort)
    assert_equal(%w[area bounds distance height terrain_profile],
                 input_schema.dig(:properties, :mode, :enum).sort)
    assert_equal(
      %w[
        bounds_center_to_bounds_center bounds_z elevation_summary horizontal_bounds surface
        world_bounds
      ],
      input_schema.dig(:properties, :kind, :enum).sort
    )
    assert_includes(
      input_schema.dig(:properties, :mode, :description),
      'Supported MVP combinations'
    )
    assert_includes(input_schema.dig(:properties, :kind, :description), 'Runtime refuses')
    assert_equal(false, schema_includes_key?(input_schema, :targetSelector))
  end

  def test_measure_scene_tool_schema_exposes_terrain_profile_sampling_policy
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'measure_scene' }
    properties = tool.fetch(:input_schema).fetch(:properties)
    assert_includes(properties.keys, :sampling)
    assert_includes(properties.keys, :samplingPolicy)

    sampling = properties.fetch(:sampling)
    sampling_policy = properties.fetch(:samplingPolicy)

    assert_equal(%w[profile], sampling.dig(:properties, :type, :enum))
    assert_equal(%i[intervalMeters path sampleCount type], sampling.fetch(:properties).keys.sort)
    assert_equal(%i[ignoreTargets visibleOnly], sampling_policy.fetch(:properties).keys.sort)
    assert_equal('boolean',
                 sampling_policy.dig(:properties, :visibleOnly, :type))
    assert_equal(
      %w[entityId persistentId sourceElementId],
      sampling_policy.dig(:properties, :ignoreTargets, :items, :properties).keys.map(&:to_s).sort
    )
  end

  def test_measure_scene_tool_schema_uses_compact_references_only
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'measure_scene' }
    properties = tool.fetch(:input_schema).fetch(:properties)

    %i[target from to].each do |reference_key|
      assert_equal(
        %w[entityId persistentId sourceElementId],
        properties.fetch(reference_key).fetch(:properties).keys.map(&:to_s).sort
      )
      assert_equal(false, properties.fetch(reference_key).key?(:targetSelector))
    end
  end

  def test_measure_scene_tool_schema_documents_runtime_mode_kind_enforcement
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'measure_scene' }
    properties = tool.fetch(:input_schema).fetch(:properties)

    assert_includes(properties.fetch(:mode).fetch(:description), 'bounds/world_bounds')
    assert_includes(
      properties.fetch(:mode).fetch(:description),
      'distance/bounds_center_to_bounds_center'
    )
    assert_includes(properties.fetch(:mode).fetch(:description),
                    'terrain_profile/elevation_summary')
    assert_includes(properties.fetch(:kind).fetch(:description), 'unsupported mode/kind pairs')
  end

  def test_measure_scene_tool_descriptions_are_contrastive
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'measure_scene' }
    properties = tool.fetch(:input_schema).fetch(:properties)

    assert_includes(tool.fetch(:description), 'Use for direct measurements')
    assert_includes(tool.fetch(:description), 'Do not use for validation verdicts')
    assert_includes(tool.fetch(:description), 'Do not use for slope, grade')
    assert_includes(properties.fetch(:mode).fetch(:description), 'Supported MVP combinations')
    assert_includes(properties.fetch(:kind).fetch(:description), 'Runtime refuses')
  end

  def test_measure_scene_tool_schema_exposes_output_options_without_widening_references
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'measure_scene' }
    output_options = tool.fetch(:input_schema).fetch(:properties).fetch(:outputOptions)

    assert_equal(['includeEvidence'], output_options.fetch(:properties).keys.map(&:to_s))
    assert_equal('boolean', output_options.fetch(:properties).fetch(:includeEvidence).fetch(:type))
  end

  def test_create_group_tool_schema_supports_managed_container_metadata_and_scene_properties
    create_group_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'create_group'
    end
    refute_nil(create_group_tool)
    input_schema = create_group_tool.fetch(:input_schema)

    assert_equal(
      %w[children metadata parent sceneProperties],
      input_schema.fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[sourceElementId status],
      input_schema.fetch(:properties).fetch(:metadata).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[name tag],
      input_schema.fetch(:properties)
                  .fetch(:sceneProperties)
                  .fetch(:properties)
                  .keys
                  .map(&:to_s)
                  .sort
    )
  end

  def test_set_material_tool_schema_supports_compact_target_references_alongside_id
    set_material_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'set_material'
    end
    refute_nil(set_material_tool)
    input_schema = set_material_tool.fetch(:input_schema)

    assert_equal(['material'], input_schema.fetch(:required))
    assert_equal(
      %w[id material targetReference],
      input_schema.fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      input_schema
        .fetch(:properties)
        .fetch(:targetReference)
        .fetch(:properties)
        .keys
        .map(&:to_s)
        .sort
    )
  end

  def test_set_entity_metadata_schema_advertises_widened_soft_mutation_fields
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'set_entity_metadata' }
    input_schema = tool.fetch(:input_schema)

    assert_equal(
      %w[plantingCategory speciesHint status structureCategory],
      input_schema.fetch(:properties).fetch(:set).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[extension main_building outbuilding],
      input_schema
        .fetch(:properties)
        .fetch(:set)
        .fetch(:properties)
        .fetch(:structureCategory)
        .fetch(:enum)
        .sort
    )
  end

  def test_create_site_element_tool_description_and_sections_expose_operational_boundaries
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'create_site_element' }
    input_schema = tool.fetch(:input_schema)

    assert_includes(tool.fetch(:description), 'Do not use for metadata-only edits')
    assert_includes(
      input_schema.fetch(:properties).fetch(:definition).fetch(:description),
      'Owns native shape'
    )
    assert_includes(
      input_schema.fetch(:properties).fetch(:hosting).fetch(:description),
      'not parent placement or identity-preserving replacement'
    )
    assert_includes(
      input_schema.fetch(:properties).fetch(:placement).fetch(:description),
      'does not own terrain conformity or lifecycle replacement'
    )
    assert_includes(
      input_schema.fetch(:properties).fetch(:lifecycle).fetch(:description),
      'create/adopt/replace intent'
    )
    assert_includes(
      input_schema.fetch(:properties).fetch(:hosting).fetch(:properties).fetch(:mode)
                  .fetch(:description),
      'Contextual by elementType'
    )
    assert_includes(
      input_schema.fetch(:properties).fetch(:hosting).fetch(:properties).fetch(:mode)
                  .fetch(:description),
      'tree_proxy -> terrain_anchored'
    )
    assert_includes(
      input_schema.fetch(:properties).fetch(:hosting).fetch(:properties).fetch(:mode)
                  .fetch(:description),
      'structure -> terrain_anchored'
    )
  end

  def test_create_site_element_schema_advertises_canonical_sections_only
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'create_site_element' }
    input_schema = tool.fetch(:input_schema)

    assert_equal(
      %w[elementType metadata definition hosting placement representation lifecycle],
      input_schema.fetch(:required)
    )
    assert_equal(false, input_schema.key?(:anyOf))
    assert_equal(false, input_schema.key?(:oneOf))
    assert_equal(false, input_schema.fetch(:properties).key?(:mode))
  end

  def test_create_site_element_description_marks_recovery_variants_as_non_canonical
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'create_site_element' }

    assert_includes(tool.fetch(:description), 'recovery-only')
  end

  def test_set_entity_metadata_tool_description_and_clear_field_expose_contextual_ownership
    tool = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'set_entity_metadata' }
    input_schema = tool.fetch(:input_schema)

    assert_includes(tool.fetch(:description), 'not geometry changes')
    assert_includes(
      input_schema.fetch(:properties).fetch(:clear).fetch(:description),
      'contextual by managed-object type'
    )
    assert_includes(
      input_schema.fetch(:properties).fetch(:set).fetch(:description),
      'Unsupported field/type combinations refuse'
    )
  end

  def test_mutation_tool_descriptions_expose_usage_boundaries_without_long_examples
    boolean_operation = @loader.tool_catalog.find do |entry|
      entry.fetch(:name) == 'boolean_operation'
    end
    transform_entities = @loader.tool_catalog.find do |entry|
      entry.fetch(:name) == 'transform_entities'
    end
    set_material = @loader.tool_catalog.find { |entry| entry.fetch(:name) == 'set_material' }

    assert_includes(boolean_operation.fetch(:description), 'not semantic replacement')
    assert_includes(transform_entities.fetch(:description), 'not semantic hosting')
    assert_includes(set_material.fetch(:description), 'Do not use for semantic metadata changes')
  end

  def test_reparent_entities_tool_schema_uses_compact_target_references_only
    reparent_entities_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'reparent_entities'
    end
    refute_nil(reparent_entities_tool)
    input_schema = reparent_entities_tool.fetch(:input_schema)

    assert_equal(['entities'], input_schema.fetch(:required))
    assert_equal(%w[entities parent], input_schema.fetch(:properties).keys.map(&:to_s).sort)
    assert_equal(
      %w[entityId persistentId sourceElementId],
      input_schema
        .fetch(:properties)
        .fetch(:entities)
        .fetch(:items)
        .fetch(:properties)
        .keys
        .map(&:to_s)
        .sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      input_schema.fetch(:properties).fetch(:parent).fetch(:properties).keys.map(&:to_s).sort
    )
    refute(input_schema.fetch(:properties).key?(:activePath))
    refute(input_schema.fetch(:properties).key?(:query))
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
        transform_entities: lambda do |arguments|
          { success: true, id: arguments.fetch('id') }
        end
      }
    )

    response = perform_json_request(
      transport,
      id: 4,
      method: 'tools/call',
      params: { name: 'transform_entities', arguments: { 'id' => '301' } }
    )

    assert_equal(200, response[:status])
    assert_equal(
      { 'success' => true, 'id' => '301' },
      response[:body].dig('result', 'structuredContent')
    )
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def test_build_transport_deeply_stringifies_nested_semantic_payload_keys
    skip_unless_staged_vendor_runtime!

    captured_arguments = nil
    transport = @loader.build_transport(
      handlers: {
        create_site_element: lambda do |arguments|
          captured_arguments = arguments
          { success: true, outcome: 'created' }
        end
      }
    )

    response = perform_json_request(
      transport,
      id: 5,
      method: 'tools/call',
      params: {
        name: 'create_site_element',
        arguments: {
          elementType: 'path',
          metadata: {
            sourceElementId: 'main-walk-001',
            status: 'proposed'
          },
          definition: {
            mode: 'centerline',
            centerline: [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
            width: 1.6,
            elevation: 0.0,
            thickness: 0.1
          },
          hosting: {
            mode: 'none'
          },
          placement: {
            mode: 'host_resolved'
          },
          representation: {
            mode: 'path_surface_proxy',
            material: 'Gravel'
          },
          lifecycle: {
            mode: 'create_new'
          },
          sceneProperties: {
            name: 'Main Walk',
            tag: 'Paths'
          }
        }
      }
    )

    assert_equal(200, response[:status])
    assert_equal(
      {
        'elementType' => 'path',
        'metadata' => {
          'sourceElementId' => 'main-walk-001',
          'status' => 'proposed'
        },
        'definition' => {
          'mode' => 'centerline',
          'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
          'width' => 1.6,
          'elevation' => 0.0,
          'thickness' => 0.1
        },
        'hosting' => {
          'mode' => 'none'
        },
        'placement' => {
          'mode' => 'host_resolved'
        },
        'representation' => {
          'mode' => 'path_surface_proxy',
          'material' => 'Gravel'
        },
        'lifecycle' => {
          'mode' => 'create_new'
        },
        'sceneProperties' => {
          'name' => 'Main Walk',
          'tag' => 'Paths'
        }
      },
      captured_arguments
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_tool_catalog_exposes_the_canonical_native_tool_inventory
    catalog = @loader.tool_catalog

    assert_equal(CANONICAL_NATIVE_TOOL_NAMES, catalog.map { |tool| tool.fetch(:name) })
  end

  def test_stringify_keys_recurses_through_nested_hashes_and_arrays
    normalized = @loader.send(
      :stringify_keys,
      {
        path: {
          centerline: [[0.0, 0.0], [4.0, 1.0]],
          metadata: [{ status: :proposed }]
        },
        tags: [:a, { sourceElementId: 'main-walk-001' }]
      }
    )

    assert_equal(
      {
        'path' => {
          'centerline' => [[0.0, 0.0], [4.0, 1.0]],
          'metadata' => [{ 'status' => :proposed }]
        },
        'tags' => [:a, { 'sourceElementId' => 'main-walk-001' }]
      },
      normalized
    )
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def test_tool_catalog_exposes_representative_metadata_and_schema
    catalog = @loader.tool_catalog

    find_entities = catalog.find { |tool| tool.fetch(:name) == 'find_entities' }
    delete_entities = catalog.find { |tool| tool.fetch(:name) == 'delete_entities' }
    sample_surface_z = catalog.find { |tool| tool.fetch(:name) == 'sample_surface_z' }
    get_entity_info = catalog.find { |tool| tool.fetch(:name) == 'get_entity_info' }
    create_site_element = catalog.find { |tool| tool.fetch(:name) == 'create_site_element' }
    set_entity_metadata = catalog.find { |tool| tool.fetch(:name) == 'set_entity_metadata' }
    transform_entities = catalog.find { |tool| tool.fetch(:name) == 'transform_entities' }
    boolean_operation = catalog.find { |tool| tool.fetch(:name) == 'boolean_operation' }
    get_selection = catalog.find { |tool| tool.fetch(:name) == 'get_selection' }
    eval_ruby = catalog.find { |tool| tool.fetch(:name) == 'eval_ruby' }

    scene_info = catalog.find { |tool| tool.fetch(:name) == 'get_scene_info' }
    list_entities = catalog.find { |tool| tool.fetch(:name) == 'list_entities' }

    assert_equal('Get Scene Summary', scene_info.dig(:metadata, :title))
    assert_equal('List Entities In Scope', list_entities.dig(:metadata, :title))
    assert_equal('Find Target Entities', find_entities.dig(:metadata, :title))
    assert_equal(true, find_entities.dig(:metadata, :annotations, :read_only_hint))
    assert_equal('object', find_entities.dig(:input_schema, :type))
    assert_equal('targetSelector', find_entities.dig(:input_schema, :required)&.first)
    assert_equal('Delete Supported Entities', delete_entities.dig(:metadata, :title))
    assert_equal('targetReference', delete_entities.dig(:input_schema, :required)&.first)

    assert_equal('Sample Target Surface Elevation', sample_surface_z.dig(:metadata, :title))
    assert_equal(%w[target sampling], sample_surface_z.dig(:input_schema, :required))
    refute(sample_surface_z.dig(:input_schema, :properties).key?(:samplePoints))
    assert_equal(
      %w[points profile],
      sample_surface_z.dig(:input_schema, :properties, :sampling, :properties, :type, :enum)
    )
    assert_equal(%i[entityId persistentId sourceElementId],
                 sample_surface_z.dig(:input_schema, :properties, :target, :properties).keys.sort)
    assert_equal('Get Entity Information', get_entity_info.dig(:metadata, :title))
    assert_equal(['id'], get_entity_info.dig(:input_schema, :required))
    assert_equal('Create Semantic Site Element', create_site_element.dig(:metadata, :title))
    assert_equal(false, create_site_element[:input_schema].key?(:anyOf))
    assert_equal('Set Entity Metadata', set_entity_metadata.dig(:metadata, :title))
    assert_equal(['target'], set_entity_metadata.dig(:input_schema, :required))
    assert_equal('Transform Entities', transform_entities.dig(:metadata, :title))
    refute(transform_entities[:input_schema].key?(:required))
    assert_equal(
      %i[id position rotation scale targetReference],
      transform_entities.dig(:input_schema, :properties).keys.sort
    )
    assert_equal(%w[target_id tool_id operation], boolean_operation.dig(:input_schema, :required))
    assert_equal(true, get_selection.dig(:metadata, :annotations, :read_only_hint))
    assert_equal(['code'], eval_ruby.dig(:input_schema, :required))
    assert_equal(:eval_ruby, eval_ruby.fetch(:handler_key))
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

  def test_tool_catalog_tracks_the_runtime_handler_key_for_representative_tools
    catalog = @loader.tool_catalog
    representative_tools = %w[
      get_scene_info create_site_element delete_entities transform_entities eval_ruby
    ]
    matching_tools = catalog.select { |tool| representative_tools.include?(tool.fetch(:name)) }

    assert_equal(
      representative_tools,
      matching_tools.map { |tool| tool.fetch(:handler_key).to_s }
    )
  end

  def test_tool_catalog_assigns_explicit_classification_to_every_public_native_tool
    catalog = @loader.tool_catalog

    assert_equal(
      CANONICAL_NATIVE_TOOL_NAMES,
      catalog.map { |tool| tool.fetch(:name) }
    )
    assert_equal(
      ['escape_hatch'],
      catalog
        .map { |tool| tool.fetch(:classification) }
        .uniq
        .select { |classification| classification == 'escape_hatch' }
    )
    assert_equal(
      CANONICAL_NATIVE_TOOL_NAMES.length,
      catalog.count { |tool| %w[first_class escape_hatch].include?(tool.fetch(:classification)) }
    )
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def test_list_entities_tool_schema_exposes_scope_selector_and_output_options
    list_entities_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'list_entities'
    end
    input_schema = list_entities_tool.fetch(:input_schema)

    assert_equal(['scopeSelector'], input_schema.fetch(:required))
    assert_equal(
      %w[outputOptions scopeSelector],
      input_schema.fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      ['mode'],
      input_schema.fetch(:properties).fetch(:scopeSelector).fetch(:required)
    )
    assert_equal(
      %w[mode targetReference],
      input_schema.fetch(:properties).fetch(:scopeSelector).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[children_of_target selection top_level],
      input_schema.fetch(:properties)
                  .fetch(:scopeSelector)
                  .fetch(:properties)
                  .fetch(:mode)
                  .fetch(:enum)
                  .sort
    )
    assert_equal(
      %w[includeHidden limit],
      input_schema.fetch(:properties).fetch(:outputOptions).fetch(:properties).keys.map(&:to_s).sort
    )
  end

  def test_find_entities_tool_schema_exposes_nested_target_selector_families
    find_entities_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'find_entities'
    end
    target_selector = find_entities_tool
                      .fetch(:input_schema)
                      .fetch(:properties)
                      .fetch(:targetSelector)

    assert_equal(['targetSelector'], find_entities_tool.fetch(:input_schema).fetch(:required))
    assert_equal(
      %w[attributes identity metadata],
      target_selector.fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      target_selector.fetch(:properties).fetch(:identity).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[material name tag],
      target_selector.fetch(:properties).fetch(:attributes).fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[managedSceneObject semanticType state status structureCategory],
      target_selector.fetch(:properties).fetch(:metadata).fetch(:properties).keys.map(&:to_s).sort
    )
  end

  def test_delete_entities_tool_schema_replaces_delete_component_with_explicit_constraints
    refute(@loader.tool_catalog.any? { |tool| tool.fetch(:name) == 'delete_component' })

    delete_entities_tool = @loader.tool_catalog.find do |tool|
      tool.fetch(:name) == 'delete_entities'
    end
    input_schema = delete_entities_tool.fetch(:input_schema)

    assert_equal(['targetReference'], input_schema.fetch(:required))
    assert_equal(
      %w[constraints outputOptions targetReference],
      input_schema.fetch(:properties).keys.map(&:to_s).sort
    )
    assert_equal(
      %w[entityId persistentId sourceElementId],
      input_schema
        .fetch(:properties)
        .fetch(:targetReference)
        .fetch(:properties)
        .keys
        .map(&:to_s)
        .sort
    )
    assert_equal(
      ['fail'],
      input_schema.fetch(:properties)
                  .fetch(:constraints)
                  .fetch(:properties)
                  .fetch(:ambiguityPolicy)
                  .fetch(:enum)
    )
    assert_equal(
      ['concise'],
      input_schema.fetch(:properties)
                  .fetch(:outputOptions)
                  .fetch(:properties)
                  .fetch(:responseFormat)
                  .fetch(:enum)
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def test_eval_ruby_is_the_only_escape_hatch_tool_definition
    catalog = @loader.tool_catalog

    assert_equal(
      ['eval_ruby'],
      catalog
        .select { |tool| tool.fetch(:classification) == 'escape_hatch' }
        .map { |tool| tool.fetch(:name) }
    )
  end

  def test_loader_exposes_a_private_tool_failure_translation_seam
    assert_includes(@loader.private_methods, :translate_tool_failure)
  end

  def test_build_tool_preserves_first_class_structured_results
    with_stubbed_mcp_tool do
      tool = @loader.send(
        :build_tool,
        name: 'create_group',
        title: 'Create Group Container',
        description: 'Create a group container.',
        annotations: { read_only_hint: false, destructive_hint: false },
        input_schema: {},
        classification: 'first_class',
        &->(_arguments) { SU_MCP::ToolResponse.success(outcome: 'created', group: { entityId: '42' }) }
      )

      response = tool.call(server_context: :ignored, children: [])

      assert_equal(
        { success: true, outcome: 'created', group: { entityId: '42' } },
        response.structured_content
      )
    end
  end

  def test_build_tool_preserves_escape_hatch_raw_return_values
    with_stubbed_mcp_tool do
      tool = @loader.send(
        :build_tool,
        name: 'eval_ruby',
        title: 'Evaluate Ruby',
        description: 'Evaluate arbitrary Ruby code inside SketchUp.',
        annotations: { read_only_hint: false, destructive_hint: false },
        input_schema: {},
        classification: 'escape_hatch',
        &->(_arguments) { '2' }
      )

      response = tool.call(server_context: :ignored, code: '1 + 1')

      assert_equal('2', response.structured_content)
    end
  end

  def test_build_tool_translates_raised_handler_failures_through_the_runtime_boundary
    with_stubbed_mcp_tool do
      tool = @loader.send(
        :build_tool,
        name: 'eval_ruby',
        title: 'Evaluate Ruby',
        description: 'Evaluate arbitrary Ruby code inside SketchUp.',
        annotations: { read_only_hint: false, destructive_hint: false },
        input_schema: {},
        classification: 'escape_hatch',
        &->(_arguments) { raise 'boom' }
      )

      error = assert_raises(RuntimeError) do
        tool.call(server_context: :ignored, code: 'raise "boom"')
      end

      assert_equal('Native MCP tool eval_ruby failed: boom', error.message)
    end
  end

  def test_build_tool_translates_missing_handler_failures_through_the_runtime_boundary
    with_stubbed_mcp_tool do
      tool = @loader.send(
        :build_tool,
        name: 'create_group',
        title: 'Create Group Container',
        description: 'Create a group container.',
        annotations: { read_only_hint: false, destructive_hint: false },
        input_schema: {},
        classification: 'first_class',
        &@loader.send(:build_tool_handler, :create_group, {})
      )

      error = assert_raises(RuntimeError) do
        tool.call(server_context: :ignored, children: [])
      end

      assert_equal(
        'Native MCP tool create_group failed: ' \
        'No native runtime handler registered for create_group',
        error.message
      )
    end
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

  def schema_includes_key?(schema, key)
    case schema
    when Hash
      schema.key?(key) || schema.any? { |_nested_key, value| schema_includes_key?(value, key) }
    when Array
      schema.any? { |value| schema_includes_key?(value, key) }
    else
      false
    end
  end

  # rubocop:disable Metrics/MethodLength
  def with_stubbed_mcp_tool
    previous_mcp = Object.const_get(:MCP) if Object.const_defined?(:MCP)
    Object.send(:remove_const, :MCP) if Object.const_defined?(:MCP)

    response_class = Class.new do
      attr_reader :content, :structured_content

      def initialize(content, structured_content:)
        @content = content
        @structured_content = structured_content
      end
    end
    tool_module = Module.new do
      define_singleton_method(:define) do |**_kwargs, &block|
        Class.new do
          define_method(:call) do |**kwargs|
            self.class.instance_exec(**kwargs, &block)
          end
        end.new
      end
    end
    tool_module.const_set(:Response, response_class)

    mcp_module = Module.new
    mcp_module.const_set(:Tool, tool_module)
    Object.const_set(:MCP, mcp_module)

    yield
  ensure
    Object.send(:remove_const, :MCP) if Object.const_defined?(:MCP)
    Object.const_set(:MCP, previous_mcp) if previous_mcp
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength
