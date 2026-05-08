# frozen_string_literal: true

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
          after_apply: nil,
          after_state_change: nil
        )
          @session = session
          @input_point_factory = input_point_factory || -> { ::Sketchup::InputPoint.new }
          @after_apply = after_apply || -> {}
          @after_state_change = after_state_change || -> {}
        end

        def activate
          session.activate if session.respond_to?(:activate)
          after_state_change.call
          nil
        end

        def deactivate(_view)
          session.deactivate if session.respond_to?(:deactivate)
          after_state_change.call
          nil
        end

        def onMouseMove(_flags, _x, _y, view)
          set_status(view, STATUS_TEXT)
          nil
        end

        def onLButtonDown(_flags, x, y, view)
          input_point = input_point_factory.call
          picked = input_point.pick(view, x, y)
          return invalid_pick_refusal unless picked && input_point.respond_to?(:position)

          position = input_point.position
          return invalid_pick_refusal unless position

          result = session.apply_click(position)
          after_apply.call
          result
        end
        # rubocop:enable Naming/MethodName

        private

        attr_reader :session, :input_point_factory, :after_apply, :after_state_change

        def set_status(view, message)
          view.status_text = message if view.respond_to?(:status_text=)
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
