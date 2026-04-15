# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/semantic/request_normalizer'

class SemanticRequestNormalizerTest < Minitest::Test
  METERS_TO_INTERNAL = 39.37007874015748

  def setup
    @normalizer = SU_MCP::Semantic::RequestNormalizer.new
  end

  def test_normalizes_structure_geometry_fields_to_internal_lengths
    normalized = @normalizer.normalize_create_site_element_params(
      'elementType' => 'structure',
      'sourceElementId' => 'shed-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
      'elevation' => 0.25,
      'height' => 2.4,
      'structureCategory' => 'outbuilding'
    )

    assert_equal(
      [[0.0, 0.0], [2.0 * METERS_TO_INTERNAL, 0.0],
       [2.0 * METERS_TO_INTERNAL, 3.0 * METERS_TO_INTERNAL],
       [0.0, 3.0 * METERS_TO_INTERNAL]],
      normalized['footprint']
    )
    assert_in_delta(0.25 * METERS_TO_INTERNAL, normalized['elevation'], 1e-9)
    assert_in_delta(2.4 * METERS_TO_INTERNAL, normalized['height'], 1e-9)
    assert_equal('outbuilding', normalized['structureCategory'])
  end

  def test_normalizes_nested_semantic_geometry_payloads_to_internal_lengths
    normalized = @normalizer.normalize_create_site_element_params(
      'elementType' => 'tree_proxy',
      'sourceElementId' => 'tree-001',
      'status' => 'retained',
      'tree_proxy' => {
        'position' => { 'x' => 14.0, 'y' => 37.7, 'z' => 0.0 },
        'canopyDiameterX' => 6.0,
        'canopyDiameterY' => 5.6,
        'height' => 5.5,
        'trunkDiameter' => 0.45,
        'speciesHint' => 'cherry'
      }
    )

    assert_in_delta(14.0 * METERS_TO_INTERNAL, normalized.dig('tree_proxy', 'position', 'x'), 1e-9)
    assert_in_delta(37.7 * METERS_TO_INTERNAL, normalized.dig('tree_proxy', 'position', 'y'), 1e-9)
    assert_in_delta(6.0 * METERS_TO_INTERNAL, normalized.dig('tree_proxy', 'canopyDiameterX'), 1e-9)
    assert_in_delta(5.6 * METERS_TO_INTERNAL, normalized.dig('tree_proxy', 'canopyDiameterY'), 1e-9)
    assert_in_delta(5.5 * METERS_TO_INTERNAL, normalized.dig('tree_proxy', 'height'), 1e-9)
    assert_in_delta(0.45 * METERS_TO_INTERNAL, normalized.dig('tree_proxy', 'trunkDiameter'), 1e-9)
    assert_equal('cherry', normalized.dig('tree_proxy', 'speciesHint'))
  end

  def test_preserves_public_meter_metadata_fields_for_later_persistence
    normalized = @normalizer.normalize_create_site_element_params(
      'elementType' => 'path',
      'sourceElementId' => 'main-walk-001',
      'status' => 'proposed',
      'path' => {
        'centerline' => [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
        'width' => 1.6,
        'thickness' => 0.1
      },
      'name' => 'Main Walk'
    )

    refute_same(normalized, normalized['__public_params__'])
    assert_equal(1.6, normalized.dig('__public_params__', 'path', 'width'))
    assert_equal(0.1, normalized.dig('__public_params__', 'path', 'thickness'))
    assert_equal('Main Walk', normalized.dig('__public_params__', 'name'))
  end
end
