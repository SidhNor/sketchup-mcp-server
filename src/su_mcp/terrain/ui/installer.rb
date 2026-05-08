# frozen_string_literal: true

require_relative 'brush_edit_session'
require_relative 'settings_dialog'
require_relative 'target_height_brush_tool'

module SU_MCP
  module Terrain
    module UI
      # Installs the managed terrain brush toolbar and menu entrypoints.
      class Installer
        TOOLBAR_NAME = 'Managed Terrain'
        COMMAND_TEXT = 'Target Height Brush'
        # rubocop:disable SketchupSuggestions/FileEncoding
        ICON_PATH = File.expand_path('assets/target_height_brush.svg', __dir__)
        # rubocop:enable SketchupSuggestions/FileEncoding

        def initialize(
          ui_host: nil,
          session: nil,
          dialog: nil,
          tool_factory: nil
        )
          @ui_host = ui_host || RealUiHost.new
          @session = session || BrushEditSession.new
          @dialog = dialog
          @tool_factory = tool_factory || lambda {
            TargetHeightBrushTool.new(
              session: @session,
              after_apply: -> { @dialog&.push_state },
              after_state_change: -> { refresh_active_ui_state }
            )
          }
          @tool = nil
          @command = nil
          @installed = false
        end

        def install
          return if @installed

          command = build_command
          @command = command
          toolbar = ui_host.toolbar(TOOLBAR_NAME)
          toolbar.add_item(command)
          toolbar.show
          ui_host.add_menu_item(COMMAND_TEXT) { activate_brush }
          @installed = true
          command
        end

        private

        attr_reader :ui_host, :session, :tool_factory

        def build_command
          command = ui_host.command(COMMAND_TEXT) { activate_brush }
          command.small_icon = ICON_PATH
          command.large_icon = ICON_PATH
          configure_validation(command)
          command
        end

        def activate_brush
          session.activate
          show_dialog
          reselect_tool
          refresh_active_ui_state
        end

        def show_dialog
          return ui_host.show_dialog if ui_host.respond_to?(:show_dialog)

          dialog.show
        end

        def reselect_tool
          ui_host.select_tool(tool)
        end

        def refresh_command_state
          update_command_icon
          ui_host.refresh_toolbars if ui_host.respond_to?(:refresh_toolbars)
        end

        def refresh_active_ui_state
          refresh_command_state
          @dialog&.push_state
        end

        def tool
          @tool ||= tool_factory.call
        end

        def update_command_icon
          return unless @command

          @command.small_icon = ICON_PATH
          @command.large_icon = ICON_PATH
        end

        def dialog
          @dialog ||= SettingsDialog.new(session: session, after_update: -> { reselect_tool })
        end

        def configure_validation(command)
          validation = -> { session.active? ? checked_state : unchecked_state }
          if command.respond_to?(:set_validation_proc)
            command.set_validation_proc(&validation)
          elsif command.respond_to?(:validation=)
            command.validation = validation
          end
        end

        def checked_state
          ui_host.respond_to?(:checked_state) ? ui_host.checked_state : :checked
        end

        def unchecked_state
          ui_host.respond_to?(:unchecked_state) ? ui_host.unchecked_state : :unchecked
        end

        # Thin adapter for real SketchUp UI objects.
        class RealUiHost
          def initialize(menu: nil)
            @menu = menu
          end

          def command(text, &block)
            ::UI.const_get('Command').new(text, &block).tap do |command|
              command.menu_text = text
              command.tooltip = text
              command.status_bar_text = 'Apply a circular managed terrain target-height brush.'
            end
          end

          def toolbar(name)
            ::UI.const_get('Toolbar').new(name)
          end

          def add_menu_item(text, &block)
            menu.add_item(text, &block)
          end

          def select_tool(tool)
            ::Sketchup.active_model.select_tool(tool)
          end

          def refresh_toolbars
            ::UI.send(:refresh_toolbars) if ::UI.respond_to?(:refresh_toolbars)
          end

          def checked_state
            defined?(MF_CHECKED) ? MF_CHECKED : :checked
          end

          def unchecked_state
            defined?(MF_UNCHECKED) ? MF_UNCHECKED : :unchecked
          end

          private

          def menu
            @menu ||= ::UI.menu('Extensions').add_submenu('SketchUp MCP')
          end
        end
      end
    end
  end
end
