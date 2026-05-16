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

  def test_curates_and_lists_asset_without_optional_tags_or_attributes
    result = @commands.curate_staged_asset(
      curation_request.merge(
        'metadata' => {
          'sourceElementId' => 'asset-minimal-001',
          'category' => 'fixture',
          'displayName' => 'Minimal Exemplar'
        }
      )
    )

    assert_equal(true, result.fetch(:success))
    assert_equal('curated', result.fetch(:outcome))

    listed = @commands.list_staged_assets('filters' => { 'category' => 'fixture' })
    assert_equal(['asset-minimal-001'], source_element_ids(listed))
    assert_equal({}, listed.fetch(:assets).first.dig(:metadata, :attributes))
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

  def test_instantiates_approved_component_exemplar_as_managed_instance
    source = build_asset_component(attributes: approved_exemplar_attributes)
    created = build_asset_component(entity_id: 901, attributes: {})
    Sketchup.active_model_override = staged_asset_model(source)
    commands = SU_MCP::StagedAssets::StagedAssetCommands.new(
      creator: RecordingInstanceCreator.new(created)
    )

    result = commands.instantiate_staged_asset(instantiate_request)

    assert_equal(true, result.fetch(:success))
    assert_equal('instantiated', result.fetch(:outcome))
    assert_equal('placed-asset-001', result.dig(:instance, :sourceElementId))
    assert_equal('asset_instance', result.dig(:instance, :semanticType))
    assert_equal('asset-tree-oak-001', result.dig(:lineage, :sourceAssetElementId))
    assert_default_placement_evidence(result)
    assert_equal([[:start_operation, 'Instantiate Staged Asset', true], [:commit_operation]],
                 Sketchup.active_model.operations)
    assert_equal(true, source.get_attribute('su_mcp', 'assetExemplar'))
  end

  def test_instantiates_with_explicit_upright_yaw_evidence
    source = build_asset_component(attributes: approved_exemplar_attributes)
    created = build_asset_component(entity_id: 901, attributes: {})
    recorder = RecordingInstanceCreator.new(created)
    Sketchup.active_model_override = staged_asset_model(source)
    commands = SU_MCP::StagedAssets::StagedAssetCommands.new(creator: recorder)

    result = commands.instantiate_staged_asset(
      instantiate_request.merge(
        'placement' => {
          'position' => [1.0, 2.0, 0.0],
          'orientation' => { 'mode' => 'upright', 'yawDegrees' => 45 }
        }
      )
    )

    assert_equal('instantiated', result.fetch(:outcome))
    assert_equal('upright', result.dig(:placement, :orientation, :mode))
    assert_equal(45.0, result.dig(:placement, :orientation, :yawDegrees))
    assert_equal(false, result.dig(:placement, :orientation, :sourceHeadingPreserved))
    assert_equal('upright', recorder.calls.first.dig(:placement, :orientation, :mode))
  end

  def test_omitted_orientation_preserves_source_heading_in_response_evidence
    source = build_asset_component(attributes: approved_exemplar_attributes)
    created = build_asset_component(entity_id: 901, attributes: {})
    Sketchup.active_model_override = staged_asset_model(source)
    commands = SU_MCP::StagedAssets::StagedAssetCommands.new(
      creator: RecordingInstanceCreator.new(created)
    )

    result = commands.instantiate_staged_asset(instantiate_request)

    assert_equal('upright', result.dig(:placement, :orientation, :mode))
    assert_nil(result.dig(:placement, :orientation, :yawDegrees))
    assert_equal(true, result.dig(:placement, :orientation, :sourceHeadingPreserved))
  end

  def test_refuses_misplaced_top_level_orientation_before_mutation
    source = build_asset_group(attributes: approved_exemplar_attributes)
    Sketchup.active_model_override = staged_asset_model(source)

    result = @commands.instantiate_staged_asset(
      instantiate_request.merge('orientation' => { 'mode' => 'upright' })
    )

    assert_equal('unsupported_request_field', result.dig(:refusal, :code))
    assert_equal('orientation', result.dig(:refusal, :details, :field))
    assert_equal([], Sketchup.active_model.operations)
  end

  def test_refuses_surface_aligned_without_surface_reference_before_mutation
    source = build_asset_group(attributes: approved_exemplar_attributes)
    Sketchup.active_model_override = staged_asset_model(source)

    result = @commands.instantiate_staged_asset(
      instantiate_request.merge(
        'placement' => {
          'position' => [1.0, 2.0, 0.0],
          'orientation' => { 'mode' => 'surface_aligned' }
        }
      )
    )

    assert_equal('missing_surface_reference', result.dig(:refusal, :code))
    assert_equal('placement.orientation.surfaceReference',
                 result.dig(:refusal, :details, :field))
    assert_equal([], Sketchup.active_model.operations)
  end

  def test_surface_aligned_placement_uses_resolved_hit_z_and_compact_evidence
    source = build_asset_component(attributes: approved_exemplar_attributes)
    created = build_asset_component(entity_id: 901, attributes: {})
    surface_origin = SceneQueryTestSupport::FakePoint.new(
      39.37007874015748,
      78.74015748031496,
      19.68503937007874
    )
    resolver = ReadySurfaceFrameResolver.new(
      origin: surface_origin,
      evidence: {
        hitPoint: [1.0, 2.0, 0.5],
        slopeDegrees: 11.5
      }
    )
    Sketchup.active_model_override = staged_asset_model(source)
    commands = SU_MCP::StagedAssets::StagedAssetCommands.new(
      creator: RecordingInstanceCreator.new(created),
      surface_frame_resolver: resolver
    )

    result = commands.instantiate_staged_asset(
      instantiate_request.merge(
        'placement' => {
          'position' => [1.0, 2.0, 0.0],
          'orientation' => {
            'mode' => 'surface_aligned',
            'yawDegrees' => 30,
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' }
          }
        }
      )
    )

    assert_equal([1.0, 2.0, 0.5], result.dig(:placement, :position))
    assert_equal('surface_aligned', result.dig(:placement, :orientation, :mode))
    assert_equal([1.0, 2.0, 0.5],
                 result.dig(:placement, :orientation, :surface, :hitPoint))
    assert_equal(11.5, result.dig(:placement, :orientation, :surface, :slopeDegrees))
  end

  def test_surface_refusal_happens_before_operation_or_mutation
    source = build_asset_component(attributes: approved_exemplar_attributes)
    resolver = RefusingSurfaceFrameResolver.new(
      code: 'ambiguous_surface_frame',
      details: { field: 'placement.orientation.surfaceReference' }
    )
    Sketchup.active_model_override = staged_asset_model(source)
    commands = SU_MCP::StagedAssets::StagedAssetCommands.new(
      creator: RaisingInstanceCreator.new,
      surface_frame_resolver: resolver
    )

    result = commands.instantiate_staged_asset(
      instantiate_request.merge(
        'placement' => {
          'position' => [1.0, 2.0, 0.0],
          'orientation' => {
            'mode' => 'surface_aligned',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' }
          }
        }
      )
    )

    assert_equal('ambiguous_surface_frame', result.dig(:refusal, :code))
    assert_equal([], Sketchup.active_model.operations)
  end

  def test_instantiated_instance_is_not_returned_by_staged_asset_listing
    source = build_asset_group(attributes: approved_exemplar_attributes)
    created = build_asset_group(entity_id: 901, attributes: {})
    Sketchup.active_model_override = staged_asset_model(source, created)
    commands = SU_MCP::StagedAssets::StagedAssetCommands.new(
      creator: RecordingInstanceCreator.new(created)
    )

    commands.instantiate_staged_asset(instantiate_request)
    listed = commands.list_staged_assets('filters' => { 'category' => 'tree' })

    assert_equal(['asset-tree-oak-001'], source_element_ids(listed))
    refute_includes(source_element_ids(listed), 'placed-asset-001')
  end

  def test_refuses_unapproved_exemplar_before_mutation
    source = build_asset_group(
      attributes: approved_exemplar_attributes('approvalState' => 'draft')
    )
    Sketchup.active_model_override = staged_asset_model(source)

    result = @commands.instantiate_staged_asset(instantiate_request)

    assert_equal('unapproved_exemplar', result.dig(:refusal, :code))
    assert_equal([], Sketchup.active_model.operations)
  end

  def test_refuses_missing_instance_identity_before_mutation
    source = build_asset_group(attributes: approved_exemplar_attributes)
    Sketchup.active_model_override = staged_asset_model(source)

    result = @commands.instantiate_staged_asset(
      instantiate_request.merge('metadata' => { 'sourceElementId' => ' ' })
    )

    assert_equal('missing_required_metadata', result.dig(:refusal, :code))
    assert_equal({ field: 'metadata.sourceElementId' }, result.dig(:refusal, :details))
    assert_equal([], Sketchup.active_model.operations)
  end

  def test_refuses_invalid_placement_position_before_mutation
    source = build_asset_group(attributes: approved_exemplar_attributes)
    Sketchup.active_model_override = staged_asset_model(source)

    result = @commands.instantiate_staged_asset(
      instantiate_request.merge('placement' => { 'position' => [1.0, 2.0] })
    )

    assert_equal('invalid_placement', result.dig(:refusal, :code))
    assert_equal('placement.position', result.dig(:refusal, :details, :field))
    assert_equal([1.0, 2.0], result.dig(:refusal, :details, :value))
    assert_equal([], Sketchup.active_model.operations)
  end

  def test_refuses_invalid_scale_before_mutation
    source = build_asset_group(attributes: approved_exemplar_attributes)
    Sketchup.active_model_override = staged_asset_model(source)

    result = @commands.instantiate_staged_asset(
      instantiate_request.merge('placement' => { 'position' => [1.0, 2.0, 0.0], 'scale' => 0 })
    )

    assert_equal('invalid_scale', result.dig(:refusal, :code))
    assert_equal(
      { field: 'placement.scale', value: 0 },
      result.dig(:refusal, :details)
    )
    assert_equal([], Sketchup.active_model.operations)
  end

  def test_aborts_sketchup_operation_when_creation_fails
    source = build_asset_group(attributes: approved_exemplar_attributes)
    Sketchup.active_model_override = staged_asset_model(source)
    commands = SU_MCP::StagedAssets::StagedAssetCommands.new(
      creator: RaisingInstanceCreator.new
    )

    assert_raises(RuntimeError) do
      commands.instantiate_staged_asset(instantiate_request)
    end

    assert_equal([[:start_operation, 'Instantiate Staged Asset', true], [:abort_operation]],
                 Sketchup.active_model.operations)
    assert_nil(source.get_attribute('su_mcp', 'managedSceneObject'))
  end

  private

  class RecordingInstanceCreator
    attr_reader :calls

    def initialize(created)
      @created = created
      @calls = []
    end

    def create(source, placement:)
      @calls << { source: source, placement: placement }
      @created
    end
  end

  class RaisingInstanceCreator
    def create(_source, placement:)
      raise "creation failed for #{placement.inspect}"
    end
  end

  class ReadySurfaceFrameResolver
    def initialize(origin:, evidence:)
      @origin = origin
      @evidence = evidence
    end

    def resolve(surface_reference:, sample_position:)
      {
        outcome: 'ready',
        frame: {
          origin: @origin,
          x_axis: [1.0, 0.0, 0.0],
          y_axis: [0.0, 1.0, 0.0],
          up_axis: [0.0, 0.0, 1.0],
          evidence: @evidence.merge(
            surfaceReference: surface_reference,
            requestedPosition: sample_position
          )
        }
      }
    end
  end

  class RefusingSurfaceFrameResolver
    def initialize(code:, details:)
      @code = code
      @details = details
    end

    def resolve(surface_reference:, sample_position:)
      {
        outcome: 'refused',
        refusal: {
          code: @code,
          message: "refused #{surface_reference.inspect} at #{sample_position.inspect}",
          details: @details
        }
      }
    end
  end

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

  def instantiate_request
    {
      'targetReference' => { 'sourceElementId' => 'asset-tree-oak-001' },
      'placement' => { 'position' => [1.0, 2.0, 0.0] },
      'metadata' => { 'sourceElementId' => 'placed-asset-001' },
      'outputOptions' => { 'includeBounds' => true }
    }
  end

  def source_element_ids(result)
    result.fetch(:assets).map { |asset| asset[:sourceElementId] }
  end

  def assert_default_placement_evidence(result)
    assert_equal([1.0, 2.0, 0.0], result.dig(:placement, :position))
    assert_equal(1.0, result.dig(:placement, :scale))
    assert_equal('upright', result.dig(:placement, :orientation, :mode))
    assert_equal(true, result.dig(:placement, :orientation, :sourceHeadingPreserved))
  end
end
