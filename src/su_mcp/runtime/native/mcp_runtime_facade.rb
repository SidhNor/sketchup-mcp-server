# frozen_string_literal: true

require_relative '../../scene_query/scene_query_commands'
require_relative '../runtime_command_factory'
require_relative '../tool_dispatcher'

module SU_MCP
  # Ruby-owned facade that exposes the current Ruby-native MCP tool slice.
  class McpRuntimeFacade
    TOOL_NAMES = ToolDispatcher::TOOL_METHODS.keys.freeze

    def initialize(
      runtime_command_factory: nil,
      command_targets: nil,
      scene_query_commands: nil,
      developer_commands: nil
    )
      @runtime_command_factory = runtime_command_factory
      @scene_query_commands = scene_query_commands
      @developer_commands = developer_commands
      @command_targets = command_targets
    end

    def ping
      { success: true, message: 'pong' }
    end

    TOOL_NAMES.each do |tool_name|
      define_method(tool_name) do |params = {}|
        tool_dispatcher.call(tool_name, params)
      end
    end

    private

    attr_reader(
      :runtime_command_factory,
      :scene_query_commands,
      :developer_commands,
      :command_targets
    )

    def tool_dispatcher
      @tool_dispatcher ||= ToolDispatcher.new(command_targets: resolved_command_targets)
    end

    def resolved_command_targets
      return command_targets if command_targets

      return runtime_command_factory.build_command_targets if runtime_command_factory

      @resolved_command_targets ||= [
        scene_query_commands || SceneQueryCommands.new,
        developer_commands
      ].compact
    end
  end
end
