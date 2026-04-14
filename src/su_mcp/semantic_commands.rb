# frozen_string_literal: true

require_relative 'semantic/builder_registry'
require_relative 'semantic/managed_object_metadata'
require_relative 'semantic/pad_builder'
require_relative 'semantic/request_validator'
require_relative 'semantic/serializer'
require_relative 'semantic/structure_builder'

module SU_MCP
  # Coordinates the Ruby-owned SEM-01 semantic creation slice.
  class SemanticCommands
    OPERATION_NAME = 'Create Site Element'
    SCHEMA_VERSION = 1

    def initialize(
      model: Sketchup.active_model,
      registry: Semantic::BuilderRegistry.new,
      validator: Semantic::RequestValidator.new,
      metadata_writer: Semantic::ManagedObjectMetadata.new,
      serializer: Semantic::Serializer.new
    )
      @model = model
      @registry = registry
      @validator = validator
      @metadata_writer = metadata_writer
      @serializer = serializer
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_site_element(params)
      refusal = validator.refusal_for(params)
      return refusal if refusal

      builder = registry.builder_for(params.fetch('elementType'))
      model.start_operation(OPERATION_NAME, true)
      entity = builder.build(model: model, params: params)
      metadata_writer.write!(entity, metadata_attributes(params))
      result = {
        success: true,
        outcome: 'created',
        managedObject: serializer.serialize(entity)
      }
      model.commit_operation
      result
    rescue StandardError
      model.abort_operation if model.respond_to?(:abort_operation)
      raise
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    attr_reader :model, :registry, :validator, :metadata_writer, :serializer

    def metadata_attributes(params)
      {
        'sourceElementId' => params.fetch('sourceElementId'),
        'semanticType' => params.fetch('elementType'),
        'status' => params.fetch('status'),
        'state' => 'Created',
        'schemaVersion' => SCHEMA_VERSION
      }.tap do |attributes|
        next unless params['elementType'] == 'structure' && params['structureCategory']

        attributes['structureCategory'] = params['structureCategory']
      end
    end
  end
end
