# frozen_string_literal: true

require_relative 'corridor_overlay_preview'

module SU_MCP
  module Terrain
    module UI
      # SketchUp tool adapter for two-point corridor transition capture.
      class CorridorTransitionTool
        ENTER_KEY = 13
        ESCAPE_KEY = 27

        # rubocop:disable Naming/MethodName
        def initialize(
          session:,
          input_point_factory: nil,
          overlay: nil,
          after_apply: nil,
          after_state_change: nil
        )
          @session = session
          @input_point_factory = input_point_factory || -> { ::Sketchup::InputPoint.new }
          @overlay = overlay || default_overlay_for(session)
          @after_apply = after_apply || -> {}
          @after_state_change = after_state_change || -> {}
        end

        def activate
          session.activate if session.respond_to?(:activate)
          after_state_change.call
          nil
        end

        def deactivate(view)
          clear_overlay(view)
          view.invalidate if view.respond_to?(:invalidate)
          session.deactivate if session.respond_to?(:deactivate)
          after_state_change.call
          nil
        end

        def suspend(view)
          clear_overlay(view)
          view.invalidate if view.respond_to?(:invalidate)
          nil
        end

        def resume(_view)
          session.resume if session.respond_to?(:resume)
          after_state_change.call
          nil
        end

        def onMouseMove(_flags, x, y, view)
          input_point = picked_input_point(x, y, view)
          return invalid_pick_refusal unless input_point

          overlay&.update_hover(input_point.position, view: view)
          nil
        end

        def onLButtonDown(_flags, x, y, view)
          input_point = picked_input_point(x, y, view)
          return invalid_pick_refusal unless input_point

          recapture_target = current_recapture_target
          session.start_recapture(recapture_target) if recapture_target &&
                                                       session.respond_to?(:start_recapture)
          result = session.capture_point(input_point.position)
          overlay&.update(view: view) if overlay.respond_to?(:update)
          invalidate(view)
          after_state_change.call
          result
        end

        def onKeyDown(key, _repeat, _flags, view)
          return apply_from_key if key == ENTER_KEY
          return reset_from_key(view) if key == ESCAPE_KEY

          nil
        end

        def draw(view)
          overlay&.draw(view)
          nil
        end

        def getExtents
          return overlay.extents if overlay

          defined?(::Geom::BoundingBox) ? ::Geom::BoundingBox.new : nil
        end

        def onMouseLeave(view)
          invalidate(view)
          nil
        end

        def clear_overlay(view = nil)
          overlay&.clear(view: view)
        end
        # rubocop:enable Naming/MethodName

        private

        attr_reader :session, :input_point_factory, :overlay, :after_apply, :after_state_change

        def default_overlay_for(session)
          CorridorOverlayPreview.new(session: session)
        end

        def picked_input_point(x, y, view)
          input_point = input_point_factory.call
          return nil unless input_point.pick(view, x, y)
          return nil unless input_point.respond_to?(:position) && input_point.position

          input_point
        end

        def current_recapture_target
          return nil unless session.respond_to?(:state_snapshot)

          session.state_snapshot.dig(:corridor, :recaptureTarget)
        end

        def apply_from_key
          result = session.apply
          after_apply.call
          result
        end

        def reset_from_key(view)
          result = if session.respond_to?(:reset_corridor)
                     session.reset_corridor
                   else
                     session.reset
                   end
          clear_overlay(view)
          after_state_change.call
          result
        end

        def invalidate(view)
          view.invalidate if view.respond_to?(:invalidate)
        end

        def invalid_pick_refusal
          {
            outcome: 'refused',
            refusal: {
              code: 'terrain_corridor_pick_invalid',
              message: 'Pick a valid terrain point before capturing the corridor endpoint.',
              details: { field: 'point' }
            }
          }
        end
      end
    end
  end
end
