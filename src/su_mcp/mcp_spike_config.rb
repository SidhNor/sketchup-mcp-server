# frozen_string_literal: true

module SU_MCP
  # Developer-only configuration for the local Ruby-native MCP spike.
  class McpSpikeConfig
    DEFAULT_HOST = '0.0.0.0'
    DEFAULT_PORT = 9877

    attr_reader :host, :port

    def initialize(env: ENV)
      @host = env_value(env, 'SKETCHUP_MCP_SPIKE_BIND_HOST', DEFAULT_HOST)
      @port = integer_env_value(env, 'SKETCHUP_MCP_SPIKE_PORT', DEFAULT_PORT)
    end

    private

    def env_value(env, key, default)
      value = env[key]
      return default if value.nil? || value.empty?

      value
    end

    def integer_env_value(env, key, default)
      Integer(env_value(env, key, default.to_s))
    rescue ArgumentError
      default
    end
  end
end
