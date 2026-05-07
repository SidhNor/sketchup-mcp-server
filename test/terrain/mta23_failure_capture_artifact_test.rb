# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/mta23_failure_capture_artifact'
require_relative '../../src/su_mcp/terrain/terrain_feature_geometry'

class Mta23FailureCaptureArtifactTest < Minitest::Test
  def test_failure_capture_artifact_requires_replayable_state_feature_geometry_row_and_digests
    feature_geometry = SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        {
          id: 'r',
          featureId: 'f',
          role: 'centerline',
          strength: 'firm',
          ownerLocalStart: [0.0, 0.0],
          ownerLocalEnd: [1.0, 0.0]
        }
      ]
    )
    artifact = SU_MCP::Terrain::Mta23FailureCaptureArtifact.build(
      fixture_id: 'created_flat_corridor_mta21',
      state_payload: { 'stateId' => 'state-1', 'schemaVersion' => 3 },
      feature_geometry: feature_geometry,
      candidate_row: { caseId: 'created_flat_corridor_mta21', failureCategory: 'topology_invalid' }
    )

    assert_equal(%i[
                   fixtureId capturedAt statePayload terrainFeatureGeometry candidateRow
                   featureGeometryDigest referenceGeometryDigest
                 ], artifact.keys)
    assert(JSON.parse(JSON.generate(artifact)))
    assert_equal(artifact.fetch(:terrainFeatureGeometry).fetch('featureGeometryDigest'),
                 artifact.fetch(:featureGeometryDigest))
  end
end
