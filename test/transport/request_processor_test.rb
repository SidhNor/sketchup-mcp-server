# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/transport/request_processor'

class RequestProcessorTest < Minitest::Test
  def test_processes_valid_jsonrpc_requests
    received_request = nil
    processor = build_processor do |request|
      received_request = request
      { jsonrpc: '2.0', result: { success: true }, id: request['id'] }
    end

    response = processor.process(valid_ping_request)

    assert_equal('ping', received_request['method'])
    assert_equal 4, received_request['id']
    assert_equal({ success: true }, response[:result])
  end

  def test_returns_parse_error_for_invalid_json_and_preserves_raw_id
    processor = build_processor { |_request| flunk 'should not run' }

    response = processor.process('{"jsonrpc":"2.0","id":9,"method":')

    assert_equal(-32_700, response.dig(:error, :code))
    assert_equal(9, response[:id])
  end

  def test_returns_request_error_with_request_id_when_handler_raises
    processor = build_processor { |_request| raise 'boom' }

    response = processor.process(error_ping_request)

    assert_equal(-32_603, response.dig(:error, :code))
    assert_equal('boom', response.dig(:error, :message))
    assert_equal(12, response[:id])
  end

  private

  def build_processor(&block)
    SU_MCP::RequestProcessor.new(request_handler: block)
  end

  def valid_ping_request
    '{"jsonrpc":"2.0","method":"ping","id":4}'
  end

  def error_ping_request
    '{"jsonrpc":"2.0","method":"ping","id":12}'
  end
end
