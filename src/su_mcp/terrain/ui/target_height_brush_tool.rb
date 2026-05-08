# frozen_string_literal: true

require_relative 'brush_overlay_preview'

module SU_MCP
  module Terrain
    module UI
      # SketchUp tool adapter for click-to-apply target-height brush edits.
      class TargetHeightBrushTool
        # rubocop:disable Naming/MethodName
        STATUS_TEXT = 'Click a managed terrain surface to apply target height.'

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
          clear_overlay(nil)
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

        def onMouseMove(_flags, x, y, view)
          return set_status(view, STATUS_TEXT) unless overlay

          input_point = input_point_factory.call
          picked = input_point.pick(view, x, y)
          unless picked && input_point.respond_to?(:position) && input_point.position
            clear_overlay(view)
            return set_status(view, invalid_pick_refusal.dig(:refusal, :message))
          end

          overlay.update_hover(input_point.position, view: view)
          nil
        end

        def onLButtonDown(_flags, x, y, view)
          input_point = input_point_factory.call
          picked = input_point.pick(view, x, y)
          return invalid_pick_refusal unless picked && input_point.respond_to?(:position)

          position = input_point.position
          return invalid_pick_refusal unless position

          result = session.apply_click(position)
          overlay&.mark_dirty(view: view)
          after_apply.call
          result
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
          clear_overlay(view)
          nil
        end

        def clear_overlay(view = nil)
          overlay&.clear(view: view)
        end
        # rubocop:enable Naming/MethodName

        private

        attr_reader :session, :input_point_factory, :overlay, :after_apply, :after_state_change

        def default_overlay_for(session)
          return nil unless session.respond_to?(:preview_context)

          BrushOverlayPreview.new(session: session)
        end

        def set_status(view, message)
          view.status_text = message if view.respond_to?(:status_text=)
          nil
        end

        def invalid_pick_refusal
          {
            outcome: 'refused',
            refusal: {
              code: 'terrain_brush_pick_invalid',
              message: 'Pick a valid terrain point before applying the brush.',
              details: { field: 'point' }
            }
          }
        end
      end
    end
  end
end
