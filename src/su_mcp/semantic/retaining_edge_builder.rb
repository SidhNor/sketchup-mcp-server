# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `retaining_edge` geometry slice from a polyline.
    class RetainingEdgeBuilder
      include PlanarGeometryHelper

      def initialize(scene_properties: SceneProperties.new)
        @scene_properties = scene_properties
      end

      def build(model:, params:)
        payload = params.fetch('retaining_edge')
        group = model.active_entities.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        face = add_planar_face(
          group: group,
          points: corridor_polygon(payload.fetch('polyline'), payload.fetch('thickness')),
          elevation: payload.fetch('elevation', 0.0)
        )
        face.pushpull(payload.fetch('height').to_f)
        group
      end

      private

      attr_reader :scene_properties
    end
  end
end
