# frozen_string_literal: true

require_relative 'brush_coordinate_converter'
require_relative '../regions/terrain_state_elevation_sampler'
require_relative '../storage/terrain_repository'

module SU_MCP
  module Terrain
    module UI
      # Transient read-only target-height brush overlay state for the active SketchUp tool.
      class BrushOverlayPreview
        DEFAULT_SEGMENT_COUNT = 32
        SUPPORT_COLOR = 'cyan'
        FALLOFF_COLOR = 'orange'
        SUPPORT_STATUS = 'Managed terrain brush target ready.'
        INVALID_STATUS = 'Pick a valid managed terrain point before applying the brush.'

        def initialize(
          session:,
          repository: TerrainRepository.new,
          coordinate_converter: BrushCoordinateConverter.new,
          extents_factory: nil,
          segment_count: DEFAULT_SEGMENT_COUNT
        )
          @session = session
          @repository = repository
          @coordinate_converter = coordinate_converter
          @extents_factory = extents_factory || method(:default_extents)
          @segment_count = segment_count
          @rings = []
          @dirty = true
          @cache = nil
          @last_view = nil
        end

        def update_hover(point, view:)
          @last_view = view
          context = session.preview_context(point)
          return invalid_hover(context, view: view, clear_visible: true) if refused?(context)

          state_result = loaded_state_for(context)
          unless state_result.fetch(:outcome) == 'loaded'
            return invalid_hover(state_result, view: view, clear_visible: true)
          end

          state = state_result.fetch(:state)
          sampler = TerrainStateElevationSampler.new(state)
          center = context.fetch(:center)
          return invalid_hover(out_of_bounds_refusal, view: view, clear_visible: true) unless
            sampler.inside_bounds?(center)

          center_z = sampler.elevation_at(center)
          if center_z.nil?
            return invalid_hover(out_of_bounds_refusal, view: view, clear_visible: true)
          end

          @rings = build_rings(context, sampler, center_z)
          set_status(view, SUPPORT_STATUS)
          invalidate(view)
          ready_result(context)
        end

        def draw(view)
          @last_view = view
          rings.each do |ring|
            configure_view(view, ring.fetch(:role))
            view.draw(draw_mode, ring.fetch(:points)) if view.respond_to?(:draw)
          end
          nil
        end

        def clear(view: nil)
          had_visible_overlay = rings.any?
          @rings = []
          invalidate(view) if had_visible_overlay
          { outcome: 'cleared' }
        end

        def mark_dirty(view:)
          @dirty = true
          invalidate(view)
          { outcome: 'dirty' }
        end

        def extents
          extents = extents_factory.call
          rings.each do |ring|
            ring.fetch(:points).each { |point| extents.add(point) if extents.respond_to?(:add) }
          end
          extents
        end

        def snapshot
          return { outcome: 'cleared' } if rings.empty?

          { outcome: 'ready', rings: rings }
        end

        private

        attr_reader :session, :repository, :coordinate_converter, :extents_factory,
                    :segment_count, :rings, :cache

        def loaded_state_for(context)
          owner = context.fetch(:owner)
          return cache.fetch(:result) if cache_valid_for?(owner)

          result = repository.load(owner)
          @dirty = false
          @cache = { owner_id: owner.object_id, state_key: state_key(result), result: result }
          result
        end

        def cache_valid_for?(owner)
          !@dirty &&
            cache &&
            cache.fetch(:owner_id) == owner.object_id &&
            cache.fetch(:result).fetch(:outcome) == 'loaded'
        end

        def state_key(result)
          return nil unless result.fetch(:outcome) == 'loaded'

          state = result.fetch(:state)
          [state.state_id, state.revision]
        end

        def build_rings(context, sampler, center_z)
          settings = context.fetch(:settings)
          center = context.fetch(:center)
          owner = context.fetch(:owner)
          support_radius = settings.fetch(:radius)
          blend_distance = settings.fetch(:blendDistance)
          [
            ring_for(:support, center, support_radius, center_z, sampler, owner),
            falloff_ring(center, support_radius, blend_distance, center_z, sampler, owner)
          ].compact
        end

        def falloff_ring(center, radius, blend_distance, center_z, sampler, owner)
          return nil unless blend_distance.positive?

          ring_for(:falloff, center, radius + blend_distance, center_z, sampler, owner)
        end

        def ring_for(role, center, radius, center_z, sampler, owner)
          {
            role: role,
            radius: radius,
            points: ring_points(center, radius, center_z, sampler, owner)
          }
        end

        def ring_points(center, radius, center_z, sampler, owner)
          (0..segment_count).map do |index|
            angle = (2.0 * Math::PI * index) / segment_count
            local = {
              'x' => center.fetch('x') + (Math.cos(angle) * radius),
              'y' => center.fetch('y') + (Math.sin(angle) * radius)
            }
            local['z'] = sampler.elevation_at(local) || center_z
            coordinate_converter.owner_world_point(local, owner: owner)
          end
        end

        def ready_result(_context)
          {
            outcome: 'ready',
            status: 'valid',
            rings: rings
          }
        end

        def invalid_hover(result, view:, clear_visible:)
          clear(view: view) if clear_visible
          set_status(view, invalid_message(result))
          {
            outcome: 'ready',
            status: 'invalid',
            rings: [],
            reason: invalid_reason(result)
          }
        end

        def invalid_message(result)
          result.dig(:refusal, :message) || INVALID_STATUS
        end

        def invalid_reason(result)
          result.dig(:refusal, :code) || result[:reason] || 'invalid_hover'
        end

        def out_of_bounds_refusal
          {
            outcome: 'refused',
            refusal: {
              code: 'terrain_brush_hover_out_of_bounds',
              message: 'Pick a point inside the selected managed terrain surface.'
            }
          }
        end

        def refused?(result)
          result.is_a?(Hash) && result[:outcome] == 'refused'
        end

        def set_status(view, message)
          view.status_text = message if view.respond_to?(:status_text=)
        end

        def invalidate(view)
          target_view = view || @last_view
          target_view.invalidate if target_view.respond_to?(:invalidate)
        end

        def configure_view(view, role)
          view.drawing_color = role == :support ? SUPPORT_COLOR : FALLOFF_COLOR if
            view.respond_to?(:drawing_color=)
          view.line_width = role == :support ? 3 : 2 if view.respond_to?(:line_width=)
          view.line_stipple = role == :support ? '' : '-' if view.respond_to?(:line_stipple=)
        end

        def draw_mode
          defined?(GL_LINE_LOOP) ? GL_LINE_LOOP : :line_loop
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
