# frozen_string_literal: true

require 'sketchup'
require_relative 'bridge'
require_relative 'mcp_runtime_config'
require_relative 'mcp_runtime_facade'
require_relative 'mcp_runtime_http_backend'
require_relative 'mcp_runtime_loader'
require_relative 'mcp_runtime_server'
require_relative 'runtime_logger'
require_relative 'socket_server'
require_relative 'version'

# Namespace for the SketchUp MCP extension runtime.
module SU_MCP
  # SketchUp-facing entrypoint for booting and controlling the MCP bridge.
  # rubocop:disable Metrics/ModuleLength
  module Main
    # Main extension bootstrap and menu wiring.
    MENU_NAME = 'SketchUp MCP'
    NATIVE_RUNTIME_MENU_PREFIX = 'Native MCP Runtime'

    module_function

    def activate
      install_menu
      socket_server.start
      log("Extension loaded (v#{VERSION}).")
    end

    def install_menu
      return if @menu_installed

      build_menu(UI.menu('Extensions').add_submenu(MENU_NAME))
      @menu_installed = true
    end

    def socket_server
      @socket_server ||= SocketServer.new(
        host: Bridge.socket_bind_host,
        port: Bridge.socket_port
      )
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
      bridge_menu_actions + native_runtime_menu_actions + console_menu_actions
    end

    def bridge_menu_actions
      [
        ['Status', -> { UI.messagebox(Bridge.status_message(socket_server.status)) }],
        ['Start Bridge', -> { socket_server.start }],
        ['Restart Bridge', -> { restart_bridge }],
        ['Stop Bridge', -> { socket_server.stop }]
      ]
    end

    def native_runtime_menu_actions
      [
        [
          "#{NATIVE_RUNTIME_MENU_PREFIX} Status",
          lambda do
            UI.messagebox(
              native_runtime_status_message(native_runtime_server.status)
            )
          end
        ],
        ["Start #{NATIVE_RUNTIME_MENU_PREFIX}", -> { native_runtime_server.start }],
        ["Restart #{NATIVE_RUNTIME_MENU_PREFIX}", -> { restart_native_runtime }],
        ["Stop #{NATIVE_RUNTIME_MENU_PREFIX}", -> { native_runtime_server.stop }]
      ]
    end

    def console_menu_actions
      [['Open Ruby Console', -> { SKETCHUP_CONSOLE.show if defined?(SKETCHUP_CONSOLE) }]]
    end

    def build_native_runtime_server
      runtime_loader = McpRuntimeLoader.new(
        logger: ->(message) { log("MCP runtime: #{message}") }
      )
      runtime_command_factory = RuntimeCommandFactory.new(
        logger: ->(message) { log("MCP runtime: #{message}") }
      )

      McpRuntimeServer.new(
        config: McpRuntimeConfig.new,
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

    def restart_bridge
      socket_server.stop
      socket_server.start
    end

    def restart_native_runtime
      native_runtime_server.stop
      native_runtime_server.start
    end

    def native_runtime_status_message(server_status)
      return available_native_runtime_status_message(server_status) if server_status[:available]

      unavailable_native_runtime_status_message(server_status)
    end

    def available_native_runtime_status_message(server_status)
      [
        'Native SketchUp MCP runtime is available.',
        "Endpoint: #{server_status[:host]}:#{server_status[:port]}",
        "Running: #{server_status[:running] ? 'yes' : 'no'}",
        'Transport: Ruby-native MCP Streamable HTTP runtime',
        'Packaging: requires staged vendored runtime support tree'
      ].join("\n")
    end

    def unavailable_native_runtime_status_message(server_status)
      [
        'Native SketchUp MCP runtime is not staged in this repo checkout.',
        "Expected vendored runtime root: #{server_status[:vendor_root]}",
        "Missing staged gems: #{server_status[:missing_gems].join(', ')}",
        'Packaging: stage vendored runtime into the extension support tree before local use'
      ].join("\n")
    end

    private_class_method(
      :build_menu,
      :menu_actions,
      :restart_bridge,
      :restart_native_runtime,
      :native_runtime_status_message,
      :build_native_runtime_server,
      :build_native_runtime_backend,
      :build_native_runtime_transport,
      :bridge_menu_actions,
      :native_runtime_menu_actions,
      :console_menu_actions,
      :available_native_runtime_status_message,
      :unavailable_native_runtime_status_message
    )
  end

  unless file_loaded?(__FILE__)
    Main.activate
    file_loaded(__FILE__)
  end
  # rubocop:enable Metrics/ModuleLength
end
