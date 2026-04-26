# frozen_string_literal: true

require_relative '../semantic/length_converter'
require_relative 'terrain_output_plan'

module SU_MCP
  module Terrain
    # Regenerates disposable SketchUp mesh output from authoritative terrain state.
    # rubocop:disable Metrics/ClassLength
    class TerrainMeshGenerator
      DERIVED_OUTPUT_DICTIONARY = 'su_mcp_terrain'
      DERIVED_OUTPUT_KEY = 'derivedOutput'

      def initialize(length_converter: Semantic::LengthConverter.new)
        @length_converter = length_converter
      end

      def generate(owner:, state:, terrain_state_summary:, output_plan: nil)
        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertices_for(state, columns, rows)
        # MTA-09 records dirty intent in the plan; production output remains full-grid.
        plan = output_plan || TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary
        )

        emit_faces_via_builder(owner.entities, vertices, columns, rows)

        generated_result(plan)
      end

      # Validation-only path for live SketchUp comparisons.
      # Do not wire this into production regeneration.
      def generate_bulk_candidate(owner:, state:, terrain_state_summary:)
        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertices_for(state, columns, rows)
        output_plan = TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary
        )

        emit_faces_via_builder(owner.entities, vertices, columns, rows)
        generated_result(output_plan).merge(validationOnly: true)
      end

      def regenerate(owner:, state:, terrain_state_summary:, output_plan: nil)
        unsupported = unsupported_child_types(owner.entities)
        return unsupported_children_refusal(unsupported) unless unsupported.empty?

        erase_entities(owner.entities, derived_output_entities(owner.entities))
        generate(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          output_plan: output_plan
        )
      end

      private

      attr_reader :length_converter

      def generated_result(output_plan)
        {
          outcome: 'generated',
          summary: output_plan.to_summary
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

      def emit_faces_via_builder(entities, vertices, columns, rows)
        return emit_faces(entities, vertices, columns, rows) unless entities.respond_to?(:build)

        entities.build do |builder|
          emit_faces(builder, vertices, columns, rows)
        end
      end

      def emit_faces(face_target, vertices, columns, rows)
        each_cell(columns, rows) do |column, row|
          add_cell_triangles(face_target, vertices, column, row, columns)
        end
      end

      def add_cell_triangles(entities, vertices, column, row, columns)
        lower_left = grid_vertex_at(vertices, column, row, columns)
        lower_right = grid_vertex_at(vertices, column + 1, row, columns)
        upper_left = grid_vertex_at(vertices, column, row + 1, columns)
        upper_right = grid_vertex_at(vertices, column + 1, row + 1, columns)

        add_derived_face(entities, lower_left, lower_right, upper_right)
        add_derived_face(entities, lower_left, upper_right, upper_left)
      end

      def grid_vertex_at(vertices, column, row, columns)
        vertices.fetch((row * columns) + column)
      end

      def add_derived_face(entities, *points)
        face = entities.add_face(*points)
        normalize_upward_face!(face)
        mark_derived(face)
      end

      def normalize_upward_face!(face)
        return face unless face.respond_to?(:normal) && face.respond_to?(:reverse!)

        normal = face.normal
        return face unless normal.respond_to?(:z)

        # Heightmap terrain is z-up; generated front faces should point upward.
        return face unless normal.z.to_f.negative?

        face.reverse!
        face
      end

      def mark_derived(entity)
        return entity unless entity.respond_to?(:set_attribute)

        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, DERIVED_OUTPUT_KEY, true)
        mark_derived_edges(entity)
        entity
      end

      def mark_derived_edges(entity)
        return unless entity.respond_to?(:edges)

        edges = entity.edges
        return unless edges.respond_to?(:each)

        edges.each { |edge| mark_derived(edge) }
      end

      def derived_output_entities(entities)
        entities.to_a.select { |entity| derived_output?(entity) }
      end

      def unsupported_child_types(entities)
        entities.each_with_object([]) do |entity, types|
          next if derived_output?(entity)

          types << entity_type(entity)
        end
      end

      def derived_output?(entity)
        entity.respond_to?(:get_attribute) &&
          entity.get_attribute(DERIVED_OUTPUT_DICTIONARY, DERIVED_OUTPUT_KEY) == true
      end

      def erase_entities(entities, output_entities)
        return if output_entities.empty?

        if entities.respond_to?(:erase_entities)
          entities.erase_entities(output_entities)
        else
          output_entities.each { |entity| entities.delete_entity(entity) }
        end
      end

      def entity_type(entity)
        case entity
        when Sketchup::Group
          'group'
        when Sketchup::ComponentInstance
          'component_instance'
        when Sketchup::ConstructionPoint
          'construction_point'
        when Sketchup::Face
          'face'
        when Sketchup::Edge
          'edge'
        else
          entity.class.name.to_s.split('::').last.to_s
        end
      end

      def unsupported_children_refusal(types)
        {
          outcome: 'refused',
          refusal: {
            code: 'terrain_output_contains_unsupported_entities',
            message: 'Terrain owner contains unsupported child entities.',
            details: {
              unsupportedChildTypes: types.uniq,
              action: 'remove unsupported children or recreate the managed terrain output'
            }
          }
        }
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
