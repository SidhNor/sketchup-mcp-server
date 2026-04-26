# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/scene_query/scene_query_serializer'

class SceneQuerySerializerAssetExemplarTest < Minitest::Test
  include StagedAssetTestSupport

  def test_asset_exemplar_with_source_element_id_is_not_a_managed_scene_object
    entity = build_asset_group(attributes: approved_exemplar_attributes)
    serializer = SU_MCP::SceneQuerySerializer.new

    metadata = serializer.serialize_target_metadata(entity)
    match = serializer.serialize_target_match(entity)

    assert_equal(false, metadata.fetch(:managedSceneObject))
    assert_equal('asset-tree-oak-001', match.fetch(:sourceElementId))
    refute(match.key?(:managedSceneObject))
  end
end
