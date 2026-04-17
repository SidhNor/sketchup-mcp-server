# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/scene_query_test_support'
require_relative '../../support/semantic_test_support'
require_relative '../../../src/su_mcp/scene_query/scene_query_commands'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_facade'
require_relative '../../../src/su_mcp/runtime/runtime_command_factory'

class McpRuntimeFacadeTest < Minitest::Test
  include SceneQueryTestSupport
  include SemanticTestSupport

  class RecordingSceneQueryCommands
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def get_scene_info(params = {})
      @calls << params
      @result
    end

    def find_entities(params)
      @calls << params
      @result
    end
  end

  class RecordingDeveloperCommands
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def eval_ruby(params = {})
      @calls << params
      @result
    end
  end

  class RecordingRuntimeCommandFactory
    attr_reader :calls

    def initialize(targets:)
      @targets = targets
      @calls = 0
    end

    def build_command_targets
      @calls += 1
      @targets
    end
  end

  def setup
    Sketchup.active_model_override = build_scene_query_model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_ping_returns_the_minimal_runtime_payload
    facade = SU_MCP::McpRuntimeFacade.new(
      scene_query_commands: RecordingSceneQueryCommands.new(result: {})
    )

    assert_equal({ success: true, message: 'pong' }, facade.ping)
  end

  def test_get_scene_info_reuses_the_existing_scene_query_response_shape
    expected = SU_MCP::SceneQueryCommands.new.get_scene_info('entity_limit' => 1)
    commands = RecordingSceneQueryCommands.new(result: expected)
    facade = SU_MCP::McpRuntimeFacade.new(scene_query_commands: commands)

    result = facade.get_scene_info('entity_limit' => 1)

    assert_equal([{ 'entity_limit' => 1 }], commands.calls)
    assert_equal(expected, result)
  end

  def test_find_entities_reuses_the_existing_scene_query_response_shape
    expected = { success: true, resolution: 'unique', matches: [{ 'persistentId' => '1001' }] }
    commands = RecordingSceneQueryCommands.new(result: expected)
    facade = SU_MCP::McpRuntimeFacade.new(scene_query_commands: commands)

    result = facade.find_entities('query' => { 'persistentId' => '1001' })

    assert_equal([{ 'query' => { 'persistentId' => '1001' } }], commands.calls)
    assert_equal(expected, result)
  end

  def test_eval_ruby_delegates_to_the_shared_developer_commands
    developer_commands = RecordingDeveloperCommands.new(result: { success: true, result: '2' })
    facade = SU_MCP::McpRuntimeFacade.new(developer_commands: developer_commands)

    result = facade.eval_ruby('code' => '1 + 1')

    assert_equal([{ 'code' => '1 + 1' }], developer_commands.calls)
    assert_equal({ success: true, result: '2' }, result)
  end

  def test_builds_command_targets_from_the_shared_runtime_command_factory
    expected = { success: true, outcome: 'created', id: 'component-1' }
    component_commands = Class.new do
      attr_reader :calls

      def initialize(result)
        @result = result
        @calls = []
      end

      def create_component(params)
        @calls << params
        @result
      end
    end.new(expected)
    factory = RecordingRuntimeCommandFactory.new(targets: [component_commands])
    facade = SU_MCP::McpRuntimeFacade.new(runtime_command_factory: factory)

    result = facade.create_component('type' => 'cube')

    assert_equal(1, factory.calls)
    assert_equal([{ 'type' => 'cube' }], component_commands.calls)
    assert_equal(expected, result)
  end

  def test_create_group_dispatches_through_the_real_runtime_command_factory
    Sketchup.active_model_override = build_semantic_model
    facade = SU_MCP::McpRuntimeFacade.new(
      runtime_command_factory: SU_MCP::RuntimeCommandFactory.new
    )

    result = facade.create_group({})

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal('group', result.dig(:group, :type))
  end
end
