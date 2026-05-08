# frozen_string_literal: true

module SU_MCP
  module Terrain
    module UI
      # Resolves the currently selected managed terrain owner at apply time.
      class SelectedTerrainResolver
        SEMANTIC_DICTIONARY = 'su_mcp'
        TERRAIN_SEMANTIC_TYPE = 'managed_terrain_surface'

        def initialize(model:)
          @model = model
        end

        def resolve
          selection = selected_entities
          if selection.empty?
            return refusal(
              'managed_terrain_selection_required',
              'Select one managed terrain surface.'
            )
          end
          if selection.length > 1
            return refusal(
              'managed_terrain_selection_ambiguous',
              'Select only one managed terrain surface.'
            )
          end

          owner = selection.first
          unless managed_terrain_owner?(owner)
            return refusal(
              'managed_terrain_selection_invalid',
              'Selection is not a managed terrain surface.'
            )
          end

          {
            outcome: 'resolved',
            owner: owner,
            targetReference: target_reference_for(owner),
            selectedTerrain: terrain_label(owner)
          }
        end

        private

        attr_reader :model

        def selected_entities
          selection = model.selection
          return selection.to_a if selection.respond_to?(:to_a)

          Array(selection)
        end

        def managed_terrain_owner?(entity)
          entity.respond_to?(:get_attribute) &&
            entity.get_attribute(SEMANTIC_DICTIONARY, 'semanticType') == TERRAIN_SEMANTIC_TYPE
        end

        def target_reference_for(owner)
          source_element_id = owner.get_attribute(SEMANTIC_DICTIONARY, 'sourceElementId')
          return { 'sourceElementId' => source_element_id } unless blank?(source_element_id)

          persistent_id = persistent_id_for(owner)
          return { 'persistentId' => persistent_id } unless blank?(persistent_id)

          { 'entityId' => owner.entityID.to_s }
        end

        def terrain_label(owner)
          name = owner.respond_to?(:name) ? owner.name.to_s.strip : ''
          return name unless blank?(name)

          target_reference_for(owner).values.first.to_s
        end

        def persistent_id_for(owner)
          return owner.persistentID.to_s if owner.respond_to?(:persistentID)

          nil
        end

        def blank?(value)
          value.nil? || value.to_s.strip.empty?
        end

        def refusal(code, message)
          {
            outcome: 'refused',
            refusal: {
              code: code,
              message: message,
              details: { field: 'selection' }
            }
          }
        end
      end
    end
  end
end
