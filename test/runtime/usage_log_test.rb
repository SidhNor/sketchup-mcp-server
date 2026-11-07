# frozen_string_literal: true

require 'json'
require 'tmpdir'
require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/usage_log'

class UsageLogTest < Minitest::Test
  def test_appends_one_json_line_per_record
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'usage.jsonl')
      usage_log = SU_MCP::UsageLog.new(path)

      usage_log.append(event: 'client.initialized', client: 'codex')
      usage_log.append(event: 'tool.completed', tool: 'ping', response_chars: 12)

      records = File.readlines(path).map { |line| JSON.parse(line) }
      assert_equal(%w[client.initialized tool.completed], records.map { |r| r['event'] })
      assert_equal(12, records.last['response_chars'])
    end
  end

  def test_is_disabled_without_a_path
    [nil, ''].each do |path|
      usage_log = SU_MCP::UsageLog.new(path)

      refute(usage_log.enabled?)
      assert_nil(usage_log.append(event: 'tool.completed'))
    end
  end

  def test_write_failures_do_not_raise
    Dir.mktmpdir do |dir|
      usage_log = SU_MCP::UsageLog.new(File.join(dir, 'missing-dir', 'usage.jsonl'))

      assert_nil(usage_log.append(event: 'tool.completed'))
    end
  end
end
