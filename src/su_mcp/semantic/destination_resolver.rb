# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Semantic
    # Resolves writable destination collections for semantic create/replace flows.
    class DestinationResolver
      def initialize(model:)
        @model = model
      end

      def resolve_for_create(parent_entity: nil)
        return success(model.active_entities) unless parent_entity

        resolve_supported_parent_destination(parent_entity)
      end

      def resolve_for_replace(previous_entity:, explicit_parent: nil)
        return resolve_supported_parent_destination(explicit_parent) if explicit_parent

        fallback_collection = fallback_parent_collection_for(previous_entity)
        return success(fallback_collection) if writable_collection?(fallback_collection)

        ToolResponse.refusal(
          code: 'invalid_parent_destination',
          message: 'Lifecycle target does not expose a writable destination collection.',
          details: { section: 'placement' }
        )
      end

      private

      attr_reader :model

      def resolve_supported_parent_destination(parent_entity)
        return unsupported_parent_refusal unless supported_parent?(parent_entity)

        collection = if parent_entity.is_a?(Sketchup::ComponentInstance)
                       parent_entity.definition.entities
                     else
                       parent_entity.entities
                     end

        return success(collection) if writable_collection?(collection)

        ToolResponse.refusal(
          code: 'invalid_parent_destination',
          message: 'Resolved parent target does not expose a writable destination collection.',
          details: { section: 'placement' }
        )
      end

      def fallback_parent_collection_for(entity)
        direct_parent_collection_for(entity) || parent_collection_for(entity_parent(entity))
      end

      def direct_parent_collection_for(entity)
        return nil unless entity.respond_to?(:parent_collection)

        entity.parent_collection
      end

      def entity_parent(entity)
        entity.respond_to?(:parent) ? entity.parent : nil
      end

      def parent_collection_for(parent)
        return model.active_entities if parent.nil? || parent == model
        return entities_collection_for(parent) if parent.respond_to?(:entities)

        if parent.is_a?(Sketchup::ComponentInstance)
          return component_definition_collection_for(parent)
        end
        return model_collection_for(parent) if parent.respond_to?(:active_entities)

        nil
      end

      def entities_collection_for(parent)
        parent.entities
      end

      def component_definition_collection_for(parent)
        parent.definition.entities
      end

      def model_collection_for(parent)
        parent.active_entities
      end

      def supported_parent?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end

      def writable_collection?(collection)
        return false unless collection.respond_to?(:add_group)
        return collection.writable? if collection.respond_to?(:writable?)

        true
      end

      def success(destination)
        { outcome: 'ready', destination: destination }
      end

      def unsupported_parent_refusal
        ToolResponse.refusal(
          code: 'invalid_parent_destination',
          message: 'Parent target must resolve to a supported writable group or component.',
          details: { section: 'placement' }
        )
      end
    end
  end
end
