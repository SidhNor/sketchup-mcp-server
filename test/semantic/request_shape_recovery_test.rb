# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/semantic/request_shape_recovery'

class RequestShapeRecoveryTest < Minitest::Test
  def setup
    @recovery = SU_MCP::Semantic::RequestShapeRecovery.new
  end

  def test_recovers_whole_sectioned_payload_nested_under_top_level_definition
    result = @recovery.recover_create_site_element_params(
      'definition' => sectioned_tree_proxy_request
    )

    assert_equal('tree_proxy', result['elementType'])
    assert_equal('generated_proxy', result.dig('definition', 'mode'))
    refute(result.dig('definition', 'elementType'))
  end

  def test_recovers_unambiguous_top_level_geometry_leafs_into_definition
    request = sectioned_terrain_path_request
    definition = request.delete('definition')
    request.merge!(definition)

    result = @recovery.recover_create_site_element_params(request)

    assert_equal('centerline', result.dig('definition', 'mode'))
    assert_equal([[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]], result.dig('definition', 'centerline'))
    refute(result.key?('mode'))
    refute(result.key?('width'))
  end

  def test_refuses_ambiguous_mixed_nested_and_top_level_geometry_shapes
    request = sectioned_terrain_path_request
    request['width'] = 3.2

    result = @recovery.recover_create_site_element_params(request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('malformed_request_shape', result.dig(:refusal, :code))
    assert_equal(['width'], result.dig(:refusal, :details, :misnestedFields))
  end

  def test_refuses_wrong_family_top_level_definition_leafs_with_family_guidance
    request = sectioned_tree_proxy_request
    request['averageHeight'] = 1.8

    result = @recovery.recover_create_site_element_params(request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('malformed_request_shape', result.dig(:refusal, :code))
    assert_equal('tree_proxy', result.dig(:refusal, :details, :elementType))
    assert_equal(['averageHeight'], result.dig(:refusal, :details, :misnestedFields))
    assert_includes(result.dig(:refusal, :details, :allowedDefinitionFields), 'height')
    refute_includes(result.dig(:refusal, :details, :allowedDefinitionFields), 'averageHeight')
  end

  def test_recovers_unambiguous_top_level_geometry_leafs_inside_wrapped_payload
    wrapped_request = sectioned_terrain_path_request
    definition = wrapped_request.delete('definition')
    wrapped_request.merge!(definition)

    result = @recovery.recover_create_site_element_params('definition' => wrapped_request)

    assert_equal('path', result['elementType'])
    assert_equal('centerline', result.dig('definition', 'mode'))
    assert_equal(
      [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
      result.dig('definition', 'centerline')
    )
    refute(result.key?('mode'))
    refute(result.key?('width'))
  end

  def test_refuses_ambiguous_mixed_geometry_inside_wrapped_payload
    wrapped_request = sectioned_terrain_path_request
    wrapped_request['width'] = 3.2

    result = @recovery.recover_create_site_element_params('definition' => wrapped_request)

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('malformed_request_shape', result.dig(:refusal, :code))
    assert_equal('path', result.dig(:refusal, :details, :elementType))
    assert_equal(['width'], result.dig(:refusal, :details, :misnestedFields))
  end

  private

  # rubocop:disable Metrics/MethodLength
  def sectioned_terrain_path_request(overrides = {})
    deep_merge(
      {
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
          'status' => 'proposed'
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
  # rubocop:enable Metrics/MethodLength

  def deep_merge(base, overrides)
    return base unless overrides.is_a?(Hash)

    base.merge(overrides) do |_key, left, right|
      left.is_a?(Hash) && right.is_a?(Hash) ? deep_merge(left, right) : right
    end
  end
end
