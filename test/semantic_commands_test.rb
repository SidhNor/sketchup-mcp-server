# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/ClassLength

require_relative 'test_helper'
require_relative 'support/semantic_test_support'
require_relative '../src/su_mcp/semantic_commands'

class SemanticCommandsTest < Minitest::Test
  include SemanticTestSupport

  METERS_TO_INTERNAL = 39.37007874015748

  class FakeRegistry
    attr_reader :calls

    def initialize(builder)
      @builder = builder
      @calls = []
    end

    def builder_for(element_type)
      @calls << element_type
      @builder
    end
  end

  class FakeSerializer
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def serialize(entity)
      @calls << entity
      @result
    end
  end

  class FakeMetadataWriter
    attr_reader :calls, :prepare_calls, :apply_calls

    def initialize(update_result: { outcome: 'updated' })
      @calls = []
      @prepare_calls = []
      @apply_calls = []
      @update_result = update_result
    end

    def write!(entity, attributes)
      @calls << [entity, attributes]
      entity
    end

    def prepare_update(entity, set:, clear:)
      @prepare_calls << [entity, set, clear]
      @update_result
    end

    def apply_prepared_update(entity, prepared_update)
      @apply_calls << [entity, prepared_update]
      { outcome: 'updated' }
    end

    def update(entity, set:, clear:)
      prepared_update = prepare_update(entity, set: set, clear: clear)
      return prepared_update unless prepared_update[:outcome] == 'ready'

      apply_prepared_update(entity, prepared_update)
    end
  end

  class FakeTargetResolver
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def resolve(query)
      @calls << query
      @result
    end
  end

  class FakeManagedEntity
    attr_reader :parent

    def initialize(parent:)
      @parent = parent
    end
  end

  def setup
    @model = build_semantic_model
  end

  def test_create_site_element_wraps_successful_creation_in_one_operation
    created_group = @model.active_entities.add_group
    request = {
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
        'width' => 1.6,
        'elevation' => 0.0,
        'thickness' => 0.1
      }
    }
    builder = Object.new
    builder.define_singleton_method(:build) { |**_kwargs| created_group }
    registry = FakeRegistry.new(builder)
    metadata_writer = FakeMetadataWriter.new
    serializer = FakeSerializer.new(sourceElementId: 'main-walk-001', semanticType: 'path')

    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: metadata_writer,
      serializer: serializer
    )
    result = commands.create_site_element(request)

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(
      [[:start_operation, 'Create Site Element', true], [:commit_operation]],
      @model.operations
    )
    assert_equal(['path'], registry.calls)
    assert_equal(
      [[
        created_group,
        {
          'sourceElementId' => 'main-walk-001',
          'semanticType' => 'path',
          'status' => 'proposed',
          'state' => 'Created',
          'schemaVersion' => 1,
          'width' => 1.6,
          'thickness' => 0.1
        }
      ]],
      metadata_writer.calls
    )
    assert_equal([created_group], serializer.calls)
  end

  # rubocop:disable Metrics/AbcSize
  def test_create_site_element_normalizes_builder_input_and_keeps_public_metadata
    created_group = @model.active_entities.add_group
    captured_params = nil
    request = {
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
        'width' => 1.6,
        'elevation' => 0.0,
        'thickness' => 0.1
      }
    }
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    metadata_writer = FakeMetadataWriter.new
    serializer = FakeSerializer.new(sourceElementId: 'main-walk-001', semanticType: 'path')

    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: metadata_writer,
      serializer: serializer
    )
    commands.create_site_element(request)

    assert_equal(
      [[0.0, 0.0], [4.0 * METERS_TO_INTERNAL, 1.0 * METERS_TO_INTERNAL],
       [8.0 * METERS_TO_INTERNAL, 1.0 * METERS_TO_INTERNAL]],
      captured_params.dig('path', 'centerline')
    )
    assert_in_delta(1.6 * METERS_TO_INTERNAL, captured_params.dig('path', 'width'), 1e-9)
    assert_in_delta(0.1 * METERS_TO_INTERNAL, captured_params.dig('path', 'thickness'), 1e-9)
    assert_equal(
      1.6,
      metadata_writer.calls.first.last['width']
    )
    assert_equal(
      0.1,
      metadata_writer.calls.first.last['thickness']
    )
  end
  # rubocop:enable Metrics/AbcSize

  def test_create_site_element_returns_structured_refusal_for_missing_matching_payloads
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'tree_proxy',
      'sourceElementId' => 'tree-001',
      'status' => 'proposed',
      'name' => 'Missing Proxy Payload'
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_element_payload', result.dig(:refusal, :code))
  end

  def test_create_site_element_returns_structured_refusal_for_contradictory_payloads
    registry = FakeRegistry.new(Object.new)
    commands = SU_MCP::SemanticCommands.new(model: @model, registry: registry)

    result = commands.create_site_element(
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [3.0, 0.0]],
        'width' => 1.6
      },
      'planting_mass' => {
        'boundary' => [[0.0, 0.0], [2.0, 0.0], [2.0, 1.0], [0.0, 1.0]],
        'averageHeight' => 0.8
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('contradictory_payload', result.dig(:refusal, :code))
    assert_equal([], registry.calls)
  end

  def test_create_site_element_refuses_invalid_path_geometry_before_builder_execution
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [0.0, 0.0]],
        'width' => 1.6
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_geometry', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_unsupported_element_types
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'water_feature_proxy',
      'sourceElementId' => 'water-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_element_type', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_structure_requests_without_structure_category
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'structure',
      'sourceElementId' => 'shed-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
      'height' => 2.4
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_required_field', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_unapproved_structure_categories
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'structure',
      'sourceElementId' => 'shed-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
      'height' => 2.4,
      'structureCategory' => 'garage'
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal(
      %w[main_building outbuilding extension],
      result.dig(:refusal, :details, :allowedValues)
    )
  end

  def test_create_site_element_refuses_non_positive_structure_height
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'structure',
      'sourceElementId' => 'shed-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
      'height' => 0.0,
      'structureCategory' => 'outbuilding'
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_numeric_value', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_non_positive_pad_thickness
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'pad',
      'sourceElementId' => 'terrace-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]],
      'thickness' => 0.0
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_numeric_value', result.dig(:refusal, :code))
  end

  # rubocop:disable Layout/LineLength
  def test_set_entity_metadata_wraps_successful_mutation_in_one_operation_and_serializes_updated_object
    parent = Object.new
    entity = FakeManagedEntity.new(parent: parent)
    metadata_writer = FakeMetadataWriter.new(
      update_result: {
        outcome: 'ready',
        updates: { 'status' => 'existing' },
        clears: []
      }
    )
    serializer = FakeSerializer.new(
      sourceElementId: 'house-extension-001',
      semanticType: 'structure',
      status: 'existing'
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)

    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      serializer: serializer,
      target_resolver: target_resolver
    )
    result = commands.set_entity_metadata(
      'target' => { 'sourceElementId' => 'house-extension-001' },
      'set' => { 'status' => 'existing' },
      'clear' => []
    )

    assert_equal(true, result[:success])
    assert_equal('updated', result[:outcome])
    assert_equal(
      [[:start_operation, 'Set Entity Metadata', true], [:commit_operation]],
      @model.operations
    )
    assert_equal([{ 'sourceElementId' => 'house-extension-001' }], target_resolver.calls)
    assert_equal([[entity, { 'status' => 'existing' }, []]], metadata_writer.prepare_calls)
    assert_equal(
      [[entity, { outcome: 'ready', updates: { 'status' => 'existing' }, clears: [] }]],
      metadata_writer.apply_calls
    )
    assert_equal([entity], serializer.calls)
    assert_same(parent, entity.parent)
  end

  def test_set_entity_metadata_returns_structured_refusal_when_target_resolves_to_no_entity
    target_resolver = FakeTargetResolver.new(resolution: 'none')
    commands = SU_MCP::SemanticCommands.new(model: @model, target_resolver: target_resolver)

    result = commands.set_entity_metadata(
      'target' => { 'sourceElementId' => 'missing-element-001' },
      'set' => { 'status' => 'existing' }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('target_not_found', result.dig(:refusal, :code))
  end

  def test_set_entity_metadata_refuses_when_no_metadata_change_is_requested
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.set_entity_metadata('target' => { 'sourceElementId' => 'house-extension-001' })

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_metadata_change', result.dig(:refusal, :code))
    assert_equal('At least one metadata change is required.', result.dig(:refusal, :message))
    assert_equal([], @model.operations)
  end

  def test_set_entity_metadata_returns_structured_refusal_when_target_resolves_ambiguously
    target_resolver = FakeTargetResolver.new(resolution: 'ambiguous')
    commands = SU_MCP::SemanticCommands.new(model: @model, target_resolver: target_resolver)

    result = commands.set_entity_metadata(
      'target' => { 'sourceElementId' => 'duplicate-managed-001' },
      'set' => { 'status' => 'existing' }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('ambiguous_target', result.dig(:refusal, :code))
  end

  def test_set_entity_metadata_returns_structured_refusal_for_unmanaged_targets
    entity = FakeManagedEntity.new(parent: Object.new)
    metadata_writer = FakeMetadataWriter.new(
      update_result: {
        outcome: 'refused',
        refusal: { code: 'unmanaged_object', message: 'Entity is not a Managed Scene Object.' }
      }
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(
      'target' => { 'entityId' => '77' },
      'set' => { 'status' => 'existing' }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unmanaged_object', result.dig(:refusal, :code))
  end

  def test_set_entity_metadata_routes_metadata_policy_refusals_without_serializing_success
    entity = FakeManagedEntity.new(parent: Object.new)
    metadata_writer = FakeMetadataWriter.new(
      update_result: {
        outcome: 'refused',
        refusal: {
          code: 'protected_metadata_field',
          message: 'Field cannot be modified for a Managed Scene Object.'
        }
      }
    )
    serializer = FakeSerializer.new(sourceElementId: 'house-extension-001')
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      serializer: serializer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(
      'target' => { 'sourceElementId' => 'house-extension-001' },
      'set' => { 'sourceElementId' => 'house-extension-002' }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('protected_metadata_field', result.dig(:refusal, :code))
    assert_equal([], @model.operations)
    assert_equal([], serializer.calls)
  end
  # rubocop:enable Layout/LineLength
end
# rubocop:enable Metrics/MethodLength, Metrics/ClassLength
