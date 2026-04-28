# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/tool_dispatcher'

class ToolDispatcherTest < Minitest::Test
  class CommandTarget
    attr_reader :calls

    def initialize
      @calls = []
    end

    def get_scene_info(args)
      @calls << [:get_scene_info, args]
      { success: true, scene: args.fetch('scene') }
    end

    def transform_entities(args)
      @calls << [:transform_entities, args]
      {
        success: true,
        outcome: 'transformed',
        entityId: args.dig('targetReference', 'entityId'),
        managedObject: nil
      }
    end

    def selection_info
      @calls << [:selection_info, nil]
      { success: true, selection: [] }
    end

    def find_entities(args)
      @calls << [:find_entities, args]
      { success: true, resolution: 'unique', matches: [args.fetch('targetSelector')] }
    end

    def validate_scene_update(args)
      @calls << [:validate_scene_update, args]
      { success: true, outcome: 'passed', errors: [], warnings: [], summary: {} }
    end

    def measure_scene(args)
      @calls << [:measure_scene, args]
      { success: true, outcome: 'measured', measurement: args }
    end

    def delete_entities(args)
      @calls << [:delete_entities, args]
      {
        success: true,
        outcome: 'deleted',
        affectedEntities: { deleted: [args.fetch('targetReference')] }
      }
    end

    def create_group(args)
      @calls << [:create_group, args]
      {
        success: true,
        outcome: 'created',
        group: { entityId: '42', type: 'group' }
      }
    end

    def reparent_entities(args)
      @calls << [:reparent_entities, args]
      {
        success: true,
        outcome: 'reparented',
        entities: args.fetch('entities')
      }
    end

    def sample_surface_z(args)
      @calls << [:sample_surface_z, args]
      {
        success: true,
        results: [{ samplePoint: args.fetch('sampling').fetch('points').first, status: 'hit' }]
      }
    end

    def create_site_element(args)
      @calls << [:create_site_element, args]
      {
        success: true,
        outcome: 'created',
        managedObject: { sourceElementId: args.fetch('sourceElementId') }
      }
    end

    def create_terrain_surface(args)
      @calls << [:create_terrain_surface, args]
      {
        success: true,
        outcome: 'created',
        managedTerrain: {
          ownerReference: { sourceElementId: args.dig('metadata', 'sourceElementId') }
        }
      }
    end

    def edit_terrain_surface(args)
      @calls << [:edit_terrain_surface, args]
      {
        success: true,
        outcome: 'edited',
        managedTerrain: {
          ownerReference: { sourceElementId: args.dig('targetReference', 'sourceElementId') }
        }
      }
    end

    def curate_staged_asset(args)
      @calls << [:curate_staged_asset, args]
      {
        success: true,
        outcome: 'curated',
        asset: { sourceElementId: args.dig('metadata', 'sourceElementId') }
      }
    end

    def list_staged_assets(args)
      @calls << [:list_staged_assets, args]
      {
        success: true,
        count: 0,
        assets: [],
        filters: args.fetch('filters', {})
      }
    end

    # rubocop:disable Naming/AccessorMethodName
    def set_entity_metadata(args)
      @calls << [:set_entity_metadata, args]
      {
        success: true,
        outcome: 'updated',
        managedObject: { sourceElementId: args.dig('target', 'sourceElementId') }
      }
    end

    def apply_material(args)
      @calls << [:apply_material, args]
      {
        success: true,
        outcome: 'material_applied',
        entityId: args.dig('targetReference', 'entityId'),
        managedObject: nil
      }
    end
    # rubocop:enable Naming/AccessorMethodName

    private :get_scene_info, :transform_entities, :selection_info, :find_entities,
            :validate_scene_update, :measure_scene,
            :delete_entities,
            :sample_surface_z,
            :create_group, :reparent_entities, :create_site_element, :create_terrain_surface,
            :edit_terrain_surface,
            :curate_staged_asset, :list_staged_assets,
            :set_entity_metadata, :apply_material
  end

  def setup
    @target = CommandTarget.new
    @dispatcher = SU_MCP::ToolDispatcher.new(command_target: @target)
  end

  def test_dispatches_supported_tool_to_matching_command_method
    result = @dispatcher.call('get_scene_info', { 'scene' => 'active' })

    assert_equal({ success: true, scene: 'active' }, result)
    assert_equal([[:get_scene_info, { 'scene' => 'active' }]], @target.calls)
  end

  def test_dispatches_transform_entities_to_the_editing_command
    payload = { 'targetReference' => { 'entityId' => '301' }, 'position' => [1, 2, 3] }

    result = @dispatcher.call('transform_entities', payload)

    assert_equal(
      { success: true, outcome: 'transformed', entityId: '301', managedObject: nil },
      result
    )
    assert_equal([[:transform_entities, payload]], @target.calls)
  end

  def test_boolean_operation_is_not_a_public_dispatch_target
    error = assert_raises(RuntimeError) do
      @dispatcher.call('boolean_operation', {})
    end

    assert_includes(error.message, 'Unknown tool')
  end

  def test_dispatches_transform_entities_with_target_reference_to_the_editing_command
    result = @dispatcher.call(
      'transform_entities',
      { 'targetReference' => { 'entityId' => '301' }, 'position' => [1, 2, 3] }
    )

    assert_equal(
      { success: true, outcome: 'transformed', entityId: '301', managedObject: nil },
      result
    )
    assert_equal(
      [[
        :transform_entities,
        { 'targetReference' => { 'entityId' => '301' }, 'position' => [1, 2, 3] }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_get_selection_without_arguments
    result = @dispatcher.call('get_selection', { 'ignored' => true })

    assert_equal({ success: true, selection: [] }, result)
    assert_equal([[:selection_info, nil]], @target.calls)
  end

  def test_dispatches_find_entities_to_the_scene_query_command
    result = @dispatcher.call(
      'find_entities',
      { 'targetSelector' => { 'identity' => { 'persistentId' => '1001' } } }
    )

    assert_equal(
      {
        success: true,
        resolution: 'unique',
        matches: [{ 'identity' => { 'persistentId' => '1001' } }]
      },
      result
    )
    assert_equal(
      [[
        :find_entities,
        { 'targetSelector' => { 'identity' => { 'persistentId' => '1001' } } }
      ]],
      @target.calls
    )
  end

  def test_dispatches_validate_scene_update_to_the_validation_command
    result = @dispatcher.call(
      'validate_scene_update',
      { 'expectations' => { 'mustExist' => [{ 'targetReference' => { 'entityId' => '101' } }] } }
    )

    assert_equal(
      { success: true, outcome: 'passed', errors: [], warnings: [], summary: {} },
      result
    )
    assert_equal(
      [[
        :validate_scene_update,
        {
          'expectations' => {
            'mustExist' => [{ 'targetReference' => { 'entityId' => '101' } }]
          }
        }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_validate_scene_update_surface_offset_payload_to_the_validation_command
    result = @dispatcher.call(
      'validate_scene_update',
      {
        'expectations' => {
          'geometryRequirements' => [
            {
              'targetReference' => { 'sourceElementId' => 'house-pad-001' },
              'kind' => 'surfaceOffset',
              'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
              'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
              'constraints' => { 'expectedOffset' => 0.0, 'tolerance' => 0.02 }
            }
          ]
        }
      }
    )

    assert_equal(
      { success: true, outcome: 'passed', errors: [], warnings: [], summary: {} },
      result
    )
    assert_equal(
      [[
        :validate_scene_update,
        {
          'expectations' => {
            'geometryRequirements' => [
              {
                'targetReference' => { 'sourceElementId' => 'house-pad-001' },
                'kind' => 'surfaceOffset',
                'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
                'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
                'constraints' => { 'expectedOffset' => 0.0, 'tolerance' => 0.02 }
              }
            ]
          }
        }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_create_terrain_surface_to_the_terrain_command
    result = @dispatcher.call(
      'create_terrain_surface',
      { 'metadata' => { 'sourceElementId' => 'terrain-main' } }
    )

    assert_equal(
      {
        success: true,
        outcome: 'created',
        managedTerrain: { ownerReference: { sourceElementId: 'terrain-main' } }
      },
      result
    )
    assert_equal(
      [[:create_terrain_surface, { 'metadata' => { 'sourceElementId' => 'terrain-main' } }]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_edit_terrain_surface_to_the_terrain_command
    payload = {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => { 'mode' => 'target_height', 'targetElevation' => 12.5 },
      'region' => {
        'type' => 'rectangle',
        'bounds' => {
          'minX' => 0.0,
          'minY' => 0.0,
          'maxX' => 1.0,
          'maxY' => 1.0
        }
      }
    }

    result = @dispatcher.call('edit_terrain_surface', payload)

    assert_equal(
      {
        success: true,
        outcome: 'edited',
        managedTerrain: { ownerReference: { sourceElementId: 'terrain-main' } }
      },
      result
    )
    assert_equal([[:edit_terrain_surface, payload]], @target.calls.last(1))
  end

  def test_dispatches_curate_staged_asset_to_the_staged_asset_command
    payload = {
      'targetReference' => { 'sourceElementId' => 'curatable-source-001' },
      'metadata' => { 'sourceElementId' => 'asset-tree-oak-001' },
      'approval' => { 'state' => 'approved' },
      'staging' => { 'mode' => 'metadata_only' }
    }

    result = @dispatcher.call('curate_staged_asset', payload)

    assert_equal(
      { success: true, outcome: 'curated', asset: { sourceElementId: 'asset-tree-oak-001' } },
      result
    )
    assert_equal([[:curate_staged_asset, payload]], @target.calls.last(1))
  end

  def test_dispatches_list_staged_assets_to_the_staged_asset_command
    payload = { 'filters' => { 'category' => 'tree' } }

    result = @dispatcher.call('list_staged_assets', payload)

    assert_equal(
      { success: true, count: 0, assets: [], filters: { 'category' => 'tree' } },
      result
    )
    assert_equal([[:list_staged_assets, payload]], @target.calls.last(1))
  end

  def test_dispatches_measure_scene_to_the_measurement_command
    payload = {
      'mode' => 'height',
      'kind' => 'bounds_z',
      'target' => { 'sourceElementId' => 'tree-001' }
    }

    result = @dispatcher.call('measure_scene', payload)

    assert_equal(
      { success: true, outcome: 'measured', measurement: payload },
      result
    )
    assert_equal([[:measure_scene, payload]], @target.calls.last(1))
  end

  def test_dispatches_delete_entities_to_the_editing_command
    result = @dispatcher.call(
      'delete_entities',
      { 'targetReference' => { 'entityId' => '301' } }
    )

    assert_equal(
      {
        success: true,
        outcome: 'deleted',
        affectedEntities: { deleted: [{ 'entityId' => '301' }] }
      },
      result
    )
    assert_equal(
      [[
        :delete_entities,
        { 'targetReference' => { 'entityId' => '301' } }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_set_material_to_the_editing_command
    result = @dispatcher.call(
      'set_material',
      { 'targetReference' => { 'entityId' => '301' }, 'material' => 'Walnut' }
    )

    assert_equal(
      { success: true, outcome: 'material_applied', entityId: '301', managedObject: nil },
      result
    )
    assert_equal(
      [[
        :apply_material,
        { 'targetReference' => { 'entityId' => '301' }, 'material' => 'Walnut' }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_create_group_to_the_hierarchy_command
    result = @dispatcher.call(
      'create_group',
      {
        'parent' => { 'persistentId' => '1001' },
        'children' => [{ 'sourceElementId' => 'tree-001' }]
      }
    )

    assert_equal(
      { success: true, outcome: 'created', group: { entityId: '42', type: 'group' } },
      result
    )
    assert_equal(
      [[
        :create_group,
        {
          'parent' => { 'persistentId' => '1001' },
          'children' => [{ 'sourceElementId' => 'tree-001' }]
        }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_create_group_with_managed_container_arguments_to_the_hierarchy_command
    result = @dispatcher.call(
      'create_group',
      {
        'metadata' => {
          'sourceElementId' => 'built-form-cluster-001',
          'status' => 'proposed'
        },
        'sceneProperties' => {
          'name' => 'Built Form Cluster',
          'tag' => 'Structures'
        }
      }
    )

    assert_equal(
      { success: true, outcome: 'created', group: { entityId: '42', type: 'group' } },
      result
    )
    assert_equal(
      [[
        :create_group,
        {
          'metadata' => {
            'sourceElementId' => 'built-form-cluster-001',
            'status' => 'proposed'
          },
          'sceneProperties' => {
            'name' => 'Built Form Cluster',
            'tag' => 'Structures'
          }
        }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_reparent_entities_to_the_hierarchy_command
    result = @dispatcher.call(
      'reparent_entities',
      {
        'parent' => { 'persistentId' => '1002' },
        'entities' => [{ 'sourceElementId' => 'house-extension-001' }]
      }
    )

    assert_equal(
      {
        success: true,
        outcome: 'reparented',
        entities: [{ 'sourceElementId' => 'house-extension-001' }]
      },
      result
    )
    assert_equal(
      [[
        :reparent_entities,
        {
          'parent' => { 'persistentId' => '1002' },
          'entities' => [{ 'sourceElementId' => 'house-extension-001' }]
        }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_sample_surface_z_to_the_scene_query_command
    result = @dispatcher.call(
      'sample_surface_z',
      {
        'target' => { 'persistentId' => '4001' },
        'sampling' => {
          'type' => 'points',
          'points' => [{ 'x' => 5.0, 'y' => 5.0 }]
        }
      }
    )

    assert_equal(
      { success: true, results: [{ samplePoint: { 'x' => 5.0, 'y' => 5.0 }, status: 'hit' }] },
      result
    )
    assert_equal(
      [[
        :sample_surface_z,
        {
          'target' => { 'persistentId' => '4001' },
          'sampling' => {
            'type' => 'points',
            'points' => [{ 'x' => 5.0, 'y' => 5.0 }]
          }
        }
      ]],
      @target.calls
    )
  end

  def test_dispatches_create_site_element_to_the_semantic_command
    result = @dispatcher.call(
      'create_site_element',
      {
        'elementType' => 'pad',
        'sourceElementId' => 'terrace-001',
        'status' => 'proposed',
        'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0]]
      }
    )

    assert_equal(
      { success: true, outcome: 'created', managedObject: { sourceElementId: 'terrace-001' } },
      result
    )
    assert_equal(
      [[
        :create_site_element,
        {
          'elementType' => 'pad',
          'sourceElementId' => 'terrace-001',
          'status' => 'proposed',
          'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0]]
        }
      ]],
      @target.calls.last(1)
    )
  end

  def test_dispatches_set_entity_metadata_to_the_semantic_command
    result = @dispatcher.call(
      'set_entity_metadata',
      {
        'target' => { 'sourceElementId' => 'house-extension-001' },
        'set' => { 'status' => 'existing' }
      }
    )

    assert_equal(
      {
        success: true,
        outcome: 'updated',
        managedObject: { sourceElementId: 'house-extension-001' }
      },
      result
    )
    assert_equal(
      [[
        :set_entity_metadata,
        {
          'target' => { 'sourceElementId' => 'house-extension-001' },
          'set' => { 'status' => 'existing' }
        }
      ]],
      @target.calls.last(1)
    )
  end

  def test_raises_for_unknown_tool
    error = assert_raises(RuntimeError) do
      @dispatcher.call('unknown_tool', {})
    end

    assert_equal('Unknown tool: unknown_tool', error.message)
  end
end
