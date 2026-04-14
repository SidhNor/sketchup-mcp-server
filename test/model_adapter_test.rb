# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/scene_query_test_support'
require_relative '../src/su_mcp/adapters/model_adapter'

class ModelAdapterTest < Minitest::Test
  include SceneQueryTestSupport

  def setup
    @adapter = SU_MCP::Adapters::ModelAdapter.new
    @model = build_scene_query_model
    Sketchup.active_model_override = @model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_active_model_returns_the_live_model
    assert_same @model, @adapter.active_model!
  end

  def test_active_model_raises_when_missing
    Sketchup.active_model_override = nil

    error = assert_raises(RuntimeError) do
      @adapter.active_model!
    end

    assert_equal('No active SketchUp model', error.message)
  end

  def test_find_entity_resolves_ids_with_wrapped_quotes
    entity = @adapter.find_entity!('"101"')

    assert_equal(101, entity.entityID)
  end

  def test_find_entity_requires_a_non_blank_id
    error = assert_raises(RuntimeError) do
      @adapter.find_entity!('')
    end

    assert_equal('Entity id is required', error.message)
  end

  def test_find_entity_raises_when_missing
    error = assert_raises(RuntimeError) do
      @adapter.find_entity!('999')
    end

    assert_equal('Entity not found', error.message)
  end

  def test_top_level_entities_filter_hidden_entities_by_default
    entities = @adapter.top_level_entities

    assert_equal([101], entities.map(&:entityID))
  end

  def test_top_level_entities_can_include_hidden_entities
    entities = @adapter.top_level_entities(include_hidden: true)

    assert_equal([101, 102], entities.map(&:entityID))
  end

  def test_selected_entities_returns_the_model_selection
    assert_equal([101], @adapter.selected_entities.map(&:entityID))
  end

  def test_export_scene_saves_skp_exports_with_a_returned_path
    export = @adapter.export_scene(format: 'skp')

    assert_equal(true, export[:success])
    assert_equal('skp', export[:format])
    assert_match(/\.skp\z/, export[:path])
    assert_equal([export[:path]], @model.saved_paths)
  end

  def test_export_scene_uses_model_export_for_obj
    export = @adapter.export_scene(format: 'obj')

    assert_equal(true, export[:success])
    assert_equal('obj', export[:format])
    assert_match(/\.obj\z/, export[:path])
    assert_equal([[export[:path], expected_obj_export_options]], @model.export_calls)
  end

  def test_export_scene_uses_view_write_image_for_png
    export = @adapter.export_scene(format: 'png', width: 640, height: 480)

    assert_equal(true, export[:success])
    assert_equal('png', export[:format])
    assert_equal([expected_png_export_options(export[:path])], @model.active_view.write_image_calls)
  end

  def test_export_scene_raises_for_unsupported_formats
    error = assert_raises(RuntimeError) do
      @adapter.export_scene(format: 'gif')
    end

    assert_equal('Unsupported export format: gif', error.message)
  end

  private

  def expected_obj_export_options
    {
      triangulated_faces: true,
      double_sided_faces: true,
      edges: false,
      texture_maps: true
    }
  end

  def expected_png_export_options(path)
    {
      filename: path,
      width: 640,
      height: 480,
      antialias: true,
      transparent: true
    }
  end
end
