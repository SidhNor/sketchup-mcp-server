# frozen_string_literal: true

require_relative '../semantic/length_converter'

module SU_MCP
  module Terrain
    # Regenerates disposable SketchUp mesh output from authoritative terrain state.
    class TerrainMeshGenerator
      def initialize(length_converter: Semantic::LengthConverter.new)
        @length_converter = length_converter
      end

      def generate(owner:, state:, terrain_state_summary:)
        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertices_for(state, columns, rows)

        each_cell(columns, rows) do |column, row|
          add_cell_triangles(owner.entities, vertices, column, row, columns)
        end

        generated_result(vertices, columns, rows, terrain_state_summary)
      end

      private

      attr_reader :length_converter

      def generated_result(vertices, columns, rows, terrain_state_summary)
        {
          outcome: 'generated',
          summary: {
            derivedMesh: {
              meshType: 'regular_grid',
              vertexCount: vertices.length,
              faceCount: (columns - 1) * (rows - 1) * 2,
              derivedFromStateDigest: terrain_state_summary.fetch(:digest)
            }
          }
        }
      end

      def vertices_for(state, columns, rows)
        (0...rows).flat_map do |row|
          (0...columns).map do |column|
            vertex_for(state, column, row, columns)
          end
        end
      end

      def vertex_for(state, column, row, columns)
        origin = state.origin
        spacing = state.spacing
        [
          internal_length(origin.fetch('x') + (column * spacing.fetch('x'))),
          internal_length(origin.fetch('y') + (row * spacing.fetch('y'))),
          internal_length(state.elevations.fetch((row * columns) + column))
        ]
      end

      def internal_length(value)
        length_converter.public_meters_to_internal(value)
      end

      def each_cell(columns, rows)
        (0...(rows - 1)).each do |row|
          (0...(columns - 1)).each do |column|
            yield column, row
          end
        end
      end

      def add_cell_triangles(entities, vertices, column, row, columns)
        lower_left = grid_vertex_at(vertices, column, row, columns)
        lower_right = grid_vertex_at(vertices, column + 1, row, columns)
        upper_left = grid_vertex_at(vertices, column, row + 1, columns)
        upper_right = grid_vertex_at(vertices, column + 1, row + 1, columns)

        entities.add_face(lower_left, lower_right, upper_right)
        entities.add_face(lower_left, upper_right, upper_left)
      end

      def grid_vertex_at(vertices, column, row, columns)
        vertices.fetch((row * columns) + column)
      end
    end
  end
end
