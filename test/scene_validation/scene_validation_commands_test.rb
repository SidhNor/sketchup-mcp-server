# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/runtime/tool_response'
require_relative '../../src/su_mcp/scene_validation/scene_validation_commands'

# rubocop:disable Metrics/ClassLength
class SceneValidationCommandsTest < Minitest::Test
  include SceneQueryTestSupport

  class RecordingAdapter
    attr_reader :entities, :calls

    # rubocop:disable Naming/PredicateMethod
    def initialize(entities:)
      @entities = entities
      @calls = []
    end

    def active_model!
      @calls << :active_model!
      true
    end
    # rubocop:enable Naming/PredicateMethod

    def all_entities_recursive
      @calls << :all_entities_recursive
      entities
    end
  end

  class FakeTargetReferenceResolver
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def resolve(target_reference)
      @calls << target_reference
      @result
    end
  end

  class FakeTargetingQuery
    attr_reader :normalized_calls, :filter_calls

    def initialize(normalized_selector: nil, matches: [], resolution: 'unique')
      @normalized_selector = normalized_selector || { 'identity' => { 'entityId' => '101' } }
      @matches = matches
      @resolution = resolution
      @normalized_calls = []
      @filter_calls = []
    end

    def normalized_target_selector(target_selector)
      @normalized_calls << target_selector
      @normalized_selector
    end

    def filter(entities, target_selector)
      @filter_calls << [entities, target_selector]
      @matches
    end

    def resolution_for(_matches)
      @resolution
    end
  end

  class FakeSerializer
    def serialize_target_match(entity)
      {
        sourceElementId: entity.get_attribute('su_mcp', 'sourceElementId'),
        persistentId: entity.respond_to?(:persistent_id) ? entity.persistent_id.to_s : nil,
        entityId: entity.entityID.to_s,
        type: 'group',
        name: entity.name,
        tag: entity.layer&.name,
        material: entity.material&.display_name
      }.compact
    end

    def public_surface_entity?(entity)
      !entity.get_attribute('su_mcp', 'placeholder', false)
    end
  end

  class FakeGeometryHealth
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def inspect(entity)
      @calls << entity
      @result
    end
  end

  def setup
    @layer = FakeLayer.new('Proposed')
    @material = FakeMaterial.new('Concrete')
    @group = build_scene_query_group(
      entity_id: 101,
      origin_x: 0,
      layer: @layer,
      material: @material,
      details: {
        persistent_id: 1001,
        name: 'Main Walk',
        attributes: {
          'su_mcp' => {
            'sourceElementId' => 'path-main',
            'status' => 'proposed',
            'semanticType' => 'path'
          }
        }
      }
    )
  end

  def test_refuses_missing_expectations
    commands = build_commands

    result = commands.validate_scene_update({})

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_expectations', result.dig(:refusal, :code))
  end

  def test_refuses_unsupported_top_level_request_keys
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {},
      'outputOptions' => { 'includeEvidence' => true }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_request_field', result.dig(:refusal, :code))
  end

  def test_refuses_expectation_objects_that_provide_both_target_reference_and_target_selector
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'mustExist' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'targetSelector' => { 'identity' => { 'entityId' => '101' } }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_target_input', result.dig(:refusal, :code))
  end

  def test_refuses_expectation_objects_that_provide_neither_target_reference_nor_target_selector
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'mustExist' => [{ 'expectationId' => 'missing-target' }]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_target_input', result.dig(:refusal, :code))
  end

  def test_refuses_metadata_requirements_without_required_keys
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'metadataRequirements' => [
          { 'targetReference' => { 'entityId' => '101' } }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
  end

  def test_refuses_geometry_requirements_without_kind
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          { 'targetReference' => { 'entityId' => '101' } }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
  end

  def test_reports_none_resolution_as_a_validation_error_for_target_references
    target_resolver = FakeTargetReferenceResolver.new({ resolution: 'none' })
    commands = build_commands(target_reference_resolver: target_resolver)

    result = commands.validate_scene_update(
      'expectations' => {
        'mustExist' => [{ 'targetReference' => { 'entityId' => '999' } }]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, result[:errors].length)
  end

  # rubocop:disable Metrics/MethodLength
  def test_target_reference_results_still_respect_public_surface_filtering
    placeholder_group = build_scene_query_group(
      entity_id: 303,
      origin_x: 0,
      layer: @layer,
      material: @material,
      details: {
        persistent_id: 3003,
        name: 'Placeholder Walk',
        attributes: {
          'su_mcp' => {
            'sourceElementId' => 'placeholder-walk',
            'placeholder' => true
          }
        }
      }
    )
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: placeholder_group }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'mustExist' => [
          { 'targetReference' => { 'sourceElementId' => 'placeholder-walk' } }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal('none', result.dig(:errors, 0, :details, :resolution))
  end
  # rubocop:enable Metrics/MethodLength

  def test_reports_ambiguous_resolution_as_a_validation_error_for_target_selectors
    targeting_query = FakeTargetingQuery.new(matches: [@group], resolution: 'ambiguous')
    commands = build_commands(targeting_query: targeting_query)

    result = commands.validate_scene_update(
      'expectations' => {
        'mustExist' => [
          { 'targetSelector' => { 'identity' => { 'sourceElementId' => 'path-main' } } }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, result[:errors].length)
  end

  def test_must_exist_passes_for_a_uniquely_resolved_target
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'mustExist' => [{ 'targetReference' => { 'sourceElementId' => 'path-main' } }]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('passed', result[:outcome])
  end

  def test_must_preserve_treats_continued_unique_resolution_as_success
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'mustPreserve' => [{ 'targetReference' => { 'persistentId' => '1001' } }]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('passed', result[:outcome])
  end

  def test_metadata_requirements_fail_when_required_keys_are_missing
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'metadataRequirements' => [
          {
            'targetReference' => { 'sourceElementId' => 'path-main' },
            'requiredKeys' => %w[sourceElementId state]
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, result[:errors].length)
  end

  def test_tag_requirements_fail_when_the_resolved_target_has_the_wrong_tag
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'tagRequirements' => [
          {
            'targetReference' => { 'sourceElementId' => 'path-main' },
            'expectedTag' => 'Existing'
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, result[:errors].length)
  end

  def test_material_requirements_fail_when_the_resolved_target_has_the_wrong_material
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'materialRequirements' => [
          {
            'targetReference' => { 'sourceElementId' => 'path-main' },
            'expectedMaterial' => 'Asphalt'
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, result[:errors].length)
  end

  def test_reports_findings_with_expectation_correlation
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'none' }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'mustExist' => [
          {
            'targetReference' => { 'entityId' => '999' },
            'expectationId' => 'missing-walk'
          }
        ]
      }
    )

    assert_equal('mustExist', result.dig(:errors, 0, :expectationFamily))
    assert_equal(0, result.dig(:errors, 0, :expectationIndex))
    assert_equal('missing-walk', result.dig(:errors, 0, :expectationId))
  end

  def test_must_have_geometry_fails_when_the_resolved_target_has_no_geometry
    geometry_health = FakeGeometryHealth.new(result: { hasGeometry: false })
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      ),
      geometry_health: geometry_health
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'sourceElementId' => 'path-main' },
            'kind' => 'mustHaveGeometry'
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, geometry_health.calls.length)
  end

  def test_must_not_be_non_manifold_fails_when_geometry_health_reports_a_non_manifold_result
    geometry_health = FakeGeometryHealth.new(result: { hasGeometry: true, nonManifold: true })
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      ),
      geometry_health: geometry_health
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'sourceElementId' => 'path-main' },
            'kind' => 'mustNotBeNonManifold'
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, result[:errors].length)
  end

  def test_must_be_valid_solid_fails_only_when_explicitly_requested
    geometry_health = FakeGeometryHealth.new(result: { hasGeometry: true, validSolid: false })
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      ),
      geometry_health: geometry_health
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'sourceElementId' => 'path-main' },
            'kind' => 'mustBeValidSolid'
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal(1, result[:errors].length)
  end

  # rubocop:disable Metrics/MethodLength
  def test_geometry_requirements_refuse_unsupported_target_types
    face = build_scene_query_face(
      entity_id: 222,
      origin_x: 0,
      layer: @layer,
      material: @material,
      details: { persistent_id: 2002, name: 'Face Target' }
    )
    commands = build_commands(
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: face }
      )
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '222' },
            'kind' => 'mustNotBeNonManifold'
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_target_type', result.dig(:refusal, :code))
  end
  # rubocop:enable Metrics/MethodLength

  private

  def build_commands(target_reference_resolver: nil, targeting_query: nil, serializer: nil,
                     geometry_health: nil)
    SU_MCP::SceneValidationCommands.new(
      adapter: RecordingAdapter.new(entities: [@group]),
      target_reference_resolver: target_reference_resolver || FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: @group }
      ),
      targeting_query: targeting_query || FakeTargetingQuery.new(matches: [@group]),
      serializer: serializer || FakeSerializer.new,
      geometry_health: geometry_health || FakeGeometryHealth.new(result: { hasGeometry: true })
    )
  end
end
# rubocop:enable Metrics/ClassLength
