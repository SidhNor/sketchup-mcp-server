# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../developer/developer_commands'
require_relative '../editing/editing_commands'
require_relative '../scene_query/scene_query_commands'
require_relative '../scene_validation/measure_scene_commands'
require_relative '../scene_validation/scene_validation_commands'
require_relative '../semantic/hierarchy_maintenance_commands'
require_relative '../semantic/semantic_commands'
require_relative '../staged_assets/staged_asset_commands'
require_relative '../terrain/commands/terrain_surface_commands'

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
        measure_scene_commands,
        scene_validation_commands,
        terrain_surface_commands,
        staged_asset_commands,
        semantic_commands,
        hierarchy_maintenance_commands,
        editing_commands,
        developer_commands
      ]
    end

    def scene_query_commands
      @scene_query_commands ||= SceneQueryCommands.new(logger: logger, adapter: model_adapter)
    end

    def semantic_commands
      @semantic_commands ||= SemanticCommands.new(model: Sketchup.active_model)
    end

    def scene_validation_commands
      @scene_validation_commands ||= SceneValidationCommands.new
    end

    def measure_scene_commands
      @measure_scene_commands ||= MeasureSceneCommands.new
    end

    def terrain_surface_commands
      @terrain_surface_commands ||= Terrain::TerrainSurfaceCommands.new(
        model: Sketchup.active_model
      )
    end

    def staged_asset_commands
      @staged_asset_commands ||= StagedAssets::StagedAssetCommands.new(
        model_adapter: model_adapter
      )
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

    def developer_commands
      @developer_commands ||= DeveloperCommands.new(logger: logger)
    end

    private

    attr_reader :logger

    def model_adapter
      @model_adapter ||= Adapters::ModelAdapter.new
    end
  end
end
