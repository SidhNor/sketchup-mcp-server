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

      # Ratios extracted from the accepted 2026-04-15 baseline tree proxy.
      CANOPY_BASE_RATIO = 0.450482
      TRUNK_ANCHOR_RATIO = 0.477409
      TRUNK_TOP_RATIO = 0.536117

      CANOPY_RING_DEFINITIONS = [
        {
          kind: :canopy, z_ratio: CANOPY_BASE_RATIO,
          radius_ratio: 0.42, lobe_strength: 0.10, trunk_multiplier: 1.45
        },
        {
          kind: :canopy, z_ratio: 0.463882,
          radius_ratio: 0.24, lobe_strength: 0.05, trunk_multiplier: 1.30
        },
        { kind: :trunk_anchor },
        {
          kind: :canopy, z_ratio: 0.490624,
          radius_ratio: 0.20, lobe_strength: 0.05, trunk_multiplier: 1.05
        },
        {
          kind: :canopy, z_ratio: 0.502622,
          radius_ratio: 0.22, lobe_strength: 0.05, trunk_multiplier: 1.10
        },
        { kind: :trunk_top },
        {
          kind: :canopy, z_ratio: 0.551048,
          radius_ratio: 0.25, lobe_strength: 0.06, trunk_multiplier: 1.18
        },
        {
          kind: :canopy, z_ratio: 0.564857,
          radius_ratio: 0.29, lobe_strength: 0.07, trunk_multiplier: 1.22
        },
        {
          kind: :canopy, z_ratio: 0.571153,
          radius_ratio: 0.33, lobe_strength: 0.08, trunk_multiplier: 1.25
        },
        {
          kind: :canopy, z_ratio: 0.651518,
          radius_ratio: 0.52, lobe_strength: 0.12, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.665052,
          radius_ratio: 0.59, lobe_strength: 0.14, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.672419,
          radius_ratio: 0.63, lobe_strength: 0.15, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.751731,
          radius_ratio: 0.80, lobe_strength: 0.18, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.758437,
          radius_ratio: 0.84, lobe_strength: 0.19, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.791372,
          radius_ratio: 0.92, lobe_strength: 0.17, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.825405,
          radius_ratio: 1.00, lobe_strength: 0.16, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.852271,
          radius_ratio: 0.93, lobe_strength: 0.13, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.898963,
          radius_ratio: 0.70, lobe_strength: 0.09, trunk_multiplier: 1.00
        },
        {
          kind: :canopy, z_ratio: 0.973453,
          radius_ratio: 0.34, lobe_strength: 0.04, trunk_multiplier: 1.00
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
        normalized_wave = (Math.cos((angle * 3.0) - ROTATION_RADIANS) + 1.0) / 2.0
        1.0 - lobe_strength.to_f + (lobe_strength.to_f * normalized_wave)
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
          group.entities.add_face(
            lower_ring[index],
            lower_ring[next_index],
            upper_ring[next_index],
            upper_ring[index]
          )
        end
      end

      def connect_ring_to_apex(group:, ring:, apex:)
        SEGMENTS.times do |index|
          next_index = (index + 1) % SEGMENTS
          group.entities.add_face(ring[index], ring[next_index], apex)
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
