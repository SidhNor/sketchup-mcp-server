# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/asset_exemplar_query'

class AssetExemplarQueryTest < Minitest::Test
  include StagedAssetTestSupport

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_lists_only_complete_approved_exemplars_by_default
    approved = build_asset_group(attributes: approved_exemplar_attributes)
    incomplete = build_asset_group(
      entity_id: 802,
      origin_x: 5,
      attributes: approved_exemplar_attributes('approvalState' => 'draft')
    )
    Sketchup.active_model_override = staged_asset_model(approved, incomplete)

    result = SU_MCP::StagedAssets::AssetExemplarQuery.new.list({})

    assert_equal(true, result.fetch(:success))
    assert_equal(1, result.fetch(:count))
    assert_equal(['asset-tree-oak-001'], source_element_ids(result))
  end

  def test_applies_category_tag_and_attribute_filters
    oak = build_asset_group(attributes: approved_exemplar_attributes)
    pine = build_asset_group(
      entity_id: 802,
      origin_x: 5,
      attributes: approved_exemplar_attributes(
        'sourceElementId' => 'asset-tree-pine-001',
        'assetTags' => %w[tree evergreen],
        'assetAttributes' => { 'species' => 'pine', 'detailLevel' => 'medium' }
      )
    )
    Sketchup.active_model_override = staged_asset_model(oak, pine)

    result = SU_MCP::StagedAssets::AssetExemplarQuery.new.list(
      'filters' => {
        'category' => 'tree',
        'tags' => ['deciduous'],
        'attributes' => { 'species' => 'oak' }
      }
    )

    assert_equal(['asset-tree-oak-001'], source_element_ids(result))
  end

  def test_component_instance_metadata_is_instance_level_and_definition_children_are_not_returned
    definition_child = build_asset_group(
      entity_id: 812,
      origin_x: 15,
      attributes: approved_exemplar_attributes('sourceElementId' => 'definition-child-001')
    )
    component = build_asset_component(
      attributes: approved_exemplar_attributes('sourceElementId' => 'asset-component-oak-001'),
      definition_entities: [definition_child]
    )
    Sketchup.active_model_override = staged_asset_model(component)

    result = SU_MCP::StagedAssets::AssetExemplarQuery.new.list({})

    assert_equal(['asset-component-oak-001'], source_element_ids(result))
  end

  def test_refuses_unsupported_approval_state_filter_with_allowed_values
    Sketchup.active_model_override = staged_asset_model

    result = SU_MCP::StagedAssets::AssetExemplarQuery.new.list(
      'filters' => { 'approvalState' => 'draft' }
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal(
      {
        field: 'filters.approvalState',
        value: 'draft',
        allowedValues: ['approved']
      },
      result.dig(:refusal, :details)
    )
  end

  def test_refuses_invalid_filter_shapes
    Sketchup.active_model_override = staged_asset_model

    result = SU_MCP::StagedAssets::AssetExemplarQuery.new.list(
      'filters' => { 'tags' => 'deciduous' }
    )

    assert_equal('invalid_filter', result.dig(:refusal, :code))
    assert_equal({ field: 'filters.tags', value: 'deciduous' }, result.dig(:refusal, :details))
  end

  def test_defaults_limit_to_twenty_five_and_caps_limit_at_one_hundred
    assets = 101.times.map do |index|
      build_asset_group(
        entity_id: 900 + index,
        origin_x: index,
        attributes: approved_exemplar_attributes('sourceElementId' => "asset-#{index}")
      )
    end
    Sketchup.active_model_override = staged_asset_model(assets)

    default_result = SU_MCP::StagedAssets::AssetExemplarQuery.new.list({})
    capped_result = SU_MCP::StagedAssets::AssetExemplarQuery.new.list(
      'outputOptions' => { 'limit' => 500 }
    )

    assert_equal(25, default_result.fetch(:count))
    assert_equal(100, capped_result.fetch(:count))
  end

  private

  def source_element_ids(result)
    result.fetch(:assets).map { |asset| asset[:sourceElementId] }
  end
end
