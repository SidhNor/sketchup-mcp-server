# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/semantic/request_validator'

# rubocop:disable Metrics/ClassLength
class SemanticRequestValidatorTest < Minitest::Test
  def setup
    @validator = SU_MCP::Semantic::RequestValidator.new
  end

  def test_accepts_valid_path_payloads
    refusal = @validator.refusal_for(sectioned_terrain_path_request)

    assert_nil(refusal)
  end

  def test_refuses_missing_matching_payloads
    refusal = @validator.refusal_for(sectioned_tree_proxy_request('definition' => nil))

    assert_equal('missing_required_field', refusal.dig(:refusal, :code))
    assert_equal('definition', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_unapproved_sectioned_structure_categories
    refusal = @validator.refusal_for(sectioned_structure_request(
                                       'definition' => {
                                         'mode' => 'footprint_mass',
                                         'footprint' => [
                                           [0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]
                                         ],
                                         'height' => 2.4,
                                         'structureCategory' => 'garage'
                                       }
                                     ))

    assert_equal('unsupported_option', refusal.dig(:refusal, :code))
    assert_equal('definition.structureCategory', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_path_payloads_with_insufficient_distinct_points
    refusal = @validator.refusal_for(
      sectioned_terrain_path_request(
        'definition' => {
          'mode' => 'centerline',
          'centerline' => [[0.0, 0.0], [0.0, 0.0]],
          'width' => 1.6
        }
      )
    )

    assert_equal('invalid_geometry', refusal.dig(:refusal, :code))
  end

  def test_refuses_retaining_edge_payloads_with_non_positive_thickness
    refusal = @validator.refusal_for(sectioned_retaining_edge_request(
                                       'definition' => {
                                         'mode' => 'polyline',
                                         'polyline' => [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
                                         'height' => 0.45,
                                         'thickness' => 0.0
                                       }
                                     ))

    assert_equal('invalid_numeric_value', refusal.dig(:refusal, :code))
  end

  def test_refuses_pad_payloads_with_non_finite_elevation
    refusal = @validator.refusal_for(sectioned_pad_request(
                                       'definition' => {
                                         'mode' => 'polygon',
                                         'footprint' => [
                                           [0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]
                                         ],
                                         'elevation' => 'not-a-number',
                                         'thickness' => 0.2
                                       }
                                     ))

    assert_equal('invalid_numeric_value', refusal.dig(:refusal, :code))
    assert_equal('definition.elevation', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_self_intersecting_planting_mass_boundaries
    refusal = @validator.refusal_for(sectioned_planting_mass_request(
                                       'definition' => {
                                         'mode' => 'mass_polygon',
                                         'boundary' => [
                                           [0.0, 0.0], [4.0, 2.0], [0.0, 2.0], [4.0, 0.0]
                                         ],
                                         'averageHeight' => 1.8
                                       }
                                     ))

    assert_equal('invalid_geometry', refusal.dig(:refusal, :code))
  end

  def test_refuses_tree_proxy_payloads_when_trunk_diameter_exceeds_canopy
    refusal = @validator.refusal_for(sectioned_tree_proxy_request(
                                       'definition' => {
                                         'mode' => 'generated_proxy',
                                         'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
                                         'canopyDiameterX' => 0.4,
                                         'height' => 5.5,
                                         'trunkDiameter' => 0.45
                                       }
                                     ))

    assert_equal('invalid_numeric_value', refusal.dig(:refusal, :code))
  end

  def test_accepts_valid_v2_terrain_following_path_requests
    refusal = @validator.refusal_for(v2_terrain_path_request)

    assert_nil(refusal)
  end

  def test_refuses_v2_adopt_requests_without_lifecycle_target
    refusal = @validator.refusal_for(v2_adopt_request_without_target)

    assert_equal('missing_required_field', refusal.dig(:refusal, :code))
    assert_equal('lifecycle.target', refusal.dig(:refusal, :details, :field))
  end

  def test_refuses_v2_replace_requests_without_distinct_lifecycle_and_parent_targets
    refusal = @validator.refusal_for(v2_replace_request_with_overlapping_targets)

    assert_equal('invalid_section_combination', refusal.dig(:refusal, :code))
  end

  def test_accepts_sectioned_path_requests_without_contract_version
    refusal = @validator.refusal_for(sectioned_terrain_path_request)

    assert_nil(refusal)
  end

  def test_accepts_supported_remaining_family_definition_modes
    requests = [
      sectioned_pad_request,
      sectioned_retaining_edge_request,
      sectioned_planting_mass_request,
      sectioned_tree_proxy_request
    ]

    requests.each do |request|
      refusal = @validator.refusal_for(request)

      assert_nil(
        refusal,
        "expected #{request['elementType']} to accept #{request.dig('definition', 'mode')}"
      )
    end
  end

  def test_refuses_transitional_remaining_family_definition_modes
    requests = [
      sectioned_pad_request('definition' => { 'mode' => 'footprint_surface' }),
      sectioned_retaining_edge_request('definition' => { 'mode' => 'wall_profile' }),
      sectioned_planting_mass_request('definition' => { 'mode' => 'boundary_mass' }),
      sectioned_tree_proxy_request('definition' => { 'mode' => 'proxy_tree' })
    ]

    requests.each do |request|
      refusal = @validator.refusal_for(request)

      refute_nil(refusal)
      assert_equal('unsupported_option', refusal.dig(:refusal, :code))
      assert_equal('definition.mode', refusal.dig(:refusal, :details, :field))
      assert_equal(request.dig('definition', 'mode'), refusal.dig(:refusal, :details, :value))
    end
  end

  def test_refuses_flat_create_shape_when_public_contract_is_sectioned_only
    refusal = @validator.refusal_for(
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
        'width' => 1.6
      }
    )

    assert_equal('missing_required_field', refusal.dig(:refusal, :code))
    assert_equal('metadata', refusal.dig(:refusal, :details, :field))
  end

  private

  # rubocop:disable Metrics/MethodLength

  def v2_terrain_path_request
    {
      'contractVersion' => 2,
      'elementType' => 'path',
      'metadata' => {
        'sourceElementId' => 'main-garden-walk-001',
        'status' => 'proposed'
      },
      'definition' => {
        'mode' => 'centerline',
        'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
        'width' => 1.6,
        'thickness' => 0.1
      },
      'hosting' => {
        'mode' => 'surface_drape',
        'target' => { 'sourceElementId' => 'terrain-main' }
      },
      'placement' => {
        'mode' => 'host_resolved'
      },
      'representation' => {
        'mode' => 'path_surface_proxy'
      },
      'lifecycle' => {
        'mode' => 'create_new'
      }
    }
  end

  def v2_adopt_request_without_target
    {
      'contractVersion' => 2,
      'elementType' => 'structure',
      'metadata' => {
        'sourceElementId' => 'retained-house-001',
        'status' => 'retained'
      },
      'definition' => {
        'mode' => 'adopt_reference',
        'structureCategory' => 'main_building'
      },
      'placement' => {
        'mode' => 'preserve_existing'
      },
      'hosting' => {
        'mode' => 'none'
      },
      'representation' => {
        'mode' => 'adopted'
      },
      'lifecycle' => {
        'mode' => 'adopt_existing'
      }
    }
  end

  def v2_replace_request_with_overlapping_targets
    {
      'contractVersion' => 2,
      'elementType' => 'structure',
      'metadata' => {
        'status' => 'existing'
      },
      'definition' => {
        'mode' => 'footprint_mass',
        'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
        'height' => 2.4,
        'structureCategory' => 'extension'
      },
      'placement' => {
        'mode' => 'parented',
        'parent' => { 'entityId' => 'existing-structure-77' }
      },
      'hosting' => {
        'mode' => 'none'
      },
      'representation' => {
        'mode' => 'procedural'
      },
      'lifecycle' => {
        'mode' => 'replace_preserve_identity',
        'target' => { 'entityId' => 'existing-structure-77' }
      }
    }
  end

  def sectioned_terrain_path_request(overrides = {})
    deep_merge(
      v2_terrain_path_request.reject { |key, _value| key == 'contractVersion' },
      overrides
    )
  end

  def sectioned_structure_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'structure',
        'metadata' => {
          'sourceElementId' => 'shed-001',
          'status' => 'proposed'
        },
        'definition' => {
          'mode' => 'footprint_mass',
          'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
          'height' => 2.4,
          'structureCategory' => 'outbuilding'
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => { 'mode' => 'procedural' },
        'lifecycle' => { 'mode' => 'create_new' }
      },
      overrides
    )
  end

  def sectioned_pad_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'pad',
        'metadata' => {
          'sourceElementId' => 'terrace-001',
          'status' => 'proposed'
        },
        'definition' => {
          'mode' => 'polygon',
          'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]],
          'thickness' => 0.2
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => { 'mode' => 'procedural' },
        'lifecycle' => { 'mode' => 'create_new' }
      },
      overrides
    )
  end

  def sectioned_retaining_edge_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'retaining_edge',
        'metadata' => {
          'sourceElementId' => 'ret-edge-001',
          'status' => 'proposed'
        },
        'definition' => {
          'mode' => 'polyline',
          'polyline' => [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
          'height' => 0.45,
          'thickness' => 0.2
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => { 'mode' => 'procedural' },
        'lifecycle' => { 'mode' => 'create_new' }
      },
      overrides
    )
  end

  def sectioned_planting_mass_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'planting_mass',
        'metadata' => {
          'sourceElementId' => 'hedge-001',
          'status' => 'proposed'
        },
        'definition' => {
          'mode' => 'mass_polygon',
          'boundary' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
          'averageHeight' => 1.8
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => { 'mode' => 'procedural' },
        'lifecycle' => { 'mode' => 'create_new' }
      },
      overrides
    )
  end

  def sectioned_tree_proxy_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'tree_proxy',
        'metadata' => {
          'sourceElementId' => 'tree-001',
          'status' => 'retained'
        },
        'definition' => {
          'mode' => 'generated_proxy',
          'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
          'canopyDiameterX' => 6.0,
          'canopyDiameterY' => 5.6,
          'height' => 5.5,
          'trunkDiameter' => 0.45
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => { 'mode' => 'proxy_mass' },
        'lifecycle' => { 'mode' => 'create_new' }
      },
      overrides
    )
  end

  def deep_merge(base, overrides)
    return base unless overrides.is_a?(Hash)

    base.merge(overrides) do |_key, left, right|
      left.is_a?(Hash) && right.is_a?(Hash) ? deep_merge(left, right) : right
    end
  end

  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength
