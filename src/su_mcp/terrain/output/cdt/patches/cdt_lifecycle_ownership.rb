# frozen_string_literal: true

module SU_MCP
  module Terrain
    # CDT face and registry metadata shaped around PatchLifecycle patch IDs.
    module CdtLifecycleOwnership
      module_function

      def face_ownership(
        patch_id:,
        patch_face_index:,
        replacement_batch_id:,
        state_digest:,
        policy_fingerprint:
      )
        {
          kind: :cdt_patch,
          patch_id: patch_id,
          patch_face_index: patch_face_index,
          replacement_batch_id: replacement_batch_id,
          state_digest: state_digest,
          policy_fingerprint: policy_fingerprint
        }
      end

      def registry_patch_record(patch:, replacement_batch_id:, face_count:)
        {
          patchId: patch.fetch(:patchId),
          bounds: patch.fetch(:bounds),
          outputBounds: patch.fetch(:bounds),
          replacementBatchId: replacement_batch_id,
          faceCount: face_count,
          status: 'valid'
        }
      end
    end
  end
end
