# frozen_string_literal: true

require 'json'

module SU_MCP
  module Terrain
    module UI
      # HtmlDialog wrapper for the compact terrain brush settings palette.
      class SettingsDialog
        # rubocop:disable SketchupSuggestions/FileEncoding
        DIALOG_FILE = File.expand_path(
          File.join(File.dirname(__FILE__), 'assets', 'target_height_brush.html')
        )
        # rubocop:enable SketchupSuggestions/FileEncoding

        def initialize(session:, dialog_factory: nil, after_update: nil)
          @session = session
          @dialog_factory = dialog_factory || method(:build_dialog)
          @after_update = after_update || -> {}
          @dialog = nil
        end

        def show
          if dialog_visible?
            @dialog.bring_to_front if @dialog.respond_to?(:bring_to_front)
            return @dialog
          end

          @dialog = dialog_factory.call(dialog_options)
          @dialog.set_file(DIALOG_FILE)
          register_callbacks(@dialog)
          @dialog.show
          @dialog
        end

        def push_state
          return unless @dialog.respond_to?(:execute_script)

          payload = script_safe_json(session.state_snapshot)
          @dialog.execute_script("window.suMcpTerrainBrush.applyState(#{payload});")
        end

        def close
          @dialog&.close
          @dialog = nil
        end

        private

        attr_reader :session, :dialog_factory, :after_update

        def register_callbacks(dialog)
          dialog.add_action_callback('ready') { |_context| refresh_and_push_state }
          dialog.add_action_callback('requestState') { |_context| refresh_and_push_state }
          dialog.add_action_callback('updateSettings') do |_context, payload|
            session.update_settings(JSON.parse(payload.to_s))
            push_state
            after_update.call
          end
          dialog.add_action_callback('close') { |_context| close }
        end

        def refresh_and_push_state
          session.refresh_selection if session.respond_to?(:refresh_selection)
          push_state
        end

        def script_safe_json(payload)
          JSON.generate(payload)
              .gsub('</', '<\\/')
              .gsub("\u2028", '\\u2028')
              .gsub("\u2029", '\\u2029')
        end

        def dialog_visible?
          @dialog.respond_to?(:visible?) && @dialog.visible?
        end

        def dialog_options
          {
            dialog_title: 'Managed Terrain Target Height Brush',
            preferences_key: 'com.su-mcp.terrain.target-height-brush',
            scrollable: false,
            resizable: false,
            width: 320,
            height: 360
          }
        end

        def build_dialog(options)
          ::UI.const_get('HtmlDialog').new(options)
        end
      end
    end
  end
end
