# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/runtime_command_factory'

class RuntimeCommandFactoryTest < Minitest::Test
  def test_builds_a_measure_scene_command_target
    targets = SU_MCP::RuntimeCommandFactory.new.build_command_targets

    assert(targets.any? { |target| target.respond_to?(:measure_scene, true) })
  end
end
