# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/cdt/terrain_cdt_result'

class TerrainCdtResultTest < Minitest::Test
  EXPECTED_FALLBACK_REASONS = %w[
    cdt_disabled feature_geometry_failed native_unavailable native_input_violation
    input_normalization_failed unsupported_constraint_shape intersecting_constraints
    pre_triangulate_budget_exceeded point_budget_exceeded face_budget_exceeded
    runtime_budget_exceeded residual_gate_failed constraint_recovery_failed
    hard_geometry_gate_failed topology_gate_failed invalid_mesh adapter_exception
  ].freeze

  INTERNAL_VOCABULARY = %w[
    backend evidenceMode candidateRow comparisonRows Mta24 mta24 rawTriangles
    expandedConstraints solverPredicates triangulatorKind triangulatorVersion
    ruby_bowyer_watson constrainedDelaunay cdt
  ].freeze

  def test_closed_fallback_reason_set_matches_plan
    assert_equal(
      EXPECTED_FALLBACK_REASONS,
      SU_MCP::Terrain::TerrainCdtResult::FALLBACK_REASONS
    )
  end

  def test_accepted_envelope_is_json_safe_and_contains_runtime_fields
    result = SU_MCP::Terrain::TerrainCdtResult.accepted(
      mesh: { vertices: [[0.0, 0.0, 0.0]], triangles: [[0, 1, 2]] },
      metrics: { faceCount: 1, vertexCount: 3 },
      limits: { pointBudget: 256 },
      limitations: [],
      feature_geometry_digest: 'feature-digest',
      reference_geometry_digest: 'reference-digest',
      state_digest: 'state-digest',
      timing: { totalSeconds: 0.01 }
    )

    assert_equal('accepted', result.fetch(:status))
    assert_equal('state-digest', result.fetch(:stateDigest))
    assert(JSON.parse(JSON.generate(result)))
    refute_internal_vocabulary(result)
  end

  def test_fallback_envelope_uses_closed_reason_and_sanitized_details
    result = SU_MCP::Terrain::TerrainCdtResult.fallback(
      reason: 'adapter_exception',
      details: { errorClass: 'RuntimeError', backtrace: ['internal.rb:1'] },
      metrics: {},
      limits: {},
      limitations: [],
      feature_geometry_digest: 'feature-digest',
      reference_geometry_digest: 'reference-digest',
      state_digest: 'state-digest',
      timing: { totalSeconds: 0.01 }
    )

    assert_equal('fallback', result.fetch(:status))
    assert_equal('adapter_exception', result.fetch(:fallbackReason))
    refute_includes(JSON.generate(result.fetch(:fallbackDetails)), 'RuntimeError')
    refute_includes(JSON.generate(result.fetch(:fallbackDetails)), 'backtrace')
    assert(JSON.parse(JSON.generate(result)))
  end

  def test_envelope_sanitizes_internal_vocabulary_without_candidate_row_input
    result = SU_MCP::Terrain::TerrainCdtResult.fallback(
      reason: 'adapter_exception',
      metrics: {
        triangulatorKind: 'ruby_bowyer_watson_constraint_recovery',
        triangulatorVersion: 'mta24-ruby-cdt-prototype-0'
      },
      limits: {},
      limitations: [{ backend: 'mta24_constrained_delaunay_cdt_prototype' }],
      details: {
        provenance: { source: 'MTA-24 comparison-only prototype' },
        rawTriangles: [[0, 1, 2]]
      },
      state_digest: 'state-digest'
    )

    refute_internal_vocabulary(result)
  end

  private

  def refute_internal_vocabulary(result)
    serialized = JSON.generate(result)
    INTERNAL_VOCABULARY.each { |term| refute_includes(serialized, term) }
  end
end
