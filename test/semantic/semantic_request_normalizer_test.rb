# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/semantic/request_normalizer'

# rubocop:disable Metrics/ClassLength
class SemanticRequestNormalizerTest < Minitest::Test
  METERS_TO_INTERNAL = 39.37007874015748

  def setup
    @normalizer = SU_MCP::Semantic::RequestNormalizer.new
  end

  def test_normalizes_structure_geometry_fields_to_internal_lengths
    normalized = @normalizer.normalize_create_site_element_params(sectioned_structure_request)

    assert_equal(
      [[0.0, 0.0], [2.0 * METERS_TO_INTERNAL, 0.0],
       [2.0 * METERS_TO_INTERNAL, 3.0 * METERS_TO_INTERNAL],
       [0.0, 3.0 * METERS_TO_INTERNAL]],
      normalized.dig('definition', 'footprint')
    )
    assert_in_delta(0.25 * METERS_TO_INTERNAL, normalized.dig('definition', 'elevation'), 1e-9)
    assert_in_delta(2.4 * METERS_TO_INTERNAL, normalized.dig('definition', 'height'), 1e-9)
    assert_equal('outbuilding', normalized.dig('definition', 'structureCategory'))
  end

  def test_normalizes_nested_semantic_geometry_payloads_to_internal_lengths
    normalized = @normalizer.normalize_create_site_element_params(sectioned_tree_proxy_request)

    assert_in_delta(14.0 * METERS_TO_INTERNAL, normalized.dig('definition', 'position', 'x'), 1e-9)
    assert_in_delta(37.7 * METERS_TO_INTERNAL, normalized.dig('definition', 'position', 'y'), 1e-9)
    assert_in_delta(6.0 * METERS_TO_INTERNAL, normalized.dig('definition', 'canopyDiameterX'), 1e-9)
    assert_in_delta(5.6 * METERS_TO_INTERNAL, normalized.dig('definition', 'canopyDiameterY'), 1e-9)
    assert_in_delta(5.5 * METERS_TO_INTERNAL, normalized.dig('definition', 'height'), 1e-9)
    assert_in_delta(0.45 * METERS_TO_INTERNAL, normalized.dig('definition', 'trunkDiameter'), 1e-9)
    assert_equal('cherry', normalized.dig('definition', 'speciesHint'))
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def test_normalizes_remaining_family_geometry_fields_to_internal_lengths
    pad = @normalizer.normalize_create_site_element_params(sectioned_pad_request)
    retaining_edge = @normalizer.normalize_create_site_element_params(
      sectioned_retaining_edge_request
    )
    planting_mass = @normalizer.normalize_create_site_element_params(
      sectioned_planting_mass_request
    )

    assert_equal(
      [[0.0, 0.0], [3.0 * METERS_TO_INTERNAL, 0.0],
       [3.0 * METERS_TO_INTERNAL, 2.0 * METERS_TO_INTERNAL], [0.0, 2.0 * METERS_TO_INTERNAL]],
      pad.dig('definition', 'footprint')
    )
    assert_in_delta(0.2 * METERS_TO_INTERNAL, pad.dig('definition', 'thickness'), 1e-9)
    assert_equal(
      [[2.0 * METERS_TO_INTERNAL, 0.0], [8.0 * METERS_TO_INTERNAL, 0.0],
       [8.0 * METERS_TO_INTERNAL, 4.0 * METERS_TO_INTERNAL]],
      retaining_edge.dig('definition', 'polyline')
    )
    assert_in_delta(0.45 * METERS_TO_INTERNAL, retaining_edge.dig('definition', 'height'), 1e-9)
    assert_in_delta(0.2 * METERS_TO_INTERNAL, retaining_edge.dig('definition', 'thickness'), 1e-9)
    assert_equal(
      [[0.0, 0.0], [4.0 * METERS_TO_INTERNAL, 0.0],
       [4.0 * METERS_TO_INTERNAL, 2.0 * METERS_TO_INTERNAL], [0.0, 2.0 * METERS_TO_INTERNAL]],
      planting_mass.dig('definition', 'boundary')
    )
    assert_in_delta(
      1.8 * METERS_TO_INTERNAL,
      planting_mass.dig('definition', 'averageHeight'),
      1e-9
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def test_defaults_tree_proxy_canopy_diameter_y_from_canopy_diameter_x
    normalized = @normalizer.normalize_create_site_element_params(
      sectioned_tree_proxy_request(
        'definition' => {
          'canopyDiameterY' => nil
        }
      )
    )

    refute_nil(normalized.dig('definition', 'canopyDiameterY'))
    assert_in_delta(
      6.0 * METERS_TO_INTERNAL,
      normalized.dig('definition', 'canopyDiameterY'),
      1e-9
    )
  end

  def test_preserves_public_meter_metadata_fields_for_later_persistence
    normalized = @normalizer.normalize_create_site_element_params(sectioned_terrain_path_request)

    assert_equal('Main Walk', normalized.dig('sceneProperties', 'name'))
    assert_equal('Gravel', normalized.dig('representation', 'material'))
    assert_equal('main-garden-walk-001', normalized.dig('metadata', 'sourceElementId'))
  end

  def test_normalizes_v2_terrain_path_into_canonical_sections_and_internal_lengths
    normalized = @normalizer.normalize_create_site_element_params(v2_terrain_path_request)

    assert_equal('proposed', normalized.dig('metadata', 'status'))
    assert_equal('centerline', normalized.dig('definition', 'mode'))
    assert_equal(
      [[0.0, 0.0], [4.0 * METERS_TO_INTERNAL, 1.0 * METERS_TO_INTERNAL],
       [8.0 * METERS_TO_INTERNAL, 1.0 * METERS_TO_INTERNAL]],
      normalized.dig('definition', 'centerline')
    )
    assert_in_delta(1.6 * METERS_TO_INTERNAL, normalized.dig('definition', 'width'), 1e-9)
    assert_in_delta(0.1 * METERS_TO_INTERNAL, normalized.dig('definition', 'thickness'), 1e-9)
    assert_equal('surface_drape', normalized.dig('hosting', 'mode'))
    assert_equal('terrain-main', normalized.dig('hosting', 'target', 'sourceElementId'))
  end

  def test_preserves_v2_lifecycle_and_placement_sections_for_replace_flow
    normalized = @normalizer.normalize_create_site_element_params(v2_replace_request)

    assert_equal('replace_preserve_identity', normalized.dig('lifecycle', 'mode'))
    assert_equal('parented', normalized.dig('placement', 'mode'))
    assert_equal('parent-group-22', normalized.dig('placement', 'parent', 'entityId'))
    assert_equal('existing-structure-77', normalized.dig('lifecycle', 'target', 'entityId'))
    assert_in_delta(2.4 * METERS_TO_INTERNAL, normalized.dig('definition', 'height'), 1e-9)
  end

  def test_normalizes_sectioned_path_without_contract_version
    normalized = @normalizer.normalize_create_site_element_params(sectioned_terrain_path_request)

    assert_equal('proposed', normalized.dig('metadata', 'status'))
    assert_equal('centerline', normalized.dig('definition', 'mode'))
    assert_in_delta(1.6 * METERS_TO_INTERNAL, normalized.dig('definition', 'width'), 1e-9)
    assert_equal('surface_drape', normalized.dig('hosting', 'mode'))
  end

  def test_does_not_carry_public_params_shadow_state_for_sectioned_requests
    normalized = @normalizer.normalize_create_site_element_params(sectioned_terrain_path_request)

    refute(normalized.key?('__public_params__'))
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

  def v2_replace_request
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
        'parent' => { 'entityId' => 'parent-group-22' }
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

  def sectioned_terrain_path_request
    request = v2_terrain_path_request.reject { |key, _value| key == 'contractVersion' }
    request['sceneProperties'] = { 'name' => 'Main Walk' }
    request['representation'] = request.fetch('representation').merge('material' => 'Gravel')
    request
  end

  def sectioned_structure_request
    {
      'elementType' => 'structure',
      'metadata' => {
        'sourceElementId' => 'shed-001',
        'status' => 'proposed'
      },
      'definition' => {
        'mode' => 'footprint_mass',
        'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
        'elevation' => 0.25,
        'height' => 2.4,
        'structureCategory' => 'outbuilding'
      },
      'hosting' => { 'mode' => 'none' },
      'placement' => { 'mode' => 'host_resolved' },
      'representation' => { 'mode' => 'procedural' },
      'lifecycle' => { 'mode' => 'create_new' }
    }
  end

  def sectioned_pad_request(overrides = {})
    deep_merge(
      {
        'elementType' => 'pad',
        'metadata' => {
          'sourceElementId' => 'terrace-001',
          'status' => 'proposed'
        },
        'sceneProperties' => {
          'name' => 'Sectioned Terrace',
          'tag' => 'Hardscape'
        },
        'definition' => {
          'mode' => 'polygon',
          'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]],
          'thickness' => 0.2
        },
        'hosting' => { 'mode' => 'none' },
        'placement' => { 'mode' => 'host_resolved' },
        'representation' => {
          'mode' => 'procedural',
          'material' => 'Concrete'
        },
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
        'representation' => {
          'mode' => 'procedural',
          'material' => 'Stone'
        },
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
        'sceneProperties' => {
          'name' => 'Hedge Mass'
        },
        'definition' => {
          'mode' => 'mass_polygon',
          'boundary' => [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]],
          'averageHeight' => 1.8,
          'plantingCategory' => 'hedge'
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
          'trunkDiameter' => 0.45,
          'speciesHint' => 'cherry'
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
