# frozen_string_literal: true

require_relative 'planar_geometry_helper'
require_relative 'path_drape_builder'
require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-02 `path` geometry slice from a centerline and width.
    class PathBuilder
      include PlanarGeometryHelper

      def initialize(scene_properties: SceneProperties.new, drape_builder: PathDrapeBuilder.new)
        @scene_properties = scene_properties
        @drape_builder = drape_builder
      end

      def build(model:, params:, destination: nil)
        payload = params['definition'] || params.fetch('path')
        target_collection = destination || model.active_entities
        group = target_collection.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        build_geometry(group: group, payload: payload, params: params)
        group
      end

      private

      attr_reader :scene_properties, :drape_builder

      def build_geometry(group:, payload:, params:)
        if params.dig('hosting', 'mode') == 'surface_drape'
          build_surface_drape(group, payload, params)
        else
          build_planar_path(group, payload)
        end
      end

      def build_surface_drape(group, payload, params)
        drape_builder.build(
          group: group,
          payload: payload,
          host_target: params.dig('hosting', 'resolved_target')
        )
      end

      def build_planar_path(group, payload)
        face = add_planar_face(
          group: group,
          points: corridor_polygon(payload.fetch('centerline'), payload.fetch('width')),
          elevation: payload.fetch('elevation', 0.0)
        )
        face.pushpull(-payload['thickness'].to_f) if payload.key?('thickness')
      end
    end
  end
end
