# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/semantic/hierarchy_maintenance_commands'

class HierarchyMaintenanceCommandsTest < Minitest::Test
  include SemanticTestSupport
  include SceneQueryTestSupport

  class FakeTargetResolver
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

  class FakeHierarchySerializer
    attr_reader :calls

    def initialize
      @calls = []
    end

    def serialize(entity)
      @calls << entity
      {
        sourceElementId: entity.get_attribute('su_mcp', 'sourceElementId'),
        persistentId: entity.respond_to?(:persistent_id) ? entity.persistent_id.to_s : nil,
        entityId: entity.entityID.to_s,
        type: entity.class.name.split('::').last.downcase,
        semanticType: entity.get_attribute('su_mcp', 'semanticType'),
        status: entity.get_attribute('su_mcp', 'status'),
        state: entity.get_attribute('su_mcp', 'state'),
        name: entity.respond_to?(:name) ? entity.name : nil,
        tag: entity.respond_to?(:layer) && entity.layer ? entity.layer.name : nil,
        childrenCount: children_count_for(entity)
      }.compact
    end

    private

    def children_count_for(entity)
      return 0 unless entity.respond_to?(:entities)

      children = entity.entities
      return children.groups.length if children.respond_to?(:groups)
      return children.length if children.respond_to?(:length)

      0
    end
  end

  class FakeRelocator
    attr_reader :calls

    def initialize(result: [])
      @result = result
      @calls = []
    end

    def relocate(entities:, parent:)
      @calls << { entities: entities, parent: parent }
      @result
    end
  end

  def setup
    @model = build_semantic_model
    @layer = @model.layers.first
    @material = @model.materials.to_a.first
  end

  def test_create_group_creates_an_empty_root_container_in_one_operation
    commands = build_commands

    result = commands.create_group({})

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(
      [[:start_operation, 'Create Group', true], [:commit_operation]],
      @model.operations
    )
  end

  def test_create_group_can_use_an_explicit_parent_target
    parent_group = @model.active_entities.add_group
    resolver = FakeTargetResolver.new({ resolution: 'unique', entity: parent_group })
    commands = build_commands(target_resolver: resolver)

    result = commands.create_group(
      'parent' => { 'persistentId' => parent_group.persistent_id.to_s }
    )

    assert_equal('created', result[:outcome])
    assert_equal([{ 'persistentId' => parent_group.persistent_id.to_s }], resolver.calls)
  end

  def test_create_group_can_group_supplied_children_atomically
    child_group = managed_group('tree-001')
    relocator = FakeRelocator.new(result: [child_group])
    commands = build_commands(
      target_resolver: FakeTargetResolver.new({ resolution: 'unique', entity: child_group }),
      relocator: relocator
    )

    result = commands.create_group('children' => [{ 'sourceElementId' => 'tree-001' }])

    assert_equal('created', result[:outcome])
    assert_equal(1, relocator.calls.length)
    assert_equal('tree-001', result.fetch(:children).first.fetch(:sourceElementId))
  end

  def test_create_group_with_real_relocator_groups_children_without_raising
    child_group = @model.active_entities.add_group
    metadata_writer = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata_writer.write!(
      child_group,
      'sourceElementId' => 'tree-001',
      'semanticType' => 'tree_proxy',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )
    commands = SU_MCP::HierarchyMaintenanceCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new({ resolution: 'unique', entity: child_group }),
      serializer: FakeHierarchySerializer.new
    )

    result = commands.create_group('children' => [{ 'sourceElementId' => 'tree-001' }])

    assert_equal('created', result[:outcome])
    assert_equal(1, result.fetch(:children).length)
    assert_equal(1, @model.active_entities.groups.length)
    assert_equal('tree-001', result.fetch(:children).first.fetch(:sourceElementId))
  end

  def test_create_group_can_create_a_managed_container_when_metadata_is_supplied
    commands = build_commands

    result = commands.create_group(
      'metadata' => {
        'sourceElementId' => 'built-form-cluster-001',
        'status' => 'proposed'
      }
    )

    assert_equal('created', result[:outcome])
    assert_equal('built-form-cluster-001', result.dig(:group, :sourceElementId))
    assert_equal('grouped_feature', result.dig(:group, :semanticType))
    assert_equal('proposed', result.dig(:group, :status))
    assert_equal('Created', result.dig(:group, :state))
  end

  def test_create_group_can_apply_scene_properties_to_a_managed_container
    commands = build_commands

    result = commands.create_group(
      'metadata' => {
        'sourceElementId' => 'built-form-cluster-001',
        'status' => 'proposed'
      },
      'sceneProperties' => {
        'name' => 'Built Form Cluster',
        'tag' => 'Structures'
      }
    )

    assert_equal('Built Form Cluster', result.dig(:group, :name))
    assert_equal('Structures', result.dig(:group, :tag))
  end

  def test_create_group_refuses_managed_container_without_source_element_id
    commands = build_commands

    result = commands.create_group(
      'metadata' => {
        'status' => 'proposed'
      }
    )

    assert_equal('refused', result[:outcome])
    assert_equal('missing_required_field', result.dig(:refusal, :code))
    assert_equal('metadata.sourceElementId', result.dig(:refusal, :details, :field))
  end

  def test_create_group_refuses_managed_container_without_status
    commands = build_commands

    result = commands.create_group(
      'metadata' => {
        'sourceElementId' => 'built-form-cluster-001'
      }
    )

    assert_equal('refused', result[:outcome])
    assert_equal('missing_required_field', result.dig(:refusal, :code))
    assert_equal('metadata.status', result.dig(:refusal, :details, :field))
  end

  def test_create_group_refuses_unsupported_managed_container_metadata_fields
    commands = build_commands

    result = commands.create_group(
      'metadata' => {
        'sourceElementId' => 'built-form-cluster-001',
        'status' => 'proposed',
        'semanticType' => 'structure'
      }
    )

    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal('metadata.semanticType', result.dig(:refusal, :details, :field))
  end

  def test_reparent_entities_can_move_supported_entities_under_an_explicit_parent
    child_group = managed_group('tree-001')
    parent_group = @model.active_entities.add_group
    relocator = FakeRelocator.new(result: [child_group])
    commands = build_commands(
      target_resolver: FakeTargetResolver.new(
        { resolution: 'unique', entity: parent_group },
        { resolution: 'unique', entity: child_group }
      ),
      relocator: relocator
    )

    result = commands.reparent_entities(
      'parent' => { 'persistentId' => parent_group.persistent_id.to_s },
      'entities' => [{ 'sourceElementId' => 'tree-001' }]
    )

    assert_equal('reparented', result[:outcome])
    assert_equal(1, relocator.calls.length)
  end

  def test_reparent_entities_with_real_relocator_moves_supported_entities
    parent_group = @model.active_entities.add_group
    child_group = managed_semantic_group('tree-001', semantic_type: 'tree_proxy')
    commands = SU_MCP::HierarchyMaintenanceCommands.new(
      model: @model,
      target_resolver: FakeTargetResolver.new(
        { resolution: 'unique', entity: parent_group },
        { resolution: 'unique', entity: child_group }
      ),
      serializer: FakeHierarchySerializer.new
    )

    result = commands.reparent_entities(
      'parent' => { 'persistentId' => parent_group.persistent_id.to_s },
      'entities' => [{ 'sourceElementId' => 'tree-001' }]
    )

    assert_equal('reparented', result[:outcome])
    assert_equal(1, parent_group.entities.groups.length)
    relocated_child = parent_group.entities.groups.first
    assert_equal('tree-001', relocated_child.get_attribute('su_mcp', 'sourceElementId'))
  end

  def test_reparent_entities_can_move_supported_entities_to_model_root
    child_group = managed_group('root-target-001')
    relocator = FakeRelocator.new(result: [child_group])
    commands = build_commands(
      target_resolver: FakeTargetResolver.new({ resolution: 'unique', entity: child_group }),
      relocator: relocator
    )

    result = commands.reparent_entities('entities' => [{ 'sourceElementId' => 'root-target-001' }])

    assert_equal('reparented', result[:outcome])
    assert_nil(relocator.calls.first.fetch(:parent))
  end

  def test_grouping_and_reparenting_preserve_managed_child_identity
    child_group = managed_group('managed-child-001')
    relocator = FakeRelocator.new(result: [child_group])
    commands = build_commands(
      target_resolver: FakeTargetResolver.new({ resolution: 'unique', entity: child_group }),
      relocator: relocator
    )

    result = commands.reparent_entities(
      'entities' => [{ 'sourceElementId' => 'managed-child-001' }]
    )

    assert_equal('managed-child-001', result.fetch(:entities).first.fetch(:sourceElementId))
  end

  def test_reparent_entities_refuses_duplicate_target_references
    commands = build_commands

    result = commands.reparent_entities(
      'entities' => [
        { 'sourceElementId' => 'duplicate-001' },
        { 'sourceElementId' => 'duplicate-001' }
      ]
    )

    assert_equal('refused', result[:outcome])
    assert_equal('duplicate_target_reference', result.dig(:refusal, :code))
  end

  def test_reparent_entities_refuses_unsupported_raw_geometry
    face = build_sample_surface_face(
      entity_id: 601,
      persistent_id: 6001,
      name: 'Loose Face',
      layer: @layer,
      material: @material,
      x_range: [0.0, 1.0],
      y_range: [0.0, 1.0],
      z_value: 0.0
    )
    commands = build_commands(
      target_resolver: FakeTargetResolver.new({ resolution: 'unique', entity: face })
    )

    result = commands.reparent_entities('entities' => [{ 'persistentId' => '6001' }])

    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_entity_type', result.dig(:refusal, :code))
  end

  def test_create_group_refuses_invalid_or_ambiguous_parent_references
    commands = build_commands(
      target_resolver: FakeTargetResolver.new({ resolution: 'ambiguous' })
    )

    result = commands.create_group('parent' => { 'sourceElementId' => 'ambiguous-parent-001' })

    assert_equal('refused', result[:outcome])
    assert_equal('ambiguous_target', result.dig(:refusal, :code))
  end

  def test_reparent_entities_refuses_cyclic_parent_relationships
    child_group = managed_group('cycle-001')
    commands = build_commands(
      target_resolver: FakeTargetResolver.new(
        { resolution: 'unique', entity: child_group },
        { resolution: 'unique', entity: child_group }
      )
    )

    result = commands.reparent_entities(
      'parent' => { 'sourceElementId' => 'cycle-001' },
      'entities' => [{ 'sourceElementId' => 'cycle-001' }]
    )

    assert_equal('refused', result[:outcome])
    assert_equal('cyclic_reparent', result.dig(:refusal, :code))
  end

  def test_reparent_entities_refuses_descendant_parent_cycles
    parent_group = @model.active_entities.add_group
    descendant_group = parent_group.entities.add_group
    commands = build_commands(
      target_resolver: FakeTargetResolver.new(
        { resolution: 'unique', entity: descendant_group },
        { resolution: 'unique', entity: parent_group }
      )
    )

    result = commands.reparent_entities(
      'parent' => { 'persistentId' => descendant_group.persistent_id.to_s },
      'entities' => [{ 'persistentId' => parent_group.persistent_id.to_s }]
    )

    assert_equal('refused', result[:outcome])
    assert_equal('cyclic_reparent', result.dig(:refusal, :code))
  end

  def test_create_group_matches_the_shared_success_envelope_shape
    commands = build_commands

    result = commands.create_group({})

    assert_equal(
      SU_MCP::ToolResponse.success(
        outcome: 'created',
        group: result.fetch(:group),
        children: result.fetch(:children)
      ),
      result
    )
  end

  def test_create_group_aborts_operation_when_relocation_raises
    child_group = managed_group('raise-001')
    relocator = Class.new do
      def relocate(**_kwargs)
        raise 'relocation failed'
      end
    end.new
    commands = build_commands(
      target_resolver: FakeTargetResolver.new({ resolution: 'unique', entity: child_group }),
      relocator: relocator
    )

    assert_raises(RuntimeError) do
      commands.create_group('children' => [{ 'sourceElementId' => 'raise-001' }])
    end
    assert_includes(@model.operations, [:abort_operation])
  end

  private

  def build_commands(
    target_resolver: FakeTargetResolver.new,
    relocator: FakeRelocator.new(result: [])
  )
    SU_MCP::HierarchyMaintenanceCommands.new(
      model: @model,
      target_resolver: target_resolver,
      relocator: relocator,
      serializer: FakeHierarchySerializer.new
    )
  end

  def managed_group(source_element_id)
    build_sample_surface_group(
      entity_id: 701,
      persistent_id: 7001,
      name: 'Managed Wrapper',
      layer: @layer,
      material: @material,
      child_faces: [],
      source_element_id: source_element_id
    )
  end

  def managed_semantic_group(source_element_id, semantic_type:)
    group = @model.active_entities.add_group
    SU_MCP::Semantic::ManagedObjectMetadata.new.write!(
      group,
      'sourceElementId' => source_element_id,
      'semanticType' => semantic_type,
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )
    group
  end
end
