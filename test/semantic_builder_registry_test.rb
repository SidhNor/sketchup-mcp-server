# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/semantic/builder_registry'

class SemanticBuilderRegistryTest < Minitest::Test
  def setup
    @registry = SU_MCP::Semantic::BuilderRegistry.new
  end

  def test_returns_pad_builder_for_pad_requests
    builder = @registry.builder_for('pad')

    assert_instance_of(SU_MCP::Semantic::PadBuilder, builder)
  end

  def test_returns_structure_builder_for_structure_requests
    builder = @registry.builder_for('structure')

    assert_instance_of(SU_MCP::Semantic::StructureBuilder, builder)
  end

  def test_rejects_unsupported_semantic_types
    error = assert_raises(ArgumentError) do
      @registry.builder_for('tree_proxy')
    end

    assert_match(/Unsupported semantic element type/, error.message)
  end
end
