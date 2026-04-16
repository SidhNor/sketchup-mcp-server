# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/transport/socket_server'

class SocketServerAdapterTest < Minitest::Test
  include SceneQueryTestSupport

  class RecordingAdapter
    attr_reader :calls

    def initialize(model:, entity:, export_result:)
      @model = model
      @entity = entity
      @export_result = export_result
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

    def export_scene(format:, width: nil, height: nil)
      @calls << [:export_scene, format, width, height]
      @export_result
    end
  end

  class AdapterAwareSocketServer < SU_MCP::SocketServer
    def initialize(adapter:)
      @adapter = adapter
      super()
    end

    private

    attr_reader :adapter

    def model_adapter
      adapter
    end

    def log(_message); end
  end

  def setup
    @model = build_mutation_model
    @entity = @model.entities.first
    @adapter = RecordingAdapter.new(
      model: @model,
      entity: @entity,
      export_result: { success: true, path: '/tmp/export.png', format: 'png' }
    )
    @server = AdapterAwareSocketServer.new(adapter: @adapter)
    Sketchup.active_model_override = @model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_delete_component_uses_the_shared_adapter_for_entity_lookup
    result = @server.send(:dispatch_tool_call, 'delete_component', 'id' => '301')

    assert_equal(true, result[:success])
    assert_equal(true, @entity.erased?)
    assert_equal([[:find_entity!, '301']], @adapter.calls)
  end

  def test_transform_component_uses_the_shared_adapter_for_entity_lookup
    result = @server.send(:dispatch_tool_call, 'transform_component', transform_params)

    assert_equal(true, result[:success])
    assert_equal(301, result[:id])
    assert_equal([[:find_entity!, '301']], @adapter.calls)
    refute_empty(@entity.transformations)
  end

  def test_apply_material_uses_the_shared_adapter_for_entity_lookup
    result = @server.send(
      :dispatch_tool_call,
      'set_material',
      'id' => '301',
      'material' => 'Walnut'
    )

    assert_equal(true, result[:success])
    assert_equal('Walnut', @entity.material.display_name)
    assert_equal([:active_model!, [:find_entity!, '301']], @adapter.calls)
  end

  def test_export_scene_uses_the_shared_adapter_for_export_execution
    result = @server.send(
      :dispatch_tool_call,
      'export_scene',
      'format' => 'png',
      'width' => 640,
      'height' => 480
    )

    assert_equal([[:export_scene, 'png', 640, 480]], @adapter.calls)
    assert_equal({ success: true, path: '/tmp/export.png', format: 'png' }, result)
  end

  private

  def transform_params
    {
      'id' => '301',
      'position' => [1, 2, 3],
      'rotation' => [0, 0, 0],
      'scale' => [1, 1, 1]
    }
  end
end
