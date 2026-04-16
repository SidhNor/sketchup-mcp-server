# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/scene_query_commands'

class FindEntitiesSceneQueryCommandsTest < Minitest::Test
  include SceneQueryTestSupport

  def setup
    @commands = SU_MCP::SceneQueryCommands.new
    Sketchup.active_model_override = build_find_entities_model
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_requires_at_least_one_query_criterion
    error = assert_raises(RuntimeError) do
      @commands.find_entities('query' => {})
    end

    assert_equal('At least one query criterion is required', error.message)
  end

  def test_resolves_unique_match_by_source_element_id_when_present
    result = @commands.find_entities('query' => { 'sourceElementId' => 'tree-001' })

    assert_equal(true, result[:success])
    assert_equal('unique', result[:resolution])
    assert_equal(expected_tree_match, result[:matches].first)
  end

  def test_resolves_unique_match_by_persistent_id
    result = @commands.find_entities('query' => { 'persistentId' => '1002' })

    assert_equal('unique', result[:resolution])
    assert_equal('102', result.dig(:matches, 0, :entityId))
    refute_includes(result[:matches].first.keys, :sourceElementId)
  end

  def test_supports_entity_id_compatibility_lookup
    result = @commands.find_entities('query' => { 'entityId' => '103' })

    assert_equal('unique', result[:resolution])
    assert_equal('Driveway', result.dig(:matches, 0, :name))
  end

  def test_supports_exact_match_lookup_by_name
    result = @commands.find_entities('query' => { 'name' => 'Retained Maple' })

    assert_equal('unique', result[:resolution])
    assert_equal('102', result.dig(:matches, 0, :entityId))
  end

  def test_supports_exact_match_lookup_by_tag
    result = @commands.find_entities('query' => { 'tag' => 'Hardscape' })

    assert_equal('unique', result[:resolution])
    assert_equal('Driveway', result.dig(:matches, 0, :name))
  end

  def test_supports_exact_match_lookup_by_material
    result = @commands.find_entities('query' => { 'material' => 'Concrete' })

    assert_equal('unique', result[:resolution])
    assert_equal('103', result.dig(:matches, 0, :entityId))
  end

  def test_applies_exact_match_and_semantics_across_multiple_filters
    result = @commands.find_entities(
      'query' => { 'name' => 'Retained Oak', 'material' => 'Bark' }
    )

    assert_equal('unique', result[:resolution])
    assert_equal(['101'], result[:matches].map { |match| match[:entityId] })
  end

  def test_returns_ambiguous_resolution_without_selecting_a_winner
    result = @commands.find_entities('query' => { 'name' => 'Retained Oak' })

    assert_equal(true, result[:success])
    assert_equal('ambiguous', result[:resolution])
    assert_equal(%w[101 104], result[:matches].map { |match| match[:entityId] })
  end

  def test_returns_none_for_valid_queries_without_matches
    result = @commands.find_entities('query' => { 'material' => 'Brick' })

    assert_equal(true, result[:success])
    assert_equal('none', result[:resolution])
    assert_equal([], result[:matches])
  end

  def test_serializes_public_identifier_fields_as_strings
    result = @commands.find_entities('query' => { 'persistentId' => '1001' })
    match = result[:matches].first

    assert_instance_of(String, match[:entityId])
    assert_instance_of(String, match[:persistentId])
    assert_instance_of(String, match[:sourceElementId])
  end

  private

  def expected_tree_match
    {
      sourceElementId: 'tree-001',
      persistentId: '1001',
      entityId: '101',
      type: 'group',
      name: 'Retained Oak',
      tag: 'Trees',
      material: 'Bark'
    }
  end
end
