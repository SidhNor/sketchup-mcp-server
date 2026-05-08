# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/main'

class McpRuntimeMainIntegrationTest < Minitest::Test
  class StubRuntimeServer
    attr_reader :start_calls

    def initialize(available:)
      @available = available
      @start_calls = 0
    end

    def status
      { available: @available }
    end

    def start
      @start_calls += 1
    end
  end

  def test_menu_actions_include_only_mcp_server_controls
    labels = SU_MCP::Main.send(:menu_actions).map(&:first)

    refute_includes(labels, 'Status')
    refute_includes(labels, 'Start Bridge')
    refute_includes(labels, 'Restart Bridge')
    refute_includes(labels, 'Stop Bridge')
    assert_includes(labels, 'MCP Server Status')
    assert_includes(labels, 'Start MCP Server')
    assert_includes(labels, 'Restart MCP Server')
    assert_includes(labels, 'Stop MCP Server')
  end

  def test_main_delegates_managed_terrain_ui_installation_without_owning_brush_logic
    main_source = File.read(File.expand_path('../../../src/su_mcp/main.rb', __dir__),
                            encoding: 'utf-8')

    assert_includes(main_source, "require_relative 'terrain/ui/installer'")
    assert_includes(main_source, 'Terrain::UI::Installer')
    refute_includes(main_source, 'targetElevation')
    refute_includes(main_source, 'blendDistance')
    refute_includes(main_source, 'Sketchup::Tool')
  end

  def test_native_runtime_server_uses_the_shared_runtime_command_factory
    server = SU_MCP::Main.send(:build_native_runtime_server)
    facade = server.instance_variable_get(:@facade)
    runtime_command_factory = facade.instance_variable_get(:@runtime_command_factory)

    assert_instance_of(SU_MCP::RuntimeCommandFactory, runtime_command_factory)
  end

  def test_main_bootstrap_no_longer_requires_bridge_runtime
    main_source = File.read(File.expand_path('../../../src/su_mcp/main.rb', __dir__),
                            encoding: 'utf-8')

    refute_includes(main_source, "require_relative 'transport/bridge'")
    refute_includes(main_source, "require_relative 'transport/socket_server'")
    refute_match(/\bsocket_server\b/, main_source)
    refute_match(/\bBridge\b/, main_source)
  end

  def test_auto_start_runs_only_when_native_runtime_is_available
    available_server = StubRuntimeServer.new(available: true)
    unavailable_server = StubRuntimeServer.new(available: false)

    SU_MCP::Main.instance_variable_set(:@native_runtime_server, available_server)
    SU_MCP::Main.send(:start_native_runtime_if_available)
    assert_equal(1, available_server.start_calls)

    SU_MCP::Main.instance_variable_set(:@native_runtime_server, unavailable_server)
    SU_MCP::Main.send(:start_native_runtime_if_available)
    assert_equal(0, unavailable_server.start_calls)
  ensure
    SU_MCP::Main.remove_instance_variable(:@native_runtime_server) if
      SU_MCP::Main.instance_variable_defined?(:@native_runtime_server)
  end
end
