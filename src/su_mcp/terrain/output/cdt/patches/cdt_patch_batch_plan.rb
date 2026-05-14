# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Invocation-scoped CDT replacement input built from PatchLifecycle resolution.
    class CdtPatchBatchPlan
      attr_reader :lifecycle_resolution, :terrain_state_summary, :feature_plan,
                  :retained_boundary_spans

      def self.from_lifecycle_resolution(
        lifecycle_resolution:,
        terrain_state_summary:,
        feature_plan:,
        retained_boundary_spans:
      )
        new(
          lifecycle_resolution: lifecycle_resolution,
          terrain_state_summary: terrain_state_summary,
          feature_plan: feature_plan,
          retained_boundary_spans: retained_boundary_spans
        )
      end

      def initialize(lifecycle_resolution:, terrain_state_summary:, feature_plan:,
                     retained_boundary_spans:)
        @lifecycle_resolution = lifecycle_resolution
        @terrain_state_summary = terrain_state_summary
        @feature_plan = feature_plan
        @retained_boundary_spans = Array(retained_boundary_spans)
      end

      def affected_patch_ids
        Array(value_from(lifecycle_resolution, :affectedPatchIds))
      end

      def replacement_patch_ids
        Array(value_from(lifecycle_resolution, :replacementPatchIds))
      end

      def affected_patches
        Array(value_from(lifecycle_resolution, :affectedPatches))
      end

      def replacement_patches
        Array(value_from(lifecycle_resolution, :replacementPatches))
      end

      def to_h
        {
          lifecycleResolution: lifecycle_resolution,
          terrainStateSummary: terrain_state_summary,
          featurePlan: feature_plan,
          retainedBoundarySpans: retained_boundary_spans
        }
      end

      private

      def value_from(hash, key)
        hash.fetch(key) { hash.fetch(key.to_s) }
      end
    end
  end
end
