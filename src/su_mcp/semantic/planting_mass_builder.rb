# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `planting_mass` geometry slice from a boundary polygon.
    class PlantingMassBuilder
      include PlanarGeometryHelper

      def initialize(scene_properties: SceneProperties.new)
        @scene_properties = scene_properties
      end

      def build(model:, params:)
        payload = params.fetch('planting_mass')
        group = model.active_entities.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        face = add_planar_face(
          group: group,
          points: payload.fetch('boundary'),
          elevation: payload.fetch('elevation', 0.0)
        )
        face.pushpull(payload.fetch('averageHeight').to_f)
        group
      end

      private

      attr_reader :scene_properties
    end
  end
end
