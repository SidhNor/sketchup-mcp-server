# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/tool_dispatcher'

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

    def export_scene(args)
      @calls << [:export_scene, args]
      { success: true, format: args.fetch('format') }
    end

    def selection_info
      @calls << [:selection_info, nil]
      { success: true, selection: [] }
    end

    def find_entities(args)
      @calls << [:find_entities, args]
      { success: true, resolution: 'unique', matches: [args.fetch('query')] }
    end

    def sample_surface_z(args)
      @calls << [:sample_surface_z, args]
      { success: true, results: [{ samplePoint: args.fetch('samplePoints').first, status: 'hit' }] }
    end

    private :get_scene_info, :export_scene, :selection_info, :find_entities, :sample_surface_z
  end

  class ExportOnlyTarget
    attr_reader :calls

    def initialize
      @calls = []
    end

    def export_scene(args)
      @calls << [:export_scene, args]
      { success: true, format: args.fetch('format'), source: :secondary }
    end

    private :export_scene
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

  def test_dispatches_export_alias_to_export_scene
    result = @dispatcher.call('export', { 'format' => 'png' })

    assert_equal({ success: true, format: 'png' }, result)
    assert_equal([[:export_scene, { 'format' => 'png' }]], @target.calls)
  end

  def test_resolves_tool_method_from_later_command_target
    secondary_target = ExportOnlyTarget.new
    dispatcher = SU_MCP::ToolDispatcher.new(command_targets: [Object.new, secondary_target])

    result = dispatcher.call('export', { 'format' => 'obj' })

    assert_equal({ success: true, format: 'obj', source: :secondary }, result)
    assert_equal([[:export_scene, { 'format' => 'obj' }]], secondary_target.calls)
  end

  def test_dispatches_get_selection_without_arguments
    result = @dispatcher.call('get_selection', { 'ignored' => true })

    assert_equal({ success: true, selection: [] }, result)
    assert_equal([[:selection_info, nil]], @target.calls)
  end

  def test_dispatches_find_entities_to_the_scene_query_command
    result = @dispatcher.call('find_entities', { 'query' => { 'persistentId' => '1001' } })

    assert_equal(
      { success: true, resolution: 'unique', matches: [{ 'persistentId' => '1001' }] },
      result
    )
    assert_equal(
      [[:find_entities, { 'query' => { 'persistentId' => '1001' } }]],
      @target.calls
    )
  end

  # rubocop:disable Metrics/MethodLength
  def test_dispatches_sample_surface_z_to_the_scene_query_command
    result = @dispatcher.call(
      'sample_surface_z',
      {
        'target' => { 'persistentId' => '4001' },
        'samplePoints' => [{ 'x' => 5.0, 'y' => 5.0 }]
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
          'samplePoints' => [{ 'x' => 5.0, 'y' => 5.0 }]
        }
      ]],
      @target.calls
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_raises_for_unknown_tool
    error = assert_raises(RuntimeError) do
      @dispatcher.call('unknown_tool', {})
    end

    assert_equal('Unknown tool: unknown_tool', error.message)
  end
end
