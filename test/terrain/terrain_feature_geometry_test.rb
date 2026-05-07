# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/terrain_feature_geometry'

class TerrainFeatureGeometryTest < Minitest::Test
  def test_normalizes_json_safe_backend_neutral_schema_and_digests
    geometry = SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        { id: 'a1', featureId: 'f1', role: 'control', strength: 'hard',
          ownerLocalPoint: [2.0, 3.0], gridPoint: [2, 3], tolerance: 0.05 }
      ],
      protectedRegions: [
        { id: 'p1', featureId: 'f2', role: 'protected', primitive: 'rectangle',
          ownerLocalBounds: [[1.0, 1.0], [4.0, 4.0]], boundaryTolerance: 0.001 }
      ],
      pressureRegions: [
        { id: 'pr1', featureId: 'f3', role: 'side_transition', strength: 'firm',
          primitive: 'corridor', ownerLocalShape: { centerline: [[0.0, 0.0], [6.0, 0.0]],
                                                    width: 2.0, blendDistance: 1.0 },
          targetCellSize: 1 }
      ],
      referenceSegments: [
        { id: 'r1', featureId: 'f3', role: 'endpoint_cap', strength: 'firm',
          ownerLocalStart: [0.0, -1.0], ownerLocalEnd: [0.0, 1.0], tolerance: 0.1 }
      ],
      affectedWindows: [
        { featureId: 'f3', role: 'centerline', minCol: 0, minRow: 0, maxCol: 6, maxRow: 2,
          source: 'derived_influence' }
      ],
      tolerances: [{ featureId: 'f3', role: 'centerline', strength: 'firm', value: 0.02 }]
    )

    payload = geometry.to_h
    expected_keys = %w[
      outputAnchorCandidates protectedRegions pressureRegions referenceSegments affectedWindows
      tolerances featureGeometryDigest referenceGeometryDigest
    ]
    assert_equal(expected_keys, payload.keys)
    assert(JSON.parse(JSON.generate(payload)))
    refute_includes(JSON.generate(payload), 'Sketchup::')
    assert_match(/\A[a-f0-9]{64}\z/, payload.fetch('featureGeometryDigest'))
    assert_match(/\A[a-f0-9]{64}\z/, payload.fetch('referenceGeometryDigest'))
  end

  def test_rejects_unknown_primitive_collection_names
    error = assert_raises(ArgumentError) do
      SU_MCP::Terrain::TerrainFeatureGeometry.new(rawTriangles: [[0, 1, 2]])
    end

    assert_includes(error.message, 'rawTriangles')
  end

  def test_digests_are_stable_for_semantically_identical_payload_order
    first = SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        { id: 'b', featureId: 'f2', role: 'side_transition', strength: 'firm',
          ownerLocalStart: [1.0, 0.0], ownerLocalEnd: [2.0, 0.0] },
        { id: 'a', featureId: 'f1', role: 'centerline', strength: 'firm',
          ownerLocalStart: [0.0, 0.0], ownerLocalEnd: [1.0, 0.0] }
      ]
    )
    second = SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        { 'ownerLocalEnd' => [1.0, 0.0], 'ownerLocalStart' => [0.0, 0.0],
          'strength' => 'firm', 'role' => 'centerline', 'featureId' => 'f1', 'id' => 'a' },
        { 'ownerLocalEnd' => [2.0, 0.0], 'ownerLocalStart' => [1.0, 0.0],
          'strength' => 'firm', 'role' => 'side_transition', 'featureId' => 'f2', 'id' => 'b' }
      ]
    )

    assert_equal(first.feature_geometry_digest, second.feature_geometry_digest)
    assert_equal(first.reference_geometry_digest, second.reference_geometry_digest)
  end
end
