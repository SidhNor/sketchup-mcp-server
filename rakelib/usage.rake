# frozen_string_literal: true

require_relative 'usage_analysis/usage_graph'

namespace :mcp do
  desc 'Report tool co-usage groups and heavy call chains from the opt-in usage log'
  task :usage_graph, [:log_path] do |_task, args|
    log_path = args[:log_path] || ENV.fetch('SKETCHUP_MCP_USAGE_LOG', nil)
    if log_path.to_s.empty?
      raise ArgumentError, 'Usage: rake "mcp:usage_graph[path/to/usage.jsonl]"'
    end
    raise ArgumentError, "Usage log not found: #{log_path}" unless File.file?(log_path)

    graph = UsageAnalysis::UsageGraph.from_jsonl(
      log_path, tool_sizes: UsageAnalysis.tool_definition_sizes
    )
    puts graph.report
  end
end
