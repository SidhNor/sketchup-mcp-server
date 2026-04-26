# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/edit_terrain_surface_request'

class EditTerrainSurfaceRequestTest < Minitest::Test
  def test_accepts_minimal_target_height_rectangle_request_with_defaults
    result = validate_request(minimal_request)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('target_height', result.fetch(:operation_mode))
    assert_equal('rectangle', result.fetch(:region_type))
    assert_equal(0.0, result.dig(:params, 'region', 'blend', 'distance'))
    assert_equal('none', result.dig(:params, 'region', 'blend', 'falloff'))
    assert_equal(false, result.dig(:params, 'outputOptions', 'includeSampleEvidence'))
    assert_equal(20, result.dig(:params, 'outputOptions', 'sampleEvidenceLimit'))
  end

  def test_accepts_corridor_transition_request_with_side_blend_defaults
    result = validate_request(corridor_request)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('corridor_transition', result.fetch(:operation_mode))
    assert_equal('corridor', result.fetch(:region_type))
    assert_equal(0.0, result.dig(:params, 'region', 'sideBlend', 'distance'))
    assert_equal('none', result.dig(:params, 'region', 'sideBlend', 'falloff'))

    positive = corridor_request
    positive['region']['sideBlend'] = { 'distance' => 1.5 }
    assert_equal(
      'cosine',
      validate_request(positive).dig(:params, 'region', 'sideBlend', 'falloff')
    )
  end

  def test_enforces_operation_mode_and_region_type_compatibility
    rectangle_corridor = corridor_request
    rectangle_corridor['region']['type'] = 'rectangle'
    assert_refusal(
      validate_request(rectangle_corridor),
      'unsupported_option',
      'region.type'
    )

    target_height_corridor = minimal_request
    target_height_corridor['region'] = corridor_request.fetch('region')
    assert_refusal(
      validate_request(target_height_corridor),
      'unsupported_option',
      'region.type'
    )
  end

  def test_mode_specific_required_fields_are_runtime_validated
    missing_target_height = minimal_request
    missing_target_height['operation'].delete('targetElevation')
    assert_refusal(
      validate_request(missing_target_height),
      'missing_required_field',
      'operation.targetElevation'
    )

    missing_corridor_control = corridor_request
    missing_corridor_control['region'].delete('startControl')
    assert_refusal(
      validate_request(missing_corridor_control),
      'missing_required_field',
      'region.startControl'
    )
  end

  def test_refuses_invalid_corridor_controls_width_and_side_blend_options
    bad_width = corridor_request
    bad_width['region']['width'] = 0.0
    assert_refusal(validate_request(bad_width), 'invalid_edit_request', 'region.width')

    bad_falloff = corridor_request
    bad_falloff['region']['sideBlend'] = { 'distance' => 1.0, 'falloff' => 'linear' }
    assert_refusal(
      validate_request(bad_falloff),
      'unsupported_option',
      'region.sideBlend.falloff'
    )

    inert_falloff = corridor_request
    inert_falloff['region']['sideBlend'] = { 'distance' => 1.0, 'falloff' => 'none' }
    assert_refusal(
      validate_request(inert_falloff),
      'invalid_edit_request',
      'region.sideBlend.falloff'
    )

    coincident = corridor_request
    coincident['region']['endControl']['point'] = { 'x' => 1.0, 'y' => 1.0 }
    assert_refusal(validate_request(coincident), 'invalid_corridor_geometry', 'region')
  end

  def test_refuses_unsupported_operation_mode_with_allowed_values
    request = minimal_request
    request['operation']['mode'] = 'smooth'

    result = validate_request(request)

    assert_refusal(result, 'unsupported_option', 'operation.mode')
    assert_equal('smooth', result.dig(:refusal, :details, :value))
    assert_equal(
      SU_MCP::Terrain::EditTerrainSurfaceRequest::SUPPORTED_OPERATION_MODES,
      result.dig(:refusal, :details, :allowedValues)
    )
  end

  def test_refuses_unsupported_region_blend_and_preserve_zone_options
    region_request = minimal_request
    region_request['region']['type'] = 'circle'
    assert_refusal(validate_request(region_request), 'unsupported_option', 'region.type')

    falloff_request = minimal_request
    falloff_request['region']['blend'] = { 'distance' => 2.0, 'falloff' => 'ease_in' }
    assert_refusal(validate_request(falloff_request), 'unsupported_option', 'region.blend.falloff')

    preserve_request = minimal_request
    preserve_request['constraints'] = {
      'preserveZones' => [{ 'type' => 'polygon', 'bounds' => rectangle_bounds }]
    }
    assert_refusal(
      validate_request(preserve_request),
      'unsupported_option',
      'constraints.preserveZones[0].type'
    )
  end

  private

  def validate_request(params)
    SU_MCP::Terrain::EditTerrainSurfaceRequest.new(params).validate
  end

  def assert_refusal(result, code, field)
    assert_equal(true, result.fetch(:success))
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
    assert_equal(field, result.dig(:refusal, :details, :field))
  end

  def minimal_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => { 'mode' => 'target_height', 'targetElevation' => 12.5 },
      'region' => { 'type' => 'rectangle', 'bounds' => rectangle_bounds }
    }
  end

  def rectangle_bounds
    {
      'minX' => 1.0,
      'minY' => 1.0,
      'maxX' => 3.0,
      'maxY' => 3.0
    }
  end

  def corridor_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => { 'mode' => 'corridor_transition' },
      'region' => {
        'type' => 'corridor',
        'startControl' => {
          'point' => { 'x' => 1.0, 'y' => 1.0 },
          'elevation' => 1.0
        },
        'endControl' => {
          'point' => { 'x' => 5.0, 'y' => 1.0 },
          'elevation' => 3.0
        },
        'width' => 2.0
      }
    }
  end
end
