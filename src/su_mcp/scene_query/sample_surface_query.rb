# frozen_string_literal: true

require_relative 'sample_surface_support'
require_relative 'sample_surface_evidence'
require_relative 'sample_surface_profile_generator'
require_relative 'prepared_face_index'
require_relative '../runtime/tool_response'

module SU_MCP
  # Ruby-owned explicit target resolution and compact surface sampling.
  # rubocop:disable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists, Metrics/PerceivedComplexity
  class SampleSurfaceQuery
    TARGET_REFERENCE_KEYS = %w[sourceElementId persistentId entityId].freeze
    SAMPLE_Z_CLUSTER_TOLERANCE_METERS = 0.001
    SAMPLING_TYPES = %w[points profile].freeze

    def initialize(serializer:, support: nil, profile_generator: nil)
      @serializer = serializer
      @support = support || SampleSurfaceSupport.new(
        serializer: serializer,
        cluster_tolerance_meters: SAMPLE_Z_CLUSTER_TOLERANCE_METERS
      )
      @profile_generator = profile_generator || SampleSurfaceProfileGenerator.new
    end

    def execute(entities:, params:, scene_entities: nil, entity_entries: nil)
      request = normalized_request(params)
      return ToolResponse.refusal_result(request.fetch(:refusal)) if request.key?(:refusal)

      resolution_entries = normalized_entity_entries(entity_entries, entities)
      blocking_entities = scene_entities || entities
      target_query = request.fetch(:target)
      sample_spec = request.fetch(:sampling)
      ignore = resolved_ignore_entities_or_refusal(resolution_entries, params['ignoreTargets'])
      return ToolResponse.refusal_result(ignore.fetch(:refusal)) if ignore.key?(:refusal)

      ignore_entities = ignore.fetch(:entities)
      target = resolved_target_or_refusal(
        resolution_entries,
        target_query,
        visible_only: visible_only?(params),
        ignore_entities: ignore_entities
      )
      return ToolResponse.refusal_result(target.fetch(:refusal)) if target.key?(:refusal)

      target_entity = target.fetch(:entity)
      target_face_entries = target.fetch(:face_entries)

      if sample_spec.fetch(:mode) == :profile
        profile_result(
          sample_spec: sample_spec,
          target_face_entries: target_face_entries,
          scene_entities: blocking_entities,
          target_entity: target_entity,
          ignore_entities: ignore_entities,
          visible_only: visible_only?(params)
        )
      else
        points_result(
          sample_points: sample_spec.fetch(:points),
          target_face_entries: target_face_entries,
          scene_entities: blocking_entities,
          target_entity: target_entity,
          ignore_entities: ignore_entities,
          visible_only: visible_only?(params)
        )
      end
    end

    def profile_evidence(entities:, params:, scene_entities: nil, entity_entries: nil)
      request = normalized_request(params)
      return ToolResponse.refusal_result(request.fetch(:refusal)) if request.key?(:refusal)

      sample_spec = request.fetch(:sampling)
      unless sample_spec.fetch(:mode) == :profile
        return ToolResponse.refusal_result(
          unsupported_sampling_type_refusal(params.dig('sampling', 'type'))
        )
      end

      resolution_entries = normalized_entity_entries(entity_entries, entities)
      blocking_entities = scene_entities || entities
      ignore = resolved_ignore_entities_or_refusal(resolution_entries, params['ignoreTargets'])
      return ToolResponse.refusal_result(ignore.fetch(:refusal)) if ignore.key?(:refusal)

      ignore_entities = ignore.fetch(:entities)
      target = resolved_target_or_refusal(
        resolution_entries,
        request.fetch(:target),
        visible_only: visible_only?(params),
        ignore_entities: ignore_entities
      )
      return ToolResponse.refusal_result(target.fetch(:refusal)) if target.key?(:refusal)

      {
        success: true,
        evidence: build_profile_evidence(
          sample_spec: sample_spec,
          target_face_entries: target.fetch(:face_entries),
          scene_entities: blocking_entities,
          target_entity: target.fetch(:entity),
          ignore_entities: ignore_entities,
          visible_only: visible_only?(params)
        )
      }
    end

    private

    attr_reader :serializer, :support, :profile_generator

    def normalized_request(params)
      target = normalized_target_or_refusal(params['target'])
      return { refusal: target } if refusal_payload?(target)

      sampling = normalized_sampling_or_refusal(params['sampling'])
      return { refusal: sampling } if refusal_payload?(sampling)

      { target: target, sampling: sampling }
    end

    def normalized_target_or_refusal(raw_target)
      normalized_target_reference(raw_target)
    rescue RuntimeError => e
      field = e.message.start_with?('Unsupported') ? e.message.split(': ').last : 'target'
      code = if e.message.start_with?('Unsupported')
               'unsupported_reference_field'
             else
               'missing_required_field'
             end
      refusal_payload(
        code: code,
        message: e.message,
        details: { field: field }
      )
    end

    def normalized_sampling_or_refusal(raw_sampling)
      return missing_field_refusal('sampling') unless raw_sampling.is_a?(Hash)

      type = raw_sampling['type'] || raw_sampling[:type]
      return missing_field_refusal('sampling.type') if blank_value?(type)
      return unsupported_sampling_type_refusal(type) unless SAMPLING_TYPES.include?(type)

      if type == 'points'
        normalized_points_sampling_or_refusal(raw_sampling)
      else
        normalized_profile_sampling_or_refusal(raw_sampling)
      end
    end

    def normalized_points_sampling_or_refusal(sampling)
      unsupported_field = %w[path sampleCount intervalMeters].find { |key| sampling.key?(key) }
      return unsupported_request_field_refusal("sampling.#{unsupported_field}") if unsupported_field

      points = Array(sampling['points'] || sampling[:points])
      return missing_field_refusal('sampling.points') if points.empty?

      { mode: :points, points: normalized_sample_points(points) }
    rescue RuntimeError => e
      invalid_value_refusal('sampling.points', e.message)
    end

    def normalized_profile_sampling_or_refusal(sampling)
      return unsupported_request_field_refusal('sampling.points') if sampling.key?('points')

      path = sampling['path'] || sampling[:path]
      return missing_field_refusal('sampling.path') if Array(path).empty?

      sample_count = sampling['sampleCount'] || sampling[:sampleCount]
      interval_meters = sampling['intervalMeters'] || sampling[:intervalMeters]
      if sample_count.nil? && interval_meters.nil?
        return missing_field_refusal('sampling.sampleCount|sampling.intervalMeters')
      end

      if !sample_count.nil? && !interval_meters.nil?
        return refusal_payload(
          code: 'mutually_exclusive_fields',
          message: 'Provide either sampleCount or intervalMeters, not both.',
          details: { fields: %w[sampling.sampleCount sampling.intervalMeters] }
        )
      end

      profile_samples = profile_generator.generate(
        path: path,
        sample_count: sample_count,
        interval_meters: interval_meters
      )
      { mode: :profile, profile_samples: profile_samples }
    rescue SampleSurfaceProfileGenerator::SampleCapExceeded => e
      refusal_payload(
        code: 'sample_cap_exceeded',
        message: e.message,
        details: {
          field: 'sampling',
          generatedCount: e.generated_count,
          allowedCap: e.allowed_cap
        }
      )
    rescue RuntimeError => e
      invalid_geometry_refusal('sampling.path', e.message)
    end

    def blank_value?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def refusal_payload?(value)
      value.is_a?(Hash) && value.key?(:code) && value.key?(:message)
    end

    def missing_field_refusal(field)
      refusal_payload(
        code: 'missing_required_field',
        message: "#{field} is required.",
        details: { field: field }
      )
    end

    def unsupported_sampling_type_refusal(value)
      refusal_payload(
        code: 'unsupported_option',
        message: 'Sampling type is not supported.',
        details: {
          field: 'sampling.type',
          value: value,
          allowedValues: SAMPLING_TYPES
        }
      )
    end

    def unsupported_request_field_refusal(field)
      refusal_payload(
        code: 'unsupported_request_field',
        message: "#{field} is not supported for this sampling type.",
        details: { field: field }
      )
    end

    def invalid_value_refusal(field, message)
      refusal_payload(
        code: 'invalid_value',
        message: message,
        details: { field: field }
      )
    end

    def invalid_geometry_refusal(field, message)
      refusal_payload(
        code: 'invalid_geometry',
        message: message,
        details: { field: field }
      )
    end

    def refusal_payload(code:, message:, details:)
      { code: code, message: message, details: details }
    end

    def normalized_entity_entries(entity_entries, entities)
      return entity_entries unless entity_entries.nil?

      entities.map { |entity| { entity: entity, ancestors: [] } }
    end

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

    def resolve_ignore_entities(entity_entries, raw_ignore_targets)
      Array(raw_ignore_targets).map do |ignore_target|
        query = normalized_target_reference(ignore_target)
        resolve_entity_entry!(
          entity_entries,
          query,
          none_message: 'Ignore target reference resolves to no entity',
          ambiguous_message: 'Ignore target reference resolves ambiguously'
        ).fetch(:entity)
      end
    end

    def resolved_ignore_entities_or_refusal(entity_entries, raw_ignore_targets)
      { entities: resolve_ignore_entities(entity_entries, raw_ignore_targets) }
    rescue RuntimeError => e
      {
        refusal: refusal_payload(
          code: 'ignore_target_resolution_failed',
          message: e.message,
          details: {
            field: 'ignoreTargets',
            resolution: e.message.include?('ambiguously') ? 'ambiguous' : 'none'
          }
        )
      }
    end

    def resolved_target_or_refusal(entity_entries, target_query, visible_only:, ignore_entities:)
      target_entry = resolve_entity_entry!(
        entity_entries,
        target_query,
        none_message: 'Target reference resolves to no entity',
        ambiguous_message: 'Target reference resolves ambiguously'
      )
      target_entity = target_entry.fetch(:entity)
      target_face_entries = support.sampleable_faces_for(
        target_entity,
        visible_only: visible_only,
        ancestor_chain: target_entry.fetch(:ancestors)
      )
      target_face_entries = support.reject_ignored_faces(target_face_entries, ignore_entities)
      unless target_face_entries.empty?
        return { entity: target_entity, face_entries: target_face_entries }
      end

      { refusal: target_not_sampleable_refusal }
    rescue RuntimeError => e
      { refusal: target_resolution_refusal(e) }
    end

    def target_resolution_refusal(error)
      message = error.message
      return unsupported_target_type_refusal(message) if message.start_with?('Target type ')

      resolution = message.include?('ambiguously') ? 'ambiguous' : 'none'
      refusal_payload(
        code: 'target_resolution_failed',
        message: message,
        details: { field: 'target', resolution: resolution }
      )
    end

    def unsupported_target_type_refusal(message)
      refusal_payload(
        code: 'unsupported_target_type',
        message: message,
        details: {
          field: 'target',
          targetType: message[/Target type (\S+) /, 1]
        }
      )
    end

    def target_not_sampleable_refusal
      refusal_payload(
        code: 'target_not_sampleable',
        message: 'Target resolves to no sampleable face geometry.',
        details: { field: 'target' }
      )
    end

    def resolve_entity_entry!(entity_entries, query, none_message:, ambiguous_message:)
      matches = entity_entries.select do |entry|
        target_reference_matches?(entry.fetch(:entity), query)
      end
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

    def points_result(sample_points:, target_face_entries:, scene_entities:, target_entity:,
                      ignore_entities:, visible_only:)
      with_active_sample_xy_bounds(sample_points) do
        prepared_target_faces = prepared_face_index(prepare_face_entries(target_face_entries))
        blocking_faces = blocking_faces_for(
          scene_entities,
          target_entity: target_entity,
          ignore_entities: ignore_entities,
          visible_only: visible_only
        )
        prepared_blocking_faces = prepared_face_index(prepare_face_entries(blocking_faces))
        {
          success: true,
          results: sample_points.map do |sample_point|
            sample_point_result(
              sample_point: sample_point,
              target_face_entries: prepared_target_faces,
              visible_only: visible_only,
              blocking_faces: prepared_blocking_faces
            )
          end
        }
      end
    end

    def profile_result(sample_spec:, target_face_entries:, scene_entities:, target_entity:,
                       ignore_entities:, visible_only:)
      evidence = build_profile_evidence(
        sample_spec: sample_spec,
        target_face_entries: target_face_entries,
        scene_entities: scene_entities,
        target_entity: target_entity,
        ignore_entities: ignore_entities,
        visible_only: visible_only
      )
      {
        success: true,
        results: evidence.map { |sample| serializer.serialize_sampling_evidence(sample) },
        summary: profile_summary(evidence)
      }
    end

    def build_profile_evidence(sample_spec:, target_face_entries:, scene_entities:, target_entity:,
                               ignore_entities:, visible_only:)
      profile_samples = sample_spec.fetch(:profile_samples)
      with_active_sample_xy_bounds(profile_samples) do
        prepared_target_faces = prepared_face_index(prepare_face_entries(target_face_entries))
        blocking_faces = blocking_faces_for(
          scene_entities,
          target_entity: target_entity,
          ignore_entities: ignore_entities,
          visible_only: visible_only
        )
        prepared_blocking_faces = prepared_face_index(prepare_face_entries(blocking_faces))
        profile_samples.map do |profile_sample|
          profile_sample_evidence(
            profile_sample,
            sample_point_result(
              sample_point: {
                x: profile_sample.fetch(:x),
                y: profile_sample.fetch(:y)
              },
              target_face_entries: prepared_target_faces,
              visible_only: visible_only,
              blocking_faces: prepared_blocking_faces
            )
          )
        end
      end
    end

    def profile_sample_evidence(profile_sample, result)
      hit_point = result[:hitPoint]
      SampleSurfaceEvidence::Sample.new(
        index: profile_sample.fetch(:index),
        x: profile_sample.fetch(:x),
        y: profile_sample.fetch(:y),
        z: hit_point&.fetch(:z),
        distance_along_path_meters: profile_sample.fetch(:distance_along_path_meters),
        path_progress: profile_sample.fetch(:path_progress),
        status: result.fetch(:status)
      )
    end

    def profile_summary(evidence)
      hit_z_values = evidence.filter_map { |sample| sample.z if sample.status == 'hit' }
      summary = {
        totalSamples: evidence.length,
        hitCount: evidence.count { |sample| sample.status == 'hit' },
        missCount: evidence.count { |sample| sample.status == 'miss' },
        ambiguousCount: evidence.count { |sample| sample.status == 'ambiguous' },
        sampledLengthMeters: evidence.last&.distance_along_path_meters || 0.0
      }
      unless hit_z_values.empty?
        summary[:minZ] = hit_z_values.min
        summary[:maxZ] = hit_z_values.max
      end
      summary
    end

    def sample_point_result(sample_point:, target_face_entries:, visible_only:,
                            blocking_faces: nil)
      target_hits = candidate_hits(target_face_entries, sample_point)
      if visible_only
        target_hits.reject! do |hit|
          blocked_by_visible_geometry?(sample_point, hit[:z], blocking_faces)
        end
      end

      clusters = support.cluster_hits(target_hits)
      return miss_result(sample_point) if clusters.empty?
      return ambiguous_result(sample_point) if clusters.length > 1

      hit = clusters.first.first
      hit_result(sample_point, hit[:z])
    end

    def candidate_hits(face_entries, sample_point)
      face_entries_for_sample(face_entries, sample_point).filter_map do |face_entry|
        sample_z = sampled_z_for_face(face_entry, sample_point)
        next if sample_z.nil?

        { face: face_entry[:face], z: sample_z }
      end
    end

    def blocking_faces_for(scene_entities, target_entity:, ignore_entities:, visible_only:)
      return [] unless visible_only

      support.blocking_faces_for(
        scene_entities,
        target_entity: target_entity,
        ignore_entities: ignore_entities,
        xy_bounds: @active_sample_xy_bounds
      )
    end

    def prepare_face_entries(face_entries)
      face_entries.map { |face_entry| prepare_face_entry(face_entry) }
    end

    def prepared_face_index(face_entries)
      PreparedFaceIndex.new(
        face_entries,
        coordinate_converter: method(:meters_to_internal),
        tolerance: internal_sample_tolerance
      )
    end

    def face_entries_for_sample(face_entries, sample_point)
      return face_entries.candidates_for(sample_point) if face_entries.respond_to?(:candidates_for)

      face_entries
    end

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

    def with_active_sample_xy_bounds(sample_points)
      previous_bounds = @active_sample_xy_bounds
      @active_sample_xy_bounds = sample_xy_bounds(sample_points)
      yield
    ensure
      @active_sample_xy_bounds = previous_bounds
    end

    def sample_xy_bounds(sample_points)
      return nil if sample_points.empty?

      xs = sample_points.filter_map do |sample|
        sample_bound_coordinate(sample[:x] || sample.fetch(:x))
      end
      ys = sample_points.filter_map do |sample|
        sample_bound_coordinate(sample[:y] || sample.fetch(:y))
      end
      return nil if xs.empty? || ys.empty?

      {
        min_x: xs.min - SAMPLE_Z_CLUSTER_TOLERANCE_METERS,
        max_x: xs.max + SAMPLE_Z_CLUSTER_TOLERANCE_METERS,
        min_y: ys.min - SAMPLE_Z_CLUSTER_TOLERANCE_METERS,
        max_y: ys.max + SAMPLE_Z_CLUSTER_TOLERANCE_METERS
      }
    end

    def sample_bound_coordinate(value)
      converted = meters_to_internal(value)
      converted.nil? ? value.to_f : converted.to_f
    rescue StandardError
      nil
    end

    def sampled_z_for_face(face_entry, sample_point)
      face = face_entry[:face]
      transform_chain = face_entry[:transform_chain]
      surface = face_entry[:surface] || fake_surface_definition(face)
      return sampled_fake_surface_z(surface, sample_point, transform_chain) if surface

      sampled_runtime_face_z(face_entry, sample_point)
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

    def blocked_by_visible_geometry?(sample_point, sampled_z, blocking_faces)
      face_entries_for_sample(blocking_faces, sample_point).any? do |face|
        blocking_z = sampled_z_for_face(face, sample_point)
        next false if blocking_z.nil?

        blocking_z > (sampled_z + SAMPLE_Z_CLUSTER_TOLERANCE_METERS)
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

    def sampled_runtime_face_z(face_entry, sample_point)
      world_hit_point = runtime_hit_point(face_entry, sample_point)
      return nil if world_hit_point.nil?

      safe_to_meters(world_hit_point.z)
    end

    def runtime_hit_point(face_entry, sample_point)
      face = face_entry[:face]
      transform_chain = face_entry[:transform_chain]
      world_plane = face_entry[:world_plane]
      return nil if world_plane.nil?
      return nil unless point_within_bounds?(sample_point, face_entry[:world_xy_bounds])

      world_hit_point = Geom.intersect_line_plane(world_vertical_line(sample_point), world_plane)
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

    def point_within_bounds?(sample_point, bounds)
      return true if bounds.nil?

      x_value = meters_to_internal(sample_point[:x])
      y_value = meters_to_internal(sample_point[:y])
      return true if x_value.nil? || y_value.nil?

      value_between_with_tolerance?(x_value.to_f, bounds[:min_x], bounds[:max_x]) &&
        value_between_with_tolerance?(y_value.to_f, bounds[:min_y], bounds[:max_y])
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
      return true if [
        Sketchup::Face::PointInside,
        Sketchup::Face::PointOnEdge,
        Sketchup::Face::PointOnVertex
      ].include?(classification)

      point_near_face_boundary?(face, point)
    rescue StandardError
      false
    end

    def point_near_face_boundary?(face, point)
      points = face_vertices(face)
      return false if points.length < 2

      closed_points = points + [points.first]
      closed_points.each_cons(2).any? do |start_point, end_point|
        point_near_segment_xy?(point, start_point, end_point)
      end
    end

    def face_vertices(face)
      return [] unless face.respond_to?(:vertices)

      Array(face.vertices).filter_map do |vertex|
        vertex.position if vertex.respond_to?(:position)
      end
    end

    def point_near_segment_xy?(point, start_point, end_point)
      px = point.x.to_f
      py = point.y.to_f
      x1 = start_point.x.to_f
      y1 = start_point.y.to_f
      x2 = end_point.x.to_f
      y2 = end_point.y.to_f

      dx = x2 - x1
      dy = y2 - y1
      length_squared = (dx * dx) + (dy * dy)
      return distance_xy(px, py, x1, y1) <= internal_sample_tolerance if length_squared.zero?

      projection = (((px - x1) * dx) + ((py - y1) * dy)) / length_squared
      clamped_projection = projection.clamp(0.0, 1.0)
      closest_x = x1 + (clamped_projection * dx)
      closest_y = y1 + (clamped_projection * dy)
      distance_xy(px, py, closest_x, closest_y) <= internal_sample_tolerance
    end

    def distance_xy(first_x, first_y, second_x, second_y)
      Math.sqrt(((first_x - second_x)**2) + ((first_y - second_y)**2))
    end

    def value_between_with_tolerance?(value, minimum, maximum)
      tolerance = internal_sample_tolerance
      value.between?(minimum - tolerance, maximum + tolerance)
    end

    def internal_sample_tolerance
      converted = meters_to_internal(SAMPLE_Z_CLUSTER_TOLERANCE_METERS)
      converted.respond_to?(:to_f) ? converted.to_f : SAMPLE_Z_CLUSTER_TOLERANCE_METERS
    rescue StandardError
      SAMPLE_Z_CLUSTER_TOLERANCE_METERS
    end

    def meters_to_internal(value)
      if value.respond_to?(:m)
        converted = value.m
        return converted unless converted.nil?
      end

      value
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists, Metrics/PerceivedComplexity
end
