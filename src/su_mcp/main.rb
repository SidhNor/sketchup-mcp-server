require "sketchup.rb"
require_relative "bridge"
require_relative "version"

module SU_MCP
  module Main
    MENU_NAME = "SketchUp MCP".freeze

    module_function

    def activate
      install_menu
      log("Extension loaded (v#{VERSION}).")
    end

    def install_menu
      return if @menu_installed

      menu = UI.menu("Extensions").add_submenu(MENU_NAME)
      menu.add_item("Status") { UI.messagebox(Bridge.status_message) }
      menu.add_item("Open Ruby Console") { SKETCHUP_CONSOLE.show if defined?(SKETCHUP_CONSOLE) }

      @menu_installed = true
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
