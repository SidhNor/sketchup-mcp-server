# frozen_string_literal: true

require 'sketchup'
require_relative 'bridge'
require_relative 'mcp_spike_config'
require_relative 'mcp_spike_facade'
require_relative 'mcp_spike_http_backend'
require_relative 'mcp_spike_runtime_loader'
require_relative 'mcp_spike_server'
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
    SPIKE_MENU_PREFIX = 'Experimental MCP Spike'

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

    def mcp_spike_server
      @mcp_spike_server ||= build_mcp_spike_server
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
      bridge_menu_actions + spike_menu_actions + console_menu_actions
    end

    def bridge_menu_actions
      [
        ['Status', -> { UI.messagebox(Bridge.status_message(socket_server.status)) }],
        ['Start Bridge', -> { socket_server.start }],
        ['Restart Bridge', -> { restart_bridge }],
        ['Stop Bridge', -> { socket_server.stop }]
      ]
    end

    def spike_menu_actions
      [
        [
          "#{SPIKE_MENU_PREFIX} Status",
          -> { UI.messagebox(mcp_spike_status_message(mcp_spike_server.status)) }
        ],
        ["Start #{SPIKE_MENU_PREFIX}", -> { mcp_spike_server.start }],
        ["Restart #{SPIKE_MENU_PREFIX}", -> { restart_mcp_spike }],
        ["Stop #{SPIKE_MENU_PREFIX}", -> { mcp_spike_server.stop }]
      ]
    end

    def console_menu_actions
      [['Open Ruby Console', -> { SKETCHUP_CONSOLE.show if defined?(SKETCHUP_CONSOLE) }]]
    end

    def build_mcp_spike_server
      runtime_loader = McpSpikeRuntimeLoader.new(
        logger: ->(message) { log("MCP spike: #{message}") }
      )

      McpSpikeServer.new(
        config: McpSpikeConfig.new,
        runtime_loader: runtime_loader,
        backend: build_mcp_spike_backend(runtime_loader),
        facade: McpSpikeFacade.new,
        logger: ->(message) { log("MCP spike: #{message}") }
      )
    end

    def build_mcp_spike_backend(runtime_loader)
      McpSpikeHttpBackend.new(
        app_builder: ->(handlers) { build_mcp_spike_transport(runtime_loader, handlers) },
        server_factory: ->(host, port) { TCPServer.new(host, port) },
        timer_starter: lambda do |interval, repeat, &block|
          UI.start_timer(interval, repeat, &block)
        end,
        timer_stopper: ->(timer_id) { UI.stop_timer(timer_id) },
        logger: method(:log)
      )
    end

    def build_mcp_spike_transport(runtime_loader, handlers)
      runtime_loader.build_transport(
        ping_handler: handlers.fetch(:ping),
        scene_info_handler: handlers.fetch(:get_scene_info)
      )
    end

    def restart_bridge
      socket_server.stop
      socket_server.start
    end

    def restart_mcp_spike
      mcp_spike_server.stop
      mcp_spike_server.start
    end

    def mcp_spike_status_message(server_status)
      return available_mcp_spike_status_message(server_status) if server_status[:available]

      unavailable_mcp_spike_status_message(server_status)
    end

    def available_mcp_spike_status_message(server_status)
      [
        'Experimental SketchUp MCP spike is available.',
        "Endpoint: #{server_status[:host]}:#{server_status[:port]}",
        "Running: #{server_status[:running] ? 'yes' : 'no'}",
        'Transport: Ruby-native MCP Streamable HTTP spike',
        'Packaging: requires staged vendored runtime support tree'
      ].join("\n")
    end

    def unavailable_mcp_spike_status_message(server_status)
      [
        'Experimental SketchUp MCP spike is not staged in this repo checkout.',
        "Expected vendored runtime root: #{server_status[:vendor_root]}",
        "Missing staged gems: #{server_status[:missing_gems].join(', ')}",
        'Packaging: stage vendored runtime into the extension support tree before local use'
      ].join("\n")
    end

    private_class_method :build_menu, :menu_actions, :restart_bridge, :restart_mcp_spike,
                         :mcp_spike_status_message, :build_mcp_spike_server,
                         :build_mcp_spike_backend, :build_mcp_spike_transport,
                         :bridge_menu_actions, :spike_menu_actions, :console_menu_actions,
                         :available_mcp_spike_status_message, :unavailable_mcp_spike_status_message
  end

  unless file_loaded?(__FILE__)
    Main.activate
    file_loaded(__FILE__)
  end
  # rubocop:enable Metrics/ModuleLength
end
