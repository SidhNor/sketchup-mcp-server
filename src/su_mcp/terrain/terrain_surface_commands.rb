# frozen_string_literal: true

require_relative '../runtime/tool_response'
require_relative '../semantic/length_converter'
require_relative '../semantic/managed_object_metadata'
require_relative '../semantic/scene_properties'
require_relative 'create_terrain_surface_request'
require_relative 'terrain_mesh_generator'
require_relative 'terrain_repository'
require_relative 'terrain_surface_adoption_sampler'
require_relative 'terrain_surface_evidence_builder'
require_relative 'terrain_surface_state_builder'

module SU_MCP
  module Terrain
    # Public terrain command target for create_terrain_surface.
    # rubocop:disable Metrics/ClassLength
    class TerrainSurfaceCommands
      OPERATION_NAME = 'Create Terrain Surface'
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
        length_converter: Semantic::LengthConverter.new
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
      end
      # rubocop:enable Metrics/ParameterLists

      def create_terrain_surface(params)
        validation = validate(params)
        return validation if refused?(validation)

        sampled_source = adoption_sample_or_refusal(validation)
        return sampled_source if refused?(sampled_source)

        execute_mutation(validation, sampled_source: sampled_source)
      end

      private

      attr_reader :model, :validator, :state_builder, :repository, :mesh_generator,
                  :evidence_builder, :adoption_sampler, :metadata_writer, :scene_properties,
                  :length_converter

      def validate(params)
        return validator.validate(params) if validator

        CreateTerrainSurfaceRequest
          .new(params, identity_exists: method(:managed_terrain_identity_exists?))
          .validate
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
    # rubocop:enable Metrics/ClassLength
  end
end
