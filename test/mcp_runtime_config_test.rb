# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/mcp_runtime_config'

class McpRuntimeConfigTest < Minitest::Test
  def test_uses_explicit_defaults_for_the_local_http_runtime
    with_env('SKETCHUP_MCP_RUNTIME_BIND_HOST' => nil, 'SKETCHUP_MCP_RUNTIME_PORT' => nil,
             'SKETCHUP_MCP_SPIKE_BIND_HOST' => nil, 'SKETCHUP_MCP_SPIKE_PORT' => nil) do
      config = SU_MCP::McpRuntimeConfig.new

      assert_equal('0.0.0.0', config.host)
      assert_equal(9877, config.port)
    end
  end

  def test_reads_runtime_specific_host_and_port_overrides
    with_env('SKETCHUP_MCP_RUNTIME_BIND_HOST' => '0.0.0.0',
             'SKETCHUP_MCP_RUNTIME_PORT' => '9988') do
      config = SU_MCP::McpRuntimeConfig.new

      assert_equal('0.0.0.0', config.host)
      assert_equal(9988, config.port)
    end
  end

  def test_falls_back_to_default_port_when_the_override_is_invalid
    with_env('SKETCHUP_MCP_RUNTIME_PORT' => 'not-a-port') do
      config = SU_MCP::McpRuntimeConfig.new

      assert_equal(9877, config.port)
    end
  end

  def test_falls_back_to_legacy_spike_env_keys_for_compatibility
    with_env('SKETCHUP_MCP_RUNTIME_BIND_HOST' => nil, 'SKETCHUP_MCP_RUNTIME_PORT' => nil,
             'SKETCHUP_MCP_SPIKE_BIND_HOST' => '127.0.0.1', 'SKETCHUP_MCP_SPIKE_PORT' => '9988') do
      config = SU_MCP::McpRuntimeConfig.new

      assert_equal('127.0.0.1', config.host)
      assert_equal(9988, config.port)
    end
  end

  private

  def with_env(overrides)
    previous = overrides.transform_values { nil }
    overrides.each_key { |key| previous[key] = ENV.fetch(key, nil) }

    overrides.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end

    yield
  ensure
    previous.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
