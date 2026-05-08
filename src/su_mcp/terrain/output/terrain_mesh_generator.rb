# frozen_string_literal: true

require 'set'

require_relative '../../semantic/length_converter'
require_relative 'cdt/terrain_cdt_backend'
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
      DEFAULT_CDT_BACKEND = Object.new.freeze
      DEFAULT_CDT_ENABLED = false

      def initialize(
        length_converter: Semantic::LengthConverter.new,
        cdt_backend: DEFAULT_CDT_BACKEND
      )
        @length_converter = length_converter
        @cdt_backend = if default_cdt_backend?(cdt_backend)
                         default_cdt_backend
                       else
                         cdt_backend
                       end
      end

      def generate(owner:, state:, terrain_state_summary:, output_plan: nil, feature_context: nil)
        return no_data_refusal if adaptive_state?(state) && state.elevations.any?(&:nil?)

        # Create/adopt generation emits the complete derived grid; edit regeneration may be partial.
        plan = output_plan || TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary
        )
        cdt_result = generate_cdt(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
        return cdt_result if cdt_result

        if plan.execution_strategy == :adaptive_tin
          return generate_adaptive(owner: owner, state: state, output_plan: plan)
        end

        rows = state.dimensions.fetch('rows')
        columns = state.dimensions.fetch('columns')
        vertices = vertices_for(state, columns, rows)
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

      def cdt_enabled?
        !cdt_backend.nil?
      end

      def regenerate(owner:, state:, terrain_state_summary:, output_plan: nil, feature_context: nil)
        unsupported = unsupported_child_types(owner.entities)
        return unsupported_children_refusal(unsupported) unless unsupported.empty?
        return no_data_refusal if adaptive_state?(state) && state.elevations.any?(&:nil?)

        plan = output_plan || TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: terrain_state_summary
        )
        cdt_result = regenerate_cdt(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
        return cdt_result if cdt_result

        if plan.execution_strategy == :adaptive_tin
          return regenerate_adaptive(owner: owner, state: state, output_plan: plan)
        end

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

      attr_reader :length_converter, :cdt_backend

      def default_cdt_backend?(candidate)
        candidate.equal?(DEFAULT_CDT_BACKEND)
      end

      def default_cdt_backend
        return nil unless DEFAULT_CDT_ENABLED

        TerrainCdtBackend.new
      end

      def generate_cdt(owner:, state:, terrain_state_summary:, plan:, feature_context:)
        return nil unless cdt_regeneration_eligible?(plan, feature_context)

        result = cdt_backend.build(
          state: feature_context[:terrainState] || feature_context['terrainState'] || state,
          feature_geometry: feature_context[:featureGeometry] || feature_context['featureGeometry'],
          primitive_request: feature_context[:primitiveRequest] ||
            feature_context['primitiveRequest'] ||
            {},
          state_digest: terrain_state_summary.fetch(:digest, nil)
        )
      rescue StandardError
        nil
      else
        return nil unless result.fetch(:status) == 'accepted'

        emit_cdt_mesh_via_builder(owner.entities, result.fetch(:mesh))
        cdt_generated_result(result, terrain_state_summary)
      end

      def generated_result(output_plan)
        {
          outcome: 'generated',
          summary: output_plan.to_summary
        }
      end

      def adaptive_state?(state)
        state.respond_to?(:tiles) && state.respond_to?(:tile_size)
      end

      def regenerate_cdt(owner:, state:, terrain_state_summary:, plan:, feature_context:)
        return nil unless cdt_regeneration_eligible?(plan, feature_context)

        result = cdt_backend.build(
          state: feature_context[:terrainState] || feature_context['terrainState'] || state,
          feature_geometry: feature_context[:featureGeometry] || feature_context['featureGeometry'],
          primitive_request: feature_context[:primitiveRequest] ||
            feature_context['primitiveRequest'] ||
            {},
          state_digest: terrain_state_summary.fetch(:digest, nil)
        )
      rescue StandardError
        nil
      else
        return nil unless result.fetch(:status) == 'accepted'

        erase_entities(owner.entities, derived_output_entities(owner.entities))
        emit_cdt_mesh_via_builder(owner.entities, result.fetch(:mesh))
        cdt_generated_result(result, terrain_state_summary)
      end

      def cdt_regeneration_eligible?(plan, feature_context)
        return false unless cdt_backend
        return false unless feature_context
        return false if plan.intent == :dirty_window && !cdt_feature_geometry?(feature_context)

        true
      end

      def cdt_feature_geometry?(feature_context)
        feature_geometry = feature_context[:featureGeometry] || feature_context['featureGeometry']
        feature_geometry.respond_to?(:feature_geometry_digest) &&
          feature_geometry.respond_to?(:protected_regions) &&
          feature_geometry.respond_to?(:reference_segments)
      end

      def cdt_generated_result(result, terrain_state_summary)
        mesh = result.fetch(:mesh)
        {
          outcome: 'generated',
          summary: {
            derivedMesh: {
              meshType: 'adaptive_tin',
              vertexCount: mesh.fetch(:vertices).length,
              faceCount: mesh.fetch(:triangles).length,
              derivedFromStateDigest: terrain_state_summary.fetch(:digest, nil)
            }
          }
        }
      end

      def emit_cdt_mesh_via_builder(entities, mesh)
        return emit_cdt_mesh(entities, mesh) unless entities.respond_to?(:build)

        entities.build { |builder| emit_cdt_mesh(builder, mesh) }
      end

      def emit_cdt_mesh(face_target, mesh)
        vertices = mesh.fetch(:vertices).map do |vertex|
          vertex.map { |coordinate| internal_length(coordinate) }
        end
        mesh.fetch(:triangles).each do |triangle|
          add_derived_face(
            face_target,
            *triangle.map { |index| vertices.fetch(index) },
            ownership: nil
          )
        end
      end

      def generate_adaptive(owner:, state:, output_plan:)
        emit_adaptive_faces_via_builder(owner.entities, state, output_plan.adaptive_cells)
        generated_result(output_plan)
      end

      def regenerate_adaptive(owner:, state:, output_plan:)
        return no_data_refusal if state.elevations.any?(&:nil?)

        erase_entities(owner.entities, derived_output_entities(owner.entities))
        generate_adaptive(owner: owner, state: state, output_plan: output_plan)
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

      def emit_adaptive_faces_via_builder(entities, state, cells)
        return emit_adaptive_faces(entities, state, cells) unless entities.respond_to?(:build)

        entities.build do |builder|
          emit_adaptive_faces(builder, state, cells)
        end
      end

      def emit_adaptive_faces(face_target, state, cells)
        cells.each do |cell|
          add_adaptive_cell_triangles(face_target, state, cell)
        end
      end

      def add_adaptive_cell_triangles(entities, state, cell)
        cell.fetch(:emission_triangles).each do |triangle|
          add_derived_face(
            entities,
            *triangle.map { |vertex| adaptive_vertex_for_planned_point(state, vertex) },
            ownership: nil
          )
        end
      end

      def adaptive_vertex_for_planned_point(state, point)
        column, row = point
        return adaptive_vertex_at(state, column, row) if column.is_a?(Integer) && row.is_a?(Integer)

        adaptive_center_vertex_at(state, point)
      end

      def adaptive_vertex_at(state, column, row)
        origin = state.origin
        spacing = state.spacing
        index = (row * state.dimensions.fetch('columns')) + column
        [
          internal_length(origin.fetch('x') + (column * spacing.fetch('x'))),
          internal_length(origin.fetch('y') + (row * spacing.fetch('y'))),
          internal_length(state.elevations.fetch(index))
        ]
      end

      def adaptive_center_vertex_at(state, center)
        column, row = center
        origin = state.origin
        spacing = state.spacing
        [
          internal_length(origin.fetch('x') + (column * spacing.fetch('x'))),
          internal_length(origin.fetch('y') + (row * spacing.fetch('y'))),
          internal_length(fitted_adaptive_elevation_at(state, column, row))
        ]
      end

      def fitted_adaptive_elevation_at(state, column, row)
        min_column = column.floor
        min_row = row.floor
        max_column = column.ceil
        max_row = row.ceil
        x_ratio = max_column == min_column ? 0.0 : column - min_column
        y_ratio = max_row == min_row ? 0.0 : row - min_row
        columns = state.dimensions.fetch('columns')
        z00 = state.elevations.fetch((min_row * columns) + min_column)
        z10 = state.elevations.fetch((min_row * columns) + max_column)
        z01 = state.elevations.fetch((max_row * columns) + min_column)
        z11 = state.elevations.fetch((max_row * columns) + max_column)
        bottom = z00 + ((z10 - z00) * x_ratio)
        top = z01 + ((z11 - z01) * x_ratio)
        bottom + ((top - bottom) * y_ratio)
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
        entity.hidden = true if entity.is_a?(Sketchup::Edge) && entity.respond_to?(:hidden=)
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

      def no_data_refusal
        {
          outcome: 'refused',
          refusal: {
            code: 'adaptive_output_generation_failed',
            message: 'Adaptive terrain output cannot be generated from no-data samples.',
            details: { category: 'no_data_samples' }
          }
        }
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
