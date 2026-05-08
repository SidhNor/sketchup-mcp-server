# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/selected_terrain_resolver'

class TerrainUiSelectedTerrainResolverTest < Minitest::Test
  FakeModel = Struct.new(:selection, keyword_init: true)

  def test_refuses_empty_selection
    result = resolver_for([]).resolve

    assert_refusal(result, 'managed_terrain_selection_required')
  end

  def test_refuses_multiple_selection
    result = resolver_for([managed_terrain('terrain-a'), managed_terrain('terrain-b')]).resolve

    assert_refusal(result, 'managed_terrain_selection_ambiguous')
  end

  def test_refuses_non_managed_terrain_selection
    result = resolver_for([managed_object('path-1', 'path')]).resolve

    assert_refusal(result, 'managed_terrain_selection_invalid')
  end

  def test_resolves_single_managed_terrain_owner_to_json_safe_reference
    terrain = managed_terrain('terrain-main', name: 'Context Terrain')

    result = resolver_for([terrain]).resolve

    assert_equal('resolved', result.fetch(:outcome))
    assert_same(terrain, result.fetch(:owner))
    assert_equal({ 'sourceElementId' => 'terrain-main' }, result.fetch(:targetReference))
    assert_equal('Context Terrain', result.fetch(:selectedTerrain))
    refute_includes(JSON.generate(result.reject { |key, _| key == :owner }), 'Sketchup::')
  end

  def test_resolved_selected_terrain_label_falls_back_to_source_identity
    result = resolver_for([managed_terrain('terrain-main')]).resolve

    assert_equal('terrain-main', result.fetch(:selectedTerrain))
  end

  def test_refuses_child_or_derived_output_selection_until_normalized_safely
    child = managed_object('terrain-output-child', 'managed_terrain_output')

    result = resolver_for([child]).resolve

    assert_refusal(result, 'managed_terrain_selection_invalid')
  end

  private

  class FakeEntity
    attr_reader :name

    def initialize(source_element_id, semantic_type, name: '')
      @source_element_id = source_element_id
      @semantic_type = semantic_type
      @name = name
    end

    def get_attribute(dictionary, key, default = nil)
      return default unless dictionary == 'su_mcp'
      return @source_element_id if key == 'sourceElementId'
      return @semantic_type if key == 'semanticType'

      default
    end
  end

  def resolver_for(selection)
    SU_MCP::Terrain::UI::SelectedTerrainResolver.new(model: FakeModel.new(selection: selection))
  end

  def managed_terrain(source_element_id, name: '')
    managed_object(source_element_id, 'managed_terrain_surface', name: name)
  end

  def managed_object(source_element_id, semantic_type, name: '')
    FakeEntity.new(source_element_id, semantic_type, name: name)
  end

  def assert_refusal(result, code)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end
end
