# frozen_string_literal: true

require_relative '../patch_lifecycle/patch_grid_policy'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Adaptive-output adapter for the generic patch lattice policy.
      class AdaptivePatchPolicy < PatchLifecycle::PatchGridPolicy
        SCHEMA_VERSION = PatchLifecycle::PatchGridPolicy::SCHEMA_VERSION
        DEFAULT_PATCH_CELL_SIZE = PatchLifecycle::PatchGridPolicy::DEFAULT_PATCH_CELL_SIZE
        DEFAULT_CONFORMANCE_RING = PatchLifecycle::PatchGridPolicy::DEFAULT_CONFORMANCE_RING
        DEFAULT_CANDIDATE_PATCH_CELL_SIZES =
          PatchLifecycle::PatchGridPolicy::DEFAULT_CANDIDATE_PATCH_CELL_SIZES

        attr_reader :adaptive_metadata_schema_version

        def initialize(
          patch_cell_size: DEFAULT_PATCH_CELL_SIZE,
          conformance_ring: DEFAULT_CONFORMANCE_RING,
          hard_patch_boundaries: true,
          adaptive_metadata_schema_version: SCHEMA_VERSION,
          candidate_patch_cell_sizes: DEFAULT_CANDIDATE_PATCH_CELL_SIZES,
          spacing: { 'x' => 1.0, 'y' => 1.0 }
        )
          @adaptive_metadata_schema_version = adaptive_metadata_schema_version
          super(
            patch_cell_size: patch_cell_size,
            conformance_ring: conformance_ring,
            hard_patch_boundaries: hard_patch_boundaries,
            metadata_schema_version: adaptive_metadata_schema_version,
            candidate_patch_cell_sizes: candidate_patch_cell_sizes,
            spacing: spacing,
            patch_id_prefix: 'adaptive-patch',
            fingerprint_kind: 'adaptive-patch'
          )
        end
      end
    end
  end
end
