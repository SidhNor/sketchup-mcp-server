# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Terrain
    # Builds JSON-safe create_terrain_surface success evidence.
    class TerrainSurfaceEvidenceBuilder
      def build_success(
        outcome:,
        lifecycle_mode:,
        owner_reference:,
        metadata:,
        terrain_state_summary:,
        output_summary:,
        request_summary:,
        source_summary:,
        sampling_summary:
      )
        ToolResponse.success(
          outcome: outcome,
          operation: operation_summary(lifecycle_mode),
          managedTerrain: managed_terrain_summary(owner_reference, metadata),
          terrainState: terrain_state_summary,
          output: output_summary,
          evidence: evidence_summary(request_summary, source_summary, sampling_summary)
        )
      end

      private

      def operation_summary(lifecycle_mode)
        {
          name: 'create_terrain_surface',
          lifecycleMode: lifecycle_mode
        }
      end

      def managed_terrain_summary(owner_reference, metadata)
        {
          ownerReference: owner_reference,
          semanticType: metadata.fetch(:semanticType),
          status: metadata.fetch(:status),
          state: metadata.fetch(:state)
        }
      end

      def evidence_summary(request_summary, source_summary, sampling_summary)
        {
          requestSummary: request_summary,
          sourceSummary: source_summary,
          samplingSummary: sampling_summary
        }
      end
    end
  end
end
