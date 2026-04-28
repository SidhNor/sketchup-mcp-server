# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/editing/editing_commands'

class EditingCommandsTest < Minitest::Test
  include SceneQueryTestSupport
  include SemanticTestSupport

  class FakeTargetResolver
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def resolve(target_reference)
      @calls << target_reference
      @result
    end
  end

  class RecordingAdapter
    attr_reader :calls

    def initialize(model:, entity:, all_entities_recursive: nil)
      @model = model
      @entity = entity
      @all_entities_recursive = all_entities_recursive || [entity]
      @calls = []
    end

    def active_model!
      @calls << :active_model!
      @model
    end

    def find_entity!(id)
      @calls << [:find_entity!, id]
      @entity
    end

    def all_entities_recursive
      @calls << :all_entities_recursive
      @all_entities_recursive
    end
  end

  class RecordingLengthConverter
    attr_reader :calls

    def initialize(multiplier: 100.0)
      @multiplier = multiplier
      @calls = []
    end

    def public_meters_to_internal(value)
      @calls << value
      value.to_f * @multiplier
    end
  end

  def setup
    @mutation_model = build_mutation_model
    @entity = @mutation_model.entities.first
    @adapter = RecordingAdapter.new(
      model: @mutation_model,
      entity: @entity
    )
    @commands = SU_MCP::EditingCommands.new(model_adapter: @adapter)
  end

  def test_delete_entities_deletes_a_supported_group_by_target_reference
    result = @commands.delete_entities('targetReference' => { 'entityId' => '301' })

    assert_equal(true, result[:success])
    assert_equal('deleted', result[:outcome])
    assert_equal(true, @entity.erased?)
    assert_equal('Delete Entities', result.dig(:operation, :name))
    assert_equal('group', result.dig(:operation, :targetKind))
    assert_equal('301', result.dig(:affectedEntities, :deleted, 0, :entityId))
    assert_equal(%i[all_entities_recursive active_model!], @adapter.calls)
  end

  def test_delete_entities_deletes_a_supported_component_instance
    model = build_mutation_model
    layer = model.layers.first
    material = model.materials.to_a.first
    component = build_scene_query_component(
      entity_id: 401,
      origin_x: 0,
      layer: layer,
      material: material,
      details: { persistent_id: 4001, name: 'Component Target' }
    )
    adapter = RecordingAdapter.new(
      model: model,
      entity: component,
      all_entities_recursive: [component]
    )
    commands = SU_MCP::EditingCommands.new(model_adapter: adapter)

    result = commands.delete_entities('targetReference' => { 'persistentId' => '4001' })

    assert_equal(true, result[:success])
    assert_equal(true, component.erased?)
    assert_equal('componentinstance', result.dig(:operation, :targetKind))
    assert_equal('4001', result.dig(:affectedEntities, :deleted, 0, :persistentId))
  end

  def test_delete_entities_allows_managed_scene_objects_backed_by_supported_targets
    @entity.set_attribute('su_mcp', 'sourceElementId', 'shed-001')

    result = @commands.delete_entities('targetReference' => { 'sourceElementId' => 'shed-001' })

    assert_equal(true, result[:success])
    assert_equal('shed-001', result.dig(:affectedEntities, :deleted, 0, :sourceElementId))
  end

  def test_delete_entities_refuses_unsupported_target_types
    model = build_mutation_model
    layer = model.layers.first
    material = model.materials.to_a.first
    face = build_scene_query_face(
      entity_id: 777,
      origin_x: 0,
      layer: layer,
      material: material,
      details: { name: 'Face Target', persistent_id: 7007 }
    )
    commands = SU_MCP::EditingCommands.new(
      model_adapter: RecordingAdapter.new(
        model: model,
        entity: face,
        all_entities_recursive: [face]
      )
    )

    result = commands.delete_entities('targetReference' => { 'entityId' => '777' })

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_target_type', result.dig(:refusal, :code))
  end

  def test_delete_entities_refuses_missing_targets
    resolver = FakeTargetResolver.new(result: { resolution: 'none' })
    commands = SU_MCP::EditingCommands.new(model_adapter: @adapter, target_resolver: resolver)

    result = commands.delete_entities('targetReference' => { 'entityId' => '999' })

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('target_not_found', result.dig(:refusal, :code))
  end

  def test_delete_entities_refuses_ambiguous_targets
    resolver = FakeTargetResolver.new(result: { resolution: 'ambiguous' })
    commands = SU_MCP::EditingCommands.new(model_adapter: @adapter, target_resolver: resolver)

    result = commands.delete_entities('targetReference' => { 'sourceElementId' => 'duplicate-001' })

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('ambiguous_target', result.dig(:refusal, :code))
  end

  def test_delete_entities_rejects_unsupported_ambiguity_policy_values
    error = assert_raises(RuntimeError) do
      @commands.delete_entities(
        'targetReference' => { 'entityId' => '301' },
        'constraints' => { 'ambiguityPolicy' => 'pick_first' }
      )
    end

    assert_equal('Unsupported ambiguityPolicy: pick_first', error.message)
  end

  def test_transform_entities_uses_canonical_target_reference_lookup
    result = @commands.transform_entities(
      'targetReference' => { 'entityId' => '301' },
      'position' => [1, 2, 3],
      'rotation' => [0, 0, 0],
      'scale' => [1, 1, 1]
    )

    assert_equal(true, result[:success])
    assert_equal('transformed', result[:outcome])
    refute_includes(result.keys, :id)
    assert_equal('301', result[:entityId])
    assert_equal('1001', result[:persistentId])
    assert_nil(result[:managedObject])
    assert_equal(%i[all_entities_recursive active_model!], @adapter.calls)
    assert_equal(
      [[:start_operation, 'Transform Entities', true], [:commit_operation]],
      @mutation_model.operations
    )
    refute_empty(@entity.transformations)
  end

  def test_transform_entities_converts_public_meter_translation_to_internal_units
    converter = RecordingLengthConverter.new(multiplier: 39.37)
    commands = SU_MCP::EditingCommands.new(
      model_adapter: @adapter,
      length_converter: converter
    )

    result = commands.transform_entities(
      'targetReference' => { 'entityId' => '301' },
      'position' => [1.0, 2.0, 3.0]
    )

    assert_equal(true, result[:success])
    assert_equal([1.0, 2.0, 3.0], converter.calls)
    refute_empty(@entity.transformations)
  end

  def test_apply_material_uses_canonical_target_reference_lookup
    result = @commands.apply_material(
      'targetReference' => { 'entityId' => '301' },
      'material' => 'Walnut'
    )

    assert_equal(true, result[:success])
    assert_equal('material_applied', result[:outcome])
    refute_includes(result.keys, :id)
    assert_equal('301', result[:entityId])
    assert_equal('1001', result[:persistentId])
    assert_nil(result[:managedObject])
    assert_equal('Walnut', @entity.material.display_name)
    assert_equal(%i[all_entities_recursive active_model!], @adapter.calls)
    assert_equal(
      [[:start_operation, 'Set Entity Material', true], [:commit_operation]],
      @mutation_model.operations
    )
  end

  def test_transform_entities_supports_managed_targets_resolved_by_target_reference
    @entity.set_attribute('su_mcp', 'managedSceneObject', true)
    @entity.set_attribute('su_mcp', 'sourceElementId', 'shed-001')
    @entity.set_attribute('su_mcp', 'semanticType', 'structure')
    @entity.set_attribute('su_mcp', 'status', 'existing')
    @entity.set_attribute('su_mcp', 'state', 'Created')
    result = @commands.transform_entities(
      'targetReference' => { 'sourceElementId' => 'shed-001' },
      'position' => [1, 2, 3]
    )

    assert_equal(true, result[:success])
    assert_equal('transformed', result[:outcome])
    refute_includes(result.keys, :id)
    assert_equal('301', result[:entityId])
    assert_equal('1001', result[:persistentId])
    assert_equal('shed-001', result.dig(:managedObject, :sourceElementId))
    assert_equal('structure', result.dig(:managedObject, :semanticType))
    assert_equal(%i[all_entities_recursive active_model!], @adapter.calls)
    assert_equal(
      [[:start_operation, 'Transform Entities', true], [:commit_operation]],
      @mutation_model.operations
    )
  end

  def test_transform_entities_refuses_when_no_target_selector_is_provided
    result = @commands.transform_entities('position' => [1, 2, 3])

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_target', result.dig(:refusal, :code))
    assert_equal('targetReference', result.dig(:refusal, :details, :field))
  end

  def test_transform_entities_refuses_legacy_top_level_id
    result = @commands.transform_entities(
      'id' => '301',
      'position' => [1, 2, 3]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_request_field', result.dig(:refusal, :code))
    assert_equal('id', result.dig(:refusal, :details, :field))
    assert_equal(['targetReference'], result.dig(:refusal, :details, :allowedFields))
  end

  def test_transform_entities_refuses_ambiguous_target_references
    resolver = FakeTargetResolver.new(result: { resolution: 'ambiguous' })
    commands = SU_MCP::EditingCommands.new(model_adapter: @adapter, target_resolver: resolver)

    result = commands.transform_entities(
      'targetReference' => { 'sourceElementId' => 'duplicate-001' },
      'position' => [1, 2, 3]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('ambiguous_target', result.dig(:refusal, :code))
  end

  def test_apply_material_supports_managed_targets_resolved_by_target_reference
    @entity.set_attribute('su_mcp', 'managedSceneObject', true)
    @entity.set_attribute('su_mcp', 'sourceElementId', 'shed-001')
    @entity.set_attribute('su_mcp', 'semanticType', 'structure')
    @entity.set_attribute('su_mcp', 'status', 'existing')
    @entity.set_attribute('su_mcp', 'state', 'Created')

    result = @commands.apply_material(
      'targetReference' => { 'sourceElementId' => 'shed-001' },
      'material' => 'Walnut'
    )

    assert_equal(true, result[:success])
    assert_equal('material_applied', result[:outcome])
    refute_includes(result.keys, :id)
    assert_equal('301', result[:entityId])
    assert_equal('1001', result[:persistentId])
    assert_equal('shed-001', result.dig(:managedObject, :sourceElementId))
    assert_equal('Walnut', @entity.material.display_name)
    assert_equal(%i[all_entities_recursive active_model!], @adapter.calls)
    assert_equal(
      [[:start_operation, 'Set Entity Material', true], [:commit_operation]],
      @mutation_model.operations
    )
  end

  def test_apply_material_refuses_when_no_target_selector_is_provided
    result = @commands.apply_material('material' => 'Walnut')

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_target', result.dig(:refusal, :code))
    assert_equal('targetReference', result.dig(:refusal, :details, :field))
  end

  def test_apply_material_refuses_legacy_top_level_id
    result = @commands.apply_material(
      'id' => '301',
      'material' => 'Walnut'
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_request_field', result.dig(:refusal, :code))
    assert_equal('id', result.dig(:refusal, :details, :field))
  end

  def test_transform_entities_refuses_unsupported_target_reference_fields
    result = @commands.transform_entities(
      'targetReference' => { 'legacyId' => '301' },
      'position' => [1, 2, 3]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_request_field', result.dig(:refusal, :code))
    assert_equal('targetReference.legacyId', result.dig(:refusal, :details, :field))
    assert_equal(%w[sourceElementId persistentId entityId],
                 result.dig(:refusal, :details, :allowedFields))
  end
end
