# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require_relative 'test_helper'
require_relative 'support/semantic_test_support'
require_relative '../src/su_mcp/semantic/managed_object_metadata'

class SemanticMetadataTest < Minitest::Test
  include SemanticTestSupport

  def test_writes_required_managed_object_attributes_to_su_mcp_dictionary
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new

    metadata.write!(
      entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'structureCategory' => 'extension'
    )

    assert_equal(true, entity.get_attribute('su_mcp', 'managedSceneObject'))
    assert_equal('house-extension-001', entity.get_attribute('su_mcp', 'sourceElementId'))
    assert_equal('structure', entity.get_attribute('su_mcp', 'semanticType'))
    assert_equal('extension', entity.get_attribute('su_mcp', 'structureCategory'))
  end
end
# rubocop:enable Metrics/MethodLength
