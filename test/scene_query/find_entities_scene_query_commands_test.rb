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

  def test_requires_a_target_selector
    error = assert_raises(RuntimeError) do
      @commands.find_entities({})
    end

    assert_equal('targetSelector is required', error.message)
  end

  def test_requires_at_least_one_populated_selector_field
    error = assert_raises(RuntimeError) do
      @commands.find_entities('targetSelector' => {})
    end

    assert_equal('At least one targetSelector criterion is required', error.message)
  end

  def test_resolves_unique_match_by_source_element_id_when_present
    result = @commands.find_entities(
      'targetSelector' => { 'identity' => { 'sourceElementId' => 'tree-001' } }
    )

    assert_equal(true, result[:success])
    assert_equal('unique', result[:resolution])
    assert_equal(expected_tree_match, result[:matches].first)
  end

  def test_resolves_unique_match_by_persistent_id
    result = @commands.find_entities(
      'targetSelector' => { 'identity' => { 'persistentId' => '1002' } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal('102', result.dig(:matches, 0, :entityId))
    assert_equal('tree_proxy', result.dig(:matches, 0, :semanticType))
    assert_equal('proposed', result.dig(:matches, 0, :status))
  end

  def test_supports_entity_id_compatibility_lookup
    result = @commands.find_entities(
      'targetSelector' => { 'identity' => { 'entityId' => '103' } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal('Driveway', result.dig(:matches, 0, :name))
  end

  def test_supports_exact_match_lookup_by_name
    result = @commands.find_entities(
      'targetSelector' => { 'attributes' => { 'name' => 'Retained Maple' } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal('102', result.dig(:matches, 0, :entityId))
  end

  def test_supports_exact_match_lookup_by_tag
    result = @commands.find_entities(
      'targetSelector' => { 'attributes' => { 'tag' => 'Hardscape' } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal('Driveway', result.dig(:matches, 0, :name))
  end

  def test_supports_exact_match_lookup_by_material
    result = @commands.find_entities(
      'targetSelector' => { 'attributes' => { 'material' => 'Concrete' } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal('103', result.dig(:matches, 0, :entityId))
  end

  def test_supports_metadata_predicates
    result = @commands.find_entities(
      'targetSelector' => { 'metadata' => { 'structureCategory' => 'outbuilding' } }
    )

    assert_equal('ambiguous', result[:resolution])
    assert_equal(%w[104 105], result[:matches].map { |match| match[:entityId] }.sort)
  end

  def test_supports_matching_managed_containers_by_semantic_type
    result = @commands.find_entities(
      'targetSelector' => { 'metadata' => { 'semanticType' => 'grouped_feature' } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal(['106'], result[:matches].map { |match| match[:entityId] })
    assert_equal('built-form-cluster-001', result.dig(:matches, 0, :sourceElementId))
  end

  def test_finds_nested_entities_recursively
    result = @commands.find_entities(
      'targetSelector' => { 'identity' => { 'sourceElementId' => 'arbor-001' } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal('105', result.dig(:matches, 0, :entityId))
    assert_equal('Nested Arbor', result.dig(:matches, 0, :name))
  end

  def test_supports_matching_unmanaged_entities_by_false_managed_scene_object_flag
    result = @commands.find_entities(
      'targetSelector' => { 'metadata' => { 'managedSceneObject' => false } }
    )

    assert_equal('unique', result[:resolution])
    assert_equal(['103'], result[:matches].map { |match| match[:entityId] })
  end

  def test_applies_exact_match_and_semantics_across_multiple_selector_sections
    result = @commands.find_entities(
      'targetSelector' => {
        'attributes' => { 'name' => 'Retained Oak', 'material' => 'Bark' },
        'metadata' => { 'status' => 'existing' }
      }
    )

    assert_equal('unique', result[:resolution])
    assert_equal(['101'], result[:matches].map { |match| match[:entityId] })
  end

  def test_returns_ambiguous_resolution_without_selecting_a_winner
    result = @commands.find_entities(
      'targetSelector' => { 'attributes' => { 'name' => 'Retained Oak' } }
    )

    assert_equal(true, result[:success])
    assert_equal('ambiguous', result[:resolution])
    assert_equal(%w[101 104], result[:matches].map { |match| match[:entityId] })
  end

  def test_returns_none_for_valid_queries_without_matches
    result = @commands.find_entities(
      'targetSelector' => { 'attributes' => { 'material' => 'Brick' } }
    )

    assert_equal(true, result[:success])
    assert_equal('none', result[:resolution])
    assert_equal([], result[:matches])
  end

  def test_rejects_unsupported_selector_fields
    error = assert_raises(RuntimeError) do
      @commands.find_entities('targetSelector' => { 'metadata' => { 'schemaVersion' => '1' } })
    end

    assert_equal('Unsupported targetSelector.metadata field: schemaVersion', error.message)
  end

  def test_serializes_public_identifier_fields_as_strings
    result = @commands.find_entities(
      'targetSelector' => { 'identity' => { 'persistentId' => '1001' } }
    )
    match = result[:matches].first

    assert_instance_of(String, match[:entityId])
    assert_instance_of(String, match[:persistentId])
    assert_instance_of(String, match[:sourceElementId])
    assert_equal('tree_proxy', match[:semanticType])
    assert_equal('existing', match[:status])
    assert_equal('existing', match[:state])
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
      material: 'Bark',
      semanticType: 'tree_proxy',
      status: 'existing',
      state: 'existing'
    }
  end
end
