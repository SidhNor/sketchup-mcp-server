# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/native/mcp_runtime_loader'

class PublicMcpContractPostureTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)

  def test_user_facing_docs_do_not_advertise_removed_boolean_operation
    docs = read_repo_file('docs/mcp-tool-reference.md')

    refute_includes(docs, 'boolean_operation')
    refute_includes(docs, 'target_id')
    refute_includes(docs, 'tool_id')
  end

  def test_user_facing_docs_teach_canonical_direct_references_for_mutation_tools
    docs = read_repo_file('docs/mcp-tool-reference.md')

    assert_includes(docs, 'transform_entities')
    assert_includes(docs, 'set_material')
    assert_includes(docs, 'instantiate_staged_asset')
    assert_includes(docs, 'targetReference')
    refute_includes(docs, 'legacy `id`')
    refute_includes(docs, 'either legacy `id` or compact `targetReference`')
  end

  def test_user_facing_docs_describe_staged_asset_instantiation_contract
    docs = read_repo_file('docs/mcp-tool-reference.md')

    assert_includes(docs, 'metadata.sourceElementId')
    assert_includes(docs, 'placement.position')
    assert_includes(docs, 'placement.scale')
    assert_includes(docs, 'model-root')
    assert_includes(docs, 'sourceAssetElementId')
  end

  def test_boolean_operation_runtime_seams_are_removed_from_public_source
    forbidden_files = {
      'src/su_mcp/runtime/native/mcp_runtime_loader.rb' => 'boolean_operation',
      'src/su_mcp/runtime/tool_dispatcher.rb' => 'boolean_operation',
      'src/su_mcp/runtime/runtime_command_factory.rb' => 'solid_modeling_commands',
      'src/su_mcp/runtime/native/mcp_runtime_facade.rb' => 'boolean_operation',
      'test/support/native_runtime_contract_cases.json' => 'boolean_operation'
    }

    forbidden_files.each do |relative_path, forbidden_text|
      refute_includes(read_repo_file(relative_path), forbidden_text, relative_path)
    end
  end

  def test_removed_boolean_operation_implementation_symbols_are_absent_from_src
    source_files = Dir.glob(File.join(ROOT, 'src/**/*.rb'))
    source_text = source_files.map { |path| File.read(path, encoding: 'utf-8') }.join("\n")

    refute_includes(source_text, 'boolean_operation')
    refute_includes(source_text, 'SolidModelingCommands')
    refute_includes(source_text, 'ModelingSupport')
    refute(source_files.any? { |path| path.end_with?('/solid_modeling_commands.rb') })
    refute(source_files.any? { |path| path.end_with?('/modeling_support.rb') })
  end

  def test_checked_in_public_contract_sweep_matches_runtime_first_class_inventory
    sweep = JSON.parse(read_repo_file('test/support/public_mcp_contract_sweep.json'))
    loader = SU_MCP::McpRuntimeLoader.new(vendor_root: File.join(ROOT, 'vendor/ruby'))
    first_class_tools = loader.tool_catalog
                              .select { |tool| tool.fetch(:classification) == 'first_class' }
                              .map { |tool| tool.fetch(:name) }

    assert_equal(first_class_tools, sweep.fetch('first_class_tools'))
    assert_equal(
      ['boolean_operation'],
      sweep.fetch('removed_tools').map { |tool| tool.fetch('name') }
    )
  end

  def test_user_facing_docs_describe_prompt_surface_without_full_prompt_bodies
    docs = read_repo_file('docs/mcp-tool-reference.md')

    assert_includes(docs, '## MCP prompts')
    assert_includes(docs, 'managed_terrain_edit_workflow')
    assert_includes(docs, 'terrain_profile_qa_workflow')
    assert_includes(docs, 'workflow guidance')
    assert_includes(docs, 'not required hidden context')
    refute_includes(docs, 'Prompt body:')
  end

  def test_user_facing_docs_describe_planar_region_fit_contract
    docs = read_repo_file('docs/mcp-tool-reference.md')

    assert_includes(docs, 'planar_region_fit')
    assert_includes(docs, 'constraints.planarControls')
    assert_includes(docs, 'evidence.planarFit')
    assert_includes(docs, 'clamp(supportFootprintLength * 0.002, 0.03, 0.15)')
    assert_includes(docs, 'Regional scope is not implicit planar fitting')
  end

  private

  def read_repo_file(relative_path)
    File.read(File.join(ROOT, relative_path), encoding: 'utf-8')
  end
end
