# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_loader'

# rubocop:disable Metrics/ClassLength
class McpRuntimeNativeContractTest < Minitest::Test
  def setup
    @vendor_root = File.expand_path('../vendor/ruby', __dir__)
    @loader = SU_MCP::McpRuntimeLoader.new(vendor_root: @vendor_root)
  end

  def test_native_transport_preserves_sample_surface_success_shape_from_shared_contract
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('sample_surface_z_hit')
    transport = @loader.build_transport(
      handlers: {
        sample_surface_z: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_refusal_details_with_allowed_values
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('set_entity_metadata_invalid_structure_category_refused')
    transport = @loader.build_transport(
      handlers: {
        set_entity_metadata: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result', 'refusal', 'details', 'allowedValues'),
      response[:body].dig('result', 'structuredContent', 'refusal', 'details', 'allowedValues')
    )
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_create_group_success_shape_from_shared_contract
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('create_group_created')
    transport = @loader.build_transport(
      handlers: {
        create_group: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_managed_create_group_success_shape_from_shared_contract
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('create_group_managed_container_created')
    transport = @loader.build_transport(
      handlers: {
        create_group: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_reparent_entities_refusal_shape_from_shared_contract
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('reparent_entities_cyclic_refused')
    transport = @loader.build_transport(
      handlers: {
        reparent_entities: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_delete_entities_success_shape_from_shared_contract
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('delete_entities_deleted')
    transport = @loader.build_transport(
      handlers: {
        delete_entities: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_managed_transform_success_shape_from_shared_contract
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('transform_entities_managed_target_transformed')
    transport = @loader.build_transport(
      handlers: {
        transform_entities: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_managed_material_success_shape_from_shared_contract
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('set_material_managed_target_updated')
    transport = @loader.build_transport(
      handlers: {
        set_material: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_conflicting_selector_refusal_for_transform_entities
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('transform_entities_conflicting_target_selectors_refused')
    transport = @loader.build_transport(
      handlers: {
        transform_entities: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  def test_native_transport_preserves_validate_scene_update_surface_offset_refusal_details
    skip_unless_staged_vendor_runtime!

    contract_case = contract_case('validate_scene_update_surface_offset_invalid_anchor_refused')
    transport = @loader.build_transport(
      handlers: {
        validate_scene_update: ->(_arguments) { contract_case.fetch('response').fetch('result') }
      }
    )

    response = perform_raw_json_request(transport, contract_case.fetch('request'))

    assert_equal(200, response[:status])
    assert_equal(
      contract_case.dig('response', 'result', 'refusal', 'details', 'allowedValues'),
      response[:body].dig('result', 'structuredContent', 'refusal', 'details', 'allowedValues')
    )
    assert_equal(
      contract_case.dig('response', 'result'),
      response[:body].dig('result', 'structuredContent')
    )
  end

  private

  def contract_case(case_id)
    contract_cases_by_id.fetch(case_id)
  end

  def contract_cases_by_id
    @contract_cases_by_id ||= begin
      contract_path = File.expand_path('../../support/native_runtime_contract_cases.json', __dir__)
      JSON
        .parse(File.read(contract_path, encoding: 'utf-8'))
        .fetch('cases')
        .to_h { |entry| [entry.fetch('case_id'), entry] }
    end
  end

  def perform_raw_json_request(transport, payload)
    require 'rack/mock_request'

    env = Rack::MockRequest.env_for(
      '/mcp',
      method: 'POST',
      'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream',
      input: JSON.generate(payload)
    )

    status, headers, body = transport.call(env)
    raw_body = body.each.to_a.join

    {
      status: status,
      headers: headers,
      raw_body: raw_body,
      body: raw_body.empty? ? {} : JSON.parse(raw_body)
    }
  ensure
    body.close if body.respond_to?(:close)
  end

  def skip_unless_staged_vendor_runtime!
    return if @loader.available?

    skip(
      'Native runtime vendor tree unavailable for test environment: ' \
      "#{@loader.missing_gems.join(', ')}"
    )
  end
end
# rubocop:enable Metrics/ClassLength
