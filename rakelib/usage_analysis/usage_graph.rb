# frozen_string_literal: true

require 'json'
require 'time'
require_relative '../../src/su_mcp/runtime/token_estimate'

# Offline analysis of the opt-in runtime usage log (SKETCHUP_MCP_USAGE_LOG).
# Dev tooling only: lives under rakelib so it never ships in the RBZ.
module UsageAnalysis
  # Same ratio as the runtime console log, so the numbers line up.
  CHARS_PER_TOKEN = SU_MCP::TokenEstimate::CHARS_PER_TOKEN

  module_function

  def estimated_tokens(chars)
    SU_MCP::TokenEstimate.from_chars(chars)
  end

  # Character size of each tool as advertised in tools/list. Mirrors the
  # fields McpRuntimeServerBuilder hands to the MCP SDK.
  def tool_definition_sizes
    require_relative '../../src/su_mcp/runtime/native/native_tool_catalog'

    SU_MCP::NativeToolCatalog.new.entries.to_h do |entry|
      annotations = entry.dig(:metadata, :annotations)
      advertised = {
        name: entry.fetch(:name), title: entry.dig(:metadata, :title),
        description: entry.fetch(:description), inputSchema: entry.fetch(:input_schema),
        annotations: {
          readOnlyHint: annotations.fetch(:read_only_hint),
          destructiveHint: annotations.fetch(:destructive_hint)
        }
      }
      [entry.fetch(:name), JSON.generate(advertised).length]
    end
  end

  # Builds the tool co-usage graph (undirected, weighted by sessions that used
  # both tools) and the call-sequence graph (directed, weighted by how often
  # one tool follows another), then groups tools by co-usage.
  class UsageGraph
    TOOL_EVENT = 'tool.completed'
    SESSION_EVENT = 'client.initialized'
    # Clients that never re-initialize still get split after a long idle gap.
    DEFAULT_SESSION_GAP_SECONDS = 30 * 60

    def self.from_jsonl(path, **options)
      skipped = 0
      records = File.readlines(path).filter_map do |line|
        next if line.strip.empty?

        JSON.parse(line)
      rescue JSON::ParserError
        skipped += 1
        nil
      end
      new(records, skipped_lines: skipped, **options)
    end

    attr_reader :skipped_lines

    def initialize(records, tool_sizes: {}, skipped_lines: 0,
                   session_gap_seconds: DEFAULT_SESSION_GAP_SECONDS)
      @records = records
      @tool_sizes = tool_sizes
      @skipped_lines = skipped_lines
      @session_gap_seconds = session_gap_seconds
    end

    # Each session is the ordered list of tool-call records between boundaries.
    def sessions
      @sessions ||= split_sessions.reject(&:empty?)
    end

    def co_usage
      @co_usage ||= sessions.each_with_object(Hash.new(0)) do |session, weights|
        session.map { |call| call.fetch('tool') }.uniq.sort.combination(2) do |pair|
          weights[pair] += 1
        end
      end
    end

    # { [from, to] => { count:, avg_response_chars: } } for consecutive calls.
    def transitions
      @transitions ||= begin
        totals = Hash.new { |hash, key| hash[key] = { count: 0, chars: 0, sized: 0 } }
        sessions.each do |session|
          session.each_cons(2) do |from, to|
            entry = totals[[from.fetch('tool'), to.fetch('tool')]]
            entry[:count] += 1
            next unless to['response_chars'].is_a?(Integer)

            entry[:chars] += to['response_chars']
            entry[:sized] += 1
          end
        end
        totals.transform_values do |entry|
          average = entry[:sized].zero? ? nil : entry[:chars].fdiv(entry[:sized]).round
          { count: entry[:count], avg_response_chars: average }
        end
      end
    end

    # Greedy modularity clustering (Clauset-Newman-Moore) on the co-usage
    # graph. Small enough here (one node per tool) to recompute every merge.
    def groups
      @groups ||= begin
        communities = used_tools.map { |tool| [tool] }
        total = co_usage.values.sum
        # Merge the pair with the largest modularity gain until no merge helps.
        while total.positive? && (pair = best_merge(communities, total))
          left, right = pair
          communities[left].concat(communities.delete_at(right))
        end
        communities.map(&:sort).sort_by { |group| [-group.size, group.first] }
      end
    end

    def report
      [
        report_summary, report_groups, report_session_cost, report_transitions,
        report_unused_tools
      ].compact.join("\n\n")
    end

    private

    attr_reader :records, :tool_sizes, :session_gap_seconds

    def split_sessions
      result = [[]]
      last_time = nil
      records.each do |record|
        time = parse_time(record['timestamp'])
        boundary = record['event'] == SESSION_EVENT ||
                   (time && last_time && time - last_time > session_gap_seconds)
        result << [] if boundary && !result.last.empty?
        last_time = time if time
        result.last << record if record['event'] == TOOL_EVENT && record['tool'].is_a?(String)
      end
      result
    end

    def parse_time(value)
      Time.iso8601(value) if value.is_a?(String)
    rescue ArgumentError
      nil
    end

    def used_tools
      sessions.flatten.map { |call| call.fetch('tool') }.uniq.sort
    end

    def degrees
      @degrees ||= co_usage.each_with_object(Hash.new(0)) do |((a, b), weight), result|
        result[a] += weight
        result[b] += weight
      end
    end

    # Index pair (left < right) with the largest positive modularity gain, or nil.
    def best_merge(communities, total)
      best = nil
      best_gain = 1e-12
      communities.each_index.to_a.combination(2) do |left, right|
        gain = modularity_gain(communities[left], communities[right], total)
        next unless gain > best_gain

        best_gain = gain
        best = [left, right]
      end
      best
    end

    def modularity_gain(left, right, total)
      between = left.product(right).sum { |a, b| co_usage[[a, b].sort] }
      left_degree = left.sum { |tool| degrees[tool] }
      right_degree = right.sum { |tool| degrees[tool] }
      edge_total = 2.0 * total
      2.0 * ((between / edge_total) - ((left_degree / edge_total) * (right_degree / edge_total)))
    end

    def group_tokens(group)
      estimated_tokens(group.sum { |tool| tool_sizes.fetch(tool, 0) })
    end

    def estimated_tokens(chars)
      UsageAnalysis.estimated_tokens(chars)
    end

    def report_summary
      clients = records.select { |r| r['event'] == SESSION_EVENT }.filter_map { |r| r['client'] }
      client_list = clients.tally.map { |client, count| "#{client} (#{count})" }.join(', ')
      lines = [
        '# SketchUp MCP usage graph', '',
        "- Sessions: #{sessions.size}",
        "- Tool calls: #{sessions.sum(&:size)}",
        "- Clients: #{clients.empty? ? 'unknown' : client_list}"
      ]
      lines << "- Skipped unreadable log lines: #{skipped_lines}" if skipped_lines.positive?
      lines << "- Token estimates use #{CHARS_PER_TOKEN} chars/token (a floor for Claude)."
      lines.join("\n")
    end

    def report_groups
      rows = groups.each_with_index.map do |group, index|
        session_count = sessions.count do |session|
          session.any? { |call| group.include?(call.fetch('tool')) }
        end
        "| #{index + 1} | #{group.join(', ')} | #{group_tokens(group)} | #{session_count} |"
      end
      ['## Tool groups (co-usage communities)', '',
       '| Group | Tools | Definition tokens | Sessions using |',
       '|---|---|---|---|', *rows].join("\n")
    end

    def report_session_cost
      return nil if tool_sizes.empty? || sessions.empty?

      all_tokens = estimated_tokens(tool_sizes.values.sum)
      per_session = sessions.map do |session|
        session_tools = session.map { |call| call.fetch('tool') }
        used_groups = groups.select { |group| group.intersect?(session_tools) }
        used_groups.sum { |group| group_tokens(group) }
      end
      average = per_session.sum.fdiv(per_session.size).round
      ['## Definition cost per session', '',
       "- All tools advertised: #{all_tokens} tokens every session.",
       "- Only the groups each session used: #{average} tokens on average " \
       "(min #{per_session.min}, max #{per_session.max})."].join("\n")
    end

    def report_transitions
      ranked = transitions.sort_by do |(_pair, stats)|
        -(stats[:count] * (stats[:avg_response_chars] || 0))
      end.first(5)
      rows = ranked.map do |(from, to), stats|
        average = stats[:avg_response_chars]
        tokens = average ? estimated_tokens(average) : 'n/a'
        "| #{from} | #{to} | #{stats[:count]} | #{tokens} |"
      end
      ['## Heaviest call transitions (candidates for one-call commands)', '',
       '| From | To | Count | Avg response tokens |', '|---|---|---|---|', *rows].join("\n")
    end

    def report_unused_tools
      unused = tool_sizes.keys.sort - used_tools
      return nil if unused.empty?

      rows = unused.map { |tool| "- #{tool} (#{estimated_tokens(tool_sizes[tool])} tokens)" }
      ['## Tools never called', '', *rows].join("\n")
    end
  end
end
