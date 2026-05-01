# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/create_terrain_surface_request'

class CreateTerrainSurfaceRequestTest < Minitest::Test
  def test_accepts_minimal_create_grid_request
    result = validate_request(create_request)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('create', result.fetch(:lifecycle_mode))
  end

  def test_requires_root_metadata_and_lifecycle_sections
    assert_refusal(validate_request(create_request.except('metadata')), 'missing_required_field',
                   'metadata')
    assert_refusal(validate_request(create_request.except('lifecycle')), 'missing_required_field',
                   'lifecycle')
  end

  def test_requires_metadata_identity_status_and_lifecycle_mode
    request = create_request
    request['metadata'].delete('sourceElementId')
    assert_refusal(validate_request(request), 'missing_required_field', 'metadata.sourceElementId')

    request = create_request
    request['metadata'].delete('status')
    assert_refusal(validate_request(request), 'missing_required_field', 'metadata.status')

    request = create_request
    request['lifecycle'].delete('mode')
    assert_refusal(validate_request(request), 'missing_required_field', 'lifecycle.mode')
  end

  def test_refuses_unsupported_lifecycle_mode_with_allowed_values
    request = create_request
    request['lifecycle']['mode'] = 'replace'

    result = validate_request(request)

    assert_refusal(result, 'unsupported_option', 'lifecycle.mode')
    assert_equal('replace', result.dig(:refusal, :details, :value))
    assert_equal(%w[create adopt], result.dig(:refusal, :details, :allowedValues))
  end

  def test_create_requires_definition_and_refuses_lifecycle_target
    assert_refusal(validate_request(create_request.except('definition')), 'missing_definition',
                   'definition')

    request = create_request
    request['lifecycle']['target'] = { 'sourceElementId' => 'source-terrain' }

    assert_refusal(validate_request(request), 'unexpected_lifecycle_target', 'lifecycle.target')
  end

  def test_adopt_requires_target_and_refuses_definition_and_placement
    assert_refusal(validate_request(adopt_request), 'missing_lifecycle_target',
                   'lifecycle.target')

    request = adopt_request('target' => { 'sourceElementId' => 'source-terrain' })
    request['definition'] = create_request.fetch('definition')
    assert_refusal(validate_request(request), 'unsupported_definition_for_adoption',
                   'definition')

    request = adopt_request('target' => { 'sourceElementId' => 'source-terrain' })
    request['placement'] = { 'origin' => { 'x' => 1.0, 'y' => 2.0, 'z' => 0.0 } }
    assert_refusal(validate_request(request), 'unsupported_placement_for_adoption', 'placement')
  end

  def test_refuses_unsupported_definition_kind_with_allowed_values
    request = create_request
    request['definition']['kind'] = 'contours'

    result = validate_request(request)

    assert_refusal(result, 'unsupported_option', 'definition.kind')
    assert_equal('contours', result.dig(:refusal, :details, :value))
    assert_equal(%w[heightmap_grid], result.dig(:refusal, :details, :allowedValues))
  end

  def test_refuses_invalid_grid_values_and_cap_exceeded
    invalid_spacing = create_request_with_grid('spacing' => { 'x' => 0.0, 'y' => 1.0 })
    invalid_dimensions = create_request_with_grid(
      'dimensions' => { 'columns' => 1, 'rows' => 2 }
    )

    assert_refusal(validate_request(invalid_spacing), 'invalid_grid_definition',
                   'definition.grid.spacing.x')
    assert_refusal(validate_request(invalid_dimensions), 'invalid_grid_definition',
                   'definition.grid.dimensions.columns')

    result = validate_request(
      create_request_with_grid('dimensions' => { 'columns' => 129, 'rows' => 2 })
    )

    assert_refusal(result, 'grid_sample_cap_exceeded', 'definition.grid.dimensions')
    assert_equal(128, result.dig(:refusal, :details, :maxColumns))
  end

  def test_accepts_public_row_major_grid_elevations
    result = validate_request(
      create_request_with_grid('elevations' => [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
    )

    assert_equal('ready', result.fetch(:outcome))
  end

  def test_refuses_malformed_public_grid_elevations
    bad_count = create_request_with_grid('elevations' => [1.0, 2.0])
    bad_value = create_request_with_grid(
      'elevations' => [1.0, 2.0, Float::NAN, 4.0, 5.0, 6.0]
    )

    assert_refusal(validate_request(bad_count), 'invalid_grid_definition',
                   'definition.grid.elevations')
    assert_refusal(validate_request(bad_value), 'invalid_grid_definition',
                   'definition.grid.elevations[2]')
  end

  def test_refuses_duplicate_source_element_id_before_mutation
    result = validate_request(create_request, identity_exists: ->(_id) { true })

    assert_refusal(result, 'duplicate_source_element_id', 'metadata.sourceElementId')
  end

  private

  def validate_request(params, identity_exists: ->(_id) { false })
    SU_MCP::Terrain::CreateTerrainSurfaceRequest.new(
      params,
      identity_exists: identity_exists
    ).validate
  end

  def assert_refusal(result, code, field)
    assert_equal(true, result.fetch(:success))
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
    assert_equal(field, result.dig(:refusal, :details, :field))
  end

  def create_request
    {
      'metadata' => { 'sourceElementId' => 'terrain-main', 'status' => 'existing' },
      'lifecycle' => { 'mode' => 'create' },
      'definition' => {
        'kind' => 'heightmap_grid',
        'grid' => {
          'origin' => { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
          'spacing' => { 'x' => 1.0, 'y' => 1.0 },
          'dimensions' => { 'columns' => 3, 'rows' => 2 },
          'baseElevation' => 10.0
        }
      }
    }
  end

  def create_request_with_grid(grid_overrides)
    request = create_request
    request['definition']['grid'] = request['definition']['grid'].merge(grid_overrides)
    request
  end

  def adopt_request(lifecycle_overrides = {})
    {
      'metadata' => { 'sourceElementId' => 'terrain-main', 'status' => 'existing' },
      'lifecycle' => { 'mode' => 'adopt' }.merge(lifecycle_overrides)
    }
  end
end
