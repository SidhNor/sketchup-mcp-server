# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Owns the Managed Scene Object metadata contract and mutation policy.
    class ManagedObjectMetadata
      DICTIONARY = 'su_mcp'
      APPROVED_STRUCTURE_CATEGORIES = %w[main_building outbuilding extension].freeze
      PROTECTED_FIELDS = %w[
        managedSceneObject
        sourceElementId
        semanticType
        schemaVersion
        state
      ].freeze

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

          dictionary.each_pair.with_object({}) do |(key, value), attributes|
            attributes[key.to_s] = value
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
        return required_field_refusal('status') if clears.include?('status')

        validate_structure_category(entity, updates, clears)
      end

      def protected_field(updates, clears)
        (updates.keys + clears).find { |field| PROTECTED_FIELDS.include?(field) }
      end

      def validate_structure_category(entity, updates, clears)
        if structure_entity?(entity) && clears.include?('structureCategory')
          return required_field_refusal('structureCategory')
        end

        return nil unless updates.key?('structureCategory')
        unless structure_entity?(entity)
          return unsupported_option_refusal('structureCategory', updates['structureCategory'])
        end
        return nil if APPROVED_STRUCTURE_CATEGORIES.include?(updates['structureCategory'])

        unsupported_option_refusal('structureCategory', updates['structureCategory'])
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

      def unmanaged_object_refusal
        {
          outcome: 'refused',
          refusal: {
            code: 'unmanaged_object',
            message: 'Entity is not a Managed Scene Object.'
          }
        }
      end

      def protected_field_refusal(field)
        {
          outcome: 'refused',
          refusal: {
            code: 'protected_metadata_field',
            message: 'Field cannot be modified for a Managed Scene Object.',
            details: { field: field }
          }
        }
      end

      def required_field_refusal(field)
        {
          outcome: 'refused',
          refusal: {
            code: 'required_metadata_field',
            message: 'Field cannot be cleared for a Managed Scene Object.',
            details: { field: field }
          }
        }
      end

      def unsupported_option_refusal(field, value)
        details = {
          field: field,
          value: value
        }
        details[:allowedValues] = APPROVED_STRUCTURE_CATEGORIES if field == 'structureCategory'

        {
          outcome: 'refused',
          refusal: {
            code: 'unsupported_option',
            message: 'Option is not supported for this Managed Scene Object.',
            details: details
          }
        }
      end
    end
  end
end
