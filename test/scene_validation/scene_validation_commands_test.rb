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

    def entity_type_key(entity)
      case entity
      when Sketchup::Group
        'group'
      when Sketchup::ComponentInstance
        'componentinstance'
      when Sketchup::Face
        'face'
      when Sketchup::Edge
        'edge'
      else
        entity.class.name.split('::').last.downcase
      end
    end

    def serialize_xy_sample_point(x_value, y_value)
      { x: x_value, y: y_value }
    end

    def serialize_xyz_sample_point(x_value, y_value, z_value)
      { x: x_value, y: y_value, z: z_value }
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

  class FakeLength
    def initialize(meters)
      @meters = meters
    end

    def to_m
      @meters
    end
  end

  class RecordingSampleSurfaceQuery
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def execute(entities:, params:)
      @calls << { entities: entities, params: params }
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

  def test_refuses_surface_offset_geometry_requirements_without_surface_reference
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
            'constraints' => { 'expectedOffset' => 0.0, 'tolerance' => 0.02 }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
    assert_match(/surfaceReference/, result.dig(:refusal, :message))
  end

  def test_refuses_surface_offset_geometry_requirements_without_anchor_selector
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
            'constraints' => { 'expectedOffset' => 0.0, 'tolerance' => 0.02 }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
    assert_match(/anchorSelector/, result.dig(:refusal, :message))
  end

  def test_refuses_surface_offset_geometry_requirements_without_constraints
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
            'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
    assert_match(/constraints/, result.dig(:refusal, :message))
  end

  def test_refuses_surface_offset_geometry_requirements_without_expected_offset
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
            'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
            'constraints' => { 'tolerance' => 0.02 }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
    assert_match(/expectedOffset/, result.dig(:refusal, :message))
  end

  def test_refuses_surface_offset_geometry_requirements_without_tolerance
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
            'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
            'constraints' => { 'expectedOffset' => 0.0 }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
    assert_match(/tolerance/, result.dig(:refusal, :message))
  end

  def test_refuses_surface_offset_geometry_requirements_with_non_numeric_expected_offset
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
            'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
            'constraints' => { 'expectedOffset' => 'zero', 'tolerance' => 0.02 }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
    assert_match(/expectedOffset/, result.dig(:refusal, :message))
  end

  def test_refuses_surface_offset_geometry_requirements_with_non_numeric_tolerance
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
            'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
            'constraints' => { 'expectedOffset' => 0.0, 'tolerance' => 'tight' }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_expectation', result.dig(:refusal, :code))
    assert_match(/tolerance/, result.dig(:refusal, :message))
  end

  # rubocop:disable Metrics/MethodLength
  def test_refuses_unsupported_surface_offset_anchor_selector_and_echoes_allowed_values
    commands = build_commands

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          {
            'targetReference' => { 'entityId' => '101' },
            'kind' => 'surfaceOffset',
            'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
            'anchorSelector' => { 'anchor' => 'footprint_vertices' },
            'constraints' => { 'expectedOffset' => 0.0, 'tolerance' => 0.02 }
          }
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_anchor_selector', result.dig(:refusal, :code))
    assert_equal('anchorSelector.anchor', result.dig(:refusal, :details, :field))
    assert_equal('footprint_vertices', result.dig(:refusal, :details, :value))
    assert_equal(
      %w[
        approximate_bottom_bounds_center
        approximate_bottom_bounds_corners
        approximate_top_bounds_center
        approximate_top_bounds_corners
      ],
      result.dig(:refusal, :details, :allowedValues)
    )
  end
  # rubocop:enable Metrics/MethodLength

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

  # rubocop:disable Metrics/MethodLength
  def test_surface_offset_passes_when_approximate_bottom_bounds_corners_match_expected_offset
    terrain_layer = FakeLayer.new('Terrain')
    terrain_material = FakeMaterial.new('Soil')
    terrain_face = build_sample_surface_face(
      entity_id: 401,
      persistent_id: 4001,
      name: 'Terrain Face',
      layer: terrain_layer,
      material: terrain_material,
      x_range: [0.0, 1.0],
      y_range: [0.0, 2.0],
      z_value: 0.0
    )
    terrain_group = build_sample_surface_group(
      entity_id: 402,
      persistent_id: 4002,
      name: 'Terrain Group',
      layer: terrain_layer,
      material: terrain_material,
      child_faces: [terrain_face],
      source_element_id: 'terrain-main'
    )
    commands = build_commands(
      adapter_entities: [@group, terrain_group],
      target_reference_resolver: :real
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          surface_offset_expectation
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('passed', result[:outcome])
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def test_surface_offset_reports_failed_anchors_for_offset_mismatch
    terrain_layer = FakeLayer.new('Terrain')
    terrain_material = FakeMaterial.new('Soil')
    terrain_face = build_sample_surface_face(
      entity_id: 411,
      persistent_id: 4011,
      name: 'Terrain Face',
      layer: terrain_layer,
      material: terrain_material,
      x_range: [0.0, 1.0],
      y_range: [0.0, 2.0],
      z_value: 0.0
    )
    terrain_group = build_sample_surface_group(
      entity_id: 412,
      persistent_id: 4012,
      name: 'Terrain Group',
      layer: terrain_layer,
      material: terrain_material,
      child_faces: [terrain_face],
      source_element_id: 'terrain-main'
    )
    commands = build_commands(
      adapter_entities: [@group, terrain_group],
      target_reference_resolver: :real
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          surface_offset_expectation(
            'constraints' => { 'expectedOffset' => 1.0, 'tolerance' => 0.02 }
          )
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal('geometry_requirement_failed', result.dig(:errors, 0, :type))
    assert_equal('surfaceOffset', result.dig(:errors, 0, :details, :kind))
    refute_empty(result.dig(:errors, 0, :details, :failedAnchors))
    assert_equal(
      'approximate_bottom_bounds_corners',
      result.dig(:errors, 0, :details, :failedAnchors, 0, :anchorSelector, :anchor)
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_surface_offset_reports_surface_sampling_failures_as_validation_errors
    commands = build_commands(
      adapter_entities: [@group],
      target_reference_resolver: :real
    )

    result = commands.validate_scene_update(
      'expectations' => {
        'geometryRequirements' => [
          surface_offset_expectation(
            'surfaceReference' => { 'sourceElementId' => 'terrain-missing' }
          )
        ]
      }
    )

    assert_equal(true, result[:success])
    assert_equal('failed', result[:outcome])
    assert_equal('surface_sampling_failed', result.dig(:errors, 0, :type))
    assert_match(/resolves to no entity/, result.dig(:errors, 0, :details, :samplingError))
  end

  def test_surface_offset_converts_anchor_coordinates_and_disables_visibility_filtering
    custom_group = measured_group
    sample_surface_query = RecordingSampleSurfaceQuery.new(result: successful_surface_offset_hit)
    commands = build_commands(
      adapter_entities: [custom_group],
      target_reference_resolver: FakeTargetReferenceResolver.new(
        { resolution: 'unique', entity: custom_group }
      ),
      sample_surface_query: sample_surface_query
    )

    result = commands.validate_scene_update(surface_offset_request_for_center_anchor)

    assert_surface_offset_sampling_contract(result, sample_surface_query)
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
                     geometry_health: nil, adapter_entities: nil, sample_surface_query: nil)
    adapter = RecordingAdapter.new(entities: adapter_entities || [@group])
    serializer_instance = serializer || FakeSerializer.new
    target_reference_resolver_instance =
      case target_reference_resolver
      when :real
        nil
      else
        target_reference_resolver || FakeTargetReferenceResolver.new(
          { resolution: 'unique', entity: @group }
        )
      end

    SU_MCP::SceneValidationCommands.new(
      adapter: adapter,
      target_reference_resolver: target_reference_resolver_instance,
      targeting_query: targeting_query || FakeTargetingQuery.new(matches: [@group]),
      serializer: serializer_instance,
      geometry_health: geometry_health || FakeGeometryHealth.new(result: { hasGeometry: true }),
      sample_surface_query: sample_surface_query
    )
  end

  def surface_offset_expectation(overrides = {})
    {
      'targetReference' => { 'sourceElementId' => 'path-main' },
      'kind' => 'surfaceOffset',
      'surfaceReference' => { 'sourceElementId' => 'terrain-main' },
      'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_corners' },
      'constraints' => { 'expectedOffset' => 0.0, 'tolerance' => 0.02 },
      'expectationId' => 'surface-offset-001'
    }.merge(overrides)
  end

  def measured_group
    FakeGroup.new(
      entity_id: 150,
      bounds: measured_bounds,
      layer: @layer,
      material: @material,
      details: {
        persistent_id: 1150,
        name: 'Measured Pad',
        entities: [Object.new],
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

  def measured_bounds
    FakeBounds.new(
      min: length_point(83.0, 82.0, 0.5),
      max: length_point(84.0, 83.0, 1.5),
      center: length_point(83.5, 82.5, 1.0),
      size: [FakeLength.new(1.0), FakeLength.new(1.0), FakeLength.new(1.0)]
    )
  end

  def length_point(x_value, y_value, z_value)
    FakePoint.new(FakeLength.new(x_value), FakeLength.new(y_value), FakeLength.new(z_value))
  end

  def successful_surface_offset_hit
    {
      success: true,
      results: [
        {
          status: 'hit',
          hitPoint: { 'x' => 83.0, 'y' => 82.0, 'z' => 0.5 }
        }
      ]
    }
  end

  def surface_offset_request_for_center_anchor
    {
      'expectations' => {
        'geometryRequirements' => [
          surface_offset_expectation(
            'anchorSelector' => { 'anchor' => 'approximate_bottom_bounds_center' }
          )
        ]
      }
    }
  end

  def assert_surface_offset_sampling_contract(result, sample_surface_query)
    assert_equal(true, result[:success])
    assert_equal('passed', result[:outcome])
    assert_equal(
      {
        'type' => 'points',
        'points' => [{ 'x' => 83.5, 'y' => 82.5 }]
      },
      sample_surface_query.calls.first.dig(:params, 'sampling')
    )
    assert_equal(false, sample_surface_query.calls.first.dig(:params, 'visibleOnly'))
  end
end
# rubocop:enable Metrics/ClassLength
