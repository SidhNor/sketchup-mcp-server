# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Hosted validation probe shell for MTA-36 adaptive patch lifecycle evidence.
    class Mta36HostedPatchLifecycleProbe
      RESPONSIVENESS_FLOOR_MS = 200.0
      SPEEDUP_TARGET = 2.0

      def initialize(timestamp:)
        @timestamp = timestamp
      end

      def payload_for(case_id:, terrain_extent_meters:, spacing_meters:, patch_cell_size:)
        {
          probeName: "MTA36-ADAPTIVE-PATCH-#{timestamp}",
          caseId: case_id,
          executionMode: 'command_path',
          terrainExtentMeters: terrain_extent_meters,
          spacingMeters: spacing_meters,
          patchCellSize: patch_cell_size,
          timingBuckets: timing_buckets,
          acceptanceRows: acceptance_rows
        }
      end

      def self.hosted_report(evidence:)
        blockers = []
        if misses_speedup_gate?(evidence)
          blockers << 'local adaptive replacement missed speedup gate'
        end
        %i[visualInspection reloadReadback undo].each do |key|
          blockers << "#{key} hosted validation gap" unless evidence.fetch(key, nil) == 'passed'
        end
        {
          status: blockers.empty? ? 'passed' : 'performance_blocked',
          blockers: blockers
        }
      end

      def self.misses_speedup_gate?(evidence)
        full_ms = evidence.fetch(:fullAdaptiveTotalMs).to_f
        local_ms = evidence.fetch(:localAdaptiveTotalMs).to_f
        return false if full_ms <= RESPONSIVENESS_FLOOR_MS

        (full_ms / local_ms) < SPEEDUP_TARGET
      end

      private

      attr_reader :timestamp

      def timing_buckets
        {
          commandPrep: nil,
          dirtyWindowMapping: nil,
          adaptivePlanning: nil,
          conformance: nil,
          registryLookup: nil,
          ownershipFaceLookup: nil,
          mutation: nil,
          registryWrites: nil,
          audit: nil,
          total: nil
        }
      end

      def acceptance_rows
        {
          repeatedSamePatchEdit: 'not_run',
          repeatedAdjacentPatchEdit: 'not_run',
          preservedNeighbors: 'not_run',
          noDeleteFallback: 'not_run',
          intersectingMultiModeEdits: 'not_run',
          singleMeshTopology: 'not_run',
          undo: 'not_run',
          reloadReadback: 'not_run',
          visualInspection: 'not_run',
          performanceComparison: 'not_run'
        }
      end
    end
  end
end
