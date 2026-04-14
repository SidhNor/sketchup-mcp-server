# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/request_handler'
require_relative '../../src/su_mcp/request_processor'
require_relative 'contract_test_helper'

module BridgeContractCaseAssertions
  include ContractTestHelper

  private

  def contract_case(case_id)
    contract_case = contract_cases_by_id[case_id]
    refute_nil(contract_case)
    contract_case
  end

  def build_handler(tool_executor:)
    SU_MCP::RequestHandler.new(tool_executor: tool_executor, resource_lister: -> { [] })
  end

  def build_processor(&block)
    SU_MCP::RequestProcessor.new(request_handler: block)
  end

  def assert_error_case(contract_case, response)
    expected_error = contract_case.fetch('response').fetch('error')

    assert_equal(expected_error.fetch('code'), response.dig(:error, :code))
    assert_equal(expected_error.fetch('message'), response.dig(:error, :message))
    assert_equal(contract_case.dig('response', 'id'), response[:id])
    return unless expected_error.key?('data')

    assert_equal(
      expected_error.dig('data', 'success'),
      response.dig(:error, :data, :success)
    )
  end

  def expected_tool_call(contract_case)
    [
      contract_case.dig('request', 'params', 'name'),
      contract_case.dig('request', 'params', 'arguments')
    ]
  end
end

class BridgeContractRequestHandlerTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_ping_request_matches_shared_contract_case
    contract_case = contract_case('ping_request')
    response = build_handler(
      tool_executor: ->(_tool_name, _args) { flunk 'tool executor should not be called for ping' }
    ).handle(contract_case.fetch('request'))

    assert_equal(contract_case.dig('response', 'result', 'message'),
                 response.dig(:result, :message))
    assert_equal(contract_case.dig('response', 'id'), response[:id])
  end

  def test_tools_call_request_matches_shared_contract_case
    contract_case = contract_case('tools_call_request')
    captured_call = nil
    response = build_handler(
      tool_executor: lambda do |tool_name, args|
        captured_call = [tool_name, args]
        { success: true }
      end
    ).handle(contract_case.fetch('request'))

    assert_equal(expected_tool_call(contract_case), captured_call)
    assert_equal(contract_case.dig('response', 'id'), response[:id])
  end

  def test_request_id_round_trip_matches_shared_contract_case
    contract_case = contract_case('request_id_round_trip')
    response = build_handler(
      tool_executor: lambda do |_tool_name, _args|
        { success: true, echoed: true }
      end
    ).handle(contract_case.fetch('request'))

    assert_equal(contract_case.dig('response', 'id'), response[:id])
    assert_equal(true, response.dig(:result, :echoed))
  end

  def test_method_not_found_matches_shared_contract_case
    contract_case = contract_case('method_not_found')
    response = build_handler(
      tool_executor: ->(_tool_name, _args) { flunk 'tool executor should not be called' }
    ).handle(contract_case.fetch('request'))

    assert_error_case(contract_case, response)
  end

  def test_operation_failure_matches_shared_contract_case
    contract_case = contract_case('operation_failure')
    response = build_handler(
      tool_executor: ->(_tool_name, _args) { { success: false } }
    ).handle(contract_case.fetch('request'))

    assert_error_case(contract_case, response)
  end

  def test_wave_ready_tool_call_matches_shared_contract_case
    contract_case = contract_case('wave_ready_tool_call')
    response = build_handler(
      tool_executor: lambda do |tool_name, args|
        { success: true, tool_name: tool_name, arguments: args }
      end
    ).handle(contract_case.fetch('request'))

    assert_equal(contract_case.dig('response', 'id'), response[:id])
    assert_equal(contract_case.dig('response', 'result', 'success'),
                 response.dig(:result, :success))
  end
end

class BridgeContractRequestProcessorTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_parse_error_matches_shared_contract_case
    contract_case = contract_case('parse_error')
    response = build_processor do |_request|
      flunk 'request handler should not be called for parse error'
    end.process(contract_case.fetch('raw_request'))

    assert_error_case(contract_case, response)
  end
end
