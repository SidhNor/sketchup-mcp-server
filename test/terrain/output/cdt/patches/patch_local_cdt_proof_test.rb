# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../support/patch_cdt_test_support'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_local_cdt_proof'

class PatchLocalCdtProofTest < Minitest::Test
  include PatchCdtTestSupport

  def test_returns_json_safe_internal_evidence_without_public_contract_fields
    state = rough_state
    result = proof.run(
      state: state,
      feature_geometry: patch_feature_geometry,
      output_plan: dirty_output_plan(state: state),
      base_tolerance: 0.05,
      max_point_budget: 128,
      max_face_budget: 256,
      max_runtime_budget: 2.0
    )

    assert_includes(%w[accepted fallback], result.fetch(:status))
    assert_equal('patch_local_incremental_residual_cdt_proof', result.fetch(:proofType))
    assert(result.key?(:patchDomain))
    assert(result.key?(:residualQuality))
    assert(result.key?(:affectedRegion))
    assert(result.key?(:timing))
    assert_json_safe(result)
    %w[rawTriangles residualQueue candidateRows patchCdtDiagnostics].each do |term|
      refute_includes(JSON.generate(public_projection(result)), term)
    end
  end

  def test_empty_dirty_window_returns_deterministic_internal_fallback
    result = proof.run(
      state: patch_state,
      feature_geometry: empty_feature_geometry,
      output_plan: NullOutputPlan.new(SU_MCP::Terrain::SampleWindow.new(empty: true)),
      base_tolerance: 0.05,
      max_point_budget: 128,
      max_face_budget: 256,
      max_runtime_budget: 2.0
    )

    assert_equal('fallback', result.fetch(:status))
    assert_equal('refused_unsupported_topology', result.fetch(:fallbackCategory))
    assert_equal('empty_dirty_window', result.fetch(:stopReason))
  end

  def test_proof_runner_does_not_call_global_residual_engine_or_production_replacement
    residual_engine = ForbiddenCollaborator.new('ResidualCdtEngine')
    point_planner = ForbiddenCollaborator.new('CdtTerrainPointPlanner')
    mesh_generator = ForbiddenCollaborator.new('TerrainMeshGenerator')
    state = flat_state

    result = SU_MCP::Terrain::PatchLocalCdtProof.new(
      residual_engine: residual_engine,
      point_planner: point_planner,
      mesh_generator: mesh_generator
    ).run(
      state: state,
      feature_geometry: empty_feature_geometry,
      output_plan: dirty_output_plan(state: state),
      base_tolerance: 0.05,
      max_point_budget: 128,
      max_face_budget: 256,
      max_runtime_budget: 2.0
    )

    assert_includes(%w[accepted fallback], result.fetch(:status))
    assert_equal(0, residual_engine.calls)
    assert_equal(0, point_planner.calls)
    assert_equal(0, mesh_generator.calls)
  end

  def test_rough_patch_refinement_accepts_multiple_residual_insertions_without_rebuilds
    state = rough_state(columns: 9, rows: 9)

    result = proof.run(
      state: state,
      feature_geometry: empty_feature_geometry,
      output_plan: dirty_output_plan(state: state),
      base_tolerance: 0.05,
      max_point_budget: 96,
      max_face_budget: 192,
      max_runtime_budget: 2.0
    )

    assert_equal('accepted', result.fetch(:status))
    assert_equal('residual_satisfied', result.fetch(:stopReason))
    assert_operator(result.dig(:affectedRegion, :insertionCount), :>, 1)
    assert_operator(
      result.dig(:residualQuality, :maxHeightError),
      :<,
      result.dig(:residualQuality, :initialMaxHeightError)
    )
    assert(result.dig(:topology, :passed))
    assert_equal(0, result.dig(:topology, :longEdgeCount))
    assert_in_delta(1.0, result.dig(:topology, :areaCoverageRatio), 0.02)
    result.dig(:affectedRegion, :insertionDiagnostics).each do |diagnostics|
      refute(diagnostics.fetch(:rebuildDetected))
      assert_includes(%w[affected bounded_neighborhood], diagnostics.fetch(:recomputationScope))
      assert_operator(
        diagnostics.fetch(:recomputedSampleCount),
        :<=,
        diagnostics.fetch(:recomputationLimit)
      )
    end
  end

  def test_debug_mesh_is_internal_and_only_returned_when_requested
    state = rough_state(columns: 9, rows: 9)
    arguments = {
      state: state,
      feature_geometry: empty_feature_geometry,
      output_plan: dirty_output_plan(state: state),
      base_tolerance: 0.05,
      max_point_budget: 96,
      max_face_budget: 192,
      max_runtime_budget: 2.0
    }

    default_result = proof.run(**arguments)
    debug_result = proof.run(**arguments, include_debug_mesh: true)

    refute(default_result.key?(:debugMesh))
    assert(debug_result.key?(:debugMesh))
    assert_operator(debug_result.dig(:debugMesh, :vertices).length, :>, 0)
    assert_operator(debug_result.dig(:debugMesh, :triangles).length, :>, 0)
    assert_json_safe(debug_result)
    refute_includes(JSON.generate(public_projection(debug_result)), 'debugMesh')
  end

  private

  def proof
    SU_MCP::Terrain::PatchLocalCdtProof.new
  end

  def public_projection(result)
    {
      summary: {
        derivedMesh: {
          meshType: 'regular_grid',
          vertexCount: result.dig(:counts, :vertexCount),
          faceCount: result.dig(:counts, :faceCount)
        }
      }
    }
  end

  class NullOutputPlan
    attr_reader :window

    def initialize(window)
      @window = window
    end
  end

  class ForbiddenCollaborator
    attr_reader :calls

    def initialize(_name)
      @calls = 0
    end

    def method_missing(*)
      @calls += 1
      raise 'forbidden collaborator called'
    end

    def respond_to_missing?(*)
      true
    end
  end
end
