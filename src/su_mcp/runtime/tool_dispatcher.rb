# frozen_string_literal: true

module SU_MCP
  # Maps stable tool names to the current Ruby command methods.
  class ToolDispatcher
    TOOL_METHODS = {
      'get_scene_info' => :get_scene_info,
      'list_entities' => :list_entities,
      'find_entities' => :find_entities,
      'sample_surface_z' => :sample_surface_z,
      'get_entity_info' => :get_entity_info,
      'create_site_element' => :create_site_element,
      'set_entity_metadata' => :set_entity_metadata,
      'create_group' => :create_group,
      'reparent_entities' => :reparent_entities,
      'delete_component' => :delete_component,
      'transform_entities' => :transform_entities,
      'get_selection' => :selection_info,
      'set_material' => :apply_material,
      'boolean_operation' => :boolean_operation,
      'eval_ruby' => :eval_ruby
    }.freeze

    def initialize(command_target: nil, command_targets: nil)
      @command_targets = Array(command_targets || command_target)
    end

    def call(tool_name, args)
      method_name = TOOL_METHODS.fetch(tool_name) do
        raise "Unknown tool: #{tool_name}"
      end
      command_target = find_command_target(method_name)

      if method_name == :selection_info
        command_target.__send__(method_name)
      else
        command_target.__send__(method_name, args)
      end
    end

    private

    def find_command_target(method_name)
      @command_targets.find { |target| target.respond_to?(method_name, true) } || begin
        raise "No command target found for #{method_name}"
      end
    end
  end
end
