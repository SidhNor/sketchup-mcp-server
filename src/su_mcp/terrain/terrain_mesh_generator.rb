# frozen_string_literal: true

require 'set'

require_relative '../semantic/length_converter'
require_relative 'terrain_output_plan'

module SU_MCP
  module Terrain
    # Regenerates disposable SketchUp mesh output from authoritative terrain state.
    # rubocop:disable Metrics/AbcSize, Metrics/ClassLength
    class TerrainMeshGenerator
      DERIVED_OUTPUT_DICTIONARY = 'su_mcp_terrain'
      DERIVED_OUTPUT_KEY = 'derivedOutput'
      OUTPUT_SCHEMA_VERSION = 1
      OUTPUT_SCHEMA_VERSION_KEY = 'outputSchemaVersion'
      GRID_CELL_COLUMN_KEY = 'gridCellColumn'
      GRID_CELL_ROW_KEY = 'gridCellRow'
      GRID_TRIANGLE_INDEX_KEY = 'gridTriangleIndex'

      def initialize(length_converter: Semantic::LengthConverter.new)
        @length_converter = length_converter
      end

      def generate(owner:, state:, terrain_state_summary:, output_plan: nil)
        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertices_for(state, columns, rows)
        # Create/adopt generation emits the complete derived grid; edit regeneration may be partial.
        plan = output_plan || TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary
        )

        emit_faces_via_builder(
          owner.entities,
          vertices,
          columns,
          rows,
          ownership_context
        )

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

        emit_faces_via_builder(
          owner.entities,
          vertices,
          columns,
          rows,
          ownership_context
        )
        generated_result(output_plan).merge(validationOnly: true)
      end

      def regenerate(owner:, state:, terrain_state_summary:, output_plan: nil)
        unsupported = unsupported_child_types(owner.entities)
        return unsupported_children_refusal(unsupported) unless unsupported.empty?

        plan = output_plan || TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary
        )
        partial_result = regenerate_partial(
          owner: owner,
          state: state,
          output_plan: plan
        )
        return partial_result if partial_result

        erase_entities(owner.entities, derived_output_entities(owner.entities))
        generate(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          output_plan: plan
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

      def ownership_context
        {}
      end

      def regenerate_partial(owner:, state:, output_plan:)
        return nil unless output_plan.intent == :dirty_window
        return nil if output_plan.cell_window.empty? || output_plan.cell_window.whole_grid?

        ownership = owned_faces_for_cell_window(
          owner.entities,
          output_plan.cell_window
        )
        return nil unless ownership.fetch(:outcome) == :owned

        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertices_for(state, columns, rows)
        erase_partial_output(owner.entities, ownership.fetch(:faces))
        emit_cell_window_via_builder(
          owner.entities,
          vertices,
          columns,
          output_plan.cell_window,
          ownership_context
        )
        cleanup_orphan_derived_edges(owner.entities)
        generated_result(output_plan)
      end

      def emit_faces_via_builder(entities, vertices, columns, rows, ownership)
        unless entities.respond_to?(:build)
          return emit_faces(entities, vertices, columns, rows, ownership)
        end

        entities.build do |builder|
          emit_faces(builder, vertices, columns, rows, ownership)
        end
      end

      def emit_faces(face_target, vertices, columns, rows, ownership)
        each_cell(columns, rows) do |column, row|
          add_cell_triangles(face_target, vertices, column, row, columns, ownership)
        end
      end

      def emit_cell_window_via_builder(entities, vertices, columns, cell_window, ownership)
        unless entities.respond_to?(:build)
          return emit_cell_window(entities, vertices, columns, cell_window, ownership)
        end

        entities.build do |builder|
          emit_cell_window(builder, vertices, columns, cell_window, ownership)
        end
      end

      def emit_cell_window(face_target, vertices, columns, cell_window, ownership)
        cell_window.each_cell do |column, row|
          add_cell_triangles(face_target, vertices, column, row, columns, ownership)
        end
      end

      def add_cell_triangles(entities, vertices, column, row, columns, ownership)
        lower_left = grid_vertex_at(vertices, column, row, columns)
        lower_right = grid_vertex_at(vertices, column + 1, row, columns)
        upper_left = grid_vertex_at(vertices, column, row + 1, columns)
        upper_right = grid_vertex_at(vertices, column + 1, row + 1, columns)

        add_derived_face(
          entities,
          lower_left,
          lower_right,
          upper_right,
          ownership: face_ownership(ownership, column, row, 0)
        )
        add_derived_face(
          entities,
          lower_left,
          upper_right,
          upper_left,
          ownership: face_ownership(ownership, column, row, 1)
        )
      end

      def grid_vertex_at(vertices, column, row, columns)
        vertices.fetch((row * columns) + column)
      end

      def face_ownership(ownership, column, row, triangle_index)
        ownership.merge(
          column: column,
          row: row,
          triangle_index: triangle_index
        )
      end

      def add_derived_face(entities, *points, ownership:)
        face = entities.add_face(*points)
        normalize_upward_face!(face)
        mark_derived(face, ownership: ownership)
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

      def mark_derived(entity, ownership: nil)
        return entity unless entity.respond_to?(:set_attribute)

        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, DERIVED_OUTPUT_KEY, true)
        mark_ownership(entity, ownership) if ownership
        mark_derived_edges(entity)
        entity
      end

      def mark_ownership(entity, ownership)
        entity.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          OUTPUT_SCHEMA_VERSION_KEY,
          OUTPUT_SCHEMA_VERSION
        )
        entity.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          GRID_CELL_COLUMN_KEY,
          ownership.fetch(:column)
        )
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, GRID_CELL_ROW_KEY, ownership.fetch(:row))
        entity.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          GRID_TRIANGLE_INDEX_KEY,
          ownership.fetch(:triangle_index)
        )
      end

      def owned_faces_for_cell_window(entities, cell_window)
        derived_faces = derived_output_entities(entities).select do |entity|
          derived_face_entity?(entity)
        end
        if derived_faces.any? { |face| legacy_owned_face?(face) }
          return fallback_ownership(:legacy_output)
        end

        faces_by_cell = Hash.new { |hash, key| hash[key] = {} }
        derived_faces.each do |face|
          column = output_attribute(face, GRID_CELL_COLUMN_KEY)
          row = output_attribute(face, GRID_CELL_ROW_KEY)
          triangle_index = output_attribute(face, GRID_TRIANGLE_INDEX_KEY)
          next unless cell_in_window?(cell_window, column, row)

          cell_faces = faces_by_cell[[column, row]]
          return fallback_ownership(:duplicate_ownership) if cell_faces.key?(triangle_index)

          cell_faces[triangle_index] = face
        end

        affected_faces = []
        cell_window.each_cell do |column, row|
          cell_faces = faces_by_cell[[column, row]]
          return fallback_ownership(:incomplete_ownership) unless cell_faces.keys.sort == [0, 1]

          affected_faces.push(cell_faces.fetch(0), cell_faces.fetch(1))
        end

        { outcome: :owned, faces: affected_faces }
      end

      def fallback_ownership(reason)
        {
          outcome: :fallback,
          reason: reason
        }
      end

      def legacy_owned_face?(face)
        [
          OUTPUT_SCHEMA_VERSION_KEY,
          GRID_CELL_COLUMN_KEY,
          GRID_CELL_ROW_KEY,
          GRID_TRIANGLE_INDEX_KEY
        ].any? { |key| output_attribute(face, key).nil? }
      end

      def cell_in_window?(cell_window, column, row)
        return false unless column.is_a?(Integer) && row.is_a?(Integer)

        column.between?(cell_window.min_column, cell_window.max_column) &&
          row.between?(cell_window.min_row, cell_window.max_row)
      end

      def output_attribute(entity, key)
        entity.get_attribute(DERIVED_OUTPUT_DICTIONARY, key)
      end

      def erase_partial_output(entities, faces)
        erase_entities(entities, faces + edges_owned_only_by(faces))
      end

      def edges_owned_only_by(faces)
        affected_faces = faces.to_set
        faces.flat_map(&:edges).uniq.select do |edge|
          edge.respond_to?(:faces) &&
            edge.faces.respond_to?(:all?) &&
            edge.faces.all? { |face| affected_faces.include?(face) }
        end
      end

      def cleanup_orphan_derived_edges(entities)
        orphan_edges = derived_output_entities(entities).select do |entity|
          entity.is_a?(Sketchup::Edge) &&
            entity.respond_to?(:faces) &&
            entity.faces.empty?
        end
        erase_entities(entities, orphan_edges)
      end

      def derived_face_entity?(entity)
        entity.is_a?(Sketchup::Face) || entity.respond_to?(:points)
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
    # rubocop:enable Metrics/AbcSize, Metrics/ClassLength
  end
end
