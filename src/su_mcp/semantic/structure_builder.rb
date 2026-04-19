# frozen_string_literal: true

require_relative 'scene_properties'

module SU_MCP
  module Semantic
    # Builds the SEM-01 `structure` geometry slice from a footprint.
    class StructureBuilder
      def initialize(scene_properties: SceneProperties.new)
        @scene_properties = scene_properties
      end

      def build(model:, params:, destination: nil)
        definition = params['definition'] || params
        structure_category = definition['structureCategory']
        raise ArgumentError, 'structureCategory is required' if structure_category.to_s.empty?

        target_collection = destination || model.active_entities
        group = target_collection.add_group
        scene_properties.apply!(model: model, group: group, params: params)
        points = footprint_points(definition.fetch('footprint'), definition.fetch('elevation', 0.0))
        face = group.entities.add_face(*points)
        normalize_horizontal_face!(face)
        face.pushpull(definition.fetch('height').to_f)

        group
      end

      private

      attr_reader :scene_properties

      def footprint_points(footprint, elevation)
        footprint.map do |point|
          [point[0].to_f, point[1].to_f, elevation.to_f]
        end
      end

      def normalize_horizontal_face!(face)
        return unless face.respond_to?(:normal) && face.normal.respond_to?(:z)
        return unless face.normal.z.to_f.negative? && face.respond_to?(:reverse!)

        face.reverse!
      end
    end
  end
end
