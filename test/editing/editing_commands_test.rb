# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/editing/editing_commands'

class EditingCommandsTest < Minitest::Test
  include SceneQueryTestSupport
  include SemanticTestSupport

  class RecordingAdapter
    attr_reader :calls

    def initialize(model:, entity:)
      @model = model
      @entity = entity
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

  def test_delete_component_uses_the_shared_adapter_for_entity_lookup
    result = @commands.delete_component('id' => '301')

    assert_equal(true, result[:success])
    assert_equal(true, @entity.erased?)
    assert_equal([[:find_entity!, '301']], @adapter.calls)
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
