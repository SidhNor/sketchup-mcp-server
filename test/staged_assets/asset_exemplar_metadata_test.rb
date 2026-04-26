# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/asset_exemplar_metadata'

class AssetExemplarMetadataTest < Minitest::Test
  include StagedAssetTestSupport

  def setup
    @metadata = SU_MCP::StagedAssets::AssetExemplarMetadata.new
  end

  def test_recognizes_complete_approved_exemplar_metadata
    entity = build_asset_group(attributes: approved_exemplar_attributes)

    assert_equal(true, @metadata.approved_exemplar?(entity))
  end

  def test_rejects_incomplete_exemplar_metadata
    entity = build_asset_group(
      attributes: approved_exemplar_attributes('assetDisplayName' => '')
    )

    assert_equal(false, @metadata.approved_exemplar?(entity))
  end

  def test_prepare_curation_normalizes_metadata_without_managed_scene_fields
    entity = build_asset_group(attributes: {})

    prepared = @metadata.prepare_curation(
      entity,
      metadata: {
        'sourceElementId' => 'asset-tree-oak-001',
        'category' => 'tree',
        'displayName' => 'Oak Tree Exemplar',
        'tags' => %w[tree deciduous],
        'attributes' => { 'species' => 'oak' }
      },
      approval: { 'state' => 'approved' },
      staging: { 'mode' => 'metadata_only' }
    )

    assert_equal('ready', prepared.fetch(:outcome))
    refute_includes(prepared.fetch(:attributes), 'managedSceneObject')
    refute_includes(prepared.fetch(:attributes), 'semanticType')
    refute_includes(prepared.fetch(:attributes), 'state')
    refute_includes(prepared.fetch(:attributes), 'status')
  end

  def test_prepare_curation_drops_non_json_safe_nested_asset_attributes
    entity = build_asset_group(attributes: {})

    prepared = @metadata.prepare_curation(
      entity,
      metadata: metadata_with_non_json_safe_values,
      approval: { 'state' => 'approved' },
      staging: { 'mode' => 'metadata_only' }
    )

    assert_equal(
      {
        'species' => 'oak',
        'nested' => { 'safe' => true },
        'array' => ['ok']
      },
      prepared.dig(:attributes, 'assetAttributes')
    )
  end

  def test_unsupported_finite_options_return_field_value_and_allowed_values
    entity = build_asset_group(attributes: {})

    result = @metadata.prepare_curation(
      entity,
      metadata: {
        'sourceElementId' => 'asset-tree-oak-001',
        'category' => 'tree',
        'displayName' => 'Oak Tree Exemplar'
      },
      approval: { 'state' => 'draft' },
      staging: { 'mode' => 'metadata_only' }
    )

    assert_equal('unsupported_approval_state', result.dig(:refusal, :code))
    assert_equal(
      {
        field: 'approval.state',
        value: 'draft',
        allowedValues: ['approved']
      },
      result.dig(:refusal, :details)
    )
  end

  private

  def metadata_with_non_json_safe_values
    {
      'sourceElementId' => 'asset-tree-oak-001',
      'category' => 'tree',
      'displayName' => 'Oak Tree Exemplar',
      'attributes' => {
        'species' => 'oak',
        'bad' => Object.new,
        'nested' => { 'safe' => true, 'bad' => Object.new },
        'array' => ['ok', Object.new]
      }
    }
  end
end
