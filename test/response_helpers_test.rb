# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/response_helpers'

class ResponseHelpersTest < Minitest::Test
  def test_success_response_preserves_request_id
    response = SU_MCP::ResponseHelpers.success({ success: true, message: 'pong' }, id: 7)

    assert_equal(
      {
        jsonrpc: '2.0',
        result: { success: true, message: 'pong' },
        id: 7
      },
      response
    )
  end

  def test_parse_error_uses_standard_jsonrpc_shape
    response = SU_MCP::ResponseHelpers.parse_error(id: 9)

    assert_equal(-32_700, response.dig(:error, :code))
    assert_equal('Parse error', response.dig(:error, :message))
    assert_equal(9, response[:id])
  end

  def test_method_not_found_sets_standard_error_payload
    response = SU_MCP::ResponseHelpers.method_not_found(id: 3)

    assert_equal(-32_601, response.dig(:error, :code))
    assert_equal('Method not found', response.dig(:error, :message))
    assert_equal({ success: false }, response.dig(:error, :data))
  end
end
