# frozen_string_literal: true

require 'sketchup'

module SU_MCP
  # Builds basic SketchUp component geometry for extracted editing commands.
  class ComponentGeometryBuilder
    def initialize(logger: nil)
      @logger = logger
    end

    def build(group:, type:, position:, dimensions:)
      case type
      when 'cube'
        build_cube(group: group, position: position, dimensions: dimensions)
      when 'cylinder'
        build_cylinder(group: group, position: position, dimensions: dimensions)
      when 'sphere'
        build_sphere(group: group, position: position, dimensions: dimensions)
      when 'cone'
        build_cone(group: group, position: position, dimensions: dimensions)
      else
        raise "Unknown component type: #{type}"
      end
    end

    private

    attr_reader :logger

    def build_cube(group:, position:, dimensions:)
      group.entities.add_face(*cube_corners(position: position, dimensions: dimensions))
           .pushpull(dimensions[2])
    end

    def build_cylinder(group:, position:, dimensions:)
      radius = dimensions[0] / 2.0
      height = dimensions[2]
      center = [position[0] + radius, position[1] + radius, position[2]]

      group.entities.add_face(*circle_points(center: center, radius: radius)).pushpull(height)
    end

    def build_sphere(group:, position:, dimensions:)
      radius = dimensions[0] / 2.0
      center = [position[0] + radius, position[1] + radius, position[2] + radius]
      return Sketchup::Tools.create_sphere(center, radius, 24, group.entities) if sphere_tool?

      build_polygon_sphere(group: group, center: center, radius: radius)
    end

    def build_cone(group:, position:, dimensions:)
      center, radius, height = cone_dimensions(position: position, dimensions: dimensions)
      apex = [center[0], center[1], center[2] + height]
      points = circle_points(center: center, radius: radius)

      group.entities.add_face(*points)
      points.each_with_index do |point, index|
        group.entities.add_face(point, points[(index + 1) % points.length], apex)
      end
    end

    def cube_corners(position:, dimensions:)
      [
        [position[0], position[1], position[2]],
        [position[0] + dimensions[0], position[1], position[2]],
        [position[0] + dimensions[0], position[1] + dimensions[1], position[2]],
        [position[0], position[1] + dimensions[1], position[2]]
      ]
    end

    def build_polygon_sphere(group:, center:, radius:)
      segments = 16
      points = sphere_points(center: center, radius: radius, segments: segments)

      (0...segments).each do |latitude_index|
        (0...segments).each do |longitude_index|
          group.entities.add_face(
            *sphere_face_points(points, latitude_index, longitude_index, segments)
          )
        rescue StandardError => e
          logger&.call("Skipping sphere face: #{e.message}")
        end
      end
    end

    def sphere_points(center:, radius:, segments:)
      (0..segments).flat_map do |latitude_index|
        latitude = Math::PI * latitude_index / segments
        (0..segments).map do |longitude_index|
          sphere_point(center, radius, latitude, longitude_index, segments)
        end
      end
    end

    def sphere_face_points(points, latitude_index, longitude_index, segments)
      first = (latitude_index * (segments + 1)) + longitude_index
      second = first + 1
      third = first + segments + 1
      fourth = third + 1
      [points[first], points[second], points[fourth], points[third]]
    end

    def circle_points(center:, radius:, segments: 24)
      segments.times.map do |index|
        angle = Math::PI * 2 * index / segments
        [
          center[0] + (radius * Math.cos(angle)),
          center[1] + (radius * Math.sin(angle)),
          center[2]
        ]
      end
    end

    def sphere_tool?
      Sketchup::Tools.respond_to?(:create_sphere)
    end

    def cone_dimensions(position:, dimensions:)
      radius = dimensions[0] / 2.0
      center = [position[0] + radius, position[1] + radius, position[2]]
      [center, radius, dimensions[2]]
    end

    def sphere_point(center, radius, latitude, longitude_index, segments)
      longitude = 2 * Math::PI * longitude_index / segments
      [
        center[0] + (radius * Math.sin(latitude) * Math.cos(longitude)),
        center[1] + (radius * Math.sin(latitude) * Math.sin(longitude)),
        center[2] + (radius * Math.cos(latitude))
      ]
    end
  end
end
