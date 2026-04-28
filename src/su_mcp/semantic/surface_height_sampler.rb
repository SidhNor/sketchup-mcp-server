# frozen_string_literal: true

require_relative '../scene_query/sample_surface_support'
require_relative '../scene_query/scene_query_serializer'

module SU_MCP
  module Semantic
    # Samples target surface height in SketchUp internal units for semantic
    # builders that need local terrain-aware geometry.
    class SurfaceHeightSampler
      def initialize(serializer: SceneQuerySerializer.new, support: nil)
        @serializer = serializer
        @support = support || SampleSurfaceSupport.new(serializer: serializer)
      end

      def prepare_context(entity)
        face_entries = sampleable_face_entries_for(entity)

        {
          entity: entity,
          face_entries: face_entries.map { |face_entry| prepare_face_entry(face_entry) }
        }
      end

      def sampleable_face_entries_for(entity)
        support.sampleable_faces_for(entity, visible_only: false, transform_chain: [])
      rescue RuntimeError
        []
      end

      def sample_z(entity:, x_value:, y_value:)
        sample_z_from_context(
          context: prepare_context(entity),
          x_value: x_value,
          y_value: y_value
        )
      end

      def sample_z_from_context(context:, x_value:, y_value:)
        face_entries = context.fetch(:face_entries)
        return nil if face_entries.empty?

        face_entries.filter_map do |face_entry|
          sampled_z_for_prepared_face(face_entry, x_value: x_value, y_value: y_value)
        end.max
      end

      private

      attr_reader :serializer, :support

      def prepare_face_entry(face_entry)
        face = face_entry[:face]
        transform_chain = face_entry[:transform_chain]
        surface = fake_surface_definition(face)

        return face_entry.merge(surface: surface) if surface

        world_points = transformed_face_points(face, transform_chain)
        face_entry.merge(
          world_plane: prepared_world_plane(face, transform_chain, world_points),
          world_xy_bounds: xy_bounds(world_points)
        )
      end

      def sampled_z_for_prepared_face(face_entry, x_value:, y_value:)
        surface = face_entry[:surface]
        return sampled_surface_z(surface, x_value, y_value, face_entry[:transform_chain]) if surface

        sampled_runtime_face_z(face_entry, x_value: x_value, y_value: y_value)
      end

      def fake_surface_definition(face)
        return nil unless face.respond_to?(:details)

        face.details[:sample_surface]
      end

      def sampled_surface_z(surface, x_value, y_value, transform_chain)
        sampled_fake_surface_z(
          surface,
          x_value: x_value,
          y_value: y_value,
          transform_chain: transform_chain
        )
      end

      def sampled_fake_surface_z(surface, x_value:, y_value:, transform_chain:)
        local_x, local_y, = inverse_transform_fake_components(
          x_value,
          y_value,
          0.0,
          transform_chain
        )
        x_range = surface[:x_range]
        y_range = surface[:y_range]
        return nil unless point_within_range?(local_x, x_range)
        return nil unless point_within_range?(local_y, y_range)

        local_z = surface[:z] +
                  ((surface[:slope_x] || 0.0) * (local_x - x_range.first)) +
                  ((surface[:slope_y] || 0.0) * (local_y - y_range.first))
        _, _, world_z = apply_fake_transform_components(local_x, local_y, local_z, transform_chain)
        world_z
      end

      def point_within_range?(value, range)
        value.between?(range.first, range.last)
      end

      def apply_fake_transform_components(x_value, y_value, z_value, transform_chain)
        transform_chain.reduce([x_value, y_value, z_value]) do |components, transformation|
          next components unless transformation.respond_to?(:apply)

          transformation.apply(*components)
        end
      end

      def inverse_transform_fake_components(x_value, y_value, z_value, transform_chain)
        transform_chain.reverse.reduce([x_value, y_value, z_value]) do |components, transformation|
          next components unless transformation.respond_to?(:inverse_apply)

          transformation.inverse_apply(*components)
        end
      end

      def sampled_runtime_face_z(face_entry, x_value:, y_value:)
        world_hit_point = runtime_hit_point(face_entry, x_value: x_value, y_value: y_value)
        return nil if world_hit_point.nil?

        world_hit_point.z.to_f
      end

      def runtime_hit_point(face_entry, x_value:, y_value:)
        face, transform_chain, world_plane, world_xy_bounds = prepared_geometry(face_entry)
        return nil if world_plane.nil?
        return nil unless point_within_bounds?(x_value, y_value, world_xy_bounds)

        world_hit_point = Geom.intersect_line_plane(
          world_vertical_line(x_value, y_value),
          world_plane
        )
        return nil if world_hit_point.nil?

        local_hit_point = world_to_local_point(world_hit_point, transform_chain)
        return nil unless point_on_face?(face, local_hit_point)

        world_hit_point
      rescue StandardError
        nil
      end

      def prepared_world_plane(face, transform_chain, world_points)
        return Geom.fit_plane_to_points(world_points) if world_points.length >= 3
        return face.plane if transform_chain.empty? && face.respond_to?(:plane)

        nil
      rescue StandardError
        nil
      end

      def transformed_face_plane(face, transform_chain)
        world_points = transformed_face_points(face, transform_chain)
        return Geom.fit_plane_to_points(world_points) if world_points.length >= 3
        return face.plane if transform_chain.empty? && face.respond_to?(:plane)

        nil
      rescue StandardError
        nil
      end

      def transformed_face_points(face, transform_chain)
        return [] unless face.respond_to?(:vertices)

        Array(face.vertices).filter_map do |vertex|
          next unless vertex.respond_to?(:position)

          local_point_to_world(vertex.position, transform_chain)
        end
      end

      def prepared_geometry(face_entry)
        [
          face_entry[:face],
          face_entry[:transform_chain],
          face_entry[:world_plane],
          face_entry[:world_xy_bounds]
        ]
      end

      def xy_bounds(points)
        return nil if points.empty?

        xs = points.map(&:x)
        ys = points.map(&:y)
        {
          min_x: xs.min.to_f,
          max_x: xs.max.to_f,
          min_y: ys.min.to_f,
          max_y: ys.max.to_f
        }
      end

      def point_within_bounds?(x_value, y_value, bounds)
        return true if bounds.nil?

        x_value.to_f.between?(bounds[:min_x], bounds[:max_x]) &&
          y_value.to_f.between?(bounds[:min_y], bounds[:max_y])
      end

      def world_vertical_line(x_value, y_value)
        [
          Geom::Point3d.new(x_value.to_f, y_value.to_f, 0.0),
          Geom::Vector3d.new(0, 0, 1)
        ]
      end

      def world_to_local_point(world_point, transform_chain)
        transform_chain.reverse.reduce(world_point) do |point, transformation|
          transform_point_inverse(point, transformation)
        end
      end

      def local_point_to_world(local_point, transform_chain)
        transform_chain.reduce(local_point) do |point, transformation|
          transform_point_forward(point, transformation)
        end
      end

      def transform_point_forward(point, transformation)
        return point unless transformation
        return point.transform(transformation) if point.respond_to?(:transform)

        point
      end

      def transform_point_inverse(point, transformation)
        return point unless transformation
        return point.transform(transformation.inverse) if point.respond_to?(:transform)

        point
      end

      def point_on_face?(face, point)
        return true unless face.respond_to?(:classify_point)

        classification = face.classify_point(point)
        [
          Sketchup::Face::PointInside,
          Sketchup::Face::PointOnEdge,
          Sketchup::Face::PointOnVertex
        ].include?(classification)
      rescue StandardError
        false
      end
    end
  end
end
