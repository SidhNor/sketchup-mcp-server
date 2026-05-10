# frozen_string_literal: true

require_relative 'brush_coordinate_converter'

module SU_MCP
  module Terrain
    module UI
      # Transient corridor transition viewport preview.
      class CorridorOverlayPreview # rubocop:disable Metrics/ClassLength
        DEFAULT_SEGMENT_COUNT = 12
        ELEVATION_PROJECTION_TOLERANCE = 0.001

        def initialize(
          session:,
          coordinate_converter: BrushCoordinateConverter.new,
          extents_factory: nil,
          segment_count: DEFAULT_SEGMENT_COUNT
        )
          @session = session
          @coordinate_converter = coordinate_converter
          @extents_factory = extents_factory || method(:default_extents)
          @segment_count = segment_count.to_i.clamp(4, 16)
          @drawables = []
          @last_view = nil
        end

        def update(view:)
          @last_view = view
          context = session.preview_context
          return invalid_preview(context, view: view) if refused?(context)

          @drawables = build_drawables(context)
          invalidate(view)
          { outcome: 'ready', drawables: drawables }
        end

        def update_hover(point, view:)
          @last_view = view
          context = session_preview_context(point)
          return invalid_preview(context, view: view) if refused?(context)

          @drawables = build_drawables(context)
          invalidate(view)
          { outcome: 'ready', drawables: drawables }
        end

        def draw(view)
          @last_view = view
          drawables.each do |drawable|
            configure_view(view, drawable.fetch(:role))
            draw_drawable(view, drawable)
          end
          nil
        end

        def clear(view: nil)
          had_visible_overlay = drawables.any?
          @drawables = []
          invalidate(view) if had_visible_overlay
          { outcome: 'cleared' }
        end

        def snapshot
          return { outcome: 'cleared' } if drawables.empty?

          { outcome: 'ready', drawables: drawables }
        end

        def extents
          extents = extents_factory.call
          drawables.each do |drawable|
            next unless extents.respond_to?(:add)

            drawable_points(drawable).each { |point| extents.add(point) }
          end
          extents
        end

        private

        attr_reader :session, :coordinate_converter, :extents_factory, :segment_count, :drawables

        def session_preview_context(point)
          preview_method = session.method(:preview_context)
          return session.preview_context(point) if accepts_preview_point?(preview_method)

          session.preview_context
        end

        def accepts_preview_point?(preview_method)
          preview_method.arity.positive? || preview_method.arity.negative?
        end

        def build_drawables(context)
          owner = context.fetch(:owner)
          corridor = context.fetch(:corridor)
          start_control = corridor.fetch(:startControl)
          end_control = corridor.fetch(:endControl)
          start_point = world_point(start_control, owner)
          end_point = world_point(end_control, owner)
          band = band_points(start_control, end_control, corridor)
          shoulders = shoulder_points(start_control, end_control, corridor)
          caps = cap_points(start_control, end_control, corridor)
          projections = projection_points(start_control, end_control, corridor, owner)
          surfaces = surface_drawables(band, corridor, owner)

          surfaces + [
            { role: :start_marker, point: start_point },
            { role: :end_marker, point: end_point },
            { role: :centerline, points: [start_point, end_point] },
            { role: :width_band, points: band.map { |local| world_point(local, owner) } },
            {
              role: :side_blend_shoulder,
              points: shoulders.map { |local| world_point(local, owner) }
            },
            { role: :endpoint_cap, points: caps.map { |local| world_point(local, owner) } },
            { role: :elevation_projection, points: projections }
          ]
        end

        def band_points(start_control, end_control, corridor)
          offset = perpendicular_offset(
            start_control,
            end_control,
            corridor.fetch(:width).to_f / 2.0
          )
          rectangle_points(start_control, end_control, offset)
        end

        def shoulder_points(start_control, end_control, corridor)
          side_blend = corridor.fetch(:sideBlend, {})
          shoulder = side_blend.fetch(:distance, 0.0).to_f
          return [] unless shoulder.positive?

          inner = corridor.fetch(:width).to_f / 2.0
          outer_offset = perpendicular_offset(start_control, end_control, inner + shoulder)
          rectangle_points(start_control, end_control, outer_offset)
        end

        def cap_points(start_control, end_control, corridor)
          offset = perpendicular_offset(
            start_control,
            end_control,
            corridor.fetch(:width).to_f / 2.0
          )
          [
            offset_point(start_control, offset),
            offset_point(start_control, negate_offset(offset)),
            offset_point(end_control, offset),
            offset_point(end_control, negate_offset(offset))
          ]
        end

        def projection_points(start_control, end_control, corridor, owner)
          sampled = corridor.fetch(:sampledElevations, {})
          [
            projection_pair(start_control, sampled[:start], owner),
            projection_pair(end_control, sampled[:end], owner)
          ].flatten.compact
        end

        def projection_pair(control, sampled_elevation, owner)
          return [] unless sampled_elevation.is_a?(Numeric)
          return [] if (control.fetch(:elevation).to_f - sampled_elevation.to_f).abs <
                       ELEVATION_PROJECTION_TOLERANCE

          [
            world_point(control.merge(elevation: sampled_elevation.to_f), owner),
            world_point(control, owner)
          ]
        end

        def surface_drawables(band, corridor, owner)
          sampled = corridor.fetch(:sampledElevations, {})
          top = band.first(4)
          surfaces = [
            { role: :corridor_surface, points: top.map { |local| world_point(local, owner) } }
          ]
          append_side_surface(surfaces, side_surface_points(top, sampled, :left), owner)
          append_side_surface(surfaces, side_surface_points(top, sampled, :right), owner)
          surfaces
        end

        def append_side_surface(surfaces, points, owner)
          return unless points

          surfaces << {
            role: :corridor_side_surface,
            points: points.map { |local| world_point(local, owner) }
          }
        end

        def side_surface_points(top, sampled, side)
          return nil unless sampled[:start].is_a?(Numeric) && sampled[:end].is_a?(Numeric)

          start_top, end_top = side == :left ? top.values_at(0, 1) : top.values_at(3, 2)
          [
            start_top,
            end_top,
            end_top.merge(elevation: sampled.fetch(:end).to_f),
            start_top.merge(elevation: sampled.fetch(:start).to_f)
          ]
        end

        def rectangle_points(start_control, end_control, offset)
          [
            offset_point(start_control, offset),
            offset_point(end_control, offset),
            offset_point(end_control, negate_offset(offset)),
            offset_point(start_control, negate_offset(offset)),
            offset_point(start_control, offset)
          ]
        end

        def perpendicular_offset(start_control, end_control, distance)
          dx = end_control.fetch(:x).to_f - start_control.fetch(:x).to_f
          dy = end_control.fetch(:y).to_f - start_control.fetch(:y).to_f
          length = Math.sqrt((dx * dx) + (dy * dy))
          return { x: 0.0, y: 0.0 } unless length.positive?

          { x: (-dy / length) * distance, y: (dx / length) * distance }
        end

        def offset_point(control, offset)
          control.merge(
            x: control.fetch(:x).to_f + offset.fetch(:x),
            y: control.fetch(:y).to_f + offset.fetch(:y)
          )
        end

        def negate_offset(offset)
          { x: -offset.fetch(:x), y: -offset.fetch(:y) }
        end

        def world_point(control, owner)
          coordinate_converter.owner_world_point(
            {
              'x' => control.fetch(:x),
              'y' => control.fetch(:y),
              'z' => control.fetch(:elevation)
            },
            owner: owner
          )
        end

        def drawable_points(drawable)
          return [drawable.fetch(:point)] if drawable.key?(:point)

          drawable.fetch(:points, [])
        end

        def draw_drawable(view, drawable)
          role = drawable.fetch(:role)
          return draw_marker(view, drawable.fetch(:point), role) if marker_role?(role)

          points = drawable_points(drawable)
          return unless view.respond_to?(:draw) && points.any?

          view.draw(draw_mode(role), points)
        end

        def draw_marker(view, point, role)
          if view.respond_to?(:draw_points)
            view.draw_points([point], 12, marker_style, drawing_color(role))
            return
          end

          view.draw(draw_mode(:marker), marker_cross_points(point)) if view.respond_to?(:draw)
        end

        def marker_cross_points(point)
          size = 0.35
          [
            build_point(x: point.x - size, y: point.y, z: point.z),
            build_point(x: point.x + size, y: point.y, z: point.z),
            build_point(x: point.x, y: point.y - size, z: point.z),
            build_point(x: point.x, y: point.y + size, z: point.z)
          ]
        end

        def invalid_preview(_context, view:)
          clear(view: view)
          { outcome: 'ready', status: 'invalid', drawables: [] }
        end

        def refused?(result)
          result.is_a?(Hash) && result[:outcome] == 'refused'
        end

        def invalidate(view)
          target = view || @last_view
          target.invalidate if target.respond_to?(:invalidate)
        end

        def configure_view(view, role)
          return unless view

          view.drawing_color = drawing_color(role) if view.respond_to?(:drawing_color=)
          view.line_width = %i[start_marker end_marker centerline].include?(role) ? 4 : 2 if
            view.respond_to?(:line_width=)
          view.line_stipple = role == :elevation_projection ? '.' : '' if
            view.respond_to?(:line_stipple=)
        end

        def drawing_color(role)
          case role
          when :corridor_surface
            color_value('cyan', 0, 220, 255, alpha: 45)
          when :corridor_side_surface
            color_value('orange', 255, 140, 0, alpha: 70)
          when :width_band, :side_blend_shoulder
            color_value('orange', 255, 140, 0)
          else
            color_value('cyan', 0, 220, 255)
          end
        end

        def color_value(fallback, red, green, blue, alpha: 255)
          if defined?(::Sketchup::Color)
            color = ::Sketchup::Color.new(red, green, blue)
            color.alpha = alpha if color.respond_to?(:alpha=)
            return color
          end

          fallback
        end

        def marker_role?(role)
          %i[start_marker end_marker].include?(role)
        end

        def draw_mode(role)
          case role
          when :corridor_surface, :corridor_side_surface
            defined?(GL_QUADS) ? GL_QUADS : :quads
          when :width_band, :side_blend_shoulder
            defined?(GL_LINE_STRIP) ? GL_LINE_STRIP : :line_strip
          else
            defined?(GL_LINES) ? GL_LINES : :lines
          end
        end

        def marker_style
          defined?(GL_POINT) ? GL_POINT : 2
        end

        def build_point(x:, y:, z:)
          return ::Geom::Point3d.new(x, y, z) if defined?(::Geom::Point3d)

          BrushCoordinateConverter::Point.new(x, y, z)
        end

        def default_extents
          return ::Geom::BoundingBox.new if defined?(::Geom::BoundingBox)

          NullExtents.new
        end

        # Minimal extents fallback for non-SketchUp unit tests.
        class NullExtents
          def add(_point); end
        end
      end
    end
  end
end
