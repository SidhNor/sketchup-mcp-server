# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/staged_asset_commands'
require_relative '../../src/su_mcp/staged_assets/asset_exemplar_metadata'
require_relative '../../src/su_mcp/staged_assets/asset_exemplar_query'
require_relative '../../src/su_mcp/staged_assets/asset_exemplar_serializer'

class StagedAssetCommandsTest < Minitest::Test
  include StagedAssetTestSupport

  def setup
    @entity = build_asset_group(attributes: { 'sourceElementId' => 'curatable-source-001' })
    @model = staged_asset_model(@entity)
    Sketchup.active_model_override = @model
    @commands = SU_MCP::StagedAssets::StagedAssetCommands.new
  end

  def teardown
    Sketchup.active_model_override = nil
  end

  def test_curates_existing_group_as_approved_exemplar_and_lists_it
    result = @commands.curate_staged_asset(curation_request)

    assert_equal(true, result.fetch(:success))
    assert_equal('curated', result.fetch(:outcome))
    assert_equal('asset-tree-oak-001', @entity.get_attribute('su_mcp', 'sourceElementId'))
    assert_equal(true, @entity.get_attribute('su_mcp', 'assetExemplar'))
    assert_equal('metadata_only', @entity.get_attribute('su_mcp', 'stagingMode'))
    assert_equal([[:start_operation, 'Curate Staged Asset', true], [:commit_operation]],
                 @model.operations)

    listed = @commands.list_staged_assets('filters' => { 'category' => 'tree' })
    assert_equal(['asset-tree-oak-001'], source_element_ids(listed))
  end

  def test_refused_curation_with_missing_metadata_writes_no_partial_exemplar_attributes
    result = @commands.curate_staged_asset(
      curation_request.merge('metadata' => { 'sourceElementId' => 'asset-tree-oak-001' })
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_nil(@entity.get_attribute('su_mcp', 'assetExemplar'))
    assert_nil(@entity.get_attribute('su_mcp', 'approvalState'))
    assert_nil(@entity.get_attribute('su_mcp', 'assetRole'))
    assert_equal([], @model.operations)
  end

  def test_refused_curation_with_unsupported_staging_mode_exposes_allowed_values
    result = @commands.curate_staged_asset(
      curation_request.merge('staging' => { 'mode' => 'tagged_library' })
    )

    assert_equal('unsupported_staging_mode', result.dig(:refusal, :code))
    assert_equal(
      {
        field: 'staging.mode',
        value: 'tagged_library',
        allowedValues: ['metadata_only']
      },
      result.dig(:refusal, :details)
    )
    assert_nil(@entity.get_attribute('su_mcp', 'assetExemplar'))
  end

  def test_refuses_missing_target_without_writes
    result = @commands.curate_staged_asset(curation_request.merge('targetReference' => {}))

    assert_equal('missing_target', result.dig(:refusal, :code))
    assert_nil(@entity.get_attribute('su_mcp', 'assetExemplar'))
  end

  def test_refuses_unsupported_target_type
    face = build_scene_query_face(
      entity_id: 888,
      origin_x: 0,
      layer: staged_asset_layer,
      material: staged_asset_material,
      details: {
        name: 'Loose Face',
        persistent_id: 8888,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'loose-face-001' } }
      }
    )
    Sketchup.active_model_override = staged_asset_model(face)

    result = @commands.curate_staged_asset(
      curation_request.merge('targetReference' => { 'sourceElementId' => 'loose-face-001' })
    )

    assert_equal('unsupported_target_type', result.dig(:refusal, :code))
  end

  private

  def curation_request
    {
      'targetReference' => { 'sourceElementId' => 'curatable-source-001' },
      'metadata' => {
        'sourceElementId' => 'asset-tree-oak-001',
        'category' => 'tree',
        'displayName' => 'Oak Tree Exemplar',
        'tags' => %w[tree deciduous],
        'attributes' => { 'species' => 'oak' }
      },
      'approval' => { 'state' => 'approved' },
      'staging' => { 'mode' => 'metadata_only' },
      'outputOptions' => { 'includeBounds' => true }
    }
  end

  def source_element_ids(result)
    result.fetch(:assets).map { |asset| asset[:sourceElementId] }
  end
end
