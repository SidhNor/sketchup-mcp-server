# frozen_string_literal: true

require 'sketchup'
require_relative 'runtime/native/mcp_runtime_config'
require_relative 'runtime/native/mcp_runtime_facade'
require_relative 'runtime/native/mcp_runtime_http_backend'
require_relative 'runtime/native/mcp_runtime_loader'
require_relative 'runtime/native/mcp_runtime_server'
require_relative 'runtime/runtime_logger'
require_relative 'terrain/ui/installer'
require_relative 'version'

# Namespace for the SketchUp MCP extension runtime.
module SU_MCP
  # SketchUp-facing entrypoint for booting and controlling the MCP server.
  module Main
    # Main extension bootstrap and menu wiring.
    MENU_NAME = 'SketchUp MCP'
    MCP_SERVER_MENU_PREFIX = 'MCP Server'

    module_function

    def activate
      install_menu
      start_native_runtime_if_available
      log("Extension loaded (v#{VERSION}).")
    end

    def install_menu
      return if @menu_installed

      menu = UI.menu('Extensions').add_submenu(MENU_NAME)
      build_menu(menu)
      install_managed_terrain_ui(menu)
      @menu_installed = true
    end

    def native_runtime_server
      @native_runtime_server ||= build_native_runtime_server
    end

    def log(message)
      RuntimeLogger.main(message)
    end

    def build_menu(menu)
      menu_actions.each do |label, action|
        menu.add_item(label, &action)
      end
    end

    def menu_actions
      native_runtime_menu_actions + console_menu_actions
    end

    def native_runtime_menu_actions
      [
        [
          "#{MCP_SERVER_MENU_PREFIX} Status",
          lambda do
            UI.messagebox(
              native_runtime_status_message(native_runtime_server.status)
            )
          end
        ],
        ["Start #{MCP_SERVER_MENU_PREFIX}", -> { native_runtime_server.start }],
        ["Restart #{MCP_SERVER_MENU_PREFIX}", -> { restart_native_runtime }],
        ["Stop #{MCP_SERVER_MENU_PREFIX}", -> { native_runtime_server.stop }]
      ]
    end

    def console_menu_actions
      [['Open Ruby Console', -> { SKETCHUP_CONSOLE.show if defined?(SKETCHUP_CONSOLE) }]]
    end

    def install_managed_terrain_ui(menu)
      Terrain::UI::Installer.new(
        ui_host: Terrain::UI::Installer::RealUiHost.new(menu: menu)
      ).install
    end

    def build_native_runtime_server
      config = McpRuntimeConfig.new
      runtime_loader = McpRuntimeLoader.new(
        logger: ->(message) { log("MCP runtime: #{message}") }
      )
      runtime_command_factory = RuntimeCommandFactory.new(
        terrain_output_stack_factory: Terrain::TerrainOutputStackFactory.new(
          mode: config.terrain_output_mode
        ),
        logger: ->(message) { log("MCP runtime: #{message}") }
      )

      McpRuntimeServer.new(
        config: config,
        runtime_loader: runtime_loader,
        backend: build_native_runtime_backend(runtime_loader),
        facade: McpRuntimeFacade.new(runtime_command_factory: runtime_command_factory),
        logger: ->(message) { log("MCP runtime: #{message}") }
      )
    end

    def build_native_runtime_backend(runtime_loader)
      McpRuntimeHttpBackend.new(
        app_builder: lambda do |handlers|
          build_native_runtime_transport(runtime_loader, handlers)
        end,
        server_factory: ->(host, port) { TCPServer.new(host, port) },
        timer_starter: lambda do |interval, repeat, &block|
          UI.start_timer(interval, repeat, &block)
        end,
        timer_stopper: ->(timer_id) { UI.stop_timer(timer_id) },
        logger: method(:log)
      )
    end

    def build_native_runtime_transport(runtime_loader, handlers)
      runtime_loader.build_transport(handlers: handlers)
    end

    def restart_native_runtime
      native_runtime_server.stop
      native_runtime_server.start
    end

    def start_native_runtime_if_available
      native_runtime_server.start if native_runtime_server.status[:available]
    rescue StandardError, LoadError => e
      log("MCP server did not start automatically: #{e.message}")
    end

    def native_runtime_status_message(server_status)
      return available_native_runtime_status_message(server_status) if server_status[:available]

      unavailable_native_runtime_status_message(server_status)
    end

    def available_native_runtime_status_message(server_status)
      [
        'SketchUp MCP server is available.',
        "Endpoint: #{server_status[:host]}:#{server_status[:port]}",
        "Running: #{server_status[:running] ? 'yes' : 'no'}",
        'Transport: MCP Streamable HTTP server',
        'Packaging: requires staged vendored runtime support tree'
      ].join("\n")
    end

    def unavailable_native_runtime_status_message(server_status)
      [
        'SketchUp MCP server support is unavailable.',
        "Expected vendored runtime root: #{server_status[:vendor_root]}",
        "Missing staged gems: #{server_status[:missing_gems].join(', ')}",
        'Packaging/install: ensure the staged vendored runtime support tree is present'
      ].join("\n")
    end

    private_class_method(
      :build_menu,
      :menu_actions,
      :restart_native_runtime,
      :start_native_runtime_if_available,
      :native_runtime_status_message,
      :build_native_runtime_server,
      :build_native_runtime_backend,
      :build_native_runtime_transport,
      :native_runtime_menu_actions,
      :console_menu_actions,
      :install_managed_terrain_ui,
      :available_native_runtime_status_message,
      :unavailable_native_runtime_status_message
    )
  end

  unless file_loaded?(__FILE__)
    Main.activate
    file_loaded(__FILE__)
  end
end
