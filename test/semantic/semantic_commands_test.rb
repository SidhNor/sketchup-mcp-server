# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/ClassLength

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/semantic/hierarchy_maintenance_commands'
require_relative '../../src/su_mcp/semantic/semantic_commands'

class SemanticCommandsTest < Minitest::Test
  include SemanticTestSupport
  include SceneQueryTestSupport

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
      if entity.respond_to?(:set_attribute)
        entity.set_attribute('su_mcp', 'managedSceneObject', true)
        attributes.each do |key, value|
          entity.set_attribute('su_mcp', key, value)
        end
      end
      entity
    end

    def attributes_for(entity)
      return {} unless entity.respond_to?(:attributes)

      entity.attributes.fetch('su_mcp', {}).dup
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

  class FakeSequentialTargetResolver
    attr_reader :calls

    def initialize(*results)
      @results = results
      @calls = []
    end

    def resolve(query)
      @calls << query
      @results.fetch(@calls.length - 1)
    end
  end

  class FakeManagedEntity
    attr_reader :parent, :attributes

    def initialize(parent:, attributes: {}, locked: false, erase_error: nil)
      @parent = parent
      @locked = locked
      @erase_error = erase_error
      @erased = false
      @attributes = Hash.new { |hash, key| hash[key] = {} }
      attributes.each do |dictionary, values|
        @attributes[dictionary] = values.dup
      end
    end

    def set_attribute(dictionary_name, key, value)
      @attributes[dictionary_name][key] = value
    end

    def get_attribute(dictionary_name, key, default = nil)
      @attributes.fetch(dictionary_name, {}).fetch(key, default)
    end

    def delete_attribute(dictionary_name, key = nil)
      return @attributes.delete(dictionary_name) if key.nil?

      @attributes.fetch(dictionary_name, {}).delete(key)
    end

    def locked?
      @locked
    end

    def erase!
      raise @erase_error if @erase_error

      @erased = true
      self
    end

    def erased?
      @erased
    end
  end

  class FakeNonWritableParent < Sketchup::Group
    attr_reader :entities

    def initialize(entities:)
      super()
      @entities = entities
    end
  end

  def setup
    @model = build_semantic_model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_create_site_element_wraps_successful_creation_in_one_operation
    created_group = @model.active_entities.add_group
    request = sectioned_terrain_path_request('hosting' => { 'mode' => 'none' })
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
          'sourceElementId' => 'main-garden-walk-001',
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
    request = sectioned_terrain_path_request('hosting' => { 'mode' => 'none' })
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
      captured_params.dig('definition', 'centerline')
    )
    assert_in_delta(1.6 * METERS_TO_INTERNAL, captured_params.dig('definition', 'width'), 1e-9)
    assert_in_delta(0.1 * METERS_TO_INTERNAL, captured_params.dig('definition', 'thickness'), 1e-9)
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

    result = commands.create_site_element(sectioned_tree_proxy_request('definition' => nil))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_required_field', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_flat_legacy_create_shape_before_builder_execution
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
    assert_equal('missing_required_field', result.dig(:refusal, :code))
    assert_equal([], registry.calls)
  end

  def test_create_site_element_recovers_definition_wrapped_requests_into_canonical_builder_execution
    built_entity = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    captured_params = nil
    builder.define_singleton_method(:build) do |model:, destination:, params:|
      _ = [model, destination]
      captured_params = params
      built_entity
    end
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'tree-001', semanticType: 'tree_proxy')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      serializer: serializer
    )

    result = commands.create_site_element('definition' => sectioned_tree_proxy_request)

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['tree_proxy'], registry.calls)
    assert_equal('tree_proxy', captured_params['elementType'])
    refute(captured_params.dig('definition', 'elementType'))
  end

  def test_create_site_element_refuses_ambiguous_misnested_geometry_before_builder_execution
    built_entity = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |model:, destination:, params:|
      _ = [model, destination, params]
      built_entity
    end
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'shed-001', semanticType: 'structure')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      serializer: serializer
    )
    request = sectioned_structure_request
    request['height'] = 3.2

    result = commands.create_site_element(request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('malformed_request_shape', result.dig(:refusal, :code))
    assert_equal([], registry.calls)
  end

  # rubocop:disable Metrics/AbcSize
  def test_create_site_element_recovers_wrapped_misnested_geometry_into_canonical_builder_execution
    built_entity = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    captured_params = nil
    builder.define_singleton_method(:build) do |model:, destination:, params:|
      _ = [model, destination]
      captured_params = params
      built_entity
    end
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'walk-001', semanticType: 'path')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      serializer: serializer
    )
    wrapped_request = sectioned_terrain_path_request
    wrapped_request['hosting'] = { 'mode' => 'none' }
    definition = wrapped_request.delete('definition')
    wrapped_request.merge!(definition)

    result = commands.create_site_element('definition' => wrapped_request)

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['path'], registry.calls)
    assert_equal('centerline', captured_params.dig('definition', 'mode'))
    refute(captured_params.key?('mode'))
  end
  # rubocop:enable Metrics/AbcSize

  def test_create_site_element_refuses_ambiguous_wrapped_misnested_geometry_before_builder_execution
    built_entity = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |model:, destination:, params:|
      _ = [model, destination, params]
      built_entity
    end
    registry = FakeRegistry.new(builder)
    commands = SU_MCP::SemanticCommands.new(model: @model, registry: registry)
    wrapped_request = sectioned_terrain_path_request
    wrapped_request['width'] = 3.2

    result = commands.create_site_element('definition' => wrapped_request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('malformed_request_shape', result.dig(:refusal, :code))
    assert_equal([], registry.calls)
  end

  def test_create_site_element_refuses_invalid_path_geometry_before_builder_execution
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(sectioned_terrain_path_request(
                                            'definition' => {
                                              'mode' => 'centerline',
                                              'centerline' => [[0.0, 0.0], [0.0, 0.0]],
                                              'width' => 1.6
                                            }
                                          ))

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

    result = commands.create_site_element(sectioned_structure_request(
                                            'definition' => {
                                              'mode' => 'footprint_mass',
                                              'footprint' => [
                                                [0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]
                                              ],
                                              'height' => 2.4,
                                              'structureCategory' => nil
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_required_field', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_unapproved_structure_categories
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(sectioned_structure_request(
                                            'definition' => {
                                              'mode' => 'footprint_mass',
                                              'footprint' => [
                                                [0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]
                                              ],
                                              'height' => 2.4,
                                              'structureCategory' => 'garage'
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal(
      %w[main_building outbuilding extension],
      result.dig(:refusal, :details, :allowedValues)
    )
  end

  def test_create_site_element_unsupported_hosting_mode_exposes_contextual_allowed_values
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(
        resolution: 'unique',
        entity: FakeManagedEntity.new(parent: Object.new)
      )
    )

    result = commands.create_site_element(sectioned_terrain_path_request(
                                            'hosting' => {
                                              'mode' => 'edge_clamp',
                                              'target' => { 'persistentId' => '4001' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_hosting_mode', result.dig(:refusal, :code))
    assert_equal('hosting', result.dig(:refusal, :details, :section))
    assert_equal('edge_clamp', result.dig(:refusal, :details, :mode))
    assert_equal('path', result.dig(:refusal, :details, :elementType))
    assert_equal(['surface_drape'], result.dig(:refusal, :details, :allowedValues))
  end

  def test_set_entity_metadata_uses_the_shared_refusal_envelope_for_missing_mutations
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.set_entity_metadata('target' => { 'sourceElementId' => 'structure-001' })

    assert_equal(
      SU_MCP::ToolResponse.refusal(
        code: 'missing_metadata_change',
        message: 'At least one metadata change is required.'
      ),
      result
    )
  end

  def test_create_site_element_refuses_non_positive_structure_height
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(sectioned_structure_request(
                                            'definition' => {
                                              'mode' => 'footprint_mass',
                                              'footprint' => [
                                                [0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]
                                              ],
                                              'height' => 0.0,
                                              'structureCategory' => 'outbuilding'
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_numeric_value', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_non_positive_pad_thickness
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(sectioned_pad_request(
                                            'definition' => {
                                              'mode' => 'polygon',
                                              'footprint' => [
                                                [0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]
                                              ],
                                              'thickness' => 0.0
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_numeric_value', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_non_finite_pad_elevation
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(sectioned_pad_request(
                                            'definition' => {
                                              'mode' => 'polygon',
                                              'footprint' => [
                                                [0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]
                                              ],
                                              'elevation' => 'not-a-number',
                                              'thickness' => 0.2
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_numeric_value', result.dig(:refusal, :code))
    assert_equal('definition.elevation', result.dig(:refusal, :details, :field))
  end

  # rubocop:disable Metrics/AbcSize, Layout/LineLength

  def test_create_site_element_adopts_existing_structure_without_builder_execution
    target_entity = FakeManagedEntity.new(parent: Object.new)
    metadata_writer = FakeMetadataWriter.new
    serializer = FakeSerializer.new(sourceElementId: 'retained-house-001', semanticType: 'structure')
    registry = FakeRegistry.new(Object.new)
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: target_entity)

    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: metadata_writer,
      serializer: serializer,
      target_resolver: target_resolver
    )

    result = commands.create_site_element(v2_structure_adopt_request)

    assert_equal(true, result[:success])
    assert_equal('adopted', result[:outcome])
    assert_equal([], registry.calls)
    assert_equal([{ 'entityId' => 'existing-structure-77' }], target_resolver.calls)
    assert_equal('retained-house-001', metadata_writer.calls.first.last['sourceElementId'])
    assert_equal('structure', metadata_writer.calls.first.last['semanticType'])
    assert_equal('retained', metadata_writer.calls.first.last['status'])
    assert_equal('main_building', metadata_writer.calls.first.last['structureCategory'])
    assert_equal([target_entity], serializer.calls)
  end

  def test_create_site_element_refuses_adopt_when_target_is_missing
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(resolution: 'none')
    )

    result = commands.create_site_element(v2_structure_adopt_request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('target_not_found', result.dig(:refusal, :code))
    assert_equal('lifecycle', result.dig(:refusal, :details, :section))
  end

  def test_create_site_element_builds_terrain_following_path_with_resolved_hosting_context
    created_group = @model.active_entities.add_group
    captured_params = nil
    host_target = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    metadata_writer = FakeMetadataWriter.new
    serializer = FakeSerializer.new(sourceElementId: 'main-garden-walk-001', semanticType: 'path')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: metadata_writer,
      serializer: serializer,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: host_target)
    )

    result = commands.create_site_element(v2_terrain_path_request)

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['path'], registry.calls)
    assert_equal(
      [{ 'sourceElementId' => 'terrain-main' }],
      commands.send(:target_resolver).calls
    )
    assert_in_delta(1.6 * METERS_TO_INTERNAL, captured_params.dig('definition', 'width'), 1e-9)
    assert_in_delta(0.1 * METERS_TO_INTERNAL, captured_params.dig('definition', 'thickness'), 1e-9)
    assert_same(host_target, captured_params.dig('hosting', 'resolved_target'))
    assert_equal('surface_drape', captured_params.dig('hosting', 'mode'))
    assert_equal('main-garden-walk-001', metadata_writer.calls.first.last['sourceElementId'])
    assert_equal([created_group], serializer.calls)
  end

  def test_create_site_element_refuses_terrain_path_when_host_target_is_missing
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(resolution: 'none')
    )

    result = commands.create_site_element(v2_terrain_path_request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('target_not_found', result.dig(:refusal, :code))
    assert_equal('hosting', result.dig(:refusal, :details, :section))
  end

  def test_create_site_element_refuses_surface_drape_path_when_terrain_sampling_misses
    terrain_target = build_sample_surface_face(
      entity_id: 501,
      persistent_id: 5001,
      source_element_id: 'terrain-main',
      name: 'Short Terrain',
      layer: SceneQueryTestSupport::FakeLayer.new('Terrain'),
      material: SceneQueryTestSupport::FakeMaterial.new('Soil'),
      x_range: [0.0, 4.0],
      y_range: [-1.0, 1.0],
      z_value: 1.0
    )
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: terrain_target)
    )

    result = commands.create_site_element(sectioned_terrain_path_request(
                                            'definition' => {
                                              'mode' => 'centerline',
                                              'centerline' => [[0.0, 0.0], [10.0, 0.0]],
                                              'width' => 1.6,
                                              'thickness' => 0.1
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('terrain_sample_miss', result.dig(:refusal, :code))
    assert_equal('hosting', result.dig(:refusal, :details, :section))
  end

  def test_create_site_element_builds_terrain_anchored_tree_with_resolved_hosting_context
    created_group = @model.active_entities.add_group
    captured_params = nil
    host_target = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: FakeRegistry.new(builder),
      metadata_writer: FakeMetadataWriter.new,
      serializer: FakeSerializer.new(sourceElementId: 'tree-001', semanticType: 'tree_proxy'),
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: host_target)
    )

    result = commands.create_site_element(sectioned_tree_proxy_request(
                                            'hosting' => {
                                              'mode' => 'terrain_anchored',
                                              'target' => { 'sourceElementId' => 'terrain-main' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_same(host_target, captured_params.dig('hosting', 'resolved_target'))
    assert_equal('terrain_anchored', captured_params.dig('hosting', 'mode'))
  end

  def test_create_site_element_builds_terrain_anchored_structure_with_resolved_hosting_context
    created_group = @model.active_entities.add_group
    captured_params = nil
    host_target = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: FakeRegistry.new(builder),
      metadata_writer: FakeMetadataWriter.new,
      serializer: FakeSerializer.new(sourceElementId: 'shed-001', semanticType: 'structure'),
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: host_target)
    )

    result = commands.create_site_element(sectioned_structure_request(
                                            'hosting' => {
                                              'mode' => 'terrain_anchored',
                                              'target' => { 'sourceElementId' => 'terrain-main' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_same(host_target, captured_params.dig('hosting', 'resolved_target'))
    assert_equal('terrain_anchored', captured_params.dig('hosting', 'mode'))
  end

  def test_create_site_element_replace_preserve_identity_resolves_terrain_hosting_context
    previous_entity = FakeManagedEntity.new(
      parent: Object.new,
      attributes: {
        'su_mcp' => {
          'sourceElementId' => 'house-extension-001',
          'semanticType' => 'structure',
          'status' => 'existing',
          'state' => 'Created',
          'schemaVersion' => 1,
          'structureCategory' => 'extension'
        }
      }
    )
    host_target = FakeManagedEntity.new(parent: Object.new)
    parent_group = @model.active_entities.add_group
    replacement_entity = FakeManagedEntity.new(parent: parent_group)
    captured_params = nil
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      replacement_entity
    end
    target_resolver = FakeSequentialTargetResolver.new(
      { resolution: 'unique', entity: previous_entity },
      { resolution: 'unique', entity: host_target },
      { resolution: 'unique', entity: parent_group }
    )
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: FakeRegistry.new(builder),
      metadata_writer: FakeMetadataWriter.new,
      serializer: FakeSerializer.new(sourceElementId: 'house-extension-001', semanticType: 'structure'),
      target_resolver: target_resolver
    )

    result = commands.create_site_element(v2_replace_request.merge(
                                            'hosting' => {
                                              'mode' => 'terrain_anchored',
                                              'target' => { 'sourceElementId' => 'terrain-main' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('replaced', result[:outcome])
    assert_equal(
      [
        { 'entityId' => 'existing-structure-77' },
        { 'sourceElementId' => 'terrain-main' },
        { 'entityId' => 'parent-group-22' }
      ],
      target_resolver.calls
    )
    assert_same(host_target, captured_params.dig('hosting', 'resolved_target'))
    assert_equal('terrain_anchored', captured_params.dig('hosting', 'mode'))
  end

  def test_create_site_element_replaces_managed_object_while_preserving_identity_and_parent_context
    old_parent = @model.active_entities.add_group
    target_entity = FakeManagedEntity.new(
      parent: old_parent,
      attributes: {
        'su_mcp' => {
          'managedSceneObject' => true,
          'sourceElementId' => 'house-extension-001',
          'semanticType' => 'structure',
          'status' => 'existing',
          'state' => 'Created',
          'schemaVersion' => 1,
          'structureCategory' => 'extension'
        }
      }
    )
    replacement_entity = FakeManagedEntity.new(parent: old_parent)
    builder = Object.new
    builder.define_singleton_method(:build) { |**_kwargs| replacement_entity }
    registry = FakeRegistry.new(builder)
    metadata_writer = FakeMetadataWriter.new
    serializer = FakeSerializer.new(sourceElementId: 'house-extension-001', semanticType: 'structure')
    target_resolver = FakeSequentialTargetResolver.new(
      { resolution: 'unique', entity: target_entity },
      { resolution: 'unique', entity: old_parent }
    )
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: metadata_writer,
      serializer: serializer,
      target_resolver: target_resolver
    )

    result = commands.create_site_element(v2_replace_request)

    assert_equal(true, result[:success])
    assert_equal('replaced', result[:outcome])
    assert_equal(
      [
        { 'entityId' => 'existing-structure-77' },
        { 'entityId' => 'parent-group-22' }
      ],
      target_resolver.calls
    )
    assert_equal('house-extension-001', metadata_writer.calls.first.last['sourceElementId'])
    assert_equal('existing', metadata_writer.calls.first.last['status'])
    assert_equal('extension', metadata_writer.calls.first.last['structureCategory'])
    assert_equal([replacement_entity], serializer.calls)
  end

  def test_create_site_element_inserts_structure_under_resolved_group_parent_context
    parent_group = @model.active_entities.add_group
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: parent_group)
    )

    result = commands.create_site_element(sectioned_structure_request(
                                            'placement' => {
                                              'mode' => 'parented',
                                              'parent' => { 'entityId' => 'parent-group-22' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(1, @model.active_entities.groups.length)
    assert_equal(1, parent_group.entities.groups.length)
    assert_equal('shed-001', parent_group.entities.groups.first.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_create_site_element_inserts_structure_under_resolved_component_parent_context
    component_parent = build_component_parent_instance
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: component_parent)
    )

    result = commands.create_site_element(sectioned_structure_request(
                                            'placement' => {
                                              'mode' => 'parented',
                                              'parent' => { 'entityId' => 'component-parent-11' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(0, @model.active_entities.groups.length)
    assert_equal(1, component_parent.definition.entities.groups.length)
    assert_equal(
      'shed-001',
      component_parent.definition.entities.groups.first.get_attribute('su_mcp', 'sourceElementId')
    )
  end

  def test_create_site_element_refuses_parented_create_when_parent_destination_is_not_writable
    build_called = false
    model = @model
    builder = Object.new
    builder.define_singleton_method(:build) do |**_kwargs|
      build_called = true
      model.active_entities.add_group
    end
    registry = FakeRegistry.new(builder)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      target_resolver: FakeTargetResolver.new(
        resolution: 'unique',
        entity: FakeNonWritableParent.new(entities: build_non_writable_collection)
      )
    )

    result = commands.create_site_element(sectioned_structure_request(
                                            'placement' => {
                                              'mode' => 'parented',
                                              'parent' => { 'entityId' => 'non-writable-parent-11' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('placement', result.dig(:refusal, :details, :section))
    assert_equal(false, build_called)
    assert_equal([], registry.calls)
  end

  def test_create_site_element_replace_without_explicit_parent_uses_target_parent_context
    parent_group = @model.active_entities.add_group
    previous_entity = parent_group.entities.add_group
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata_writer.write!(
      previous_entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'existing',
      'state' => 'Created',
      'schemaVersion' => 1,
      'structureCategory' => 'extension'
    )
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      serializer: SU_MCP::Semantic::Serializer.new,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: previous_entity)
    )

    result = commands.create_site_element(v2_replace_request_without_explicit_parent)

    assert_equal(true, result[:success])
    assert_equal('replaced', result[:outcome])
    assert_equal(true, previous_entity.erased?)
    assert_equal(1, parent_group.entities.groups.length)
    assert_equal('house-extension-001', parent_group.entities.groups.first.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_create_site_element_replace_uses_explicit_parent_override_when_supplied
    old_parent = @model.active_entities.add_group
    new_parent = @model.active_entities.add_group
    previous_entity = old_parent.entities.add_group
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata_writer.write!(
      previous_entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'existing',
      'state' => 'Created',
      'schemaVersion' => 1,
      'structureCategory' => 'extension'
    )
    target_resolver = FakeSequentialTargetResolver.new(
      { resolution: 'unique', entity: previous_entity },
      { resolution: 'unique', entity: new_parent }
    )
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      serializer: SU_MCP::Semantic::Serializer.new,
      target_resolver: target_resolver
    )

    result = commands.create_site_element(v2_replace_request)

    assert_equal(true, result[:success])
    assert_equal('replaced', result[:outcome])
    assert_equal(true, previous_entity.erased?)
    assert_empty(old_parent.entities.groups)
    assert_equal(1, new_parent.entities.groups.length)
    assert_equal('house-extension-001', new_parent.entities.groups.first.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_create_site_element_refuses_replace_when_target_is_locked
    target_entity = FakeManagedEntity.new(
      parent: Object.new,
      locked: true,
      attributes: {
        'su_mcp' => {
          'managedSceneObject' => true,
          'sourceElementId' => 'house-extension-001',
          'semanticType' => 'structure',
          'status' => 'existing',
          'state' => 'Created',
          'schemaVersion' => 1,
          'structureCategory' => 'extension'
        }
      }
    )
    build_called = false
    builder = Object.new
    builder.define_singleton_method(:build) { |**_kwargs| build_called = true }
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: FakeRegistry.new(builder),
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: target_entity)
    )

    result = commands.create_site_element(v2_replace_request_without_explicit_parent)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('lifecycle', result.dig(:refusal, :details, :section))
    assert_equal(false, build_called)
  end

  def test_create_site_element_creates_supported_surface_drape_path_inside_parent_destination_context
    host_target = build_sample_surface_group(
      entity_id: 601,
      persistent_id: 6001,
      name: 'Terrain Host',
      layer: SceneQueryTestSupport::FakeLayer.new('Terrain'),
      material: SceneQueryTestSupport::FakeMaterial.new('Soil'),
      child_faces: [
        build_sample_surface_face(
          entity_id: 602,
          persistent_id: 6002,
          name: 'Terrain Face',
          layer: SceneQueryTestSupport::FakeLayer.new('Terrain'),
          material: SceneQueryTestSupport::FakeMaterial.new('Soil'),
          x_range: [-2.0 * METERS_TO_INTERNAL, 10.0 * METERS_TO_INTERNAL],
          y_range: [-3.0 * METERS_TO_INTERNAL, 4.0 * METERS_TO_INTERNAL],
          z_value: 0.0,
          source_element_id: 'terrain-main'
        )
      ],
      source_element_id: 'terrain-main'
    )
    parent_group = @model.active_entities.add_group
    target_resolver = FakeSequentialTargetResolver.new(
      { resolution: 'unique', entity: host_target },
      { resolution: 'unique', entity: parent_group }
    )
    commands = SU_MCP::SemanticCommands.new(model: @model, target_resolver: target_resolver)

    result = commands.create_site_element(sectioned_terrain_path_request(
                                            'placement' => {
                                              'mode' => 'parented',
                                              'parent' => { 'entityId' => 'parent-group-22' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(1, parent_group.entities.groups.length)
    assert_equal('main-garden-walk-001',
                 parent_group.entities.groups.first.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_create_site_element_can_create_a_child_under_a_managed_container_created_by_create_group
    hierarchy_commands = SU_MCP::HierarchyMaintenanceCommands.new(model: @model)
    create_group_result = hierarchy_commands.create_group(
      'metadata' => {
        'sourceElementId' => 'built-form-cluster-001',
        'status' => 'proposed'
      },
      'sceneProperties' => {
        'name' => 'Built Form Cluster',
        'tag' => 'Structures'
      }
    )
    container = @model.active_entities.groups.first
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: container)
    )

    result = commands.create_site_element(sectioned_structure_request(
                                            'metadata' => {
                                              'sourceElementId' => 'house-extension-001',
                                              'status' => 'proposed'
                                            },
                                            'placement' => {
                                              'mode' => 'parented',
                                              'parent' => {
                                                'persistentId' => container.persistent_id.to_s
                                              }
                                            }
                                          ))

    assert_equal('built-form-cluster-001', create_group_result.dig(:group, :sourceElementId))
    assert_equal('grouped_feature', container.get_attribute('su_mcp', 'semanticType'))
    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(1, container.entities.groups.length)
    assert_equal('house-extension-001',
                 container.entities.groups.first.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_create_site_element_refuses_unsupported_hosted_execution_combination
    build_called = false
    model = @model
    builder = Object.new
    builder.define_singleton_method(:build) do |**_kwargs|
      build_called = true
      model.active_entities.add_group
    end
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: FakeRegistry.new(builder),
      target_resolver: FakeTargetResolver.new(
        resolution: 'unique',
        entity: @model.active_entities.add_group
      )
    )

    result = commands.create_site_element(sectioned_structure_request(
                                            'hosting' => {
                                              'mode' => 'surface_drape',
                                              'target' => { 'entityId' => 'terrain-main' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('hosting', result.dig(:refusal, :details, :section))
    assert_equal(false, build_called)
  end

  def test_create_site_element_unsupported_hosting_mode_allowed_values_reflect_contextual_matrix
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(
        resolution: 'unique',
        entity: @model.active_entities.add_group
      )
    )

    pad_result = commands.create_site_element(sectioned_pad_request(
                                                'hosting' => {
                                                  'mode' => 'terrain_anchored',
                                                  'target' => { 'sourceElementId' => 'terrain-main' }
                                                }
                                              ))
    tree_result = commands.create_site_element(sectioned_tree_proxy_request(
                                                 'hosting' => {
                                                   'mode' => 'surface_snap',
                                                   'target' => { 'sourceElementId' => 'terrain-main' }
                                                 }
                                               ))
    structure_result = commands.create_site_element(sectioned_structure_request(
                                                      'hosting' => {
                                                        'mode' => 'surface_snap',
                                                        'target' => { 'sourceElementId' => 'terrain-main' }
                                                      }
                                                    ))

    assert_equal('unsupported_hosting_mode', pad_result.dig(:refusal, :code))
    assert_equal(['surface_snap'], pad_result.dig(:refusal, :details, :allowedValues))
    assert_equal(['terrain_anchored'], tree_result.dig(:refusal, :details, :allowedValues))
    assert_equal(['terrain_anchored'], structure_result.dig(:refusal, :details, :allowedValues))
  end

  def test_create_site_element_aborts_and_cleans_up_replacement_when_old_entity_erase_fails
    parent_group = @model.active_entities.add_group
    previous_entity = parent_group.entities.add_group
    previous_entity.instance_variable_set(:@erase_error, RuntimeError.new('erase failed'))
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata_writer.write!(
      previous_entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'existing',
      'state' => 'Created',
      'schemaVersion' => 1,
      'structureCategory' => 'extension'
    )
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      serializer: SU_MCP::Semantic::Serializer.new,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: previous_entity)
    )

    error = assert_raises(RuntimeError) do
      commands.create_site_element(v2_replace_request_without_explicit_parent)
    end

    assert_equal('erase failed', error.message)
    assert_equal([[:start_operation, 'Create Site Element', true], [:abort_operation]], @model.operations)
    assert_equal(1, parent_group.entities.groups.length)
    assert_same(previous_entity, parent_group.entities.groups.first)
  end

  def test_create_site_element_replace_hybrid_uses_real_target_resolution_and_metadata_handoff
    Sketchup.active_model_override = build_v2_replace_target_model
    created_group = @model.active_entities.add_group
    captured_params = nil
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: SU_MCP::Semantic::ManagedObjectMetadata.new,
      serializer: SU_MCP::Semantic::Serializer.new,
      target_resolver: SU_MCP::TargetReferenceResolver.new
    )

    result = commands.create_site_element(v2_replace_request_for_real_targeting)

    assert_equal(true, result[:success])
    assert_equal('replaced', result[:outcome])
    assert_equal(['structure'], registry.calls)
    assert_equal('house-extension-001', result.dig(:managedObject, :sourceElementId))
    assert_equal('structure', result.dig(:managedObject, :semanticType))
    assert_equal('Replaced', created_group.get_attribute('su_mcp', 'state'))
    assert_equal('house-extension-001', created_group.get_attribute('su_mcp', 'sourceElementId'))
    assert_equal('existing', created_group.get_attribute('su_mcp', 'status'))
    assert_equal('extension', created_group.get_attribute('su_mcp', 'structureCategory'))
    assert_equal('parented', captured_params.dig('placement', 'mode'))
    assert_equal('replace_preserve_identity', captured_params.dig('lifecycle', 'mode'))
    assert_equal('house-extension-001', captured_params.dig('lifecycle', 'resolved_target')
      .get_attribute('su_mcp', 'sourceElementId'))
    assert_equal('parent-group-22', captured_params.dig('placement', 'resolved_parent')
      .get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_create_site_element_refuses_replace_when_parent_target_is_ambiguous
    target_entity = FakeManagedEntity.new(parent: Object.new)
    target_resolver = FakeSequentialTargetResolver.new(
      { resolution: 'unique', entity: target_entity },
      { resolution: 'ambiguous' }
    )
    commands = SU_MCP::SemanticCommands.new(model: @model, target_resolver: target_resolver)

    result = commands.create_site_element(v2_replace_request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('ambiguous_target', result.dig(:refusal, :code))
    assert_equal('placement', result.dig(:refusal, :details, :section))
  end

  def test_create_site_element_routes_sectioned_path_requests_without_contract_version
    created_group = @model.active_entities.add_group
    captured_params = nil
    host_target = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    metadata_writer = FakeMetadataWriter.new
    serializer = FakeSerializer.new(sourceElementId: 'main-garden-walk-001', semanticType: 'path')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: metadata_writer,
      serializer: serializer,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: host_target)
    )

    result = commands.create_site_element(sectioned_terrain_path_request)

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['path'], registry.calls)
    assert_in_delta(1.6 * METERS_TO_INTERNAL, captured_params.dig('definition', 'width'), 1e-9)
    assert_equal('Sectioned Walk', captured_params.dig('sceneProperties', 'name'))
    assert_equal('Gravel', captured_params.dig('representation', 'material'))
    assert_equal(1.6, metadata_writer.calls.first.last['width'])
    assert_equal(0.1, metadata_writer.calls.first.last['thickness'])
  end

  def test_create_site_element_refuses_transitional_remaining_family_modes
    commands = SU_MCP::SemanticCommands.new(model: @model)
    requests = [
      sectioned_pad_request('definition' => { 'mode' => 'footprint_surface' }),
      sectioned_retaining_edge_request('definition' => { 'mode' => 'wall_profile' }),
      sectioned_planting_mass_request('definition' => { 'mode' => 'boundary_mass' }),
      sectioned_tree_proxy_request('definition' => { 'mode' => 'proxy_tree' })
    ]

    requests.each do |request|
      result = commands.create_site_element(request)

      assert_equal(true, result[:success])
      assert_equal('refused', result[:outcome])
      assert_equal('unsupported_option', result.dig(:refusal, :code))
      assert_equal('definition.mode', result.dig(:refusal, :details, :field))
      assert_equal(request.dig('definition', 'mode'), result.dig(:refusal, :details, :value))
    end
  end

  def test_create_site_element_routes_sectioned_pad_requests_directly_to_builder_native_definition
    created_group = @model.active_entities.add_group
    captured_params = nil
    host_target = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'terrace-001', semanticType: 'pad')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: FakeMetadataWriter.new,
      serializer: serializer,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: host_target)
    )

    result = commands.create_site_element(sectioned_pad_request(
                                            'definition' => {
                                              'elevation' => 0.35
                                            },
                                            'hosting' => {
                                              'mode' => 'surface_snap',
                                              'target' => { 'sourceElementId' => 'terrain-main' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['pad'], registry.calls)
    assert_equal('Sectioned Terrace', captured_params.dig('sceneProperties', 'name'))
    assert_equal('Hardscape', captured_params.dig('sceneProperties', 'tag'))
    assert_equal('Concrete', captured_params.dig('representation', 'material'))
    assert_equal('polygon', captured_params.dig('definition', 'mode'))
    assert_same(host_target, captured_params.dig('hosting', 'resolved_target'))
    assert_in_delta(0.35 * METERS_TO_INTERNAL, captured_params.dig('definition', 'elevation'), 1e-9)
    assert_equal(
      [[0.0, 0.0], [3.0 * METERS_TO_INTERNAL, 0.0],
       [3.0 * METERS_TO_INTERNAL, 2.0 * METERS_TO_INTERNAL],
       [0.0, 2.0 * METERS_TO_INTERNAL]],
      captured_params.dig('definition', 'footprint')
    )
  end

  def test_create_site_element_routes_sectioned_retaining_edge_requests_directly_to_builder_native_definition
    created_group = @model.active_entities.add_group
    captured_params = nil
    host_target = FakeManagedEntity.new(parent: Object.new)
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'ret-edge-001', semanticType: 'retaining_edge')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: FakeMetadataWriter.new,
      serializer: serializer,
      target_resolver: FakeTargetResolver.new(resolution: 'unique', entity: host_target)
    )

    result = commands.create_site_element(sectioned_retaining_edge_request(
                                            'definition' => {
                                              'elevation' => 0.15
                                            },
                                            'hosting' => {
                                              'mode' => 'edge_clamp',
                                              'target' => { 'sourceElementId' => 'edge-main' }
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['retaining_edge'], registry.calls)
    assert_equal('polyline', captured_params.dig('definition', 'mode'))
    assert_equal('Stone', captured_params.dig('representation', 'material'))
    assert_same(host_target, captured_params.dig('hosting', 'resolved_target'))
    assert_in_delta(0.15 * METERS_TO_INTERNAL, captured_params.dig('definition', 'elevation'), 1e-9)
    assert_equal(
      [[2.0 * METERS_TO_INTERNAL, 0.0], [8.0 * METERS_TO_INTERNAL, 0.0],
       [8.0 * METERS_TO_INTERNAL, 4.0 * METERS_TO_INTERNAL]],
      captured_params.dig('definition', 'polyline')
    )
  end

  def test_create_site_element_routes_sectioned_planting_mass_requests_directly_to_builder_native_definition
    created_group = @model.active_entities.add_group
    captured_params = nil
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'hedge-001', semanticType: 'planting_mass')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: FakeMetadataWriter.new,
      serializer: serializer
    )

    result = commands.create_site_element(sectioned_planting_mass_request)

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['planting_mass'], registry.calls)
    assert_equal('mass_polygon', captured_params.dig('definition', 'mode'))
    assert_equal('Hedge Mass', captured_params.dig('sceneProperties', 'name'))
    assert_equal(
      [[0.0, 0.0], [4.0 * METERS_TO_INTERNAL, 0.0],
       [4.0 * METERS_TO_INTERNAL, 2.0 * METERS_TO_INTERNAL],
       [0.0, 2.0 * METERS_TO_INTERNAL]],
      captured_params.dig('definition', 'boundary')
    )
  end

  def test_create_site_element_routes_sectioned_tree_proxy_requests_directly_to_builder_native_definition
    created_group = @model.active_entities.add_group
    captured_params = nil
    builder = Object.new
    builder.define_singleton_method(:build) do |**kwargs|
      captured_params = kwargs.fetch(:params)
      created_group
    end
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'tree-001', semanticType: 'tree_proxy')
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      metadata_writer: FakeMetadataWriter.new,
      serializer: serializer
    )

    result = commands.create_site_element(sectioned_tree_proxy_request(
                                            'definition' => {
                                              'canopyDiameterY' => nil
                                            }
                                          ))

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(['tree_proxy'], registry.calls)
    assert_equal('generated_proxy', captured_params.dig('definition', 'mode'))
    assert_equal('Cherry Proxy', captured_params.dig('sceneProperties', 'name'))
    assert_in_delta(
      6.0 * METERS_TO_INTERNAL,
      captured_params.dig('definition', 'canopyDiameterY'),
      1e-9
    )
  end

  # rubocop:enable Metrics/AbcSize, Layout/LineLength

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

  def test_create_site_element_unsupported_type_refusal_matches_shared_contract
    contract_case = contract_cases_by_id.fetch('create_site_element_unsupported_type_refused')
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(contract_case.dig('request', 'params', 'arguments'))

    assert_equal(contract_case.dig('response', 'result'), normalized_result(result))
  end

  def test_set_entity_metadata_missing_change_refusal_matches_shared_contract
    contract_case = contract_cases_by_id.fetch('set_entity_metadata_missing_change_refused')
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.set_entity_metadata(contract_case.dig('request', 'params', 'arguments'))

    assert_equal(contract_case.dig('response', 'result'), normalized_result(result))
  end

  def test_set_entity_metadata_required_clear_refusal_matches_shared_contract
    contract_case = contract_cases_by_id.fetch('set_entity_metadata_required_clear_refused')
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    entity = @model.active_entities.add_group
    metadata_writer.write!(
      entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'structureCategory' => 'extension'
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(contract_case.dig('request', 'params', 'arguments'))

    assert_equal(contract_case.dig('response', 'result'), normalized_result(result))
  end

  def test_set_entity_metadata_invalid_structure_category_refusal_matches_shared_contract
    contract_case = contract_cases_by_id.fetch('set_entity_metadata_invalid_structure_category_refused')
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    entity = @model.active_entities.add_group
    metadata_writer.write!(
      entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'structureCategory' => 'extension'
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(contract_case.dig('request', 'params', 'arguments'))

    assert_equal(contract_case.dig('response', 'result'), normalized_result(result))
  end

  def test_set_entity_metadata_updates_supported_planting_category_and_serializes_updated_object
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    entity = @model.active_entities.add_group
    metadata_writer.write!(
      entity,
      'sourceElementId' => 'hedge-001',
      'semanticType' => 'planting_mass',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'plantingCategory' => 'hedge'
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(
      'target' => { 'sourceElementId' => 'hedge-001' },
      'set' => { 'plantingCategory' => 'groundcover' }
    )

    assert_equal(true, result[:success])
    assert_equal('updated', result[:outcome])
    assert_equal(
      [[:start_operation, 'Set Entity Metadata', true], [:commit_operation]],
      @model.operations
    )
    assert_equal('groundcover', result.dig(:managedObject, :plantingCategory))
  end

  def test_set_entity_metadata_updates_supported_species_hint_and_serializes_updated_object
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    entity = @model.active_entities.add_group
    metadata_writer.write!(
      entity,
      'sourceElementId' => 'tree-001',
      'semanticType' => 'tree_proxy',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'speciesHint' => 'cherry'
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(
      'target' => { 'sourceElementId' => 'tree-001' },
      'set' => { 'speciesHint' => 'plum' }
    )

    assert_equal(true, result[:success])
    assert_equal('updated', result[:outcome])
    assert_equal(
      [[:start_operation, 'Set Entity Metadata', true], [:commit_operation]],
      @model.operations
    )
    assert_equal('plum', result.dig(:managedObject, :speciesHint))
  end

  def test_set_entity_metadata_updates_status_for_grouped_feature_containers
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    entity = @model.active_entities.add_group
    metadata_writer.write!(
      entity,
      'sourceElementId' => 'built-form-cluster-001',
      'semanticType' => 'grouped_feature',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(
      'target' => { 'sourceElementId' => 'built-form-cluster-001' },
      'set' => { 'status' => 'existing' }
    )

    assert_equal(true, result[:success])
    assert_equal('updated', result[:outcome])
    assert_equal('existing', result.dig(:managedObject, :status))
  end

  def test_set_entity_metadata_planting_category_update_matches_shared_contract
    contract_case = contract_cases_by_id.fetch('set_entity_metadata_planting_category_updated')
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    entity = @model.active_entities.add_group
    metadata_writer.write!(
      entity,
      'sourceElementId' => 'hedge-001',
      'semanticType' => 'planting_mass',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'plantingCategory' => 'hedge'
    )
    target_resolver = FakeTargetResolver.new(resolution: 'unique', entity: entity)
    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      metadata_writer: metadata_writer,
      target_resolver: target_resolver
    )

    result = commands.set_entity_metadata(contract_case.dig('request', 'params', 'arguments'))

    assert_equal(contract_case.dig('response', 'result'), normalized_result(result))
  end
  # rubocop:enable Layout/LineLength

  private

  def normalized_result(result)
    JSON.parse(JSON.generate(result))
  end

  def contract_cases_by_id
    @contract_cases_by_id ||= begin
      contract_path = File.expand_path('../support/semantic_contract_cases.json', __dir__)
      JSON
        .parse(File.read(contract_path, encoding: 'utf-8'))
        .fetch('cases')
        .to_h { |entry| [entry.fetch('case_id'), entry] }
    end
  end

  def v2_structure_adopt_request
    {
      'contractVersion' => 2,
      'elementType' => 'structure',
      'metadata' => {
        'sourceElementId' => 'retained-house-001',
        'status' => 'retained'
      },
      'definition' => {
        'mode' => 'adopt_reference',
        'structureCategory' => 'main_building'
      },
      'placement' => {
        'mode' => 'preserve_existing'
      },
      'hosting' => {
        'mode' => 'none'
      },
      'representation' => {
        'mode' => 'adopted'
      },
      'lifecycle' => {
        'mode' => 'adopt_existing',
        'target' => { 'entityId' => 'existing-structure-77' }
      }
    }
  end

  def v2_terrain_path_request
    {
      'contractVersion' => 2,
      'elementType' => 'path',
      'metadata' => {
        'sourceElementId' => 'main-garden-walk-001',
        'status' => 'proposed'
      },
      'definition' => {
        'mode' => 'centerline',
        'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
        'width' => 1.6,
        'thickness' => 0.1
      },
      'placement' => {
        'mode' => 'host_resolved'
      },
      'hosting' => {
        'mode' => 'surface_drape',
        'target' => { 'sourceElementId' => 'terrain-main' }
      },
      'representation' => {
        'mode' => 'path_surface_proxy'
      },
      'lifecycle' => {
        'mode' => 'create_new'
      }
    }
  end

  def v2_replace_request
    {
      'contractVersion' => 2,
      'elementType' => 'structure',
      'metadata' => {
        'status' => 'existing'
      },
      'definition' => {
        'mode' => 'footprint_mass',
        'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
        'height' => 2.4,
        'structureCategory' => 'extension'
      },
      'placement' => {
        'mode' => 'parented',
        'parent' => { 'entityId' => 'parent-group-22' }
      },
      'hosting' => {
        'mode' => 'none'
      },
      'representation' => {
        'mode' => 'procedural'
      },
      'lifecycle' => {
        'mode' => 'replace_preserve_identity',
        'target' => { 'entityId' => 'existing-structure-77' }
      }
    }
  end

  def v2_replace_request_without_explicit_parent
    request = Marshal.load(Marshal.dump(v2_replace_request))
    request['placement'] = { 'mode' => 'parented' }
    request
  end

  def v2_replace_request_for_real_targeting
    {
      'contractVersion' => 2,
      'elementType' => 'structure',
      'metadata' => {
        'status' => 'existing'
      },
      'definition' => {
        'mode' => 'footprint_mass',
        'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
        'height' => 2.4,
        'structureCategory' => 'extension'
      },
      'placement' => {
        'mode' => 'parented',
        'parent' => { 'sourceElementId' => 'parent-group-22' }
      },
      'hosting' => {
        'mode' => 'none'
      },
      'representation' => {
        'mode' => 'procedural'
      },
      'lifecycle' => {
        'mode' => 'replace_preserve_identity',
        'target' => { 'sourceElementId' => 'house-extension-001' }
      }
    }
  end

  def sectioned_terrain_path_request(overrides = {})
    request = deep_merge(
      v2_terrain_path_request.reject { |key, _value| key == 'contractVersion' },
      overrides
    )
    request['hosting'].delete('target') if request.dig('hosting', 'mode') == 'none'
    request['sceneProperties'] ||= {}
    request['sceneProperties']['name'] ||= 'Sectioned Walk'
    request['sceneProperties']['tag'] ||= 'Paths'
    request['representation'] ||= {}
    request['representation']['material'] ||= 'Gravel'
    request
  end

  def sectioned_structure_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'structure',
        'metadata' => {
          'sourceElementId' => 'shed-001',
          'status' => 'proposed'
        },
        'definition' => {
          'mode' => 'footprint_mass',
          'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
          'height' => 2.4,
          'structureCategory' => 'outbuilding'
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => { 'mode' => 'procedural' },
        'lifecycle' => { 'mode' => 'create_new' }
      },
      overrides
    )
  end

  def sectioned_tree_proxy_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'tree_proxy',
        'metadata' => {
          'sourceElementId' => 'tree-001',
          'status' => 'proposed'
        },
        'sceneProperties' => {
          'name' => 'Cherry Proxy',
          'tag' => 'Trees'
        },
        'definition' => {
          'mode' => 'generated_proxy',
          'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
          'canopyDiameterX' => 6.0,
          'canopyDiameterY' => 5.6,
          'height' => 5.5,
          'trunkDiameter' => 0.45
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => { 'mode' => 'proxy_mass' },
        'lifecycle' => { 'mode' => 'create_new' }
      },
      overrides
    )
  end

  def sectioned_pad_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'pad',
        'metadata' => {
          'sourceElementId' => 'terrace-001',
          'status' => 'proposed'
        },
        'sceneProperties' => {
          'name' => 'Sectioned Terrace',
          'tag' => 'Hardscape'
        },
        'definition' => {
          'mode' => 'polygon',
          'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]],
          'thickness' => 0.2
        },
        'hosting' => {
          'mode' => 'none'
        },
        'placement' => {
          'mode' => 'host_resolved'
        },
        'representation' => {
          'mode' => 'procedural',
          'material' => 'Concrete'
        },
        'lifecycle' => {
          'mode' => 'create_new'
        }
      },
      overrides
    )
  end

  def sectioned_retaining_edge_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'retaining_edge',
        'metadata' => {
          'sourceElementId' => 'ret-edge-001',
          'status' => 'proposed'
        },
        'sceneProperties' => {
          'tag' => 'Edges'
        },
        'definition' => {
          'mode' => 'polyline',
          'polyline' => [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
          'height' => 0.45,
          'thickness' => 0.2
        },
        'hosting' => {
          'mode' => 'none'
        },
        'placement' => {
          'mode' => 'host_resolved'
        },
        'representation' => {
          'mode' => 'procedural',
          'material' => 'Stone'
        },
        'lifecycle' => {
          'mode' => 'create_new'
        }
      },
      overrides
    )
  end

  def sectioned_planting_mass_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'planting_mass',
        'metadata' => {
          'sourceElementId' => 'hedge-001',
          'status' => 'proposed'
        },
        'sceneProperties' => {
          'name' => 'Hedge Mass'
        },
        'definition' => {
          'mode' => 'mass_polygon',
          'boundary' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
          'averageHeight' => 1.8,
          'plantingCategory' => 'hedge'
        },
        'hosting' => {
          'mode' => 'none'
        },
        'placement' => {
          'mode' => 'host_resolved'
        },
        'representation' => {
          'mode' => 'procedural'
        },
        'lifecycle' => {
          'mode' => 'create_new'
        }
      },
      overrides
    )
  end

  def deep_merge(base, overrides)
    return base unless overrides.is_a?(Hash)

    base.merge(overrides) do |_key, left, right|
      left.is_a?(Hash) && right.is_a?(Hash) ? deep_merge(left, right) : right
    end
  end

  def build_v2_replace_target_model
    layer = FakeLayer.new('Structures')
    material = FakeMaterial.new('Timber')
    writable_entities = SemanticTestSupport::FakeEntitiesCollection.new(
      id_sequence: SemanticTestSupport::IdSequence.new,
      layer: layer,
      material: material
    )
    target_entity = build_scene_query_group(
      entity_id: 777,
      origin_x: 12,
      layer: layer,
      material: material,
      details: {
        name: 'Existing Extension',
        persistent_id: 7007,
        entities: [],
        attributes: {
          'su_mcp' => {
            'managedSceneObject' => true,
            'sourceElementId' => 'house-extension-001',
            'semanticType' => 'structure',
            'status' => 'existing',
            'state' => 'Created',
            'schemaVersion' => 1,
            'structureCategory' => 'extension'
          }
        }
      }
    )
    parent_group = build_scene_query_group(
      entity_id: 722,
      origin_x: 10,
      layer: layer,
      material: material,
      details: {
        name: 'Parent Group',
        persistent_id: 7001,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'parent-group-22' } },
        entities: writable_entities
      }
    )
    writable_entities.owner = parent_group
    writable_entities.groups << target_entity

    SceneQueryTestSupport::FakeModel.new(
      state: {
        entities: [parent_group],
        active_entities: [],
        selection: [],
        materials: [material],
        layers: [layer],
        bounds: build_bounds(origin_x: -5)
      },
      details: { options: default_options }
    )
  end

  def build_component_parent_instance
    component_entities = SemanticTestSupport::FakeEntitiesCollection.new(
      id_sequence: SemanticTestSupport::IdSequence.new,
      layer: @model.layers.first,
      material: @model.materials.to_a.first
    )
    definition = SceneQueryTestSupport::FakeComponentDefinition.new(
      name: 'Parent Component',
      entities: component_entities
    )
    component_entities.owner = definition
    @model.active_entities.add_instance(definition)
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/ClassLength
