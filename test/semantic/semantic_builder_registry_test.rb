# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/semantic/builder_registry'
require_relative '../../src/su_mcp/semantic/path_builder'
require_relative '../../src/su_mcp/semantic/planting_mass_builder'
require_relative '../../src/su_mcp/semantic/retaining_edge_builder'
require_relative '../../src/su_mcp/semantic/tree_proxy_builder'

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

  def test_returns_path_builder_for_path_requests
    builder = @registry.builder_for('path')

    assert_instance_of(SU_MCP::Semantic::PathBuilder, builder)
  end

  def test_returns_retaining_edge_builder_for_retaining_edge_requests
    builder = @registry.builder_for('retaining_edge')

    assert_instance_of(SU_MCP::Semantic::RetainingEdgeBuilder, builder)
  end

  def test_returns_planting_mass_builder_for_planting_mass_requests
    builder = @registry.builder_for('planting_mass')

    assert_instance_of(SU_MCP::Semantic::PlantingMassBuilder, builder)
  end

  def test_returns_tree_proxy_builder_for_tree_proxy_requests
    builder = @registry.builder_for('tree_proxy')

    assert_instance_of(SU_MCP::Semantic::TreeProxyBuilder, builder)
  end

  def test_rejects_unsupported_semantic_types
    error = assert_raises(ArgumentError) do
      @registry.builder_for('water_feature_proxy')
    end

    assert_match(/Unsupported semantic element type/, error.message)
  end
end
