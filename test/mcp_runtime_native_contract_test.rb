# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'
require_relative '../src/su_mcp/mcp_runtime_loader'

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

  private

  def contract_case(case_id)
    contract_cases_by_id.fetch(case_id)
  end

  def contract_cases_by_id
    @contract_cases_by_id ||= begin
      contract_path = File.expand_path('../contracts/bridge/bridge_contract.json', __dir__)
      JSON
        .parse(File.read(contract_path))
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
