# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Semantic
    # Owns the Managed Scene Object metadata contract and mutation policy.
    class ManagedObjectMetadata
      DICTIONARY = 'su_mcp'
      # Empty managed containers need a hidden internal entity so SketchUp keeps
      # the wrapper group alive until real children are added.
      INTERNAL_PLACEHOLDER_KEY = '_managedContainerPlaceholder'
      APPROVED_STRUCTURE_CATEGORIES = %w[main_building outbuilding extension].freeze
      SOFT_MUTABLE_FIELDS_BY_TYPE = {
        'structure' => %w[status structureCategory].freeze,
        'planting_mass' => %w[status plantingCategory].freeze,
        'tree_proxy' => %w[status speciesHint].freeze
      }.freeze
      DEFAULT_SOFT_MUTABLE_FIELDS = %w[status].freeze
      REQUIRED_MUTABLE_FIELDS_BY_TYPE = {
        'structure' => %w[status structureCategory].freeze
      }.freeze
      DEFAULT_REQUIRED_MUTABLE_FIELDS = %w[status].freeze
      PROTECTED_FIELDS = %w[
        managedSceneObject
        sourceElementId
        semanticType
        schemaVersion
        state
      ].freeze

      def self.placeholder_entity?(entity)
        entity.respond_to?(:get_attribute) &&
          entity.get_attribute(DICTIONARY, INTERNAL_PLACEHOLDER_KEY) == true
      end

      def self.collection_entities(collection)
        return collection.to_a if collection.respond_to?(:to_a)

        Array(collection)
      end

      def self.placeholder_entities(collection)
        collection_entities(collection).select { |entity| placeholder_entity?(entity) }
      end

      def write!(entity, attributes)
        entity.set_attribute(DICTIONARY, 'managedSceneObject', true)
        attributes.each do |key, value|
          entity.set_attribute(DICTIONARY, key, value)
        end

        entity
      end

      def managed_object?(entity)
        entity.get_attribute(DICTIONARY, 'managedSceneObject') == true
      end

      def attributes_for(entity)
        dictionary_attributes(entity).dup
      end

      def prepare_update(entity, set:, clear:)
        return unmanaged_object_refusal unless managed_object?(entity)

        updates = normalize_hash(set)
        clears = normalize_clear_list(clear)
        validation_refusal = validate_update(entity, updates, clears)
        return validation_refusal if validation_refusal

        {
          outcome: 'ready',
          updates: updates,
          clears: clears
        }
      end

      def apply_prepared_update(entity, prepared_update)
        apply_updates(entity, prepared_update.fetch(:updates), prepared_update.fetch(:clears))

        { outcome: 'updated' }
      end

      def update(entity, set:, clear:)
        prepared_update = prepare_update(entity, set: set, clear: clear)
        return prepared_update unless prepared_update[:outcome] == 'ready'

        apply_prepared_update(entity, prepared_update)
      end

      private

      def dictionary_attributes(entity)
        if entity.respond_to?(:attributes)
          entity.attributes.fetch(DICTIONARY, {})
        elsif entity.respond_to?(:attribute_dictionary)
          dictionary = entity.attribute_dictionary(DICTIONARY, false)
          return {} unless dictionary

          {}.tap do |attributes|
            dictionary.each_pair do |key, value|
              attributes[key.to_s] = value
            end
          end
        else
          {}
        end
      end

      def normalize_hash(values)
        return {} unless values.is_a?(Hash)

        values.each_with_object({}) do |(key, value), normalized|
          normalized[key.to_s] = value
        end
      end

      def normalize_clear_list(values)
        Array(values).filter_map do |value|
          field = value.to_s
          field unless field.empty?
        end
      end

      def validate_update(entity, updates, clears)
        protected_field = protected_field(updates, clears)
        return protected_field_refusal(protected_field) if protected_field

        unsupported_field = unsupported_field(entity, updates, clears)
        if unsupported_field
          return unsupported_option_refusal(
            entity,
            unsupported_field,
            field_value(updates, unsupported_field)
          )
        end

        required_field = required_field(entity, clears)
        return required_field_refusal(entity, required_field) if required_field

        validate_structure_category(entity, updates)
      end

      def protected_field(updates, clears)
        (updates.keys + clears).find { |field| PROTECTED_FIELDS.include?(field) }
      end

      def validate_structure_category(entity, updates)
        return nil unless updates.key?('structureCategory')
        unless structure_entity?(entity)
          return unsupported_option_refusal(
            entity,
            'structureCategory',
            updates['structureCategory']
          )
        end
        return nil if APPROVED_STRUCTURE_CATEGORIES.include?(updates['structureCategory'])

        unsupported_option_refusal(entity, 'structureCategory', updates['structureCategory'])
      end

      def apply_updates(entity, updates, clears)
        clears.each do |field|
          entity.delete_attribute(DICTIONARY, field)
        end
        updates.each do |field, value|
          entity.set_attribute(DICTIONARY, field, value)
        end
      end

      def structure_entity?(entity)
        entity.get_attribute(DICTIONARY, 'semanticType') == 'structure'
      end

      def semantic_type_for(entity)
        entity.get_attribute(DICTIONARY, 'semanticType')
      end

      def soft_mutable_fields_for(entity)
        SOFT_MUTABLE_FIELDS_BY_TYPE.fetch(semantic_type_for(entity), DEFAULT_SOFT_MUTABLE_FIELDS)
      end

      def required_mutable_fields_for(entity)
        REQUIRED_MUTABLE_FIELDS_BY_TYPE.fetch(
          semantic_type_for(entity),
          DEFAULT_REQUIRED_MUTABLE_FIELDS
        )
      end

      def clearable_fields_for(entity)
        soft_mutable_fields_for(entity) - required_mutable_fields_for(entity)
      end

      def unsupported_field(entity, updates, clears)
        supported_fields = soft_mutable_fields_for(entity)
        (updates.keys + clears).find { |field| !supported_fields.include?(field) }
      end

      def required_field(entity, clears)
        required_mutable_fields_for(entity).find { |field| clears.include?(field) }
      end

      def field_value(updates, field)
        updates.key?(field) ? updates[field] : nil
      end

      def unmanaged_object_refusal
        refusal_without_success(
          code: 'unmanaged_object',
          message: 'Entity is not a Managed Scene Object.'
        )
      end

      def protected_field_refusal(field)
        refusal_without_success(
          code: 'protected_metadata_field',
          message: 'Field cannot be modified for a Managed Scene Object.',
          details: { field: field }
        )
      end

      def required_field_refusal(entity, field)
        refusal_without_success(
          code: 'required_metadata_field',
          message: 'Field cannot be cleared for a Managed Scene Object.',
          details: {
            field: field,
            allowedValues: clearable_fields_for(entity)
          }
        )
      end

      def unsupported_option_refusal(entity, field, value)
        details = {
          field: field,
          value: value
        }
        if field == 'structureCategory'
          details[:allowedValues] = APPROVED_STRUCTURE_CATEGORIES
        elsif value.nil?
          details[:allowedValues] = clearable_fields_for(entity)
        end

        refusal_without_success(
          code: 'unsupported_option',
          message: 'Option is not supported for this Managed Scene Object.',
          details: details
        )
      end

      def refusal_without_success(code:, message:, details: nil)
        ToolResponse
          .refusal(code: code, message: message, details: details)
          .reject { |key, _value| key == :success }
      end
    end
  end
end
