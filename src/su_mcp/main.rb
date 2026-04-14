# frozen_string_literal: true

require 'sketchup'
require_relative 'bridge'
require_relative 'runtime_logger'
require_relative 'socket_server'
require_relative 'version'

# Namespace for the SketchUp MCP extension runtime.
module SU_MCP
  # SketchUp-facing entrypoint for booting and controlling the MCP bridge.
  module Main
    # Main extension bootstrap and menu wiring.
    MENU_NAME = 'SketchUp MCP'

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

    def log(message)
      RuntimeLogger.main(message)
    end

    def build_menu(menu)
      menu_actions.each do |label, action|
        menu.add_item(label, &action)
      end
    end

    def menu_actions
      [
        ['Status', -> { UI.messagebox(Bridge.status_message(socket_server.status)) }],
        ['Start Bridge', -> { socket_server.start }],
        ['Restart Bridge', -> { restart_bridge }],
        ['Stop Bridge', -> { socket_server.stop }],
        ['Open Ruby Console', -> { SKETCHUP_CONSOLE.show if defined?(SKETCHUP_CONSOLE) }]
      ]
    end

    def restart_bridge
      socket_server.stop
      socket_server.start
    end

    private_class_method :build_menu, :menu_actions, :restart_bridge
  end

  unless file_loaded?(__FILE__)
    Main.activate
    file_loaded(__FILE__)
  end
end
