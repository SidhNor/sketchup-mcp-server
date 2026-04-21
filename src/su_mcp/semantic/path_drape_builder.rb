# frozen_string_literal: true

require_relative 'builder_refusal'
require_relative 'length_converter'
require_relative 'surface_height_sampler'

module SU_MCP
  module Semantic
    # Builds the lightweight surface-drape ribbon for path hosting without
    # modifying the terrain or conforming width-wise to the terrain mesh.
    # rubocop:disable Metrics/ClassLength
    class PathDrapeBuilder
      DEFAULT_CLEARANCE_METERS = 0.02
      DEFAULT_STATION_SPACING_METERS = 1.0
      DEFAULT_STATION_LIMIT = 1_000
      DEFAULT_CROSS_SLOPE_SAMPLE_FRACTIONS = [-0.5, -0.25, 0.0, 0.25, 0.5].freeze
      STATION_TOLERANCE = 1e-9

      def initialize(surface_sampler: SurfaceHeightSampler.new,
                     station_spacing: nil,
                     clearance: nil,
                     station_limit: DEFAULT_STATION_LIMIT,
                     cross_slope_sample_fractions: DEFAULT_CROSS_SLOPE_SAMPLE_FRACTIONS)
        @surface_sampler = surface_sampler
        @station_spacing = station_spacing || meters_to_internal(DEFAULT_STATION_SPACING_METERS)
        @clearance = clearance || meters_to_internal(DEFAULT_CLEARANCE_METERS)
        @station_limit = station_limit
        @cross_slope_sample_fractions = cross_slope_sample_fractions
      end

      def build(group:, payload:, host_target:)
        sample_context = surface_sampler.prepare_context(host_target)
        raise invalid_hosting_target_refusal if sample_context.fetch(:face_entries).empty?

        stations = resample_centerline(payload.fetch('centerline'))
        raise tessellation_limit_refusal(stations.length) if stations.length > station_limit

        sections = build_sections(
          stations: stations,
          width: payload.fetch('width'),
          sample_context: sample_context
        )
        stitch_ribbon(group: group, sections: sections, thickness: payload['thickness'])
      end

      private

      attr_reader :surface_sampler, :station_spacing, :clearance, :station_limit,
                  :cross_slope_sample_fractions

      def meters_to_internal(value)
        value.to_f * LengthConverter::METERS_TO_INTERNAL
      end

      def resample_centerline(centerline)
        normalized = normalize_centerline(centerline)
        raise invalid_centerline_refusal if normalized.length < 2

        stations = [normalized.first]
        normalized.each_cons(2) do |start_point, end_point|
          intermediate_stations_for_segment(start_point, end_point).each do |station|
            append_station(stations, station)
          end
          append_station(stations, end_point)
        end

        stations
      end

      def normalize_centerline(centerline)
        Array(centerline).map do |point|
          values = Array(point).first(2)
          next nil unless values.length == 2

          values.map(&:to_f)
        end.compact
      end

      # rubocop:disable Metrics/AbcSize
      def build_sections(stations:, width:, sample_context:)
        half_width = width.to_f / 2.0
        tangents = stations.each_index.map { |index| tangent_for(stations, index) }
        normals = tangents.map { |tangent| [-tangent[1], tangent[0]] }
        raw_zs = raw_section_zs(stations, normals, width, sample_context)
        smoothed_zs = smooth_section_zs(raw_zs)

        stations.each_index.map do |index|
          build_section(
            center: stations[index],
            normal: normals[index],
            half_width: half_width,
            top_z: [smoothed_zs[index], raw_zs[index]].max
          )
        end
      end
      # rubocop:enable Metrics/AbcSize

      def smooth_section_zs(raw_zs)
        return raw_zs if raw_zs.length <= 2

        raw_zs.each_index.map do |index|
          if index.zero? || index == raw_zs.length - 1
            raw_zs[index]
          else
            (raw_zs[index - 1] + raw_zs[index] + raw_zs[index + 1]) / 3.0
          end
        end
      end

      def tangent_for(stations, index)
        start_point, end_point = tangent_window_for(stations, index)

        direction = [end_point[0] - start_point[0], end_point[1] - start_point[1]]
        length = Math.hypot(*direction)
        raise invalid_centerline_refusal if length <= STATION_TOLERANCE

        [direction[0] / length, direction[1] / length]
      end

      def offset_point(center, normal, distance)
        [
          center[0] + (normal[0] * distance.to_f),
          center[1] + (normal[1] * distance.to_f)
        ]
      end

      def section_base_z(center, normal, width, sample_context, station_index)
        z_samples = cross_slope_sample_fractions.map do |fraction|
          sample_point = offset_point(center, normal, width.to_f * fraction.to_f)
          sampled_z = surface_sampler.sample_z_from_context(
            context: sample_context,
            x_value: sample_point[0],
            y_value: sample_point[1]
          )
          raise terrain_sample_miss_refusal(station_index) if sampled_z.nil?

          sampled_z
        end

        z_samples.max + clearance
      end

      def stitch_ribbon(group:, sections:, thickness:)
        raise invalid_centerline_refusal if sections.length < 2

        emit_faces(group.entities, sections, thickness.to_f)
      end

      # rubocop:disable Metrics/AbcSize
      def intermediate_stations_for_segment(start_point, end_point)
        segment_vector = [end_point[0] - start_point[0], end_point[1] - start_point[1]]
        segment_length = Math.hypot(*segment_vector)
        raise invalid_centerline_refusal if segment_length <= STATION_TOLERANCE

        step_count = (segment_length / station_spacing).floor
        1.upto(step_count).filter_map do |step|
          distance = station_spacing * step
          next if distance >= (segment_length - STATION_TOLERANCE)

          ratio = distance / segment_length
          [
            start_point[0] + (segment_vector[0] * ratio),
            start_point[1] + (segment_vector[1] * ratio)
          ]
        end
      end
      # rubocop:enable Metrics/AbcSize

      def raw_section_zs(stations, normals, width, sample_context)
        stations.each_index.map do |index|
          section_base_z(stations[index], normals[index], width.to_f, sample_context, index)
        end
      end

      def build_section(center:, normal:, half_width:, top_z:)
        left_xy = offset_point(center, normal, half_width)
        right_xy = offset_point(center, normal, -half_width)

        {
          left: [left_xy[0], left_xy[1], top_z],
          right: [right_xy[0], right_xy[1], top_z]
        }
      end

      def append_station(stations, station)
        return if stations.any? && duplicate_station?(stations.last, station)

        stations << station
      end

      def duplicate_station?(left, right)
        Math.hypot(left[0] - right[0], left[1] - right[1]) <= STATION_TOLERANCE
      end

      def tangent_window_for(stations, index)
        return [stations[0], stations[1]] if index.zero?
        return [stations[-2], stations[-1]] if index == stations.length - 1

        [stations[index - 1], stations[index + 1]]
      end

      def emit_faces(entities, sections, thickness)
        return emit_face_batch(entities, sections, thickness) unless entities.respond_to?(:build)

        entities.build do |builder|
          emit_face_batch(builder, sections, thickness)
        end
      end

      def emit_face_batch(face_target, sections, thickness)
        sections.each_cons(2) do |first_section, second_section|
          add_top_interval_faces(face_target, first_section, second_section)
        end

        add_thickness_shell(face_target, sections, thickness)
      end

      def add_top_interval_faces(face_target, first_section, second_section)
        [
          face_target.add_face(
            first_section[:left],
            first_section[:right],
            second_section[:right]
          ),
          face_target.add_face(
            first_section[:left],
            second_section[:right],
            second_section[:left]
          )
        ]
      end

      def add_thickness_shell(face_target, sections, thickness)
        return unless thickness.positive?

        bottom_sections = sections.map { |section| lowered_section(section, thickness) }
        add_bottom_ribbon(face_target, sections, bottom_sections)
        add_end_caps(face_target, sections, bottom_sections)
      end

      def add_bottom_ribbon(face_target, sections, bottom_sections)
        sections.each_index do |index|
          next if index == sections.length - 1

          add_bottom_interval(face_target, sections, bottom_sections, index)
        end
      end

      def add_bottom_interval(face_target, sections, bottom_sections, index)
        add_bottom_interval_faces(
          face_target,
          bottom_sections[index],
          bottom_sections[index + 1]
        )
        add_side_interval_faces(
          face_target,
          first_top: sections[index],
          second_top: sections[index + 1],
          first_bottom: bottom_sections[index],
          second_bottom: bottom_sections[index + 1]
        )
      end

      def add_end_caps(face_target, sections, bottom_sections)
        add_cap_faces(
          face_target,
          top_section: sections.first,
          bottom_section: bottom_sections.first
        )
        add_cap_faces(
          face_target,
          top_section: sections.last,
          bottom_section: bottom_sections.last
        )
      end

      def lowered_section(section, thickness)
        {
          left: lower_point(section[:left], thickness),
          right: lower_point(section[:right], thickness)
        }
      end

      def lower_point(point, thickness)
        [point[0], point[1], point[2] - thickness]
      end

      def add_bottom_interval_faces(face_target, first_section, second_section)
        [
          face_target.add_face(
            first_section[:left],
            second_section[:right],
            first_section[:right]
          ),
          face_target.add_face(
            first_section[:left],
            second_section[:left],
            second_section[:right]
          )
        ]
      end

      def add_side_interval_faces(
        face_target,
        first_top:,
        second_top:,
        first_bottom:,
        second_bottom:
      )
        add_side_quad(
          face_target,
          first_top[:left],
          second_top[:left],
          second_bottom[:left],
          first_bottom[:left]
        )
        add_side_quad(
          face_target,
          first_top[:right],
          first_bottom[:right],
          second_bottom[:right],
          second_top[:right]
        )
      end

      def add_cap_faces(face_target, top_section:, bottom_section:)
        add_side_quad(
          face_target,
          top_section[:left],
          bottom_section[:left],
          bottom_section[:right],
          top_section[:right]
        )
      end

      def add_side_quad(face_target, first_point, second_point, third_point, fourth_point)
        [
          face_target.add_face(first_point, second_point, third_point),
          face_target.add_face(first_point, third_point, fourth_point)
        ]
      end

      def invalid_hosting_target_refusal
        BuilderRefusal.new(
          code: 'invalid_hosting_target',
          message: 'Hosting target does not expose sampleable surface geometry for path drape.',
          details: { section: 'hosting' }
        )
      end

      def invalid_centerline_refusal
        BuilderRefusal.new(
          code: 'invalid_geometry',
          message: [
            'Path centerline must contain at least two distinct',
            'non-overlapping points for drape.'
          ].join(' '),
          details: { section: 'definition', field: 'definition.centerline' }
        )
      end

      def terrain_sample_miss_refusal(station_index)
        BuilderRefusal.new(
          code: 'terrain_sample_miss',
          message: 'Terrain sampling missed at one or more path drape stations.',
          details: { section: 'hosting', stationIndex: station_index }
        )
      end

      def tessellation_limit_refusal(station_count)
        BuilderRefusal.new(
          code: 'path_tessellation_limit_exceeded',
          message: 'Path drape would create too many stations for safe geometry generation.',
          details: {
            section: 'definition',
            field: 'definition.centerline',
            stationCount: station_count,
            stationLimit: station_limit
          }
        )
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
