# frozen_string_literal: true

require_relative 'brush_edit_session'
require_relative 'corridor_transition_tool'
require_relative 'managed_terrain_tool_session'
require_relative 'settings_dialog'
require_relative 'target_height_brush_tool'

module SU_MCP
  module Terrain
    module UI
      # Installs the managed terrain brush toolbar and menu entrypoints.
      class Installer
        TOOLBAR_NAME = 'Managed Terrain'
        COMMAND_TEXT = 'Target Height Brush'
        LOCAL_FAIRING_COMMAND_TEXT = 'Local Fairing'
        CORRIDOR_TRANSITION_COMMAND_TEXT = 'Corridor Transition'
        # rubocop:disable SketchupSuggestions/FileEncoding
        ICON_PATH = File.expand_path('assets/target_height_brush.svg', __dir__)
        LOCAL_FAIRING_ICON_PATH = File.expand_path('assets/local_fairing.svg', __dir__)
        CORRIDOR_TRANSITION_ICON_PATH = File.expand_path(
          'assets/corridor_transition.svg',
          __dir__
        )
        # rubocop:enable SketchupSuggestions/FileEncoding
        COMMANDS = [
          {
            tool: 'target_height',
            text: COMMAND_TEXT,
            icon: ICON_PATH,
            status: 'Apply a circular managed terrain target-height brush.'
          },
          {
            tool: 'local_fairing',
            text: LOCAL_FAIRING_COMMAND_TEXT,
            icon: LOCAL_FAIRING_ICON_PATH,
            status: 'Apply a circular managed terrain local fairing brush.'
          },
          {
            tool: 'corridor_transition',
            text: CORRIDOR_TRANSITION_COMMAND_TEXT,
            icon: CORRIDOR_TRANSITION_ICON_PATH,
            status: 'Apply a managed terrain corridor transition.'
          }
        ].freeze

        def initialize(
          ui_host: nil,
          session: nil,
          dialog: nil,
          tool_factory: nil,
          corridor_tool_factory: nil
        )
          @ui_host = ui_host || RealUiHost.new
          @session = session || ManagedTerrainToolSession.new
          @dialog = dialog
          @tool_factory = tool_factory || lambda {
            TargetHeightBrushTool.new(
              session: session_for_tool('target_height'),
              after_apply: -> { @dialog&.push_state },
              after_state_change: -> { refresh_active_ui_state }
            )
          }
          @corridor_tool_factory = corridor_tool_factory || lambda {
            CorridorTransitionTool.new(
              session: session_for_tool('corridor_transition'),
              after_apply: -> { @dialog&.push_state },
              after_state_change: -> { refresh_active_ui_state }
            )
          }
          @brush_tool = nil
          @corridor_tool = nil
          @commands = {}
          @installed = false
        end

        def install
          return if @installed

          toolbar = ui_host.toolbar(TOOLBAR_NAME)
          COMMANDS.each do |definition|
            command = build_command(definition)
            @commands[definition.fetch(:tool)] = command
            toolbar.add_item(command)
            ui_host.add_menu_item(definition.fetch(:text)) do
              activate_brush(definition.fetch(:tool))
            end
          end
          toolbar.show
          @installed = true
          @commands.fetch('target_height')
        end

        private

        attr_reader :ui_host, :session, :tool_factory, :corridor_tool_factory

        def build_command(definition)
          command = ui_host.command(definition.fetch(:text)) do
            activate_brush(definition.fetch(:tool))
          end
          command.small_icon = definition.fetch(:icon)
          command.large_icon = definition.fetch(:icon)
          configure_validation(command, definition.fetch(:tool))
          command
        end

        def activate_brush(tool)
          if session.respond_to?(:activate_tool)
            session.activate_tool(tool)
          else
            session.activate
          end
          show_dialog
          reselect_tool(tool)
          refresh_active_ui_state
        end

        def show_dialog
          return ui_host.show_dialog if ui_host.respond_to?(:show_dialog)

          dialog.show
        end

        def reselect_tool(tool_name = active_tool_name)
          ui_host.select_tool(sketchup_tool_for(tool_name))
        end

        def refresh_command_state
          update_command_icon
          ui_host.refresh_toolbars if ui_host.respond_to?(:refresh_toolbars)
        end

        def refresh_active_ui_state
          refresh_command_state
          @dialog&.push_state
        end

        def sketchup_tool_for(tool_name)
          case tool_name
          when 'corridor_transition'
            corridor_tool
          when 'target_height', 'local_fairing'
            brush_tool
          else
            raise ArgumentError, "Unknown managed terrain tool: #{tool_name}"
          end
        end

        def session_for_tool(tool_name)
          return session unless session.is_a?(ManagedTerrainToolSession)

          case tool_name
          when 'corridor_transition'
            session.corridor_session
          when 'target_height', 'local_fairing'
            session.brush_session
          else
            raise ArgumentError, "Unknown managed terrain tool: #{tool_name}"
          end
        end

        def active_tool_name
          snapshot = session.respond_to?(:state_snapshot) ? session.state_snapshot : {}
          snapshot.fetch(:activeTool, snapshot.fetch('activeTool', 'target_height'))
        end

        def brush_tool
          @brush_tool ||= tool_factory.call
        end

        def tool
          brush_tool
        end

        def corridor_tool
          @corridor_tool ||= corridor_tool_factory.call
        end

        def update_command_icon
          COMMANDS.each do |definition|
            command = @commands[definition.fetch(:tool)]
            next unless command

            command.small_icon = definition.fetch(:icon)
            command.large_icon = definition.fetch(:icon)
          end
        end

        def dialog
          @dialog ||= SettingsDialog.new(
            session: session,
            after_update: -> { reselect_tool },
            after_close: -> { clear_tool_overlays }
          )
        end

        def clear_tool_overlays
          [brush_tool, @corridor_tool].compact.each do |active_tool|
            active_tool.clear_overlay if active_tool.respond_to?(:clear_overlay)
          end
        end

        def configure_validation(command, tool)
          validation = lambda do
            active = if session.respond_to?(:active_tool?)
                       session.active_tool?(tool)
                     else
                       session.active?
                     end
            active ? checked_state : unchecked_state
          end
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
              command.status_bar_text = status_for(text)
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

          def status_for(text)
            definition = COMMANDS.find { |entry| entry.fetch(:text) == text }
            return definition.fetch(:status) if definition

            'Apply a circular managed terrain target-height brush.'
          end

          def menu
            @menu ||= ::UI.menu('Extensions').add_submenu('SketchUp MCP')
          end
        end
      end
    end
  end
end
