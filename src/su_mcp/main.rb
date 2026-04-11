require "sketchup.rb"
require_relative "bridge"
require_relative "socket_server"
require_relative "version"

module SU_MCP
  module Main
    MENU_NAME = "SketchUp MCP".freeze

    module_function

    def activate
      install_menu
      socket_server.start
      log("Extension loaded (v#{VERSION}).")
    end

    def install_menu
      return if @menu_installed

      menu = UI.menu("Extensions").add_submenu(MENU_NAME)
      menu.add_item("Status") { UI.messagebox(Bridge.status_message(socket_server.status)) }
      menu.add_item("Start Bridge") { socket_server.start }
      menu.add_item("Restart Bridge") do
        socket_server.stop
        socket_server.start
      end
      menu.add_item("Stop Bridge") { socket_server.stop }
      menu.add_item("Open Ruby Console") { SKETCHUP_CONSOLE.show if defined?(SKETCHUP_CONSOLE) }

      @menu_installed = true
    end

    def socket_server
      @socket_server ||= SocketServer.new(
        host: Bridge.socket_bind_host,
        port: Bridge.socket_port
      )
    end

    def log(message)
      SKETCHUP_CONSOLE.show if defined?(SKETCHUP_CONSOLE)
      puts "SketchUp MCP: #{message}"
    rescue StandardError
      puts "SketchUp MCP: #{message}"
    end
  end

  unless file_loaded?(__FILE__)
    Main.activate
    file_loaded(__FILE__)
  end
end
