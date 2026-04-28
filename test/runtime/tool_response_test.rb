# frozen_string_literal: true

require_relative '../test_helper'

tool_response_path = File.expand_path('../../src/su_mcp/runtime/tool_response', __dir__)
require tool_response_path if File.exist?("#{tool_response_path}.rb")

class ToolResponseTest < Minitest::Test
  def test_exposes_a_shared_success_builder_for_first_class_native_tools
    assert(defined?(SU_MCP::ToolResponse), 'Expected SU_MCP::ToolResponse to be defined')

    result = SU_MCP::ToolResponse.success(
      outcome: 'created',
      group: { entityId: '42', type: 'group' },
      children: []
    )

    assert_equal(
      {
        success: true,
        outcome: 'created',
        group: { entityId: '42', type: 'group' },
        children: []
      },
      result
    )
  end

  def test_exposes_a_shared_refusal_builder_with_optional_allowed_values
    assert(defined?(SU_MCP::ToolResponse), 'Expected SU_MCP::ToolResponse to be defined')

    result = SU_MCP::ToolResponse.refusal(
      code: 'unsupported_option',
      message: 'Option is not supported.',
      details: {
        field: 'structureCategory',
        value: 'garage',
        allowedValues: %w[main_building outbuilding extension]
      }
    )

    assert_equal(
      {
        success: true,
        outcome: 'refused',
        refusal: {
          code: 'unsupported_option',
          message: 'Option is not supported.',
          details: {
            field: 'structureCategory',
            value: 'garage',
            allowedValues: %w[main_building outbuilding extension]
          }
        }
      },
      result
    )
  end

  def test_can_wrap_existing_refusal_payloads_from_lower_level_collaborators
    assert(defined?(SU_MCP::ToolResponse), 'Expected SU_MCP::ToolResponse to be defined')

    result = SU_MCP::ToolResponse.refusal_result(
      {
        code: 'required_metadata_field',
        message: 'Field cannot be cleared for a Managed Scene Object.',
        details: { field: 'status' }
      }
    )

    assert_equal(
      {
        success: true,
        outcome: 'refused',
        refusal: {
          code: 'required_metadata_field',
          message: 'Field cannot be cleared for a Managed Scene Object.',
          details: { field: 'status' }
        }
      },
      result
    )
  end
end
