# frozen_string_literal: true

require 'set'

require_relative '../../semantic/length_converter'
require_relative 'patch_lifecycle/patch_registry_store'
require_relative 'patch_lifecycle/patch_window_resolver'
require_relative 'patch_lifecycle/patch_timing'
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
      OUTPUT_KIND_KEY = 'outputKind'
      ADAPTIVE_PATCH_MESH_OUTPUT_KIND = 'adaptive_patch_mesh'
      ADAPTIVE_PATCH_FACE_OUTPUT_KIND = 'adaptive_patch_face'
      ADAPTIVE_PATCH_REGISTRY_KEY = 'adaptivePatchRegistry'
      ADAPTIVE_PATCH_ID_KEY = 'adaptivePatchId'
      ADAPTIVE_PATCH_FACE_INDEX_KEY = 'adaptivePatchFaceIndex'
      ADAPTIVE_POLICY_FINGERPRINT_KEY = 'adaptiveOutputPolicyFingerprint'
      REPLACEMENT_BATCH_ID_KEY = 'replacementBatchId'
      TERRAIN_STATE_DIGEST_KEY = 'terrainStateDigest'
      TERRAIN_STATE_REVISION_KEY = 'terrainStateRevision'
      FACE_COUNT_KEY = 'faceCount'
      CDT_PATCH_OUTPUT_KIND = 'cdt_patch_face'
      CDT_OWNERSHIP_SCHEMA_VERSION_KEY = 'cdtOwnershipSchemaVersion'
      CDT_PATCH_DOMAIN_DIGEST_KEY = 'cdtPatchDomainDigest'
      CDT_REPLACEMENT_BATCH_ID_KEY = 'cdtReplacementBatchId'
      CDT_PATCH_FACE_INDEX_KEY = 'cdtPatchFaceIndex'
      CDT_BORDER_SIDE_KEY = 'cdtBorderSide'
      CDT_BORDER_SPAN_ID_KEY = 'cdtBorderSpanId'
      CDT_BORDER_SIDE_DEFINITIONS = [
        ['west', 0, :min],
        ['east', 0, :max],
        ['south', 1, :min],
        ['north', 1, :max]
      ].freeze
      DEFAULT_CDT_BACKEND = Object.new.freeze
      DEFAULT_CDT_ENABLED = false

      def initialize(
        length_converter: Semantic::LengthConverter.new,
        cdt_backend: DEFAULT_CDT_BACKEND,
        cdt_patch_replacement_provider: nil,
        seam_validator: nil
      )
        @length_converter = length_converter
        @cdt_backend = if default_cdt_backend?(cdt_backend)
                         default_cdt_backend
                       else
                         cdt_backend
                       end
        @cdt_patch_replacement_provider = cdt_patch_replacement_provider
        @seam_validator = seam_validator
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
        !cdt_backend.nil? || !cdt_patch_replacement_provider.nil?
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

      attr_reader :length_converter, :cdt_backend, :cdt_patch_replacement_provider,
                  :seam_validator

      def default_cdt_backend?(candidate)
        candidate.equal?(DEFAULT_CDT_BACKEND)
      end

      def default_cdt_backend
        return nil unless DEFAULT_CDT_ENABLED

        TerrainCdtBackend.new
      end

      def generate_cdt(owner:, state:, terrain_state_summary:, plan:, feature_context:)
        return nil unless cdt_backend
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
        patch_attempt = cdt_patch_regeneration_attempt(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
        return nil if patch_attempt == :fallback
        return patch_attempt if patch_attempt

        result = build_global_cdt_result(
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
        return nil unless result&.fetch(:status) == 'accepted'

        erase_entities(owner.entities, derived_output_entities(owner.entities))
        emit_cdt_mesh_via_builder(owner.entities, result.fetch(:mesh))
        cdt_generated_result(result, terrain_state_summary)
      end

      def build_global_cdt_result(state:, terrain_state_summary:, plan:, feature_context:)
        return nil unless global_cdt_regeneration_eligible?(plan, feature_context)

        cdt_backend.build(
          state: feature_context[:terrainState] || feature_context['terrainState'] || state,
          feature_geometry: feature_context[:featureGeometry] || feature_context['featureGeometry'],
          primitive_request: feature_context[:primitiveRequest] ||
            feature_context['primitiveRequest'] ||
            {},
          state_digest: terrain_state_summary.fetch(:digest, nil)
        )
      rescue StandardError
        nil
      end

      def cdt_patch_regeneration_attempt(owner:, state:, terrain_state_summary:, plan:,
                                         feature_context:)
        return nil unless cdt_patch_replacement_eligible?(plan, feature_context)

        regenerate_cdt_patch(
          owner: owner,
          state: state,
          terrain_state_summary: terrain_state_summary,
          plan: plan,
          feature_context: feature_context
        )
      end

      def global_cdt_regeneration_eligible?(plan, feature_context)
        cdt_backend && cdt_regeneration_eligible?(plan, feature_context)
      end

      def cdt_regeneration_eligible?(plan, feature_context)
        return false unless feature_context
        return false if cdt_participation_skipped?(feature_context)
        return false if plan.intent == :dirty_window && !cdt_feature_geometry?(feature_context)

        true
      end

      def cdt_patch_replacement_eligible?(plan, feature_context)
        # MTA-34 retained infrastructure: this must stay dormant until MTA-35
        # supplies stable CDT-owned patch output and injects a real provider.
        return false unless cdt_patch_replacement_provider
        return false unless plan.intent == :dirty_window

        cdt_regeneration_eligible?(plan, feature_context)
      end

      def regenerate_cdt_patch(owner:, state:, terrain_state_summary:, plan:, feature_context:)
        mutation_started = false
        replacement = cdt_patch_replacement_provider.build(
          state: state,
          feature_geometry: feature_context[:featureGeometry] || feature_context['featureGeometry'],
          output_plan: plan,
          terrain_state_summary: terrain_state_summary,
          feature_context: feature_context
        )
        return :fallback unless replacement_accepted?(replacement)

        ownership = owned_cdt_patch_faces(owner.entities, replacement.patch_domain_digest)
        return cdt_ownership_refusal if ownership.fetch(:outcome) == :refused
        return :fallback unless ownership.fetch(:outcome) == :owned

        seam = cdt_patch_seam_validator.validate(
          replacement_spans: replacement.border_spans,
          preserved_neighbor_spans: preserved_cdt_neighbor_spans(
            owner.entities,
            replacement.patch_domain_digest
          )
        )
        return :fallback unless seam.fetch(:status) == 'passed'

        mutation_started = true
        erase_partial_output(owner.entities, ownership.fetch(:faces))
        emit_cdt_mesh_via_builder(
          owner.entities,
          replacement.mesh,
          ownership: cdt_patch_ownership_context(replacement)
        )
        cleanup_orphan_derived_edges(owner.entities)
        cdt_generated_result({ mesh: replacement.mesh }, terrain_state_summary)
      rescue StandardError
        raise if mutation_started

        :fallback
      end

      def replacement_accepted?(replacement)
        replacement.respond_to?(:accepted?) && replacement.accepted?
      end

      def cdt_patch_seam_validator
        return seam_validator if seam_validator

        require_relative 'cdt/patches/patch_cdt_seam_validator'
        @seam_validator = PatchCdtSeamValidator.new
      end

      def cdt_participation_skipped?(feature_context)
        participation = feature_context[:cdtParticipation] || feature_context['cdtParticipation']
        return false unless participation.is_a?(Hash)

        (participation[:status] || participation['status']) == 'skip'
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

      def emit_cdt_mesh_via_builder(entities, mesh, ownership: nil)
        unless entities.respond_to?(:build)
          return emit_cdt_mesh(entities, mesh,
                               ownership: ownership)
        end

        entities.build { |builder| emit_cdt_mesh(builder, mesh, ownership: ownership) }
      end

      def emit_cdt_mesh(face_target, mesh, ownership:)
        vertices = mesh.fetch(:vertices).map do |vertex|
          vertex.map { |coordinate| internal_length(coordinate) }
        end
        mesh.fetch(:triangles).each_with_index do |triangle, index|
          add_derived_face(
            face_target,
            *triangle.map { |index| vertices.fetch(index) },
            ownership: cdt_face_ownership(ownership, index, vertices, triangle)
          )
        end
      end

      def generate_adaptive(owner:, state:, output_plan:)
        if output_plan.adaptive_patch_policy
          return generate_adaptive_patches(
            owner: owner,
            state: state,
            output_plan: output_plan
          )
        end

        emit_adaptive_faces_via_builder(owner.entities, state, output_plan.adaptive_cells)
        generated_result(output_plan)
      end

      def regenerate_adaptive(owner:, state:, output_plan:)
        return no_data_refusal if state.elevations.any?(&:nil?)

        if output_plan.adaptive_patch_policy
          return regenerate_adaptive_patches(
            owner: owner,
            state: state,
            output_plan: output_plan
          )
        end

        erase_entities(owner.entities, derived_output_entities(owner.entities))
        generate_adaptive(owner: owner, state: state, output_plan: output_plan)
      end

      def generate_adaptive_patches(owner:, state:, output_plan:)
        erase_entities(owner.entities, derived_output_entities(owner.entities))
        mesh = owner.entities.add_group
        mark_adaptive_patch_mesh(
          mesh,
          batch_id: adaptive_replacement_batch_id(output_plan),
          output_plan: output_plan,
          face_count: 0
        )
        emit_adaptive_patch_batch(
          owner: owner,
          mesh: mesh,
          state: state,
          output_plan: output_plan,
          patches: output_plan.adaptive_patch_policy.patch_domains(state.dimensions)
        )
        mark_adaptive_patch_mesh(
          mesh,
          batch_id: adaptive_replacement_batch_id(output_plan),
          output_plan: output_plan,
          face_count: entity_faces(mesh.entities).length
        )
        generated_result(output_plan)
      end

      def regenerate_adaptive_patches(owner:, state:, output_plan:)
        return generate_adaptive_patches(owner: owner, state: state, output_plan: output_plan) if
          output_plan.intent != :dirty_window

        timing = PatchLifecycle::PatchTiming.new
        resolver = PatchLifecycle::PatchWindowResolver.new(
          policy: output_plan.adaptive_patch_policy,
          dimensions: state.dimensions
        )
        resolution = timing.measure(:dirty_window_mapping) do
          resolver.resolve(cell_window: output_plan.cell_window)
        end
        mesh = adaptive_patch_mesh(owner.entities)
        unless mesh
          return generate_adaptive_patches(owner: owner, state: state, output_plan: output_plan)
        end

        unsupported = unsupported_child_types(mesh.entities)
        return unsupported_children_refusal(unsupported) unless unsupported.empty?

        ownership = timing.measure(:ownership_lookup) do
          owned_adaptive_patch_faces(
            owner: owner,
            entities: mesh.entities,
            patch_ids: resolution.fetch(:replacementPatchIds),
            output_plan: output_plan
          )
        end
        return cdt_ownership_refusal if ownership.fetch(:outcome) == :refused
        return generate_adaptive_patches(owner: owner, state: state, output_plan: output_plan) if
          ownership.fetch(:outcome) == :fallback

        patches = resolution.fetch(:replacementPatches)
        planned = planned_adaptive_patch_batch(
          state: state,
          output_plan: output_plan,
          patches: patches
        )
        timing.measure(:mutation) do
          erase_partial_output(mesh.entities, ownership.fetch(:faces))
          emit_planned_adaptive_patch_faces(mesh.entities, planned.fetch(:faces))
          cleanup_orphan_derived_edges(mesh.entities)
          mark_adaptive_patch_mesh(
            mesh,
            batch_id: adaptive_replacement_batch_id(output_plan),
            output_plan: output_plan,
            face_count: entity_faces(mesh.entities).length
          )
          write_adaptive_patch_registry(
            owner: owner,
            output_plan: output_plan,
            patches: planned.fetch(:patches)
          )
        end
        generated_result(output_plan)
      end

      def adaptive_patch_mesh(entities)
        entities.to_a.find do |entity|
          derived_output?(entity) &&
            output_attribute(entity, OUTPUT_KIND_KEY) == ADAPTIVE_PATCH_MESH_OUTPUT_KIND &&
            entity.respond_to?(:entities)
        end
      end

      def adaptive_patch_faces(entities, patch_ids)
        wanted = patch_ids.to_set
        entity_faces(entities).select do |face|
          output_attribute(face, OUTPUT_KIND_KEY) == ADAPTIVE_PATCH_FACE_OUTPUT_KIND &&
            wanted.include?(output_attribute(face, ADAPTIVE_PATCH_ID_KEY))
        end
      end

      def owned_adaptive_patch_faces(owner:, entities:, patch_ids:, output_plan:)
        faces = adaptive_patch_faces(entities, patch_ids)
        return fallback_ownership(:missing_ownership) if faces.empty?

        registry = patch_registry_store.read(owner)
        return { outcome: :refused, reason: :registry_invalid } unless
          registry.fetch(:status) == 'valid'

        patch_face_counts = registry.fetch(:patches, []).to_h do |patch|
          [patch.fetch(:patchId), patch.fetch(:faceCount)]
        end
        faces_by_patch = faces.group_by { |face| output_attribute(face, ADAPTIVE_PATCH_ID_KEY) }
        patch_ids.each do |patch_id|
          patch_faces = faces_by_patch.fetch(patch_id, [])
          return { outcome: :refused, reason: :ownership_integrity_mismatch } unless
            adaptive_patch_ownership_complete?(
              patch_faces,
              expected_face_count: patch_face_counts.fetch(patch_id, nil),
              output_plan: output_plan
            )
        end

        { outcome: :owned, faces: faces }
      end

      def adaptive_patch_ownership_complete?(faces, expected_face_count:, output_plan:)
        return false unless expected_face_count.is_a?(Integer) && expected_face_count.positive?
        return false unless faces.length == expected_face_count

        indexes = []
        faces.each do |face|
          return false unless adaptive_owned_face_complete?(face, output_plan)

          indexes << output_attribute(face, ADAPTIVE_PATCH_FACE_INDEX_KEY)
        end
        indexes.sort == (0...expected_face_count).to_a
      end

      def adaptive_owned_face_complete?(face, output_plan)
        output_attribute(face, DERIVED_OUTPUT_KEY) == true &&
          output_attribute(face, OUTPUT_KIND_KEY) == ADAPTIVE_PATCH_FACE_OUTPUT_KIND &&
          !output_attribute(face, ADAPTIVE_PATCH_ID_KEY).nil? &&
          output_attribute(face, ADAPTIVE_PATCH_FACE_INDEX_KEY).is_a?(Integer) &&
          !output_attribute(face, REPLACEMENT_BATCH_ID_KEY).nil? &&
          output_attribute(face, TERRAIN_STATE_DIGEST_KEY).is_a?(String) &&
          output_attribute(face, ADAPTIVE_POLICY_FINGERPRINT_KEY) ==
            output_plan.adaptive_patch_policy.output_policy_fingerprint
      end

      def emit_adaptive_patch_batch(owner:, mesh:, state:, output_plan:, patches:)
        planned = planned_adaptive_patch_batch(
          state: state,
          output_plan: output_plan,
          patches: patches
        )
        emit_planned_adaptive_patch_faces(mesh.entities, planned.fetch(:faces))
        write_adaptive_patch_registry(
          owner: owner,
          output_plan: output_plan,
          patches: planned.fetch(:patches)
        )
      end

      def planned_adaptive_patch_batch(state:, output_plan:, patches:)
        patch_records = []
        batch_id = adaptive_replacement_batch_id(output_plan)
        policy_fingerprint = output_plan.adaptive_patch_policy.output_policy_fingerprint
        vertex_cache = {}
        face_plans = patches.flat_map do |patch|
          cells = adaptive_cells_for_patch(output_plan.adaptive_cells, patch)
          next [] if cells.empty?

          faces = planned_adaptive_patch_faces(
            state,
            cells,
            patch_id: patch.fetch(:patchId),
            batch_id: batch_id,
            state_digest: output_plan.state_digest,
            policy_fingerprint: policy_fingerprint,
            vertex_cache: vertex_cache
          )
          patch_records << adaptive_registry_patch_record(
            patch: patch,
            batch_id: batch_id,
            face_count: faces.length
          )
          faces
        end
        { faces: face_plans, patches: patch_records }
      end

      def emit_planned_adaptive_patch_faces(entities, faces)
        emitted_faces = []
        unless entities.respond_to?(:build)
          faces.each do |face|
            emitted_faces << add_derived_face(
              entities,
              *face.fetch(:points),
              ownership: face.fetch(:ownership),
              mark_edges: false
            )
          end
          mark_unique_derived_edges(emitted_faces)
          return emitted_faces
        end

        entities.build do |builder|
          faces.each do |face|
            emitted_faces << add_derived_face(
              builder,
              *face.fetch(:points),
              ownership: face.fetch(:ownership),
              mark_edges: false
            )
          end
          mark_unique_derived_edges(emitted_faces)
        end
      end

      def planned_adaptive_patch_faces(
        state,
        cells,
        patch_id:,
        batch_id:,
        state_digest:,
        policy_fingerprint:,
        vertex_cache:
      )
        face_index = 0
        cells.flat_map do |cell|
          cell.fetch(:emission_triangles).map do |triangle|
            plan = {
              points: triangle.map do |vertex|
                vertex_cache[vertex] ||= adaptive_vertex_for_planned_point(state, vertex)
              end,
              ownership: {
                kind: :adaptive_patch,
                patch_id: patch_id,
                patch_face_index: face_index,
                replacement_batch_id: batch_id,
                state_digest: state_digest,
                policy_fingerprint: policy_fingerprint
              }
            }
            face_index += 1
            plan
          end
        end
      end

      def adaptive_cells_for_patch(cells, patch)
        bounds = patch.fetch(:cell_bounds)
        cells.select do |cell|
          cell.fetch(:min_column) >= bounds.fetch(:min_column) &&
            cell.fetch(:min_row) >= bounds.fetch(:min_row) &&
            cell.fetch(:max_column) <= bounds.fetch(:max_column) + 1 &&
            cell.fetch(:max_row) <= bounds.fetch(:max_row) + 1
        end
      end

      def entity_faces(entities)
        return entities.faces if entities.respond_to?(:faces)

        entities.grep(Sketchup::Face)
      end

      def write_adaptive_patch_registry(owner:, output_plan:, patches:)
        store = patch_registry_store
        existing = store.read(owner)
        retained = existing.fetch(:patches, []).reject do |patch|
          patches.any? { |new_patch| new_patch.fetch(:patchId) == patch.fetch(:patchId) }
        end
        store.write!(
          owner: owner,
          registry: {
            outputPolicyFingerprint: output_plan.adaptive_patch_policy.output_policy_fingerprint,
            stateDigest: output_plan.state_digest,
            stateRevision: output_plan.state_revision,
            ownerTransformSignature: nil,
            patches: retained + patches
          }
        )
      end

      def adaptive_registry_patch_record(patch:, batch_id:, face_count:)
        {
          patchId: patch.fetch(:patchId),
          bounds: patch.fetch(:bounds),
          outputBounds: patch.fetch(:bounds),
          replacementBatchId: batch_id,
          faceCount: face_count,
          status: 'valid'
        }
      end

      def patch_registry_store
        PatchLifecycle::PatchRegistryStore.new(registry_key: ADAPTIVE_PATCH_REGISTRY_KEY)
      end

      def adaptive_replacement_batch_id(output_plan)
        "adaptive-batch-#{output_plan.state_digest}"
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

      def add_derived_face(entities, *points, ownership:, mark_edges: true)
        face = entities.add_face(*points)
        normalize_upward_face!(face)
        mark_derived(face, ownership: ownership, mark_edges: mark_edges)
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

      def mark_derived(entity, ownership: nil, mark_edges: true)
        return entity unless entity.respond_to?(:set_attribute)

        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, DERIVED_OUTPUT_KEY, true)
        entity.hidden = true if entity.is_a?(Sketchup::Edge) && entity.respond_to?(:hidden=)
        mark_ownership(entity, ownership) if ownership
        mark_derived_edges(entity) if mark_edges
        entity
      end

      def mark_ownership(entity, ownership)
        return mark_cdt_ownership(entity, ownership) if ownership[:kind] == :cdt_patch
        return mark_adaptive_patch_ownership(entity, ownership) if
          ownership[:kind] == :adaptive_patch

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

      def mark_adaptive_patch_mesh(mesh, batch_id:, output_plan:, face_count:)
        mark_derived(mesh)
        mesh.set_attribute(DERIVED_OUTPUT_DICTIONARY, OUTPUT_KIND_KEY,
                           ADAPTIVE_PATCH_MESH_OUTPUT_KIND)
        mesh.set_attribute(DERIVED_OUTPUT_DICTIONARY, REPLACEMENT_BATCH_ID_KEY, batch_id)
        mesh.set_attribute(DERIVED_OUTPUT_DICTIONARY, TERRAIN_STATE_DIGEST_KEY,
                           output_plan.state_digest)
        mesh.set_attribute(DERIVED_OUTPUT_DICTIONARY, TERRAIN_STATE_REVISION_KEY,
                           output_plan.state_revision)
        mesh.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          ADAPTIVE_POLICY_FINGERPRINT_KEY,
          output_plan.adaptive_patch_policy.output_policy_fingerprint
        )
        mesh.set_attribute(DERIVED_OUTPUT_DICTIONARY, FACE_COUNT_KEY, face_count)
      end

      def mark_adaptive_patch_ownership(entity, ownership)
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, OUTPUT_KIND_KEY,
                             ADAPTIVE_PATCH_FACE_OUTPUT_KIND)
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, ADAPTIVE_PATCH_ID_KEY,
                             ownership.fetch(:patch_id))
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, ADAPTIVE_PATCH_FACE_INDEX_KEY,
                             ownership.fetch(:patch_face_index))
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, REPLACEMENT_BATCH_ID_KEY,
                             ownership.fetch(:replacement_batch_id))
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, TERRAIN_STATE_DIGEST_KEY,
                             ownership.fetch(:state_digest))
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, ADAPTIVE_POLICY_FINGERPRINT_KEY,
                             ownership.fetch(:policy_fingerprint))
      end

      def mark_cdt_ownership(entity, ownership)
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, OUTPUT_KIND_KEY, CDT_PATCH_OUTPUT_KIND)
        entity.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          CDT_OWNERSHIP_SCHEMA_VERSION_KEY,
          OUTPUT_SCHEMA_VERSION
        )
        entity.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          CDT_PATCH_DOMAIN_DIGEST_KEY,
          ownership.fetch(:patch_domain_digest)
        )
        entity.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          CDT_REPLACEMENT_BATCH_ID_KEY,
          ownership.fetch(:replacement_batch_id)
        )
        entity.set_attribute(
          DERIVED_OUTPUT_DICTIONARY,
          CDT_PATCH_FACE_INDEX_KEY,
          ownership.fetch(:patch_face_index)
        )
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, CDT_BORDER_SIDE_KEY, ownership[:side])
        entity.set_attribute(DERIVED_OUTPUT_DICTIONARY, CDT_BORDER_SPAN_ID_KEY, ownership[:span_id])
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

      def owned_cdt_patch_faces(entities, patch_domain_digest)
        faces = derived_output_entities(entities).select do |entity|
          derived_face_entity?(entity) &&
            output_attribute(entity, OUTPUT_KIND_KEY) == CDT_PATCH_OUTPUT_KIND &&
            output_attribute(entity, CDT_PATCH_DOMAIN_DIGEST_KEY) == patch_domain_digest
        end
        return fallback_ownership(:missing_ownership) if faces.empty?

        by_index = {}
        faces.each do |face|
          return { outcome: :refused, reason: :ownership_integrity_mismatch } unless
            cdt_owned_face_complete?(face)

          index = output_attribute(face, CDT_PATCH_FACE_INDEX_KEY)
          return { outcome: :refused, reason: :ownership_integrity_mismatch } if
            by_index.key?(index)

          by_index[index] = face
        end
        { outcome: :owned, faces: faces }
      end

      def cdt_owned_face_complete?(face)
        [
          CDT_OWNERSHIP_SCHEMA_VERSION_KEY,
          CDT_PATCH_DOMAIN_DIGEST_KEY,
          CDT_REPLACEMENT_BATCH_ID_KEY,
          CDT_PATCH_FACE_INDEX_KEY
        ].all? { |key| !output_attribute(face, key).nil? }
      end

      def preserved_cdt_neighbor_spans(entities, patch_domain_digest)
        # MTA-35 must replace this one-face-per-side snapshot with ordered seam
        # stitching that can represent multiple preserved neighbor spans.
        derived_output_entities(entities).filter_map do |entity|
          next unless derived_face_entity?(entity)
          next unless output_attribute(entity, OUTPUT_KIND_KEY) == CDT_PATCH_OUTPUT_KIND
          next if output_attribute(entity, CDT_PATCH_DOMAIN_DIGEST_KEY) == patch_domain_digest

          side = output_attribute(entity, CDT_BORDER_SIDE_KEY)
          next unless side

          {
            side: side,
            spanId: output_attribute(entity, CDT_BORDER_SPAN_ID_KEY) || "#{side}-0",
            patchDomainDigest: output_attribute(entity, CDT_PATCH_DOMAIN_DIGEST_KEY),
            fresh: cdt_owned_face_complete?(entity),
            protectedBoundaryCrossing: false,
            vertices: border_points_for_side(entity_points(entity), side)
          }
        end
      end

      def border_points_for_side(points, side)
        axis = %w[east west].include?(side) ? 0 : 1
        value = if %w[east north].include?(side)
                  points.map { |point| point[axis] }.max
                else
                  points.map { |point| point[axis] }.min
                end
        points.select { |point| (point[axis].to_f - value.to_f).abs <= 1e-6 }
              .sort_by { |point| axis.zero? ? point[1] : point[0] }
      end

      def entity_points(entity)
        return entity.points if entity.respond_to?(:points)
        return entity.vertices.map { |vertex| point_to_a(vertex.position) } if
          entity.respond_to?(:vertices)

        []
      end

      def point_to_a(point)
        [
          length_converter.internal_to_public_meters(point.x),
          length_converter.internal_to_public_meters(point.y),
          length_converter.internal_to_public_meters(point.z)
        ]
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

      def cdt_patch_ownership_context(replacement)
        {
          kind: :cdt_patch,
          patch_domain_digest: replacement.patch_domain_digest,
          replacement_batch_id: replacement.replacement_batch_id
        }
      end

      def cdt_face_ownership(ownership, index, vertices, triangle)
        return nil unless ownership

        side = cdt_border_side_for(vertices, triangle)
        ownership.merge(
          patch_face_index: index,
          side: side,
          span_id: side ? "#{side}-0" : nil
        )
      end

      def cdt_border_side_for(vertices, triangle)
        points = triangle.map { |vertex_index| vertices.fetch(vertex_index) }
        bounds = mesh_bounds(vertices)
        definition = CDT_BORDER_SIDE_DEFINITIONS.find do |_side, axis, limit|
          values = points.map { |point| point[axis] }
          values.count { |value| value == bounds.fetch(axis).fetch(limit) } >= 2
        end
        definition&.first
      end

      def mesh_bounds(vertices)
        {
          0 => { min: vertices.map { |point| point[0] }.min,
                 max: vertices.map { |point| point[0] }.max },
          1 => { min: vertices.map { |point| point[1] }.min,
                 max: vertices.map { |point| point[1] }.max }
        }
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

        edges.each { |edge| mark_derived(edge, mark_edges: false) }
      end

      def mark_unique_derived_edges(faces)
        edges = Set.new
        faces.each do |face|
          next unless face.respond_to?(:edges)

          face.edges.each { |edge| edges.add(edge) }
        end
        edges.each { |edge| mark_derived(edge, mark_edges: false) }
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

      def cdt_ownership_refusal
        {
          outcome: 'refused',
          refusal: {
            code: 'terrain_output_ownership_invalid',
            message: 'Terrain output ownership metadata is invalid.',
            details: {
              category: 'derived_output_ownership',
              action: 'recreate the managed terrain output'
            }
          }
        }
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/ClassLength
  end
end
