# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Builds hosted sidecar probe payloads for MTA-23 eval_ruby validation.
    class Mta23HostedSidecarProbe
      def initialize(timestamp:, model_bounds:)
        @timestamp = timestamp
        @model_bounds = model_bounds
      end

      def payload_for(candidate_row:, mesh:)
        {
          sidecarName: "MTA23-CANDIDATE-#{timestamp}",
          placementOffset: placement_offset,
          candidateRow: candidate_row,
          mesh: mesh,
          evidence: default_evidence(mesh)
        }
      end

      def self.hosted_report(evidence:, requested_recommendation:)
        save_reopen_gap = evidence.fetch(:saveReopenStatus, nil) == 'skipped'
        recommendation = if save_reopen_gap &&
                            requested_recommendation == 'productionize_adaptive_candidate_later'
                           'pursue_constrained_delaunay_or_cdt_follow_up'
                         else
                           requested_recommendation
                         end
        {
          recommendation: recommendation,
          validationGaps: save_reopen_gap ? ['save/reopen validation gap'] : []
        }
      end

      private

      attr_reader :timestamp, :model_bounds

      def placement_offset
        max = model_bounds.fetch(:max) { model_bounds.fetch('max') }
        [(max.fetch(0) + 10.0), 0.0, 0.0]
      end

      def default_evidence(mesh)
        {
          beforeTopLevelEntityIds: [],
          afterTopLevelEntityIds: [],
          generatedFaceCount: mesh.fetch(:triangles, []).length,
          generatedVertexCount: mesh.fetch(:vertices, []).length,
          topologyChecks: {},
          profileChecks: [],
          timing: nil,
          undoStatus: 'not_run',
          saveCopyStatus: 'not_run',
          saveReopenStatus: 'not_run',
          candidateOnlyMetadata: {
            dictionary: 'su_mcp_mta23_candidate',
            validationOnly: true
          }
        }
      end
    end
  end
end
