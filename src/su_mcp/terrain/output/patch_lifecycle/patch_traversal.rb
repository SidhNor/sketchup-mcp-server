# frozen_string_literal: true

require 'set'

module SU_MCP
  module Terrain
    module PatchLifecycle
      # Purpose-specific traversal for derived patch output.
      class PatchTraversal
        DICTIONARY = 'su_mcp_terrain'
        DERIVED_OUTPUT_KEY = 'derivedOutput'
        OUTPUT_KIND_KEY = 'outputKind'
        PATCH_ID_KEY = 'adaptivePatchId'

        def initialize(mesh_kind:, face_kind:, container_kind: nil, patch_id_key: PATCH_ID_KEY)
          @mesh_kind = mesh_kind
          @container_kind = container_kind
          @face_kind = face_kind
          @patch_id_key = patch_id_key
        end

        def patch_mesh(entities)
          entities.to_a.find { |entity| patch_mesh?(entity) }
        end

        def affected_faces(entities, patch_ids)
          wanted = patch_ids.to_set
          entities.to_a.select do |entity|
            patch_face?(entity) && wanted.include?(attribute(entity, patch_id_key))
          end
        end

        def affected_containers(entities, patch_ids)
          wanted = patch_ids.to_set
          entities.to_a.select do |entity|
            patch_container?(entity) && wanted.include?(attribute(entity, patch_id_key))
          end
        end

        def all_patch_containers(entities)
          entities.to_a.select { |entity| patch_container?(entity) }
        end

        def faces_for_integrity(containers)
          containers.flat_map do |container|
            next [] unless container.respond_to?(:entities)

            container.entities.to_a.select { |entity| face_entity?(entity) }
          end
        end

        private

        attr_reader :mesh_kind, :container_kind, :face_kind, :patch_id_key

        def patch_container?(entity)
          return false unless container_kind

          attribute(entity, DERIVED_OUTPUT_KEY) == true &&
            attribute(entity, OUTPUT_KIND_KEY) == container_kind
        end

        def patch_mesh?(entity)
          attribute(entity, DERIVED_OUTPUT_KEY) == true &&
            attribute(entity, OUTPUT_KIND_KEY) == mesh_kind &&
            entity.respond_to?(:entities)
        end

        def patch_face?(entity)
          face_entity?(entity) &&
            attribute(entity, DERIVED_OUTPUT_KEY) == true &&
            attribute(entity, OUTPUT_KIND_KEY) == face_kind
        end

        def attribute(entity, key)
          return nil unless entity.respond_to?(:get_attribute)

          entity.get_attribute(DICTIONARY, key)
        end

        def face_entity?(entity)
          entity.is_a?(Sketchup::Face) || entity.respond_to?(:points)
        end
      end
    end
  end
end
