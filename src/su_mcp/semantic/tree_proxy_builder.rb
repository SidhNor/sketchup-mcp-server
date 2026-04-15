# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `tree_proxy` geometry slice as a deterministic clustered proxy.
    class TreeProxyBuilder
      include PlanarGeometryHelper

      TRUNK_HEIGHT_RATIO = 0.35
      PRIMARY_CANOPY_HEIGHT_RATIO = 0.3
      SECONDARY_CANOPY_HEIGHT_RATIO = 0.22
      PRIMARY_CANOPY_BASE_RATIO = 0.42
      SECONDARY_CANOPY_BASE_RATIO = 0.5
      LOBE_RADIUS_SCALE = 0.58
      CANOPY_LOBE_OFFSETS = [
        [0.24, 0.12],
        [-0.2, 0.16]
      ].freeze

      def initialize(scene_properties: SceneProperties.new)
        @scene_properties = scene_properties
      end

      def build(model:, params:)
        payload = params.fetch('tree_proxy')
        group = model.active_entities.add_group
        scene_properties.apply!(model: model, group: group, params: params)

        build_trunk(group: group, payload: payload)
        build_primary_canopy(group: group, payload: payload)
        build_secondary_canopies(group: group, payload: payload)

        group
      end

      private

      attr_reader :scene_properties

      def build_trunk(group:, payload:)
        position = tree_position(payload)
        trunk = group.entities.add_group
        face = add_planar_face(
          group: trunk,
          points: square_points(
            center_x: position[:x],
            center_y: position[:y],
            size: payload.fetch('trunkDiameter')
          ),
          elevation: position[:z]
        )
        face.pushpull(tree_height(payload) * TRUNK_HEIGHT_RATIO)
      end

      def build_primary_canopy(group:, payload:)
        position = tree_position(payload)
        face = add_planar_face(
          group: group.entities.add_group,
          points: ellipse_points(
            center_x: position[:x],
            center_y: position[:y],
            radius_x: payload.fetch('canopyDiameterX').to_f / 2.0,
            radius_y: canopy_diameter_y(payload) / 2.0
          ),
          elevation: canopy_base_elevation(payload, PRIMARY_CANOPY_BASE_RATIO)
        )
        face.pushpull(tree_height(payload) * PRIMARY_CANOPY_HEIGHT_RATIO)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def build_secondary_canopies(group:, payload:)
        position = tree_position(payload)
        canopy_x = payload.fetch('canopyDiameterX').to_f
        canopy_y = canopy_diameter_y(payload)

        CANOPY_LOBE_OFFSETS.each do |offset_x_ratio, offset_y_ratio|
          face = add_planar_face(
            group: group.entities.add_group,
            points: ellipse_points(
              center_x: position[:x] + (canopy_x * offset_x_ratio),
              center_y: position[:y] + (canopy_y * offset_y_ratio),
              radius_x: (canopy_x / 2.0) * LOBE_RADIUS_SCALE,
              radius_y: (canopy_y / 2.0) * LOBE_RADIUS_SCALE
            ),
            elevation: canopy_base_elevation(payload, SECONDARY_CANOPY_BASE_RATIO)
          )
          face.pushpull(tree_height(payload) * SECONDARY_CANOPY_HEIGHT_RATIO)
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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

      def canopy_base_elevation(payload, base_ratio)
        tree_position(payload)[:z] + (tree_height(payload) * base_ratio)
      end
    end
  end
end
