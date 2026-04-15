# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `tree_proxy` geometry slice from an accepted stepped proxy
    # silhouette while keeping the public payload parametric.
    # rubocop:disable Metrics/ClassLength
    class TreeProxyBuilder
      include PlanarGeometryHelper

      SEGMENTS = 12
      ROTATION_RADIANS = Math::PI / 6.0
      LOBE_PHASE_RADIANS = ROTATION_RADIANS
      MIN_LOBE_SCALE = 0.58

      TRUNK_ANCHOR_RATIO = 0.477409
      TRUNK_TOP_RATIO = 0.536117

      CANOPY_RING_DEFINITIONS = [
        { kind: :trunk_top },
        {
          kind: :canopy, z_ratio: 0.60,
          radius_ratio: 0.24, lobe_strength: 0.0, trunk_multiplier: 1.45
        },
        {
          kind: :canopy, z_ratio: 0.69,
          radius_ratio: 0.48, lobe_strength: 0.16, trunk_multiplier: 1.75
        },
        {
          kind: :canopy, z_ratio: 0.78,
          radius_ratio: 0.72, lobe_strength: 0.22, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.85,
          radius_ratio: 0.86, lobe_strength: 0.25, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.91,
          radius_ratio: 0.74, lobe_strength: 0.18, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.965,
          radius_ratio: 0.40, lobe_strength: 0.10, trunk_multiplier: 1.00
        }
      ].freeze

      def initialize(scene_properties: SceneProperties.new)
        @scene_properties = scene_properties
      end

      def build(model:, params:)
        payload = params.fetch('tree_proxy')
        wrapper_group = model.active_entities.add_group
        scene_properties.apply!(model: model, group: wrapper_group, params: params)

        proxy_mesh = wrapper_group.entities.add_group
        trunk_rings = build_trunk(group: proxy_mesh, payload: payload)
        build_canopy(group: proxy_mesh, payload: payload, trunk_rings: trunk_rings)

        wrapper_group
      end

      private

      attr_reader :scene_properties

      def build_trunk(group:, payload:)
        base_ring = trunk_ring(payload: payload, z_ratio: 0.0)
        anchor_ring = trunk_ring(payload: payload, z_ratio: TRUNK_ANCHOR_RATIO)
        top_ring = trunk_ring(payload: payload, z_ratio: TRUNK_TOP_RATIO)

        add_ring_face(group: group, ring: base_ring, reverse: true)
        connect_rings_with_quads(group: group, lower_ring: base_ring, upper_ring: anchor_ring)
        connect_rings_with_quads(group: group, lower_ring: anchor_ring, upper_ring: top_ring)
        add_ring_face(group: group, ring: top_ring)

        {
          anchor: anchor_ring,
          top: top_ring
        }
      end

      def build_canopy(group:, payload:, trunk_rings:)
        canopy_rings = CANOPY_RING_DEFINITIONS.map do |definition|
          canopy_ring(definition: definition, payload: payload, trunk_rings: trunk_rings)
        end

        canopy_rings.each_cons(2) do |lower_ring, upper_ring|
          connect_rings_with_quads(group: group, lower_ring: lower_ring, upper_ring: upper_ring)
        end

        connect_ring_to_apex(
          group: group,
          ring: canopy_rings.last,
          apex: apex_point(payload)
        )
      end

      def tree_position(payload)
        position = payload.fetch('position')
        {
          x: position.fetch('x').to_f,
          y: position.fetch('y').to_f,
          z: position.fetch('z', 0.0).to_f
        }
      end

      def tree_height(payload)
        payload.fetch('height').to_f
      end

      def canopy_diameter_y(payload)
        payload.fetch('canopyDiameterY', payload.fetch('canopyDiameterX')).to_f
      end

      def canopy_radius_x(payload)
        payload.fetch('canopyDiameterX').to_f / 2.0
      end

      def canopy_radius_y(payload)
        canopy_diameter_y(payload) / 2.0
      end

      def trunk_radius(payload)
        payload.fetch('trunkDiameter').to_f / 2.0
      end

      def trunk_ring(payload:, z_ratio:)
        build_ring(
          center: tree_position(payload),
          z_height: elevation_for(payload, z_ratio),
          radius_x: trunk_radius(payload),
          radius_y: trunk_radius(payload)
        )
      end

      # rubocop:disable Metrics/MethodLength
      def canopy_ring(definition:, payload:, trunk_rings:)
        return trunk_rings.fetch(:anchor) if definition.fetch(:kind) == :trunk_anchor
        return trunk_rings.fetch(:top) if definition.fetch(:kind) == :trunk_top

        build_ring(
          center: tree_position(payload),
          z_height: elevation_for(payload, definition.fetch(:z_ratio)),
          radius_x: radius_for_axis(
            canopy_radius: canopy_radius_x(payload),
            trunk_radius: trunk_radius(payload),
            definition: definition
          ),
          radius_y: radius_for_axis(
            canopy_radius: canopy_radius_y(payload),
            trunk_radius: trunk_radius(payload),
            definition: definition
          ),
          lobe_strength: definition.fetch(:lobe_strength)
        )
      end
      # rubocop:enable Metrics/MethodLength

      def radius_for_axis(canopy_radius:, trunk_radius:, definition:)
        [
          canopy_radius.to_f * definition.fetch(:radius_ratio),
          trunk_radius.to_f * definition.fetch(:trunk_multiplier)
        ].max.clamp(0.0, canopy_radius.to_f)
      end

      def elevation_for(payload, z_ratio)
        tree_position(payload)[:z] + (tree_height(payload) * z_ratio.to_f)
      end

      # rubocop:disable Metrics/AbcSize
      def build_ring(center:, z_height:, radius_x:, radius_y:, lobe_strength: 0.0)
        Array.new(SEGMENTS) do |index|
          angle = ROTATION_RADIANS + ((Math::PI * 2.0 * index) / SEGMENTS.to_f)
          radial_scale = lobed_radius_scale(angle, lobe_strength)
          [
            center.fetch(:x) + (Math.cos(angle) * radius_x.to_f * radial_scale),
            center.fetch(:y) + (Math.sin(angle) * radius_y.to_f * radial_scale),
            z_height.to_f
          ]
        end
      end
      # rubocop:enable Metrics/AbcSize

      def lobed_radius_scale(angle, lobe_strength)
        wave = Math.cos(3.0 * (angle - LOBE_PHASE_RADIANS))
        [1.0 + (lobe_strength.to_f * wave), MIN_LOBE_SCALE].max
      end

      def apex_point(payload)
        position = tree_position(payload)
        [position[:x], position[:y], position[:z] + tree_height(payload)]
      end

      def add_ring_face(group:, ring:, reverse: false)
        ordered_ring = reverse ? ring.reverse : ring
        group.entities.add_face(*ordered_ring)
      end

      def connect_rings_with_quads(group:, lower_ring:, upper_ring:)
        SEGMENTS.times do |index|
          next_index = (index + 1) % SEGMENTS
          add_ring_segment_face(
            group: group,
            lower_start: lower_ring[index],
            lower_finish: lower_ring[next_index],
            upper_finish: upper_ring[next_index],
            upper_start: upper_ring[index]
          )
        end
      end

      def connect_ring_to_apex(group:, ring:, apex:)
        SEGMENTS.times do |index|
          next_index = (index + 1) % SEGMENTS
          group.entities.add_face(ring[index], ring[next_index], apex)
        end
      end

      def add_ring_segment_face(group:, lower_start:, lower_finish:, upper_finish:, upper_start:)
        quad_points = [lower_start, lower_finish, upper_finish, upper_start]
        if planar_points?(quad_points)
          group.entities.add_face(*quad_points)
          return
        end

        group.entities.add_face(lower_start, lower_finish, upper_finish)
        group.entities.add_face(lower_start, upper_finish, upper_start)
      end

      def planar_points?(points, tolerance: 1e-6)
        return true if points.length <= 3

        origin = points[0]
        normal = triangle_normal(origin, points[1], points[2])
        return true if near_zero_vector?(normal)

        points[3..].all? do |point|
          vector = subtract_points(point, origin)
          dot_product(normal, vector).abs <= tolerance
        end
      end

      def triangle_normal(point_a, point_b, point_c)
        cross_product(
          subtract_points(point_b, point_a),
          subtract_points(point_c, point_a)
        )
      end

      def subtract_points(point, origin)
        [
          point[0].to_f - origin[0].to_f,
          point[1].to_f - origin[1].to_f,
          point[2].to_f - origin[2].to_f
        ]
      end

      # rubocop:disable Metrics/AbcSize
      def cross_product(left, right)
        [
          (left[1].to_f * right[2].to_f) - (left[2].to_f * right[1].to_f),
          (left[2].to_f * right[0].to_f) - (left[0].to_f * right[2].to_f),
          (left[0].to_f * right[1].to_f) - (left[1].to_f * right[0].to_f)
        ]
      end
      # rubocop:enable Metrics/AbcSize

      def near_zero_vector?(vector, tolerance: 1e-9)
        vector.all? { |value| value.abs <= tolerance }
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
