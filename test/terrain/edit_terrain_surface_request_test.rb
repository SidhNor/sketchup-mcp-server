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
end
