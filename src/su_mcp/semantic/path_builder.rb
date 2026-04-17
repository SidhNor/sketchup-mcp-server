# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `path` geometry slice from a centerline and width.
    class PathBuilder
      include PlanarGeometryHelper

      def initialize(scene_properties: SceneProperties.new)
        @scene_properties = scene_properties
      end

      def build(model:, params:)
        payload = params['definition'] || params.fetch('path')
        group = model.active_entities.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        face = add_planar_face(
          group: group,
          points: corridor_polygon(payload.fetch('centerline'), payload.fetch('width')),
          elevation: payload.fetch('elevation', 0.0)
        )
        face.pushpull(-payload['thickness'].to_f) if payload.key?('thickness')
        group
      end

      private

      attr_reader :scene_properties
    end
  end
end
