# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/asset_instance_metadata'

class AssetInstanceMetadataTest < Minitest::Test
  include StagedAssetTestSupport

  def setup
    @metadata = SU_MCP::StagedAssets::AssetInstanceMetadata.new
  end

  def test_prepares_instance_attributes_with_lean_lineage_and_exemplar_cleanup
    prepared = @metadata.prepare_instance(
      metadata: { 'sourceElementId' => 'placed-asset-001' },
      source_attributes: approved_exemplar_attributes('sourceElementId' => 'asset-tree-oak-001')
    )

    assert_equal('ready', prepared.fetch(:outcome))
    assert_equal(
      {
        'managedSceneObject' => true,
        'semanticType' => 'asset_instance',
        'assetRole' => 'instance',
        'assetInstanceSchemaVersion' => 1,
        'sourceElementId' => 'placed-asset-001',
        'sourceAssetElementId' => 'asset-tree-oak-001'
      },
      prepared.fetch(:attributes)
    )
    assert_equal(
      %w[assetExemplar assetExemplarSchemaVersion approvalState stagingMode],
      prepared.fetch(:clear)
    )
  end

  def test_applies_instance_attributes_and_removes_exemplar_fields
    entity = build_asset_group(attributes: approved_exemplar_attributes)
    prepared = {
      outcome: 'ready',
      attributes: {
        'managedSceneObject' => true,
        'semanticType' => 'asset_instance',
        'assetRole' => 'instance',
        'assetInstanceSchemaVersion' => 1,
        'sourceElementId' => 'placed-asset-001',
        'sourceAssetElementId' => 'asset-tree-oak-001'
      },
      clear: %w[assetExemplar assetExemplarSchemaVersion approvalState stagingMode]
    }

    @metadata.apply_prepared_instance(entity, prepared)

    assert_equal(true, entity.get_attribute('su_mcp', 'managedSceneObject'))
    assert_equal('asset_instance', entity.get_attribute('su_mcp', 'semanticType'))
    assert_equal('instance', entity.get_attribute('su_mcp', 'assetRole'))
    assert_equal('placed-asset-001', entity.get_attribute('su_mcp', 'sourceElementId'))
    assert_equal('asset-tree-oak-001', entity.get_attribute('su_mcp', 'sourceAssetElementId'))
    assert_nil(entity.get_attribute('su_mcp', 'assetExemplar'))
    assert_nil(entity.get_attribute('su_mcp', 'approvalState'))
    assert_nil(entity.get_attribute('su_mcp', 'stagingMode'))
  end

  def test_missing_instance_source_element_id_refuses_before_write
    result = @metadata.prepare_instance(
      metadata: { 'sourceElementId' => ' ' },
      source_attributes: approved_exemplar_attributes
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('missing_required_metadata', result.dig(:refusal, :code))
    assert_equal({ field: 'metadata.sourceElementId' }, result.dig(:refusal, :details))
  end
end
