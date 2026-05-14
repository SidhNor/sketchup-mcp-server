# frozen_string_literal: true

require_relative '../../patch_lifecycle/patch_grid_policy'

module SU_MCP
  module Terrain
    # CDT-specific PatchLifecycle policy adapter. It configures lifecycle identity;
    # it does not own registry, traversal, timing, readback, or mutation sequencing.
    class CdtPatchPolicy < PatchLifecycle::PatchGridPolicy
      def initialize(patch_cell_size: PatchLifecycle::PatchGridPolicy::DEFAULT_PATCH_CELL_SIZE)
        super(
          patch_cell_size: patch_cell_size,
          conformance_ring: 0,
          patch_id_prefix: 'cdt-patch',
          fingerprint_kind: 'cdt-patch'
        )
      end
    end
  end
end
