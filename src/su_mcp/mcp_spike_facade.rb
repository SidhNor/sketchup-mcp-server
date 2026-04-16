# frozen_string_literal: true

require_relative 'scene_query_commands'

module SU_MCP
  # Experimental Ruby-owned facade that exposes the representative spike tool slice.
  class McpSpikeFacade
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
