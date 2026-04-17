# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../developer/developer_commands'
require_relative '../editing/editing_commands'
require_relative '../modeling/modeling_support'
require_relative '../scene_query/scene_query_commands'
require_relative '../semantic/hierarchy_maintenance_commands'
require_relative '../semantic/semantic_commands'
require_relative '../modeling/solid_modeling_commands'

module SU_MCP
  # Builds the shared Ruby command collaborators used by both runtime paths.
  class RuntimeCommandFactory
    def initialize(logger: nil, model_adapter: nil)
      @logger = logger
      @model_adapter = model_adapter
    end

    def build_command_targets
      [
        scene_query_commands,
        semantic_commands,
        hierarchy_maintenance_commands,
        editing_commands,
        solid_modeling_commands,
        developer_commands
      ]
    end

    def scene_query_commands
      @scene_query_commands ||= SceneQueryCommands.new(logger: logger, adapter: model_adapter)
    end

    def semantic_commands
      @semantic_commands ||= SemanticCommands.new(model: Sketchup.active_model)
    end

    def hierarchy_maintenance_commands
      @hierarchy_maintenance_commands ||= HierarchyMaintenanceCommands.new(
        model: Sketchup.active_model
      )
    end

    def editing_commands
      @editing_commands ||= EditingCommands.new(
        model_adapter: model_adapter,
        logger: logger
      )
    end

    def solid_modeling_commands
      @solid_modeling_commands ||= SolidModelingCommands.new(
        model_provider: -> { Sketchup.active_model },
        logger: logger,
        support: modeling_support
      )
    end

    def developer_commands
      @developer_commands ||= DeveloperCommands.new(logger: logger)
    end

    private

    attr_reader :logger

    def modeling_support
      @modeling_support ||= ModelingSupport.new
    end

    def model_adapter
      @model_adapter ||= Adapters::ModelAdapter.new
    end
  end
end
