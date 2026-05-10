# frozen_string_literal: true

require_relative 'brush_edit_session'
require_relative 'corridor_transition_session'

module SU_MCP
  module Terrain
    module UI
      # Delegates shared panel callbacks to the active managed terrain UI session.
      class ManagedTerrainToolSession
        CORRIDOR_TOOL = 'corridor_transition'
        attr_reader :brush_session, :corridor_session

        def initialize(
          brush_session: BrushEditSession.new,
          corridor_session: CorridorTransitionSession.new
        )
          @brush_session = brush_session
          @corridor_session = corridor_session
          @active_tool = 'target_height'
        end

        def activate_tool(tool)
          @active_tool = tool.to_s
          active_session.activate_tool(tool) if active_session.respond_to?(:activate_tool)
          active_session.activate if active_session.respond_to?(:activate) &&
                                     !active_session.respond_to?(:activate_tool)
          state_snapshot
        end

        def activate
          activate_tool(@active_tool)
        end

        def deactivate
          active_session.deactivate if active_session.respond_to?(:deactivate)
        end

        def active?
          active_session.respond_to?(:active?) && active_session.active?
        end

        def active_tool?(tool)
          @active_tool == tool.to_s && active?
        end

        def refresh_selection
          active_session.refresh_selection if active_session.respond_to?(:refresh_selection)
        end

        def update_settings(values)
          active_session.update_settings(values)
        end

        def apply_click(point)
          brush_session.apply_click(point)
        end

        def preview_context(point = nil)
          return corridor_session.preview_context(point) if corridor_active?

          brush_session.preview_context(point)
        end

        def capture_point(point)
          corridor_session.capture_point(point)
        end

        def start_recapture(endpoint)
          corridor_session.start_recapture(endpoint)
        end

        def sample_terrain(endpoint)
          corridor_session.sample_terrain(endpoint)
        end

        def reset_corridor
          corridor_session.reset_corridor
        end

        def apply_corridor
          corridor_session.apply_corridor
        end

        def state_snapshot
          snapshot = active_session.state_snapshot
          snapshot.merge(activeTool: @active_tool, mode: @active_tool)
        end

        private

        def active_session
          corridor_active? ? corridor_session : brush_session
        end

        def corridor_active?
          @active_tool == CORRIDOR_TOOL
        end
      end
    end
  end
end
