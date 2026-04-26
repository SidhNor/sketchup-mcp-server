# frozen_string_literal: true

require_relative 'scene_query_test_support'

module StagedAssetTestSupport
  include SceneQueryTestSupport

  def staged_asset_layer
    @staged_asset_layer ||= SceneQueryTestSupport::FakeLayer.new('Asset Library')
  end

  def staged_asset_material
    @staged_asset_material ||= SceneQueryTestSupport::FakeMaterial.new('Leaf')
  end

  def build_asset_group(entity_id: 801, origin_x: 0, attributes: {}, details: {})
    build_scene_query_group(
      entity_id: entity_id,
      origin_x: origin_x,
      layer: staged_asset_layer,
      material: staged_asset_material,
      details: {
        name: 'Oak Tree Exemplar',
        persistent_id: entity_id + 7000,
        entities: []
      }.merge(details).merge(attributes: { 'su_mcp' => attributes })
    )
  end

  def build_asset_component(entity_id: 811, origin_x: 10, attributes: {}, definition_entities: [])
    definition = SceneQueryTestSupport::FakeComponentDefinition.new(
      name: 'Oak Component Definition',
      entities: definition_entities
    )
    build_scene_query_component(
      entity_id: entity_id,
      origin_x: origin_x,
      layer: staged_asset_layer,
      material: staged_asset_material,
      details: {
        name: 'Oak Component Instance',
        persistent_id: entity_id + 7000,
        attributes: { 'su_mcp' => attributes },
        definition: definition
      }
    )
  end

  def approved_exemplar_attributes(overrides = {})
    {
      'assetExemplar' => true,
      'assetExemplarSchemaVersion' => 1,
      'assetRole' => 'exemplar',
      'approvalState' => 'approved',
      'sourceElementId' => 'asset-tree-oak-001',
      'assetCategory' => 'tree',
      'assetDisplayName' => 'Oak Tree Exemplar',
      'assetTags' => %w[tree deciduous],
      'assetAttributes' => { 'species' => 'oak', 'detailLevel' => 'high' },
      'stagingMode' => 'metadata_only'
    }.merge(overrides)
  end

  def staged_asset_model(*entities)
    SceneQueryTestSupport::FakeModel.new(
      state: {
        entities: entities.flatten,
        active_entities: [],
        selection: [],
        materials: [staged_asset_material],
        layers: [staged_asset_layer],
        bounds: build_bounds(origin_x: -5)
      },
      details: { options: default_options }
    )
  end
end
