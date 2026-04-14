# frozen_string_literal: true

module SU_MCP
  # Ruby-owned explicit target resolution and compact surface sampling.
  # rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/ParameterLists
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/BlockLength
  class SampleSurfaceQuery
    TARGET_REFERENCE_KEYS = %w[sourceElementId persistentId entityId].freeze
    SAMPLE_Z_CLUSTER_TOLERANCE_METERS = 0.001

    def initialize(serializer:)
      @serializer = serializer
    end

    def execute(entities:, params:)
      target_query = normalized_target_reference(params['target'])
      sample_points = normalized_sample_points(params['samplePoints'])
      ignore_entities = resolve_ignore_entities(entities, params['ignoreTargets'])
      target_entity = resolve_entity!(
        entities,
        target_query,
        none_message: 'Target reference resolves to no entity',
        ambiguous_message: 'Target reference resolves ambiguously'
      )
      target_face_entries = sampleable_faces_for(target_entity, visible_only: visible_only?(params))
      raise 'Target resolves to no sampleable face geometry' if target_face_entries.empty?

      {
        success: true,
        results: sample_points.map do |sample_point|
          sample_point_result(
            sample_point: sample_point,
            target_face_entries: target_face_entries,
            scene_entities: entities,
            target_entity: target_entity,
            ignore_entities: ignore_entities,
            visible_only: visible_only?(params)
          )
        end
      }
    end

    private

    attr_reader :serializer

    def normalized_target_reference(raw_target)
      target = normalize_values(raw_target)
      raise 'Target reference with at least one identifier is required' if target.empty?

      unsupported_keys = target.keys - TARGET_REFERENCE_KEYS
      return target if unsupported_keys.empty?

      raise "Unsupported target reference criterion: #{unsupported_keys.first}"
    end

    def normalized_sample_points(raw_sample_points)
      sample_points = Array(raw_sample_points).map do |sample_point|
        normalized_sample_point(sample_point)
      end
      raise 'At least one sample point is required' if sample_points.empty?

      sample_points
    end

    def normalized_sample_point(sample_point)
      point = sample_point || {}
      x_value = extract_sample_coordinate(point, 'x')
      y_value = extract_sample_coordinate(point, 'y')

      {
        x: numeric_value(x_value),
        y: numeric_value(y_value)
      }
    end

    def numeric_value(value)
      Float(value)
    rescue ArgumentError, TypeError
      raise 'Sample point coordinates must be numeric'
    end

    def extract_sample_coordinate(point, key)
      return point[key] if point.key?(key)
      return point[key.to_sym] if point.key?(key.to_sym)

      raise "Sample point #{key} is required"
    end

    def resolve_ignore_entities(entities, raw_ignore_targets)
      Array(raw_ignore_targets).map do |ignore_target|
        query = normalized_target_reference(ignore_target)
        resolve_entity!(
          entities,
          query,
          none_message: 'Ignore target reference resolves to no entity',
          ambiguous_message: 'Ignore target reference resolves ambiguously'
        )
      end
    end

    def resolve_entity!(entities, query, none_message:, ambiguous_message:)
      matches = entities.select { |entity| target_reference_matches?(entity, query) }
      raise none_message if matches.empty?
      raise ambiguous_message if matches.length > 1

      matches.first
    end

    def target_reference_matches?(entity, query)
      summary = serializer.serialize_target_match(entity)
      query.all? { |key, value| summary[key.to_sym] == value }
    end

    def visible_only?(params)
      params['visibleOnly'] != false
    end

    def sampleable_faces_for(entity, visible_only:, transform_chain: [])
      type = serializer.entity_type_key(entity)
      return [] unless visible_entity?(entity, visible_only)

      case type
      when 'face'
        [{ face: entity, transform_chain: transform_chain }]
      when 'group'
        collect_faces(
          entity.entities,
          visible_only: visible_only,
          transform_chain: append_transform(transform_chain, entity)
        )
      when 'componentinstance'
        collect_faces(
          entity.definition.entities,
          visible_only: visible_only,
          transform_chain: append_transform(transform_chain, entity)
        )
      else
        raise "Target type #{type} is not supported by sample_surface_z"
      end
    end

    def collect_faces(entities, visible_only:, transform_chain:)
      Array(entities).flat_map do |entity|
        next [] unless entity

        type = serializer.entity_type_key(entity)
        case type
        when 'face'
          if visible_entity?(entity, visible_only)
            [{ face: entity, transform_chain: transform_chain }]
          else
            []
          end
        when 'group'
          next [] unless visible_entity?(entity, visible_only)

          collect_faces(
            entity.entities,
            visible_only: visible_only,
            transform_chain: append_transform(transform_chain, entity)
          )
        when 'componentinstance'
          next [] unless visible_entity?(entity, visible_only)

          collect_faces(
            entity.definition.entities,
            visible_only: visible_only,
            transform_chain: append_transform(transform_chain, entity)
          )
        else
          []
        end
      end
    end

    def visible_entity?(entity, visible_only)
      !visible_only || !(entity.respond_to?(:hidden?) && entity.hidden?)
    end

    def sample_point_result(sample_point:, target_face_entries:, scene_entities:, target_entity:,
                            ignore_entities:, visible_only:)
      target_hits = candidate_hits(target_face_entries, sample_point)
      if visible_only
        blocking_faces = blocking_faces_for(
          scene_entities,
          target_entity: target_entity,
          ignore_entities: ignore_entities
        )
        target_hits.reject! do |hit|
          blocked_by_visible_geometry?(sample_point, hit[:z], blocking_faces)
        end
      end

      clusters = cluster_hits(target_hits)
      return miss_result(sample_point) if clusters.empty?
      return ambiguous_result(sample_point) if clusters.length > 1

      hit = clusters.first.first
      hit_result(sample_point, hit[:z])
    end

    def candidate_hits(face_entries, sample_point)
      face_entries.filter_map do |face_entry|
        sample_z = sampled_z_for_face(face_entry, sample_point)
        next if sample_z.nil?

        { face: face_entry[:face], z: sample_z }
      end
    end

    def sampled_z_for_face(face_entry, sample_point)
      face = face_entry[:face]
      transform_chain = face_entry[:transform_chain]
      surface = fake_surface_definition(face)
      return sampled_fake_surface_z(surface, sample_point, transform_chain) if surface

      sampled_runtime_face_z(face, sample_point, transform_chain)
    end

    def fake_surface_definition(face)
      return nil unless face.respond_to?(:details)

      face.details[:sample_surface]
    end

    def sampled_fake_surface_z(surface, sample_point, transform_chain)
      local_x, local_y, = inverse_transform_fake_components(
        sample_point[:x],
        sample_point[:y],
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

    def blocking_faces_for(scene_entities, target_entity:, ignore_entities:)
      scene_entities.flat_map do |entity|
        next [] if entity.equal?(target_entity)
        next [] if ignore_entities.any? { |ignore_entity| ignore_entity.equal?(entity) }

        sampleable_faces_for(entity, visible_only: true, transform_chain: [])
      rescue RuntimeError
        []
      end
    end

    def blocked_by_visible_geometry?(sample_point, sampled_z, blocking_faces)
      blocking_faces.any? do |face|
        blocking_z = sampled_z_for_face(face, sample_point)
        next false if blocking_z.nil?

        blocking_z > (sampled_z + SAMPLE_Z_CLUSTER_TOLERANCE_METERS)
      end
    end

    def cluster_hits(hits)
      hits.sort_by { |hit| hit[:z] }.each_with_object([]) do |hit, clusters|
        current_cluster = clusters.last
        if current_cluster.nil? ||
           (hit[:z] - current_cluster.last[:z]).abs > SAMPLE_Z_CLUSTER_TOLERANCE_METERS
          clusters << [hit]
        else
          current_cluster << hit
        end
      end
    end

    def hit_result(sample_point, z_value)
      {
        samplePoint: serializer.serialize_xy_sample_point(sample_point[:x], sample_point[:y]),
        status: 'hit',
        hitPoint: serializer.serialize_xyz_sample_point(sample_point[:x], sample_point[:y], z_value)
      }
    end

    def miss_result(sample_point)
      {
        samplePoint: serializer.serialize_xy_sample_point(sample_point[:x], sample_point[:y]),
        status: 'miss'
      }
    end

    def ambiguous_result(sample_point)
      {
        samplePoint: serializer.serialize_xy_sample_point(sample_point[:x], sample_point[:y]),
        status: 'ambiguous'
      }
    end

    def normalize_values(raw_hash)
      (raw_hash || {}).each_with_object({}) do |(key, value), normalized|
        next if value.nil?

        string_value = value.to_s.strip
        next if string_value.empty?

        normalized[key.to_s] = string_value
      end
    end

    def safe_to_meters(value)
      return value.to_m.to_f if value.respond_to?(:to_m)

      value.to_f
    end

    def append_transform(transform_chain, entity)
      transformation = entity.respond_to?(:transformation) ? entity.transformation : nil
      return transform_chain if transformation.nil?

      transform_chain + [transformation]
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

    def sampled_runtime_face_z(face, sample_point, transform_chain)
      world_hit_point = runtime_hit_point(face, sample_point, transform_chain)
      return nil if world_hit_point.nil?

      safe_to_meters(world_hit_point.z)
    end

    def runtime_hit_point(face, sample_point, transform_chain)
      world_plane = transformed_face_plane(face, transform_chain)
      return nil if world_plane.nil?

      world_hit_point = Geom.intersect_line_plane(world_vertical_line(sample_point), world_plane)
      return nil if world_hit_point.nil?

      local_hit_point = world_to_local_point(world_hit_point, transform_chain)
      return nil unless point_on_face?(face, local_hit_point)

      world_hit_point
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

    def world_vertical_line(sample_point)
      [
        Geom::Point3d.new(
          meters_to_internal(sample_point[:x]),
          meters_to_internal(sample_point[:y]),
          0
        ),
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

    def meters_to_internal(value)
      return value.m if value.respond_to?(:m)

      value
    end
  end
  # rubocop:enable Metrics/ClassLength, Metrics/MethodLength, Metrics/ParameterLists
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/BlockLength
end
