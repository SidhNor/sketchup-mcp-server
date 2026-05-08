# frozen_string_literal: true

require_relative '../../semantic/length_converter'

module SU_MCP
  module Terrain
    module UI
      # Converts SketchUp click points to owner-local public-meter coordinates.
      class BrushCoordinateConverter
        def initialize(length_converter: nil)
          @length_converter = length_converter || Semantic::LengthConverter.new
        end

        def owner_local_xy(point, owner:)
          local = owner_local_point(point, owner)
          {
            'x' => length_converter.internal_to_public_meters(local.fetch(:x)),
            'y' => length_converter.internal_to_public_meters(local.fetch(:y))
          }
        end

        private

        attr_reader :length_converter

        def owner_local_point(point, owner)
          components = point_components(point)
          transformation = owner.respond_to?(:transformation) ? owner.transformation : nil
          return components unless transformation
          return fake_inverse_components(components, transformation) if
            transformation.respond_to?(:inverse_apply)
          return sketchup_inverse_components(point, transformation) if
            point.respond_to?(:transform) && transformation.respond_to?(:inverse)

          components
        end

        def point_components(point)
          {
            x: point.x.to_f,
            y: point.y.to_f,
            z: point.z.to_f
          }
        end

        def fake_inverse_components(components, transformation)
          x_value, y_value, z_value = transformation.inverse_apply(
            components.fetch(:x),
            components.fetch(:y),
            components.fetch(:z)
          )
          { x: x_value, y: y_value, z: z_value }
        end

        def sketchup_inverse_components(point, transformation)
          transformed = point.transform(transformation.inverse)
          point_components(transformed)
        end
      end
    end
  end
end
