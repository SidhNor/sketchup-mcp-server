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

  # rubocop:disable Metrics/MethodLength
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

  # rubocop:enable Metrics/MethodLength

  def test_delete_entities_allows_managed_scene_objects_backed_by_supported_targets
    @entity.set_attribute('su_mcp', 'sourceElementId', 'shed-001')

    result = @commands.delete_entities('targetReference' => { 'sourceElementId' => 'shed-001' })

    assert_equal(true, result[:success])
    assert_equal('shed-001', result.dig(:affectedEntities, :deleted, 0, :sourceElementId))
  end

  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength

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

  def test_transform_entities_uses_the_shared_adapter_for_entity_lookup
    result = @commands.transform_entities(
      'id' => '301',
      'position' => [1, 2, 3],
      'rotation' => [0, 0, 0],
      'scale' => [1, 1, 1]
    )

    assert_equal(true, result[:success])
    assert_equal(301, result[:id])
    assert_equal([[:find_entity!, '301']], @adapter.calls)
    refute_empty(@entity.transformations)
  end

  def test_apply_material_uses_the_shared_adapter_for_entity_lookup
    result = @commands.apply_material('id' => '301', 'material' => 'Walnut')

    assert_equal(true, result[:success])
    assert_equal('Walnut', @entity.material.display_name)
    assert_equal([:active_model!, [:find_entity!, '301']], @adapter.calls)
  end
end
