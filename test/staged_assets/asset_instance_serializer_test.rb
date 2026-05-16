# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/asset_instance_serializer'

class AssetInstanceSerializerTest < Minitest::Test
  include StagedAssetTestSupport

  def test_serializes_instance_source_lineage_placement_and_bounds
    serializer = SU_MCP::StagedAssets::AssetInstanceSerializer.new
    source = build_asset_component(
      attributes: approved_exemplar_attributes(
        'sourceElementId' => 'asset-hedge-001',
        'assetAttributes' => {
          'assetSet' => 'garden-library',
          'assetKey' => 'hedge-low-a',
          'heightClass' => 'low'
        }
      )
    )
    instance = build_asset_component(
      entity_id: 901,
      attributes: {
        'managedSceneObject' => true,
        'semanticType' => 'asset_instance',
        'assetRole' => 'instance',
        'assetInstanceSchemaVersion' => 1,
        'sourceElementId' => 'placed-hedge-001',
        'sourceAssetElementId' => 'asset-hedge-001'
      }
    )

    result = serializer.serialize(
      instance,
      source_entity: source,
      placement: { position: [1.0, 2.0, 0.0], scale: 1.1 },
      include_bounds: true
    )

    assert_equal('placed-hedge-001', result.dig(:instance, :sourceElementId))
    assert_equal('asset_instance', result.dig(:instance, :semanticType))
    assert_equal('instance', result.dig(:instance, :assetRole))
    assert_equal('asset-hedge-001', result.dig(:sourceAsset, :sourceElementId))
    assert_equal(
      {
        'assetSet' => 'garden-library',
        'assetKey' => 'hedge-low-a',
        'heightClass' => 'low'
      },
      result.dig(:sourceAsset, :metadata, :attributes)
    )
    assert_equal({ sourceAssetElementId: 'asset-hedge-001' }, result.fetch(:lineage))
    assert_equal({ position: [1.0, 2.0, 0.0], scale: 1.1 }, result.fetch(:placement))
    assert_equal([0.254, 0.0, 0.0], result.dig(:bounds, :min))
  end

  def test_serializes_compact_orientation_evidence_when_present
    serializer = SU_MCP::StagedAssets::AssetInstanceSerializer.new
    source = build_asset_component(attributes: approved_exemplar_attributes)
    instance = build_asset_component(
      entity_id: 901,
      attributes: {
        'managedSceneObject' => true,
        'semanticType' => 'asset_instance',
        'assetRole' => 'instance',
        'assetInstanceSchemaVersion' => 1,
        'sourceElementId' => 'placed-asset-001',
        'sourceAssetElementId' => 'asset-tree-oak-001'
      }
    )

    result = serializer.serialize(
      instance,
      source_entity: source,
      placement: {
        position: [1.0, 2.0, 0.5],
        scale: 1.0,
        orientation: {
          mode: 'surface_aligned',
          yawDegrees: 30.0,
          sourceHeadingPreserved: false,
          surface: {
            hitPoint: [1.0, 2.0, 0.5],
            slopeDegrees: 11.5
          }
        }
      },
      include_bounds: false
    )

    assert_equal(
      {
        mode: 'surface_aligned',
        yawDegrees: 30.0,
        sourceHeadingPreserved: false,
        surface: {
          hitPoint: [1.0, 2.0, 0.5],
          slopeDegrees: 11.5
        }
      },
      result.dig(:placement, :orientation)
    )
  end

  def test_omits_bounds_when_not_requested
    serializer = SU_MCP::StagedAssets::AssetInstanceSerializer.new
    source = build_asset_group(attributes: approved_exemplar_attributes)
    instance = build_asset_group(
      entity_id: 901,
      attributes: {
        'managedSceneObject' => true,
        'semanticType' => 'asset_instance',
        'assetRole' => 'instance',
        'assetInstanceSchemaVersion' => 1,
        'sourceElementId' => 'placed-asset-001',
        'sourceAssetElementId' => 'asset-tree-oak-001'
      }
    )

    result = serializer.serialize(
      instance,
      source_entity: source,
      placement: { position: [1.0, 2.0, 0.0], scale: 1.0 },
      include_bounds: false
    )

    refute(result.key?(:bounds))
  end
end
