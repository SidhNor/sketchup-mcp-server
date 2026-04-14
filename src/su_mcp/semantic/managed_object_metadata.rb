# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Writes the SEM-01 Managed Scene Object metadata contract.
    class ManagedObjectMetadata
      DICTIONARY = 'su_mcp'

      def write!(entity, attributes)
        entity.set_attribute(DICTIONARY, 'managedSceneObject', true)
        attributes.each do |key, value|
          entity.set_attribute(DICTIONARY, key, value)
        end

        entity
      end
    end
  end
end
