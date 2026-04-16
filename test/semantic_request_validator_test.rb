# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/semantic/request_validator'

class SemanticRequestValidatorTest < Minitest::Test
  def setup
    @validator = SU_MCP::Semantic::RequestValidator.new
  end

  def test_accepts_valid_path_payloads
    refusal = @validator.refusal_for(
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
        'width' => 1.6,
        'elevation' => 0.0,
        'thickness' => 0.1
      }
    )

    assert_nil(refusal)
  end

  def test_refuses_missing_matching_payloads
    refusal = @validator.refusal_for(
      'elementType' => 'tree_proxy',
      'sourceElementId' => 'tree-001',
      'status' => 'retained'
    )

    assert_equal('missing_element_payload', refusal.dig(:refusal, :code))
  end

  def test_refuses_contradictory_payload_sections
    refusal = @validator.refusal_for(
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [4.0, 1.0]],
        'width' => 1.6
      },
      'planting_mass' => {
        'boundary' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
        'averageHeight' => 1.8
      }
    )

    assert_equal('contradictory_payload', refusal.dig(:refusal, :code))
  end

  def test_refuses_path_payloads_with_insufficient_distinct_points
    refusal = @validator.refusal_for(
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [0.0, 0.0]],
        'width' => 1.6
      }
    )

    assert_equal('invalid_geometry', refusal.dig(:refusal, :code))
  end

  def test_refuses_retaining_edge_payloads_with_non_positive_thickness
    refusal = @validator.refusal_for(
      'elementType' => 'retaining_edge',
      'sourceElementId' => 'ret-edge-001',
      'status' => 'proposed',
      'retaining_edge' => {
        'polyline' => [[2.0, 0.0], [8.0, 0.0], [8.0, 4.0]],
        'height' => 0.45,
        'thickness' => 0.0
      }
    )

    assert_equal('invalid_numeric_value', refusal.dig(:refusal, :code))
  end

  def test_refuses_self_intersecting_planting_mass_boundaries
    refusal = @validator.refusal_for(
      'elementType' => 'planting_mass',
      'sourceElementId' => 'hedge-001',
      'status' => 'proposed',
      'planting_mass' => {
        'boundary' => [[0.0, 0.0], [4.0, 2.0], [0.0, 2.0], [4.0, 0.0]],
        'averageHeight' => 1.8
      }
    )

    assert_equal('invalid_geometry', refusal.dig(:refusal, :code))
  end

  def test_refuses_tree_proxy_payloads_when_trunk_diameter_exceeds_canopy
    refusal = @validator.refusal_for(
      'elementType' => 'tree_proxy',
      'sourceElementId' => 'tree-001',
      'status' => 'retained',
      'tree_proxy' => {
        'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
        'canopyDiameterX' => 0.4,
        'height' => 5.5,
        'trunkDiameter' => 0.45
      }
    )

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

  # rubocop:enable Metrics/MethodLength
end
