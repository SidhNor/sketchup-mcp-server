# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/edit_terrain_surface_request'

class EditTerrainSurfaceRequestTest < Minitest::Test # rubocop:disable Metrics/ClassLength
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

  def test_accepts_local_fairing_rectangle_request_with_iteration_default
    result = validate_request(local_fairing_request)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('local_fairing', result.fetch(:operation_mode))
    assert_equal('rectangle', result.fetch(:region_type))
    assert_equal(1, result.dig(:params, 'operation', 'iterations'))
    assert_equal(0.0, result.dig(:params, 'region', 'blend', 'distance'))
    assert_equal('none', result.dig(:params, 'region', 'blend', 'falloff'))
  end

  def test_accepts_survey_point_constraint_request_with_defaults
    result = validate_request(survey_request)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('survey_point_constraint', result.fetch(:operation_mode))
    assert_equal('rectangle', result.fetch(:region_type))
    assert_equal('local', result.dig(:params, 'operation', 'correctionScope'))
    point = result.dig(:params, 'constraints', 'surveyPoints').first
    assert_equal('survey-1', point.fetch('id'))
    assert_equal(0.01, point.fetch('tolerance'))
    assert_equal({ 'x' => 2.0, 'y' => 2.0, 'z' => 1.75 }, point.fetch('point'))
  end

  def test_accepts_circle_regions_for_local_area_modes_with_blend_defaults
    target_height = minimal_request
    target_height['region'] = circle_region(blend: { 'distance' => 1.5 })

    result = validate_request(target_height)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('circle', result.fetch(:region_type))
    assert_equal('smooth', result.dig(:params, 'region', 'blend', 'falloff'))

    local_fairing = local_fairing_request
    local_fairing['region'] = circle_region

    result = validate_request(local_fairing)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('circle', result.fetch(:region_type))
    assert_equal(0.0, result.dig(:params, 'region', 'blend', 'distance'))
    assert_equal('none', result.dig(:params, 'region', 'blend', 'falloff'))
  end

  def test_circle_positive_blend_defaults_match_rectangle_positive_blend_defaults
    rectangle = minimal_request
    rectangle['region']['blend'] = { 'distance' => 1.5 }
    rectangle_result = validate_request(rectangle)

    target_height = minimal_request
    target_height['region'] = circle_region(blend: { 'distance' => 1.5 })

    result = validate_request(target_height)

    assert_equal(
      rectangle_result.dig(:params, 'region', 'blend'),
      result.dig(:params, 'region', 'blend')
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

    local_fairing_corridor = local_fairing_request
    local_fairing_corridor['region'] = corridor_request.fetch('region')
    result = validate_request(local_fairing_corridor)
    assert_refusal(result, 'unsupported_option', 'region.type')
    assert_equal(%w[rectangle circle], result.dig(:refusal, :details, :allowedValues))

    survey_corridor = survey_request
    survey_corridor['region'] = corridor_request.fetch('region')
    result = validate_request(survey_corridor)
    assert_refusal(result, 'unsupported_option', 'region.type')
    assert_equal(%w[rectangle circle], result.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_circle_region_for_corridor_transition_with_mode_specific_allowed_values
    circle_corridor = corridor_request
    circle_corridor['region'] = circle_region

    result = validate_request(circle_corridor)

    assert_refusal(result, 'unsupported_option', 'region.type')
    assert_equal(['corridor'], result.dig(:refusal, :details, :allowedValues))
  end

  def test_mode_specific_required_fields_are_runtime_validated # rubocop:disable Metrics/MethodLength
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

    missing_strength = local_fairing_request
    missing_strength['operation'].delete('strength')
    assert_refusal(
      validate_request(missing_strength),
      'missing_required_field',
      'operation.strength'
    )

    missing_radius = local_fairing_request
    missing_radius['operation'].delete('neighborhoodRadiusSamples')
    assert_refusal(
      validate_request(missing_radius),
      'missing_required_field',
      'operation.neighborhoodRadiusSamples'
    )

    missing_scope = survey_request
    missing_scope['operation'].delete('correctionScope')
    assert_refusal(
      validate_request(missing_scope),
      'missing_required_field',
      'operation.correctionScope'
    )

    missing_points = survey_request
    missing_points['constraints'].delete('surveyPoints')
    assert_refusal(
      validate_request(missing_points),
      'missing_required_field',
      'constraints.surveyPoints'
    )
  end

  def test_refuses_invalid_local_fairing_operation_fields
    bad_strength = local_fairing_request
    bad_strength['operation']['strength'] = 0.0
    assert_refusal(validate_request(bad_strength), 'invalid_edit_request', 'operation.strength')

    bad_radius = local_fairing_request
    bad_radius['operation']['neighborhoodRadiusSamples'] = 32
    assert_refusal(
      validate_request(bad_radius),
      'invalid_edit_request',
      'operation.neighborhoodRadiusSamples'
    )

    bad_iterations = local_fairing_request
    bad_iterations['operation']['iterations'] = 9
    assert_refusal(
      validate_request(bad_iterations),
      'invalid_edit_request',
      'operation.iterations'
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

  def test_refuses_invalid_survey_correction_scope_with_allowed_values
    request = survey_request
    request['operation']['correctionScope'] = 'global'

    result = validate_request(request)

    assert_refusal(result, 'unsupported_option', 'operation.correctionScope')
    assert_equal('global', result.dig(:refusal, :details, :value))
    assert_equal(%w[local regional], result.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_invalid_survey_point_shapes
    missing_point = survey_request
    missing_point['constraints']['surveyPoints'] = [{ 'id' => 'bad' }]
    assert_refusal(
      validate_request(missing_point),
      'invalid_edit_request',
      'constraints.surveyPoints[0].point'
    )

    invalid_z = survey_request
    invalid_z['constraints']['surveyPoints'][0]['point'].delete('z')
    assert_refusal(
      validate_request(invalid_z),
      'invalid_edit_request',
      'constraints.surveyPoints[0].point.z'
    )

    negative_tolerance = survey_request
    negative_tolerance['constraints']['surveyPoints'][0]['tolerance'] = -0.01
    assert_refusal(
      validate_request(negative_tolerance),
      'invalid_edit_request',
      'constraints.surveyPoints[0].tolerance'
    )
  end

  def test_refuses_unsupported_region_blend_and_preserve_zone_options
    region_request = minimal_request
    region_request['region']['type'] = 'polygon'
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

  def test_validates_circle_required_fields
    missing_center = minimal_request
    missing_center['region'] = circle_region
    missing_center['region'].delete('center')
    assert_refusal(validate_request(missing_center), 'missing_required_field', 'region.center')

    missing_radius = minimal_request
    missing_radius['region'] = circle_region
    missing_radius['region'].delete('radius')
    assert_refusal(validate_request(missing_radius), 'missing_required_field', 'region.radius')
  end

  def test_validates_circle_numeric_fields
    invalid_center = minimal_request
    invalid_center['region'] = circle_region(center: { 'x' => 1.0 })
    assert_refusal(validate_request(invalid_center), 'invalid_edit_request', 'region.center.y')

    invalid_radius = minimal_request
    invalid_radius['region'] = circle_region(radius: 0.0)
    assert_refusal(validate_request(invalid_radius), 'invalid_edit_request', 'region.radius')
  end

  def test_validates_circle_preserve_zones_by_operation_mode
    target_height = minimal_request
    target_height['constraints'] = {
      'preserveZones' => [circle_preserve_zone]
    }
    assert_equal('ready', validate_request(target_height).fetch(:outcome))

    local_fairing = local_fairing_request
    local_fairing['constraints'] = {
      'preserveZones' => [circle_preserve_zone]
    }
    assert_equal('ready', validate_request(local_fairing).fetch(:outcome))

    corridor = corridor_request
    corridor['constraints'] = {
      'preserveZones' => [circle_preserve_zone]
    }
    result = validate_request(corridor)
    assert_refusal(result, 'unsupported_option', 'constraints.preserveZones[0].type')
    assert_equal(['rectangle'], result.dig(:refusal, :details, :allowedValues))
  end

  def test_validates_circle_preserve_zone_required_fields
    missing_center = minimal_request
    missing_center['constraints'] = {
      'preserveZones' => [circle_preserve_zone.tap { |zone| zone.delete('center') }]
    }
    assert_refusal(
      validate_request(missing_center),
      'missing_required_field',
      'constraints.preserveZones[0].center'
    )

    invalid_radius = minimal_request
    invalid_radius['constraints'] = {
      'preserveZones' => [circle_preserve_zone(radius: -1.0)]
    }
    assert_refusal(
      validate_request(invalid_radius),
      'invalid_edit_request',
      'constraints.preserveZones[0].radius'
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

  def circle_region(center: { 'x' => 2.0, 'y' => 2.0 }, radius: 1.5,
                    blend: { 'distance' => 0.0, 'falloff' => 'none' })
    {
      'type' => 'circle',
      'center' => center,
      'radius' => radius,
      'blend' => blend
    }
  end

  def circle_preserve_zone(center: { 'x' => 2.0, 'y' => 2.0 }, radius: 0.75)
    {
      'type' => 'circle',
      'center' => center,
      'radius' => radius
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

  def local_fairing_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => {
        'mode' => 'local_fairing',
        'strength' => 0.35,
        'neighborhoodRadiusSamples' => 2
      },
      'region' => { 'type' => 'rectangle', 'bounds' => rectangle_bounds }
    }
  end

  def survey_request
    {
      'targetReference' => { 'sourceElementId' => 'terrain-main' },
      'operation' => {
        'mode' => 'survey_point_constraint',
        'correctionScope' => 'local'
      },
      'region' => { 'type' => 'rectangle', 'bounds' => rectangle_bounds },
      'constraints' => {
        'surveyPoints' => [
          {
            'id' => 'survey-1',
            'point' => { 'x' => 2.0, 'y' => 2.0, 'z' => 1.75 }
          }
        ]
      }
    }
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
