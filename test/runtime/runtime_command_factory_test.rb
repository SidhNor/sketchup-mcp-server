# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/runtime_command_factory'

class RuntimeCommandFactoryTest < Minitest::Test
  def test_builds_a_measure_scene_command_target
    targets = SU_MCP::RuntimeCommandFactory.new.build_command_targets

    assert(targets.any? { |target| target.respond_to?(:measure_scene, true) })
  end

  def test_builds_a_terrain_surface_command_target
    targets = SU_MCP::RuntimeCommandFactory.new.build_command_targets

    assert(targets.any? { |target| target.respond_to?(:create_terrain_surface, true) })
  end

  def test_builds_an_editable_terrain_surface_command_target
    targets = SU_MCP::RuntimeCommandFactory.new.build_command_targets

    assert(targets.any? { |target| target.respond_to?(:edit_terrain_surface, true) })
  end

  def test_terrain_surface_commands_receive_mesh_generator_from_output_stack_factory
    mesh_generator = Object.new
    factory = SU_MCP::RuntimeCommandFactory.new(
      terrain_output_stack_factory: StaticTerrainOutputStackFactory.new(mesh_generator)
    )

    commands = factory.terrain_surface_commands

    assert_same(mesh_generator, commands.send(:mesh_generator))
  end

  def test_builds_a_staged_asset_command_target
    targets = SU_MCP::RuntimeCommandFactory.new.build_command_targets

    assert(targets.any? { |target| target.respond_to?(:curate_staged_asset, true) })
    assert(targets.any? { |target| target.respond_to?(:list_staged_assets, true) })
  end

  def test_does_not_build_a_boolean_operation_command_target
    targets = SU_MCP::RuntimeCommandFactory.new.build_command_targets

    refute(targets.any? { |target| target.respond_to?(:boolean_operation, true) })
  end

  class StaticTerrainOutputStackFactory
    attr_reader :mesh_generator

    def initialize(mesh_generator)
      @mesh_generator = mesh_generator
    end
  end
end
