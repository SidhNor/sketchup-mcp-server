# frozen_string_literal: true

require_relative 'scene_properties'
require_relative 'terrain_anchor_resolver'

module SU_MCP
  module Semantic
    # Builds the SEM-01 `structure` geometry slice from a footprint.
    class StructureBuilder
      def initialize(scene_properties: SceneProperties.new,
                     terrain_anchor_resolver: TerrainAnchorResolver.new)
        @scene_properties = scene_properties
        @terrain_anchor_resolver = terrain_anchor_resolver
      end

      def build(model:, params:, destination: nil)
        definition = params['definition'] || params
        structure_category = definition['structureCategory']
        raise ArgumentError, 'structureCategory is required' if structure_category.to_s.empty?

        elevation = base_elevation(definition, params)
        target_collection = destination || model.active_entities
        group = target_collection.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        points = footprint_points(definition.fetch('footprint'), elevation)
        face = group.entities.add_face(*points)
        normalize_horizontal_face!(face)
        face.pushpull(definition.fetch('height').to_f)

        group
      end

      private

      attr_reader :scene_properties, :terrain_anchor_resolver

      def base_elevation(definition, params)
        unless params.dig('hosting', 'mode') == 'terrain_anchored'
          return definition.fetch('elevation', 0.0)
        end

        terrain_anchor_resolver.resolve(
          host_target: params.dig('hosting', 'resolved_target'),
          anchor_xy: footprint_centroid(definition.fetch('footprint')),
          role: 'structure_centroid'
        )
      end

      def footprint_points(footprint, elevation)
        footprint.map do |point|
          [point[0].to_f, point[1].to_f, elevation.to_f]
        end
      end

      def footprint_centroid(footprint)
        points = footprint.map { |point| [point[0].to_f, point[1].to_f] }
        [
          points.sum(&:first) / points.length.to_f,
          points.sum(&:last) / points.length.to_f
        ]
      end

      def normalize_horizontal_face!(face)
        return unless face.respond_to?(:normal) && face.normal.respond_to?(:z)
        return unless face.normal.z.to_f.negative? && face.respond_to?(:reverse!)

        face.reverse!
      end
    end
  end
end
