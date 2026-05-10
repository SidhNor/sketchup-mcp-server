# frozen_string_literal: true

require 'json'

module SU_MCP
  module Terrain
    module UI
      # HtmlDialog wrapper for the compact terrain brush settings palette.
      class SettingsDialog
        # rubocop:disable SketchupSuggestions/FileEncoding
        DIALOG_FILE = File.expand_path(
          File.join(File.dirname(__FILE__), 'assets', 'managed_terrain_panel.html')
        )
        # rubocop:enable SketchupSuggestions/FileEncoding

        def initialize(session:, dialog_factory: nil, after_update: nil, after_close: nil)
          @session = session
          @dialog_factory = dialog_factory || method(:build_dialog)
          @after_update = after_update || -> {}
          @after_close = after_close || -> {}
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

        attr_reader :session, :dialog_factory, :after_update, :after_close

        def register_callbacks(dialog)
          dialog.add_action_callback('ready') { |_context| refresh_and_push_state }
          dialog.add_action_callback('requestState') { |_context| refresh_and_push_state }
          dialog.add_action_callback('updateSettings') do |_context, payload|
            values = JSON.parse(payload.to_s)
            session.update_settings(values)
            unless transient_slider_update?(values)
              push_state
              after_update.call
            end
          end
          register_corridor_callbacks(dialog)
          dialog.add_action_callback('close') do |_context|
            close
            after_close.call
          end
        end

        def register_corridor_callbacks(dialog)
          dialog.add_action_callback('recaptureCorridorEndpoint') do |_context, endpoint|
            update_corridor_action { session.start_recapture(endpoint.to_s) }
          end
          dialog.add_action_callback('sampleCorridorTerrain') do |_context, endpoint|
            update_corridor_action { session.sample_terrain(endpoint.to_s) }
          end
          dialog.add_action_callback('resetCorridor') do |_context|
            update_corridor_action { reset_corridor }
          end
          dialog.add_action_callback('applyCorridor') do |_context|
            update_corridor_action { apply_corridor }
          end
        end

        def update_corridor_action
          yield
          push_state
          after_update.call
        end

        def reset_corridor
          return session.reset_corridor if session.respond_to?(:reset_corridor)

          session.reset if session.respond_to?(:reset)
        end

        def apply_corridor
          return session.apply_corridor if session.respond_to?(:apply_corridor)

          session.apply if session.respond_to?(:apply)
        end

        def refresh_and_push_state
          session.refresh_selection if session.respond_to?(:refresh_selection)
          push_state
        end

        def transient_slider_update?(values)
          source = values['source']
          source && %w[slider corridorElevationSlider].include?(source.to_s)
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
            dialog_title: 'Managed Terrain Tools',
            preferences_key: 'com.su-mcp.terrain.tools',
            scrollable: true,
            resizable: true,
            width: 320,
            height: 640
          }
        end

        def build_dialog(options)
          ::UI.const_get('HtmlDialog').new(options)
        end
      end
    end
  end
end
