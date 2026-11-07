# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/tool_definition'

class NativeToolDefinitionTest < Minitest::Test
  def test_required_arguments_check_defaults_to_sdk
    assert_equal('sdk', build_definition.fetch(:required_arguments_check))
  end

  def test_required_arguments_check_can_be_owned_by_the_runtime
    definition = build_definition(required_arguments_check: 'runtime')

    assert_equal('runtime', definition.fetch(:required_arguments_check))
  end

  def test_required_arguments_check_rejects_unknown_values
    error = assert_raises(ArgumentError) { build_definition(required_arguments_check: 'none') }

    assert_includes(error.message, 'sdk, runtime')
  end

  private

  def build_definition(**overrides)
    SU_MCP::NativeToolDefinition.build(
      name: 'example_tool', title: 'Example Tool', description: 'Example.',
      annotations: { read_only_hint: true, destructive_hint: false },
      handler_key: :example_tool, input_schema: { type: 'object', properties: {} },
      classification: 'first_class', **overrides
    )
  end
end
