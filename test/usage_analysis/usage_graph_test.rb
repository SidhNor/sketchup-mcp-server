# frozen_string_literal: true

require 'json'
require 'tmpdir'
require_relative '../test_helper'
require_relative '../../rakelib/usage_analysis/usage_graph'

class UsageGraphTest < Minitest::Test
  QUERY_TOOLS = %w[find_entities get_entity_info measure_scene].freeze
  TERRAIN_TOOLS = %w[create_terrain_surface edit_terrain_surface sample_surface_z].freeze

  def test_splits_sessions_on_initialize_and_idle_gaps
    graph = UsageAnalysis::UsageGraph.new(fixture_records)

    assert_equal(
      [QUERY_TOOLS, QUERY_TOOLS, TERRAIN_TOOLS, %w[create_terrain_surface edit_terrain_surface]],
      graph.sessions.map { |session| session.map { |call| call.fetch('tool') } }
    )
  end

  def test_weights_co_usage_by_session_and_transitions_by_order
    graph = UsageAnalysis::UsageGraph.new(fixture_records)

    assert_equal(2, graph.co_usage[%w[find_entities measure_scene]])
    assert_equal(2, graph.co_usage[%w[create_terrain_surface edit_terrain_surface]])
    assert_equal(0, graph.co_usage[%w[find_entities sample_surface_z]])
    assert_equal({ count: 2, avg_response_chars: 900 },
                 graph.transitions[%w[find_entities get_entity_info]])
  end

  def test_groups_tools_that_are_used_together
    graph = UsageAnalysis::UsageGraph.new(fixture_records)

    assert_equal([QUERY_TOOLS, TERRAIN_TOOLS].sort, graph.groups.sort)
  end

  def test_report_prices_groups_and_lists_unused_tools
    sizes = (QUERY_TOOLS + TERRAIN_TOOLS).to_h { |tool| [tool, 490] }.merge('eval_ruby' => 98)
    graph = UsageAnalysis::UsageGraph.new(fixture_records, tool_sizes: sizes)
    report = graph.report

    assert_includes(report, '- Sessions: 4')
    assert_includes(report, 'codex-mcp-client/0.50.0 (3)')
    assert_includes(report, '| find_entities, get_entity_info, measure_scene | 300 | 2 |')
    assert_includes(report, 'All tools advertised: 620 tokens every session.')
    assert_includes(report, 'Only the groups each session used: 300 tokens on average')
    assert_includes(report, '| find_entities | get_entity_info | 2 | 184 |')
    assert_includes(report, '- eval_ruby (20 tokens)')
  end

  def test_reads_jsonl_and_skips_unreadable_lines
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'usage.jsonl')
      File.write(path, "#{fixture_records.map { |r| JSON.generate(r) }.join("\n")}\nnot json\n\n")

      graph = UsageAnalysis::UsageGraph.from_jsonl(path)

      assert_equal(1, graph.skipped_lines)
      assert_equal(4, graph.sessions.size)
    end
  end

  def test_tool_definition_sizes_cover_the_public_catalog
    sizes = UsageAnalysis.tool_definition_sizes

    assert_includes(sizes.keys, 'validate_scene_update')
    assert(sizes.values.all?(&:positive?))
  end

  private

  def fixture_records
    clock = Time.utc(2026, 11, 1, 9, 0, 0)
    records = []
    add = lambda do |record, advance = 10|
      clock += advance
      records << record.merge('timestamp' => clock.iso8601(3))
    end

    2.times do
      add.call(session_start)
      add.call(tool_call('find_entities', 400))
      add.call(tool_call('get_entity_info', 900))
      add.call(tool_call('measure_scene', 300))
    end
    add.call(session_start)
    TERRAIN_TOOLS.each { |tool| add.call(tool_call(tool, 200)) }
    # No initialize: only the idle gap separates this session.
    add.call(tool_call('create_terrain_surface', 200), 3_600)
    add.call(tool_call('edit_terrain_surface', 200))
    records
  end

  def session_start
    { 'event' => 'client.initialized', 'client' => 'codex-mcp-client/0.50.0' }
  end

  def tool_call(tool, response_chars)
    { 'event' => 'tool.completed', 'tool' => tool, 'outcome' => 'succeeded',
      'response_chars' => response_chars }
  end
end
