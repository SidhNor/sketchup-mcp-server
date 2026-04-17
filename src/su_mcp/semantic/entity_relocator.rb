# frozen_string_literal: true

require_relative 'managed_object_metadata'

module SU_MCP
  module Semantic
    # Owns supported wrapper relocation across parent collections.
    class EntityRelocator
      SUPPORTED_NESTED_ENTITY_TYPES = [
        Sketchup::Group,
        Sketchup::ComponentInstance,
        Sketchup::Face
      ].freeze

      def initialize(model: Sketchup.active_model, metadata_writer: ManagedObjectMetadata.new)
        @model = model
        @metadata_writer = metadata_writer
      end

      def relocate(entities:, parent:)
        target_collection = target_collection_for(parent)
        entities.map do |entity|
          relocated_entity = relocate_entity(entity, target_collection)
          entity.erase! if entity.respond_to?(:erase!)
          relocated_entity
        end
      end

      private

      attr_reader :model, :metadata_writer

      def target_collection_for(parent)
        return model.active_entities if parent.nil? && model.respond_to?(:active_entities)
        return parent.entities if parent.respond_to?(:entities)
        return parent.definition.entities if parent.is_a?(Sketchup::ComponentInstance)

        raise ArgumentError, 'Parent does not expose a writable entities collection'
      end

      def relocate_entity(entity, target_collection)
        case entity
        when Sketchup::Group
          clone_group(entity, target_collection)
        when Sketchup::ComponentInstance
          clone_component_instance(entity, target_collection)
        else
          raise ArgumentError, "Unsupported entity type for relocation: #{entity.class}"
        end
      end

      def clone_group(entity, target_collection)
        target_group = target_collection.add_group
        clone_group_contents(entity, target_group)
        copy_wrapper_properties(entity, target_group)
        copy_metadata(entity, target_group)
        target_group
      end

      def clone_component_instance(entity, target_collection)
        target_instance = target_collection.add_instance(entity.definition, entity.transformation)
        copy_wrapper_properties(entity, target_instance)
        copy_metadata(entity, target_instance)
        target_instance
      end

      def copy_wrapper_properties(source, target)
        target.name = source.name if target.respond_to?(:name=) && source.respond_to?(:name)
        target.layer = source.layer if target.respond_to?(:layer=) && source.respond_to?(:layer)
        copy_transformation(source, target)
        return unless target.respond_to?(:material=) && source.respond_to?(:material)

        target.material = source.material
      end

      def copy_transformation(source, target)
        return unless source.respond_to?(:transformation)

        transformation = source.transformation
        return unless transformation

        if target.respond_to?(:transformation=)
          target.transformation = transformation
        elsif target.respond_to?(:move!)
          target.move!(transformation)
        end
      end

      def copy_metadata(source, target)
        metadata_writer.attributes_for(source).each do |key, value|
          target.set_attribute(ManagedObjectMetadata::DICTIONARY, key, value)
        end
      end

      def clone_group_contents(source_group, target_group)
        each_collection_entity(source_group.entities) do |entity|
          clone_nested_entity(entity, target_group.entities)
        end
      end

      def clone_nested_entity(entity, target_collection)
        case entity
        when Sketchup::Group
          clone_group(entity, target_collection)
        when Sketchup::ComponentInstance
          clone_component_instance(entity, target_collection)
        when Sketchup::Face
          clone_face(entity, target_collection)
        end
      end

      def clone_face(entity, target_collection)
        points = face_points(entity)
        return unless points

        target_face = target_collection.add_face(*points)
        return unless target_face.respond_to?(:material=)
        return unless entity.respond_to?(:material)

        target_face.material = entity.material
      end

      def face_points(entity)
        return entity.points if entity.respond_to?(:points)

        return nil unless entity.respond_to?(:outer_loop)

        vertices = entity.outer_loop&.vertices
        return nil unless vertices

        vertices.map(&:position)
      end

      def each_collection_entity(collection, &block)
        return collection.each(&block) if collection.respond_to?(:each)

        extract_collection_entities(collection).each(&block)
      end

      def extract_collection_entities(collection)
        if collection.respond_to?(:grep)
          SUPPORTED_NESTED_ENTITY_TYPES.flat_map { |klass| collection.grep(klass) }
        else
          [].tap do |entities|
            entities.concat(collection.groups) if collection.respond_to?(:groups)
            if collection.respond_to?(:component_instances)
              entities.concat(collection.component_instances)
            end
            entities.concat(collection.faces) if collection.respond_to?(:faces)
          end
        end
      end
    end
  end
end
