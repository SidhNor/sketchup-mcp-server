# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/token_estimate'

class TokenEstimateTest < Minitest::Test
  def test_rounds_characters_to_estimated_tokens
    assert_equal(0, SU_MCP::TokenEstimate.from_chars(0))
    assert_equal(1, SU_MCP::TokenEstimate.from_chars(5))
    assert_equal(100, SU_MCP::TokenEstimate.from_chars(490))
  end

  def test_unknown_sizes_stay_unknown
    assert_nil(SU_MCP::TokenEstimate.from_chars(nil))
  end
end
