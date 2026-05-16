# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../scene_query/sample_surface_support'
require_relative '../scene_query/scene_query_serializer'
require_relative '../scene_query/target_reference_resolver'
require_relative '../semantic/length_converter'

module SU_MCP
  module StagedAssets
    # Resolves one local surface frame for surface-aligned asset placement.
    # rubocop:disable Metrics/ClassLength
    class SurfaceFrameResolver
      NORMAL_TOLERANCE = 0.001
      Point = Struct.new(:x, :y, :z)

      def initialize(
        model_adapter: Adapters::ModelAdapter.new,
        serializer: SceneQuerySerializer.new,
        support: nil,
        target_resolver: nil,
        length_converter: Semantic::LengthConverter.new
      )
        @model_adapter = model_adapter
        @serializer = serializer
        @support = support || SampleSurfaceSupport.new(serializer: serializer)
        @target_resolver = target_resolver || TargetReferenceResolver.new(
          adapter: model_adapter,
          serializer: serializer
        )
        @length_converter = length_converter
      end

      def resolve(surface_reference:, sample_position:)
        target = resolve_target(surface_reference)
        return target if refused?(target)

        face_entries = sampleable_faces(target.fetch(:entity))
        return unsupported_surface_refusal if refused_face_entries?(face_entries)
        return unsampleable_surface_refusal if face_entries.empty?

        hits = candidate_hits(face_entries, sample_position)
        clusters = support.cluster_hits(hits)
        return surface_miss_refusal if clusters.empty?
        return ambiguous_surface_refusal if clusters.length > 1

        build_frame(clusters.first, sample_position)
      rescue TargetReferenceResolver::InvalidReference => e
        invalid_surface_reference_refusal(e)
      end

      private

      attr_reader :model_adapter, :serializer, :support, :target_resolver, :length_converter

      def resolve_target(surface_reference)
        resolution = target_resolver.resolve(
          surface_reference,
          field: 'placement.orientation.surfaceReference'
        )
        return unresolved_surface_refusal if resolution[:resolution] == 'none'
        return ambiguous_surface_refusal if resolution[:resolution] == 'ambiguous'

        resolution
      end

      def sampleable_faces(entity)
        support.sampleable_faces_for(entity, visible_only: true, transform_chain: [])
      rescue RuntimeError
        :unsupported
      end

      def refused_face_entries?(face_entries)
        face_entries == :unsupported
      end

      def candidate_hits(face_entries, sample_position)
        face_entries.filter_map do |face_entry|
          sample = sample_face(face_entry, sample_position)
          next unless sample

          sample.merge(face: face_entry.fetch(:face))
        end
      end

      def sample_face(face_entry, sample_position)
        fake_surface_sample(face_entry, sample_position) ||
          runtime_face_sample(face_entry, sample_position)
      end

      def fake_surface_sample(face_entry, sample_position)
        surface = fake_surface_definition(face_entry.fetch(:face))
        return nil unless surface

        local = local_fake_surface_sample(surface, sample_position, face_entry[:transform_chain])
        return nil unless local

        fake_surface_hit(surface, local, sample_position, face_entry[:transform_chain])
      end

      def local_fake_surface_sample(surface, sample_position, transform_chain)
        local_x, local_y, = inverse_fake_transform_components(
          sample_position[0],
          sample_position[1],
          0.0,
          transform_chain
        )
        return nil unless within_range?(local_x, surface.fetch(:x_range))
        return nil unless within_range?(local_y, surface.fetch(:y_range))

        [local_x, local_y]
      end

      def fake_surface_hit(surface, local, sample_position, transform_chain)
        local_x, local_y = local
        slope_x = surface.fetch(:slope_x, 0.0).to_f
        slope_y = surface.fetch(:slope_y, 0.0).to_f
        world_x, world_y, world_z = world_fake_surface_hit(
          surface,
          local_x,
          local_y,
          transform_chain
        )
        fake_surface_hit_payload(sample_position, world_x, world_y, world_z, slope_x, slope_y)
      end

      def world_fake_surface_hit(surface, local_x, local_y, transform_chain)
        slope_x = surface.fetch(:slope_x, 0.0).to_f
        slope_y = surface.fetch(:slope_y, 0.0).to_f
        local_z = surface.fetch(:z).to_f +
                  (slope_x * (local_x - surface.fetch(:x_range).first)) +
                  (slope_y * (local_y - surface.fetch(:y_range).first))
        apply_fake_transform_components(local_x, local_y, local_z, transform_chain)
      end

      def fake_surface_hit_payload(sample_position, world_x, world_y, world_z, slope_x, slope_y)
        {
          z: world_z,
          hitPoint: [sample_position[0].to_f, sample_position[1].to_f, world_z],
          origin: internal_point(world_x, world_y, world_z),
          normal: normalize([-slope_x, -slope_y, 1.0])
        }
      end

      def within_range?(value, range)
        value.between?(range.first, range.last)
      end

      def runtime_face_sample(face_entry, sample_position)
        face = face_entry.fetch(:face)
        plane = runtime_world_plane(face, face_entry[:transform_chain])
        return nil unless plane

        hit = runtime_plane_hit(plane, sample_position)
        return nil unless hit
        return nil unless runtime_point_on_face?(face, hit, face_entry[:transform_chain])

        runtime_hit_payload(hit, plane)
      end

      def runtime_world_plane(face, transform_chain)
        points = runtime_world_points(face, transform_chain)
        return Geom.fit_plane_to_points(points) if points.length >= 3
        return face.plane if Array(transform_chain).empty? && face.respond_to?(:plane)

        nil
      rescue StandardError
        nil
      end

      def runtime_world_points(face, transform_chain)
        return [] unless face.respond_to?(:vertices)

        Array(face.vertices).filter_map do |vertex|
          next unless vertex.respond_to?(:position)

          runtime_transform_point_forward(vertex.position, transform_chain)
        end
      end

      def runtime_plane_hit(plane, sample_position)
        a_value, b_value, c_value, d_value = plane
        return nil if c_value.to_f.abs <= NORMAL_TOLERANCE

        x_value = length_converter.public_meters_to_internal(sample_position[0])
        y_value = length_converter.public_meters_to_internal(sample_position[1])
        z_value = -((a_value.to_f * x_value) + (b_value.to_f * y_value) + d_value.to_f) /
                  c_value.to_f
        point_from_internal(x_value, y_value, z_value)
      end

      def runtime_point_on_face?(face, world_point, transform_chain)
        return true unless face.respond_to?(:classify_point)

        local_point = runtime_transform_point_inverse(world_point, transform_chain)
        [
          Sketchup::Face::PointInside,
          Sketchup::Face::PointOnEdge,
          Sketchup::Face::PointOnVertex
        ].include?(face.classify_point(local_point))
      rescue StandardError
        false
      end

      def runtime_hit_payload(hit, plane)
        {
          z: length_converter.internal_to_public_meters(hit.z),
          hitPoint: [
            length_converter.internal_to_public_meters(hit.x),
            length_converter.internal_to_public_meters(hit.y),
            length_converter.internal_to_public_meters(hit.z)
          ],
          origin: hit,
          normal: normalize(plane.first(3))
        }
      end

      def runtime_transform_point_forward(point, transform_chain)
        Array(transform_chain).reduce(point) do |current, transformation|
          next current unless current.respond_to?(:transform)

          current.transform(transformation)
        end
      end

      def runtime_transform_point_inverse(point, transform_chain)
        Array(transform_chain).reverse.reduce(point) do |current, transformation|
          unless current.respond_to?(:transform) && transformation.respond_to?(:inverse)
            next current
          end

          current.transform(transformation.inverse)
        end
      end

      def fake_surface_definition(face)
        return nil unless face.respond_to?(:details)

        face.details[:sample_surface]
      end

      def build_frame(hit_cluster, _sample_position)
        return ambiguous_surface_refusal unless normals_equivalent?(hit_cluster)

        hit = hit_cluster.first
        up_axis = upward(hit.fetch(:normal))
        x_axis = projected_model_x(up_axis)
        return degenerate_frame_refusal if x_axis.nil?

        y_axis = normalize(cross(up_axis, x_axis))
        ready(
          origin: hit.fetch(:origin),
          x_axis: x_axis,
          y_axis: y_axis,
          up_axis: up_axis,
          evidence: {
            hitPoint: hit.fetch(:hitPoint),
            slopeDegrees: slope_degrees(up_axis)
          }
        )
      end

      def normals_equivalent?(hit_cluster)
        normal = upward(hit_cluster.first.fetch(:normal))
        hit_cluster.all? do |hit|
          distance(upward(hit.fetch(:normal)), normal) <= NORMAL_TOLERANCE
        end
      end

      def projected_model_x(up_axis)
        x_axis = cross([0.0, 1.0, 0.0], up_axis)
        return nil if magnitude(x_axis) <= NORMAL_TOLERANCE

        normalize(x_axis)
      end

      def slope_degrees(up_axis)
        z_value = up_axis[2].clamp(-1.0, 1.0)
        (Math.acos(z_value) * 180.0 / Math::PI).round(9)
      end

      def internal_point(x_value, y_value, z_value)
        point_from_internal(
          length_converter.public_meters_to_internal(x_value),
          length_converter.public_meters_to_internal(y_value),
          length_converter.public_meters_to_internal(z_value)
        )
      end

      def point_from_internal(x_value, y_value, z_value)
        point = Geom::Point3d.new(x_value, y_value, z_value)
        return point if point.respond_to?(:x) && !point.x.nil?

        Point.new(x_value, y_value, z_value)
      end

      def apply_fake_transform_components(x_value, y_value, z_value, transform_chain)
        Array(transform_chain).reduce([x_value, y_value, z_value]) do |components, transformation|
          next components unless transformation.respond_to?(:apply)

          transformation.apply(*components)
        end
      end

      def inverse_fake_transform_components(x_value, y_value, z_value, transform_chain)
        Array(transform_chain).reverse.reduce([x_value, y_value, z_value]) do |components,
          transformation|
          next components unless transformation.respond_to?(:inverse_apply)

          transformation.inverse_apply(*components)
        end
      end

      def ready(frame)
        { outcome: 'ready', frame: frame }
      end

      def refused?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end

      def invalid_surface_reference_refusal(error)
        refusal(
          code: error.code,
          message: error.message,
          details: error.details
        )
      end

      def unsupported_surface_refusal
        refusal(
          code: 'unsupported_surface_reference',
          message: 'Surface reference must resolve to a face, group, or component with ' \
                   'sampleable faces.',
          details: { field: 'placement.orientation.surfaceReference' }
        )
      end

      def unsampleable_surface_refusal
        refusal(
          code: 'surface_not_sampleable',
          message: 'Surface reference resolves to no sampleable face geometry.',
          details: { field: 'placement.orientation.surfaceReference' }
        )
      end

      def unresolved_surface_refusal
        refusal(
          code: 'surface_reference_not_found',
          message: 'placement.orientation.surfaceReference resolves to no entity.',
          details: { field: 'placement.orientation.surfaceReference' }
        )
      end

      def surface_miss_refusal
        refusal(
          code: 'surface_frame_miss',
          message: 'Referenced surface has no hit at placement.position XY.',
          details: { field: 'placement.orientation.surfaceReference' }
        )
      end

      def ambiguous_surface_refusal
        refusal(
          code: 'ambiguous_surface_frame',
          message: 'Referenced surface does not produce one unambiguous local placement frame.',
          details: { field: 'placement.orientation.surfaceReference' }
        )
      end

      def degenerate_frame_refusal
        refusal(
          code: 'degenerate_surface_frame',
          message: 'Referenced surface produced a degenerate local placement frame.',
          details: { field: 'placement.orientation.surfaceReference' }
        )
      end

      def refusal(code:, message:, details:)
        {
          outcome: 'refused',
          refusal: {
            code: code,
            message: message,
            details: details
          }
        }
      end

      def upward(vector)
        normalized = normalize(vector)
        normalized[2].negative? ? normalized.map(&:-@) : normalized
      end

      def normalize(vector)
        length = magnitude(vector)
        return [0.0, 0.0, 1.0] if length.zero?

        vector.map { |component| component.to_f / length }
      end

      def magnitude(vector)
        Math.sqrt(vector.sum { |component| component.to_f * component.to_f })
      end

      def distance(first, second)
        magnitude(first.zip(second).map { |left, right| left - right })
      end

      def cross(first, second)
        [
          (first[1] * second[2]) - (first[2] * second[1]),
          (first[2] * second[0]) - (first[0] * second[2]),
          (first[0] * second[1]) - (first[1] * second[0])
        ]
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
