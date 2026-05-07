# frozen_string_literal: true

require 'time'

module SU_MCP
  module Terrain
    # Replayable local/hosted failure payload for MTA-23 follow-up work.
    class Mta23FailureCaptureArtifact
      def self.build(fixture_id:, state_payload:, feature_geometry:, candidate_row:)
        {
          fixtureId: fixture_id,
          capturedAt: Time.now.utc.iso8601,
          statePayload: state_payload,
          terrainFeatureGeometry: feature_geometry.to_h,
          candidateRow: candidate_row,
          featureGeometryDigest: feature_geometry.feature_geometry_digest,
          referenceGeometryDigest: feature_geometry.reference_geometry_digest
        }
      end
    end
  end
end
