# frozen_string_literal: true

module SU_MCP
  module Adapters
    # Entity occurrence paths for the active model, as `{ entity:, ancestors: }`
    # entries where `ancestors` lists the enclosing groups and component
    # instances from outermost to innermost.
    #
    # Iterating yields every occurrence, expanding each component instance into
    # its definition. That grows with the number of placed copies (tens of
    # millions of entries on large models), so callers that only need a few
    # entries should use #entries_matching or #each_outside_components.
    class EntityPathIndex
      include Enumerable

      def initialize(model)
        @model = model
        @container_paths = {}.compare_by_identity
      end

      # Full preorder expansion, matching the historical traversal order.
      def each(&block)
        return enum_for(:each) unless block

        walk(model.entities, [], descend_into_components: true, &block)
      end

      # Occurrences of groups and components that are not inside any component
      # instance, in the same order as #each.
      def each_outside_components(&block)
        return enum_for(:each_outside_components) unless block

        walk(model.entities, [], descend_into_components: false) do |entry|
          yield entry if instance?(entry.fetch(:entity))
        end
      end

      # Every occurrence of the entities the predicate accepts. Each unique
      # entity is tested once; only matches are expanded to their occurrence
      # paths, so cost follows the number of unique entities, not placed copies.
      def entries_matching(&predicate)
        return select { |entry| predicate.call(entry.fetch(:entity)) } unless unique_scan_supported?

        matches = []
        each_unique_entity do |entity|
          next unless predicate.call(entity)

          occurrence_paths(entity.parent).each do |ancestors|
            matches << { entity: entity, ancestors: ancestors }
          end
        end
        matches
      end

      private

      attr_reader :model

      def walk(entities, ancestors, descend_into_components:, &block)
        entities.each do |entity|
          next unless entity
          next unless entity.respond_to?(:entityID)

          yield({ entity: entity, ancestors: ancestors })
          children = child_entities(entity, descend_into_components)
          next unless children

          walk(children, (ancestors + [entity]).freeze,
               descend_into_components: descend_into_components, &block)
        end
      end

      def child_entities(entity, descend_into_components)
        return entity.entities if entity.is_a?(Sketchup::Group)
        return nil unless descend_into_components && entity.is_a?(Sketchup::ComponentInstance)

        entity.definition.entities
      end

      def unique_scan_supported?
        model.respond_to?(:definitions)
      end

      def each_unique_entity(&block)
        each_entity_in(model.entities, &block)
        model.definitions.each { |definition| each_entity_in(definition.entities, &block) }
      end

      def each_entity_in(entities)
        entities.each do |entity|
          yield entity if entity.respond_to?(:entityID) && entity.respond_to?(:parent)
        end
      end

      # Ancestor chains under which a container's entities appear in #each.
      def occurrence_paths(container)
        return [[].freeze] if container.equal?(model) || container.is_a?(Sketchup::Model)
        return [] unless container.is_a?(Sketchup::ComponentDefinition)

        @container_paths[container] ||= instance_paths(container)
      end

      def instance_paths(definition)
        definition.instances.each_with_object([]) do |instance, paths|
          # Image definitions have Sketchup::Image instances, which #each never enters.
          next unless instance?(instance)

          occurrence_paths(instance.parent).each do |ancestors|
            paths << (ancestors + [instance]).freeze
          end
        end
      end

      def instance?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end
    end
  end
end
