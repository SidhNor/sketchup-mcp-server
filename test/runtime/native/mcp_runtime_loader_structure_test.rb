# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_loader'

class McpRuntimeLoaderStructureTest < Minitest::Test
  ROOT = File.expand_path('../../..', __dir__)
  LOADER_PATH = File.join(ROOT, 'src/su_mcp/runtime/native/mcp_runtime_loader.rb')
  CATALOG_PATH = File.join(ROOT, 'src/su_mcp/runtime/native/native_tool_catalog.rb')

  def test_loader_no_longer_disables_class_length_metric
    loader_source = File.read(LOADER_PATH, encoding: 'utf-8')

    refute_includes(loader_source, 'rubocop:disable Metrics/ClassLength')
    refute_includes(loader_source, 'rubocop:enable Metrics/ClassLength')
  end

  def test_native_tool_catalog_owns_tool_definitions_separately
    loader = SU_MCP::McpRuntimeLoader.new(vendor_root: File.join(ROOT, 'vendor/ruby'))
    catalog = SU_MCP::NativeToolCatalog.new

    assert_equal(catalog.entries, loader.tool_catalog)
  end

  def test_native_tool_contracts_stay_colocated_for_tool_edits
    catalog_source = File.read(CATALOG_PATH, encoding: 'utf-8')

    refute_includes(catalog_source, "require_relative 'native_tool_schema_builder'")
    assert_match(/def validate_scene_update_schema/, catalog_source)
    assert_match(/def edit_terrain_surface_schema/, catalog_source)
    assert_match(/def create_site_element_schema/, catalog_source)
  end
end
