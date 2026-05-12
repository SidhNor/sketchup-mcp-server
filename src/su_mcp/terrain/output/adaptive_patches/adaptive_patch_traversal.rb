# frozen_string_literal: true

require_relative '../patch_lifecycle/patch_traversal'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Adaptive-output adapter for generic derived patch traversal.
      class AdaptivePatchTraversal < PatchLifecycle::PatchTraversal
        PATCH_MESH_KIND = 'adaptive_patch_mesh'
        PATCH_CONTAINER_KIND = 'adaptive_patch_container'
        PATCH_FACE_KIND = 'adaptive_patch_face'
        PATCH_ID_KEY = 'adaptivePatchId'

        def initialize
          super(
            mesh_kind: PATCH_MESH_KIND,
            face_kind: PATCH_FACE_KIND,
            container_kind: PATCH_CONTAINER_KIND,
            patch_id_key: PATCH_ID_KEY
          )
        end

        def adaptive_mesh(entities)
          patch_mesh(entities)
        end
      end
    end
  end
end
