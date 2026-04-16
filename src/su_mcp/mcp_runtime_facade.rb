# frozen_string_literal: true

require_relative 'scene_query_commands'

module SU_MCP
  # Ruby-owned facade that exposes the current Ruby-native MCP tool slice.
  class McpRuntimeFacade
    def initialize(scene_query_commands: SceneQueryCommands.new)
      @scene_query_commands = scene_query_commands
    end

    def ping
      { success: true, message: 'pong' }
    end

    def get_scene_info(params = {})
      scene_query_commands.get_scene_info(params)
    end

    private

    attr_reader :scene_query_commands
  end
end
