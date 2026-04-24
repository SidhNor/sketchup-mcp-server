# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/scene_query/sample_surface_evidence'
require_relative '../../src/su_mcp/scene_query/scene_query_serializer'

class SampleSurfaceEvidenceTest < Minitest::Test
  # rubocop:disable Metrics/MethodLength
  def test_serializer_shapes_profile_evidence_without_extra_transport_fields
    evidence = SU_MCP::SampleSurfaceEvidence::Sample.new(
      index: 1,
      x: 5.0,
      y: 0.0,
      z: 2.5,
      distance_along_path_meters: 5.0,
      path_progress: 0.5,
      status: 'hit'
    )

    serialized = SU_MCP::SceneQuerySerializer.new.serialize_sampling_evidence(evidence)

    assert_equal(
      {
        index: 1,
        samplePoint: { x: 5.0, y: 0.0 },
        distanceAlongPathMeters: 5.0,
        pathProgress: 0.5,
        status: 'hit',
        hitPoint: { x: 5.0, y: 0.0, z: 2.5 }
      },
      serialized
    )
  end
  # rubocop:enable Metrics/MethodLength

  def test_serializer_does_not_fabricate_hit_point_for_non_hit_evidence
    evidence = SU_MCP::SampleSurfaceEvidence::Sample.new(
      index: 2,
      x: 15.0,
      y: 0.0,
      distance_along_path_meters: 15.0,
      path_progress: 1.0,
      status: 'miss'
    )

    serialized = SU_MCP::SceneQuerySerializer.new.serialize_sampling_evidence(evidence)

    assert_equal('miss', serialized[:status])
    refute(serialized.key?(:hitPoint))
  end
end
