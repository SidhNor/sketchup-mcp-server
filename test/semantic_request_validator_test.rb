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
end
