# frozen_string_literal: true

require_relative '../runtime/tool_response'
require_relative '../scene_query/target_reference_resolver'
require_relative '../semantic/length_converter'
require_relative '../semantic/managed_object_metadata'
require_relative '../semantic/scene_properties'
require_relative 'bounded_grade_edit'
require_relative 'corridor_transition_edit'
require_relative 'create_terrain_surface_request'
require_relative 'edit_terrain_surface_request'
require_relative 'sample_window'
require_relative 'terrain_edit_evidence_builder'
require_relative 'terrain_mesh_generator'
require_relative 'terrain_output_plan'
require_relative 'terrain_repository'
require_relative 'terrain_surface_adoption_sampler'
require_relative 'terrain_surface_evidence_builder'
require_relative 'terrain_surface_state_builder'

module SU_MCP
  module Terrain
    # Public terrain command target for create_terrain_surface and edit_terrain_surface.
    # rubocop:disable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    class TerrainSurfaceCommands
      OPERATION_NAME = 'Create Terrain Surface'
      EDIT_OPERATION_NAME = 'Edit Terrain Surface'
      SEMANTIC_TYPE = 'managed_terrain_surface'
      SCHEMA_VERSION = 1

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        model: Sketchup.active_model,
        validator: nil,
        state_builder: TerrainSurfaceStateBuilder.new,
        repository: TerrainRepository.new,
        mesh_generator: TerrainMeshGenerator.new,
        evidence_builder: TerrainSurfaceEvidenceBuilder.new,
        adoption_sampler: TerrainSurfaceAdoptionSampler.new,
        metadata_writer: Semantic::ManagedObjectMetadata.new,
        scene_properties: Semantic::SceneProperties.new,
        length_converter: Semantic::LengthConverter.new,
        edit_request_validator: nil,
        grade_editor: BoundedGradeEdit.new,
        corridor_editor: CorridorTransitionEdit.new,
        target_resolver: nil,
        edit_evidence_builder: TerrainEditEvidenceBuilder.new
      )
        @model = model
        @validator = validator
        @state_builder = state_builder
        @repository = repository
        @mesh_generator = mesh_generator
        @evidence_builder = evidence_builder
        @adoption_sampler = adoption_sampler
        @metadata_writer = metadata_writer
        @scene_properties = scene_properties
        @length_converter = length_converter
        @edit_request_validator = edit_request_validator
        @grade_editor = grade_editor
        @corridor_editor = corridor_editor
        @target_resolver = target_resolver || TargetReferenceResolver.new
        @edit_evidence_builder = edit_evidence_builder
      end
      # rubocop:enable Metrics/ParameterLists

      def create_terrain_surface(params)
        validation = validate(params)
        return validation if refused?(validation)

        sampled_source = adoption_sample_or_refusal(validation)
        return sampled_source if refused?(sampled_source)

        execute_mutation(validation, sampled_source: sampled_source)
      end

      def edit_terrain_surface(params)
        validation = validate_edit(params)
        return validation if refused?(validation)

        edit_context = prepare_edit_context(validation)
        return edit_context if refused?(edit_context)

        execute_edit_mutation(edit_context)
      end

      private

      attr_reader :model, :validator, :state_builder, :repository, :mesh_generator,
                  :evidence_builder, :adoption_sampler, :metadata_writer, :scene_properties,
                  :length_converter, :edit_request_validator, :grade_editor, :target_resolver,
                  :corridor_editor, :edit_evidence_builder

      def validate(params)
        return validator.validate(params) if validator

        CreateTerrainSurfaceRequest
          .new(params, identity_exists: method(:managed_terrain_identity_exists?))
          .validate
      end

      def validate_edit(params)
        return edit_request_validator.validate(params) if edit_request_validator

        EditTerrainSurfaceRequest.new(params).validate
      end

      def prepare_edit_context(validation)
        owner_result = resolve_terrain_owner(validation.fetch(:params).fetch('targetReference'))
        return owner_result if refused?(owner_result)

        owner = owner_result.fetch(:owner)
        loaded = load_state_or_refusal(owner)
        return loaded if refused?(loaded)

        edit_result = editor_for(validation).apply(
          state: loaded.fetch(:state),
          request: validation.fetch(:params)
        )
        return edit_result if refused?(edit_result)

        {
          validation: validation,
          owner: owner,
          loaded: loaded,
          edit_result: edit_result
        }
      end

      def editor_for(validation)
        mode = validation[:operation_mode] || validation.fetch(:params).dig('operation', 'mode')
        return corridor_editor if mode == 'corridor_transition'

        grade_editor
      end

      def execute_edit_mutation(context)
        operation_started = false
        model.start_operation(EDIT_OPERATION_NAME, true)
        operation_started = true

        saved = save_state_or_refusal(
          context.fetch(:owner),
          context.fetch(:edit_result).fetch(:state)
        )
        return finish_edit_refusal(saved) if refused?(saved)

        output = mesh_generator.regenerate(
          owner: context.fetch(:owner),
          state: context.fetch(:edit_result).fetch(:state),
          terrain_state_summary: saved.fetch(:summary),
          output_plan: edit_output_plan(context, saved)
        )
        return finish_edit_refusal(output_refusal(output)) if refused?(output)

        result = edit_success_response(context, saved, output)
        model.commit_operation
        result
      rescue StandardError
        model.abort_operation if operation_started && model.respond_to?(:abort_operation)
        raise
      end

      def finish_edit_refusal(result)
        model.abort_operation if model.respond_to?(:abort_operation)
        result
      end

      def resolve_terrain_owner(target_reference)
        direct_resolution = direct_managed_terrain_owner_resolution(target_reference)
        return direct_resolution if direct_resolution

        resolution = target_resolver.resolve(target_reference)
        resolution_state = resolution[:resolution] || resolution[:outcome]
        if %w[unique resolved].include?(resolution_state)
          owner = resolution[:entity] || managed_entity_for(target_reference)
          return terrain_target_not_found(target_reference) unless owner
          return unsupported_target_type(owner) unless managed_terrain_owner?(owner)

          { outcome: 'resolved', owner: owner }
        elsif resolution_state == 'ambiguous'
          ToolResponse.refusal(
            code: 'terrain_target_ambiguous',
            message: 'Managed terrain target reference matched multiple entities.',
            details: { targetReference: target_reference }
          )
        else
          terrain_target_not_found(target_reference)
        end
      rescue StandardError => e
        ToolResponse.refusal(
          code: 'terrain_target_not_found',
          message: 'Managed terrain target could not be resolved.',
          details: { targetReference: target_reference, error: e.message }
        )
      end

      def direct_managed_terrain_owner_resolution(target_reference)
        matches = managed_entities.select do |entity|
          managed_entity_matches_reference?(entity, target_reference)
        end
        return nil if matches.empty?
        return terrain_target_ambiguous(target_reference) if matches.length > 1

        owner = matches.first
        return unsupported_target_type(owner) unless managed_terrain_owner?(owner)

        { outcome: 'resolved', owner: owner }
      end

      def managed_entity_matches_reference?(entity, target_reference)
        target_reference.all? do |key, value|
          case key
          when 'sourceElementId'
            entity.get_attribute('su_mcp', 'sourceElementId') == value
          when 'persistentId'
            persistent_id_for(entity) == value.to_s
          when 'entityId'
            entity.respond_to?(:entityID) && entity.entityID.to_s == value.to_s
          else
            false
          end
        end
      end

      def managed_entity_for(target_reference)
        managed_entities.find do |entity|
          managed_entity_matches_reference?(entity, target_reference)
        end
      end

      def managed_terrain_owner?(entity)
        entity.respond_to?(:get_attribute) &&
          entity.get_attribute('su_mcp', 'semanticType') == SEMANTIC_TYPE
      end

      def terrain_target_not_found(target_reference)
        ToolResponse.refusal(
          code: 'terrain_target_not_found',
          message: 'Managed terrain target was not found.',
          details: { targetReference: target_reference }
        )
      end

      def terrain_target_ambiguous(target_reference)
        ToolResponse.refusal(
          code: 'terrain_target_ambiguous',
          message: 'Managed terrain target reference matched multiple entities.',
          details: { targetReference: target_reference }
        )
      end

      def unsupported_target_type(entity)
        ToolResponse.refusal(
          code: 'unsupported_target_type',
          message: 'Target is not a managed terrain surface.',
          details: {
            semanticType: entity.get_attribute('su_mcp', 'semanticType')
          }
        )
      end

      def load_state_or_refusal(owner)
        loaded = repository.load(owner)
        return loaded if loaded.fetch(:outcome) == 'loaded'

        ToolResponse.refusal(
          code: 'terrain_state_load_failed',
          message: 'Terrain state could not be loaded.',
          details: loaded[:refusal] || loaded
        )
      end

      def output_refusal(output)
        refusal = output.fetch(:refusal)
        ToolResponse.refusal(
          code: refusal.fetch(:code),
          message: refusal.fetch(:message),
          details: refusal[:details]
        )
      end

      def edit_output_plan(context, saved)
        TerrainOutputPlan.dirty_window(
          state: context.fetch(:edit_result).fetch(:state),
          terrain_state_summary: saved.fetch(:summary),
          previous_terrain_state_summary: context.fetch(:loaded).fetch(:summary),
          window: changed_region_window(context.fetch(:edit_result).fetch(:diagnostics))
        )
      end

      def changed_region_window(diagnostics)
        # Edit kernels own changed-region diagnostics; commands translate them into output intent.
        changed_region = diagnostics.fetch(:changedRegion)
        min = changed_region.fetch(:min)
        max = changed_region.fetch(:max)
        SampleWindow.new(
          min_column: min.fetch(:column),
          min_row: min.fetch(:row),
          max_column: max.fetch(:column),
          max_row: max.fetch(:row)
        )
      end

      def edit_success_response(context, saved, output)
        state = context.fetch(:edit_result).fetch(:state)
        params = context.fetch(:validation).fetch(:params)
        edit_evidence_builder.build_success(
          outcome: 'edited',
          owner_reference: owner_reference(
            context.fetch(:owner),
            edit_owner_reference_params(params)
          ),
          terrain_state_summary: edit_terrain_state_summary(context.fetch(:loaded), state, saved),
          output_summary: output.fetch(:summary),
          edit_summary: edit_summary(params, context.fetch(:edit_result).fetch(:diagnostics)),
          diagnostics: context.fetch(:edit_result).fetch(:diagnostics),
          metadata: existing_owner_metadata(context.fetch(:owner)),
          sample_limit: edit_sample_evidence_limit(params)
        )
      end

      def edit_sample_evidence_limit(params)
        output_options = params.fetch('outputOptions', {})
        return 0 unless output_options.fetch('includeSampleEvidence', false)

        output_options.fetch('sampleEvidenceLimit', 20)
      end

      def existing_owner_metadata(owner)
        {
          status: owner.get_attribute('su_mcp', 'status'),
          state: owner.get_attribute('su_mcp', 'state')
        }.compact
      end

      def edit_owner_reference_params(params)
        {
          'metadata' => {
            'sourceElementId' => params.dig('targetReference', 'sourceElementId')
          }
        }
      end

      def edit_terrain_state_summary(loaded, state, saved)
        {
          before: loaded.fetch(:summary),
          after: terrain_state_summary(state, saved.fetch(:summary))
        }
      end

      def edit_summary(params, diagnostics)
        {
          mode: params.dig('operation', 'mode'),
          region: params.fetch('region'),
          changedRegion: diagnostics[:changedRegion]
        }
      end

      def adoption_sample_or_refusal(validation)
        return nil unless validation.fetch(:lifecycle_mode) == 'adopt'

        adoption_sampler.derive(adoption_target(validation))
      end

      def execute_mutation(validation, sampled_source: nil)
        operation_started = false
        model.start_operation(OPERATION_NAME, true)
        operation_started = true

        result = if validation.fetch(:lifecycle_mode) == 'adopt'
                   adopt_terrain(validation, sampled_source)
                 else
                   create_terrain(validation)
                 end
        finish_operation(result)
        result
      rescue StandardError
        model.abort_operation if operation_started && model.respond_to?(:abort_operation)
        raise
      end

      def finish_operation(result)
        if refused?(result)
          model.abort_operation if model.respond_to?(:abort_operation)
        else
          model.commit_operation
        end
      end

      def create_terrain(validation)
        owner = create_owner(validation.fetch(:params))
        state = build_create_state(validation, owner)
        saved, output = save_and_generate(owner, state)
        return saved if refused?(saved)

        success_response(
          outcome: 'created',
          lifecycle_mode: 'create',
          owner: owner,
          params: validation.fetch(:params),
          state: state,
          saved: saved,
          output: output
        )
      end

      def adopt_terrain(validation, sampled_source)
        owner = create_owner(validation.fetch(:params), terrain_state: 'Adopted')
        state = build_adopted_state(sampled_source, owner)
        saved, output = save_and_generate(owner, state)
        return saved if refused?(saved)

        erase_source(sampled_source)
        adoption_success_response(
          adoption_context(validation, owner, state, saved, output, sampled_source)
        )
      end

      def build_create_state(validation, owner)
        state_builder.build_create_state(
          validation.fetch(:params),
          owner_transform_signature: owner_transform_signature(owner)
        )
      end

      def build_adopted_state(sampled_source, owner)
        state_builder.build_adopted_state(
          sampled_source,
          owner_transform_signature: owner_transform_signature(owner)
        )
      end

      def adoption_target(validation)
        validation.fetch(:params).dig('lifecycle', 'target')
      end

      def save_and_generate(owner, state)
        saved = save_state_or_refusal(owner, state)
        return [saved, nil] if refused?(saved)

        output = mesh_generator.generate(
          owner: owner,
          state: state,
          terrain_state_summary: saved.fetch(:summary)
        )
        [saved, output]
      end

      def adoption_success_response(context)
        success_response(
          outcome: 'adopted',
          lifecycle_mode: 'adopt',
          owner: context.fetch(:owner),
          params: context.fetch(:validation).fetch(:params),
          state: context.fetch(:state),
          saved: context.fetch(:saved),
          output: context.fetch(:output),
          source_summary: context.fetch(:sampled_source)[:source_summary],
          sampling_summary: context.fetch(:sampled_source)[:sampling_summary]
        )
      end

      def adoption_context(*values)
        validation, owner, state, saved, output, sampled_source = values
        {
          validation: validation,
          owner: owner,
          state: state,
          saved: saved,
          output: output,
          sampled_source: sampled_source
        }
      end

      def create_owner(params, terrain_state: 'Created')
        owner = model.active_entities.add_group
        scene_properties.apply!(model: model, group: owner, params: params)
        apply_placement!(owner, params)
        metadata_writer.write!(owner, metadata_attributes(params, terrain_state))
        owner
      end

      def apply_placement!(owner, params)
        origin = params.dig('placement', 'origin')
        return unless origin.is_a?(Hash)
        return unless owner.respond_to?(:move!)

        owner.move!(placement_transformation(origin))
      end

      def placement_transformation(origin)
        point = Geom::Point3d.new(
          internal_length(origin.fetch('x')),
          internal_length(origin.fetch('y')),
          internal_length(origin.fetch('z'))
        )
        Geom::Transformation.translation(point) || Struct.new(:origin).new(point)
      end

      def internal_length(value)
        length_converter.public_meters_to_internal(value)
      end

      def metadata_attributes(params, terrain_state)
        {
          'sourceElementId' => params.dig('metadata', 'sourceElementId'),
          'semanticType' => SEMANTIC_TYPE,
          'status' => params.dig('metadata', 'status'),
          'state' => terrain_state,
          'schemaVersion' => SCHEMA_VERSION
        }
      end

      def save_state_or_refusal(owner, state)
        saved = repository.save(owner, state)
        return saved unless saved.fetch(:outcome) == 'refused'

        ToolResponse.refusal(
          code: 'terrain_state_save_failed',
          message: 'Terrain state could not be saved.',
          details: saved.fetch(:refusal)
        )
      end

      def erase_source(sampled_source)
        sampled_source[:source_entity]&.erase!
      end

      # rubocop:disable Metrics/ParameterLists
      def success_response(
        outcome:,
        lifecycle_mode:,
        owner:,
        params:,
        state:,
        saved:,
        output:,
        source_summary: nil,
        sampling_summary: nil
      )
        evidence_builder.build_success(
          outcome: outcome,
          lifecycle_mode: lifecycle_mode,
          owner_reference: owner_reference(owner, params),
          metadata: metadata_summary(params, lifecycle_mode),
          terrain_state_summary: terrain_state_summary(state, saved.fetch(:summary)),
          output_summary: output.fetch(:summary),
          request_summary: request_summary(params, lifecycle_mode),
          source_summary: source_summary,
          sampling_summary: sampling_summary
        )
      end
      # rubocop:enable Metrics/ParameterLists

      def owner_reference(owner, params)
        {
          sourceElementId: params.dig('metadata', 'sourceElementId'),
          persistentId: persistent_id_for(owner)
        }.compact
      end

      def metadata_summary(params, lifecycle_mode)
        {
          semanticType: SEMANTIC_TYPE,
          status: params.dig('metadata', 'status'),
          state: lifecycle_mode == 'adopt' ? 'Adopted' : 'Created'
        }
      end

      def terrain_state_summary(state, summary)
        summary.merge(
          stateId: state.state_id,
          payloadKind: state.payload_kind,
          origin: state.origin,
          spacing: state.spacing
        )
      end

      def request_summary(params, lifecycle_mode)
        return { lifecycleMode: lifecycle_mode } if lifecycle_mode == 'adopt'

        { definitionKind: params.dig('definition', 'kind') }
      end

      def persistent_id_for(owner)
        if owner.respond_to?(:persistent_id)
          persistent_id = owner.method(:persistent_id).call
          return persistent_id.to_s if persistent_id
        end
        return owner.persistentID.to_s if owner.respond_to?(:persistentID)

        nil
      end

      def owner_transform_signature(owner)
        Terrain::AttributeTerrainStorage.new.owner_transform_signature(owner)
      end

      def managed_terrain_identity_exists?(source_element_id)
        managed_entities.any? do |entity|
          entity.respond_to?(:get_attribute) &&
            entity.get_attribute('su_mcp', 'semanticType') == SEMANTIC_TYPE &&
            entity.get_attribute('su_mcp', 'sourceElementId') == source_element_id
        end
      end

      def managed_entities
        return [] unless model.respond_to?(:active_entities)

        model.active_entities.to_a
      end

      def refused?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/ClassLength, Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
