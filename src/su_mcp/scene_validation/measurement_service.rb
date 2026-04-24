# frozen_string_literal: true

require_relative 'measurement_result_builder'
require_relative 'terrain_profile_elevation_summary'

module SU_MCP
  # Performs low-level geometry measurements for measure_scene.
  # rubocop:disable Metrics/ClassLength
  class MeasurementService
    def initialize(serializer: nil, result_builder: nil, terrain_profile_summary: nil)
      @serializer = serializer
      @result_builder = result_builder || MeasurementResultBuilder.new
      @terrain_profile_summary = terrain_profile_summary || TerrainProfileElevationSummary.new(
        result_builder: @result_builder,
        serializer: serializer
      )
    end

    def measure(mode:, kind:, **targets)
      case [mode, kind]
      when %w[bounds world_bounds]
        measure_bounds(mode, kind, targets[:target])
      when %w[height bounds_z]
        measure_height(mode, kind, targets[:target])
      when %w[distance bounds_center_to_bounds_center]
        measure_distance(mode, kind, targets[:from], targets[:to])
      when %w[area horizontal_bounds]
        measure_horizontal_bounds_area(mode, kind, targets[:target])
      when %w[area surface] then measure_surface_area(mode, kind, targets[:target])
      when %w[terrain_profile elevation_summary] then measure_terrain_profile(targets)
      else
        unavailable(mode, kind, 'unsupported_geometry')
      end
    end

    private

    attr_reader :serializer, :result_builder, :terrain_profile_summary

    def measure_bounds(mode, kind, target)
      bounds = valid_bounds_for(target)
      return unavailable(mode, kind, 'invalid_bounds') unless bounds
      return unavailable(mode, kind, 'empty_bounds') if empty_bounds?(bounds)

      measured(
        mode,
        kind,
        value: result_builder.bounds_value(bounds),
        unit: 'm',
        evidence: result_builder.bounds_evidence(bounds)
      )
    end

    def measure_height(mode, kind, target)
      bounds = valid_bounds_for(target)
      return unavailable(mode, kind, 'invalid_bounds') unless bounds
      return unavailable(mode, kind, 'empty_bounds') if empty_bounds?(bounds)

      measured(
        mode,
        kind,
        value: meters(bounds.max.z - bounds.min.z),
        unit: 'm',
        evidence: result_builder.bounds_evidence(bounds)
      )
    end

    def measure_distance(mode, kind, from, to)
      from_bounds = valid_bounds_for(from)
      to_bounds = valid_bounds_for(to)
      return unavailable(mode, kind, 'invalid_bounds') unless from_bounds && to_bounds

      measured(
        mode,
        kind,
        value: meters(distance_between_points(from_bounds.center, to_bounds.center)),
        unit: 'm',
        evidence: {
          fromCenter: result_builder.point_hash(from_bounds.center),
          toCenter: result_builder.point_hash(to_bounds.center)
        }
      )
    end

    def measure_horizontal_bounds_area(mode, kind, target)
      bounds = valid_bounds_for(target)
      return unavailable(mode, kind, 'invalid_bounds') unless bounds
      return unavailable(mode, kind, 'empty_bounds') if empty_bounds?(bounds)

      measured(
        mode,
        kind,
        value: result_builder.horizontal_bounds_area(bounds),
        unit: 'm2',
        evidence: result_builder.bounds_evidence(bounds)
      )
    end

    def measure_surface_area(mode, kind, target)
      faces = descendant_faces(target)
      return unavailable(mode, kind, 'no_faces') if faces.empty?

      measured(
        mode,
        kind,
        value: square_meters(surface_area(faces)),
        unit: 'm2',
        evidence: { faceCount: faces.length }
      )
    end

    def measure_terrain_profile(targets)
      terrain_profile_summary.measure(targets[:profile_samples])
    end

    def descendant_faces(entity, transformation = entity_transformation(entity))
      return [[entity, transformation]] if entity.is_a?(Sketchup::Face)

      children = child_entities(entity)
      children.flat_map do |child|
        child_transformation = combined_transformation(transformation, entity_transformation(child))
        descendant_faces(child, child_transformation)
      end
    end

    def child_entities(entity)
      if entity.is_a?(Sketchup::Group)
        entity.entities.to_a
      elsif entity.is_a?(Sketchup::ComponentInstance)
        entity.definition.entities.to_a
      else
        []
      end
    end

    def surface_area(faces)
      faces.sum do |face, transformation|
        face_area(face, transformation)
      end
    end

    def face_area(face, transformation)
      return face.area if face.method(:area).arity.zero?

      face.area(transformation)
    end

    def distance_between_points(from_point, to_point)
      Math.sqrt(
        ((from_point.x - to_point.x)**2) +
        ((from_point.y - to_point.y)**2) +
        ((from_point.z - to_point.z)**2)
      )
    end

    def entity_transformation(entity)
      entity.transformation if entity.respond_to?(:transformation)
    end

    def combined_transformation(parent, child)
      return parent unless child
      return child unless parent
      return parent * child if parent.respond_to?(:*)

      child
    end

    def valid_bounds_for(entity)
      bounds = entity&.bounds
      return nil unless bounds&.valid?

      bounds
    end

    def empty_bounds?(bounds)
      (bounds.max.x - bounds.min.x).zero? &&
        (bounds.max.y - bounds.min.y).zero? &&
        (bounds.max.z - bounds.min.z).zero?
    end

    def measured(mode, kind, value:, unit:, evidence:)
      result_builder.measured(mode, kind, value: value, unit: unit, evidence: evidence)
    end

    def unavailable(mode, kind, reason)
      result_builder.unavailable(mode, kind, reason)
    end

    def meters(value)
      result_builder.meters(value)
    end

    def square_meters(value)
      result_builder.square_meters(value)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
