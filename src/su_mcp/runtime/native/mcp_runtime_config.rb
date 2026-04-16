# frozen_string_literal: true

module SU_MCP
  # Configuration for the Ruby-native MCP runtime inside SketchUp.
  class McpRuntimeConfig
    DEFAULT_HOST = '0.0.0.0'
    DEFAULT_PORT = 9877
    HOST_KEYS = %w[SKETCHUP_MCP_RUNTIME_BIND_HOST SKETCHUP_MCP_SPIKE_BIND_HOST].freeze
    PORT_KEYS = %w[SKETCHUP_MCP_RUNTIME_PORT SKETCHUP_MCP_SPIKE_PORT].freeze

    attr_reader :host, :port

    def initialize(env: ENV)
      @host = env_value(env, HOST_KEYS, DEFAULT_HOST)
      @port = integer_env_value(env, PORT_KEYS, DEFAULT_PORT)
    end

    private

    def env_value(env, keys, default)
      value = Array(keys).lazy.map { |key| env[key] }.find { |entry| !entry.nil? && !entry.empty? }
      return default if value.nil?

      value
    end

    def integer_env_value(env, keys, default)
      Integer(env_value(env, keys, default.to_s))
    rescue ArgumentError
      default
    end
  end
end
