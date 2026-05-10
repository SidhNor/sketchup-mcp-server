# frozen_string_literal: true

require_relative '../../semantic/length_converter'

module SU_MCP
  module Terrain
    module UI
      # Converts SketchUp click points to owner-local public-meter coordinates.
      class BrushCoordinateConverter
        Point = Struct.new(:x, :y, :z)

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

        def owner_local_xyz(point, owner:)
          local = owner_local_point(point, owner)
          {
            'x' => length_converter.internal_to_public_meters(local.fetch(:x)),
            'y' => length_converter.internal_to_public_meters(local.fetch(:y)),
            'z' => length_converter.internal_to_public_meters(local.fetch(:z))
          }
        end

        def owner_world_point(point, owner:)
          internal = public_meter_point_to_internal(point)
          components = owner_world_components(internal, owner)
          build_point(components)
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

        def owner_world_components(components, owner)
          transformation = owner.respond_to?(:transformation) ? owner.transformation : nil
          return components unless transformation
          if transformation.respond_to?(:apply)
            return fake_world_components(components, transformation)
          end

          sketchup_world_components(components, transformation)
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

        def public_meter_point_to_internal(point)
          {
            x: length_converter.public_meters_to_internal(point.fetch('x')),
            y: length_converter.public_meters_to_internal(point.fetch('y')),
            z: length_converter.public_meters_to_internal(point.fetch('z'))
          }
        end

        def fake_world_components(components, transformation)
          x_value, y_value, z_value = transformation.apply(
            components.fetch(:x),
            components.fetch(:y),
            components.fetch(:z)
          )
          { x: x_value, y: y_value, z: z_value }
        end

        def sketchup_world_components(components, transformation)
          point = build_point(components)
          return point_components(point.transform(transformation)) if point.respond_to?(:transform)

          components
        end

        def build_point(components)
          if usable_geom_point3d?
            return ::Geom::Point3d.new(
              components.fetch(:x),
              components.fetch(:y),
              components.fetch(:z)
            )
          end

          Point.new(components.fetch(:x), components.fetch(:y), components.fetch(:z))
        end

        def usable_geom_point3d?
          return false unless defined?(::Geom::Point3d)

          probe = ::Geom::Point3d.new(1.0, 2.0, 3.0)
          probe.respond_to?(:x) && !probe.x.nil?
        end
      end
    end
  end
end
