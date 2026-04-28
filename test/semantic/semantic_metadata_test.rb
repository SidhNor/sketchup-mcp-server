# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/managed_object_metadata'

class SemanticMetadataTest < Minitest::Test
  include SemanticTestSupport

  class HostLikeAttributeDictionary
    def initialize(values)
      @values = values
    end

    def each_pair(&block)
      raise 'no block given' unless block_given?

      @values.each_pair(&block)
    end
  end

  class HostLikeAttributeEntity
    # rubocop:disable Style/OptionalBooleanParameter
    def initialize(dictionary)
      @dictionary = dictionary
    end

    def attribute_dictionary(name, create = false)
      return nil if create
      return @dictionary if name == 'su_mcp'

      nil
    end
    # rubocop:enable Style/OptionalBooleanParameter
  end

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

  def test_detects_managed_scene_objects_from_the_su_mcp_dictionary
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )

    assert_equal(true, metadata.managed_object?(entity))
  end

  def test_reads_existing_semantic_attributes_for_managed_objects
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

    assert_equal(
      {
        'managedSceneObject' => true,
        'sourceElementId' => 'house-extension-001',
        'semanticType' => 'structure',
        'status' => 'proposed',
        'state' => 'Created',
        'schemaVersion' => 1,
        'structureCategory' => 'extension'
      },
      metadata.attributes_for(entity)
    )
  end

  def test_reads_existing_semantic_attributes_from_host_like_attribute_dictionaries
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    entity = HostLikeAttributeEntity.new(
      HostLikeAttributeDictionary.new(
        'managedSceneObject' => true,
        'sourceElementId' => 'host-like-001',
        'semanticType' => 'structure',
        'status' => 'proposed',
        'state' => 'Created',
        'schemaVersion' => 1
      )
    )

    assert_equal(
      {
        'managedSceneObject' => true,
        'sourceElementId' => 'host-like-001',
        'semanticType' => 'structure',
        'status' => 'proposed',
        'state' => 'Created',
        'schemaVersion' => 1
      },
      metadata.attributes_for(entity)
    )
  end

  def test_updates_supported_status_metadata_in_place
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

    result = metadata.update(entity, set: { 'status' => 'existing' }, clear: [])

    assert_equal('updated', result[:outcome])
    assert_equal('existing', entity.get_attribute('su_mcp', 'status'))
  end

  def test_refuses_protected_field_mutations
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'house-extension-001',
      'semanticType' => 'structure',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )

    result = metadata.update(entity, set: { 'sourceElementId' => 'house-extension-002' }, clear: [])

    assert_equal('refused', result[:outcome])
    assert_equal('protected_metadata_field', result.dig(:refusal, :code))
  end

  def test_refuses_clearing_required_metadata_fields
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

    result = metadata.update(entity, set: {}, clear: ['status'])

    assert_equal('refused', result[:outcome])
    assert_equal('required_metadata_field', result.dig(:refusal, :code))
  end

  def test_required_clear_refusal_exposes_contextual_allowed_values
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'hedge-001',
      'semanticType' => 'planting_mass',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'plantingCategory' => 'hedge'
    )

    result = metadata.update(entity, set: {}, clear: ['status'])

    assert_equal('refused', result[:outcome])
    assert_equal('required_metadata_field', result.dig(:refusal, :code))
    assert_equal('status', result.dig(:refusal, :details, :field))
    assert_equal(['plantingCategory'], result.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_invalid_structure_category_updates_for_structures
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

    result = metadata.update(entity, set: { 'structureCategory' => 'garage' }, clear: [])

    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal(
      %w[main_building outbuilding extension],
      result.dig(:refusal, :details, :allowedValues)
    )
  end

  def test_refuses_clearing_structure_category_for_structures
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

    result = metadata.update(entity, set: {}, clear: ['structureCategory'])

    assert_equal('refused', result[:outcome])
    assert_equal('required_metadata_field', result.dig(:refusal, :code))
    assert_equal('structureCategory', result.dig(:refusal, :details, :field))
  end

  def test_refuses_structure_category_updates_for_non_structure_objects
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'main-walk-001',
      'semanticType' => 'path',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )

    result = metadata.update(entity, set: { 'structureCategory' => 'extension' }, clear: [])

    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal(
      %w[main_building outbuilding extension],
      result.dig(:refusal, :details, :allowedValues)
    )
  end

  def test_refuses_unknown_clear_fields_with_contextual_allowed_values
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'hedge-001',
      'semanticType' => 'planting_mass',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'plantingCategory' => 'hedge'
    )

    result = metadata.update(entity, set: {}, clear: ['speciesHint'])

    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal('speciesHint', result.dig(:refusal, :details, :field))
    assert_nil(result.dig(:refusal, :details, :value))
    assert_equal(['plantingCategory'], result.dig(:refusal, :details, :allowedValues))
  end

  def test_updates_supported_planting_category_for_planting_mass_objects
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'hedge-001',
      'semanticType' => 'planting_mass',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'plantingCategory' => 'hedge'
    )

    result = metadata.update(entity, set: { 'plantingCategory' => 'groundcover' }, clear: [])

    assert_equal('updated', result[:outcome])
    assert_equal('groundcover', entity.get_attribute('su_mcp', 'plantingCategory'))
  end

  def test_refuses_planting_category_updates_for_non_planting_mass_objects
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'main-walk-001',
      'semanticType' => 'path',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )

    result = metadata.update(entity, set: { 'plantingCategory' => 'groundcover' }, clear: [])

    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal('plantingCategory', result.dig(:refusal, :details, :field))
  end

  def test_updates_supported_species_hint_for_tree_proxy_objects
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'tree-001',
      'semanticType' => 'tree_proxy',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1,
      'speciesHint' => 'cherry'
    )

    result = metadata.update(entity, set: { 'speciesHint' => 'plum' }, clear: [])

    assert_equal('updated', result[:outcome])
    assert_equal('plum', entity.get_attribute('su_mcp', 'speciesHint'))
  end

  def test_refuses_species_hint_updates_for_non_tree_proxy_objects
    entity = build_semantic_model.active_entities.add_group
    metadata = SU_MCP::Semantic::ManagedObjectMetadata.new
    metadata.write!(
      entity,
      'sourceElementId' => 'terrace-001',
      'semanticType' => 'pad',
      'status' => 'proposed',
      'state' => 'Created',
      'schemaVersion' => 1
    )

    result = metadata.update(entity, set: { 'speciesHint' => 'plum' }, clear: [])

    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_option', result.dig(:refusal, :code))
    assert_equal('speciesHint', result.dig(:refusal, :details, :field))
  end
end
