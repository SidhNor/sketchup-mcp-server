# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/asset_exemplar_serializer'

class AssetExemplarSerializerTest < Minitest::Test
  include StagedAssetTestSupport

  def test_serializes_json_safe_selection_summary_with_bounds
    serializer = SU_MCP::StagedAssets::AssetExemplarSerializer.new
    entity = build_asset_group(attributes: approved_exemplar_attributes)

    result = serializer.serialize(entity, include_bounds: true)

    assert_equal(expected_identity_summary, result.slice(
                                              :sourceElementId,
                                              :persistentId,
                                              :entityId,
                                              :type,
                                              :displayName,
                                              :category,
                                              :approvalState,
                                              :tags
                                            ))
    assert_equal('metadata_only', result.dig(:metadata, :stagingMode))
    assert_equal(1, result.dig(:metadata, :schemaVersion))
    assert_equal([0, 0, 0], result.dig(:bounds, :min))
  end

  def test_omits_bounds_when_not_requested
    serializer = SU_MCP::StagedAssets::AssetExemplarSerializer.new
    entity = build_asset_group(attributes: approved_exemplar_attributes)

    result = serializer.serialize(entity, include_bounds: false)

    refute(result.key?(:bounds))
  end

  private

  def expected_identity_summary
    {
      sourceElementId: 'asset-tree-oak-001',
      persistentId: '7801',
      entityId: '801',
      type: 'group',
      displayName: 'Oak Tree Exemplar',
      category: 'tree',
      approvalState: 'approved',
      tags: %w[tree deciduous]
    }
  end
end
