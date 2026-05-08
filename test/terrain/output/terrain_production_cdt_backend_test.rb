# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/terrain_production_cdt_backend'

class TerrainProductionCdtBackendTest < Minitest::Test
  def test_disabled_gate_returns_cdt_disabled_without_engine_call
    engine = RecordingResidualEngine.new(engine_result)
    result = backend(enabled: false, residual_engine: engine).build(**input)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('cdt_disabled', result.fetch(:fallbackReason))
    assert_equal(0, engine.calls)
  end

  def test_accepted_engine_result_maps_to_production_envelope_without_candidate_vocab
    result = backend(residual_engine: RecordingResidualEngine.new(engine_result)).build(**input)

    assert_equal('accepted', result.fetch(:status))
    assert_equal([[0, 1, 2]], result.dig(:mesh, :triangles))
    assert_equal('state-digest', result.fetch(:stateDigest))
    refute_internal_vocabulary(result)
  end

  def test_intersecting_constraint_limitation_does_not_trigger_ruby_cdt_fallback_by_itself
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(limitations: [{ category: 'intersecting_constraint' }])
      )
    ).build(**input)

    assert_equal('accepted', result.fetch(:status))
    refute_includes(result.keys, :fallbackReason)
    assert_includes(JSON.generate(result.fetch(:limitations)), 'intersecting_constraint')
  end

  def test_residual_miss_is_diagnostic_not_current_backend_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(metrics: { maxHeightError: 0.25 })
      )
    ).build(**input)

    assert_equal('accepted', result.fetch(:status))
    refute_includes(result.keys, :fallbackReason)
    refute_internal_vocabulary(result)
  end

  def test_small_residual_excess_does_not_force_current_backend_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(
          metrics: {
            maxHeightError: 0.066,
            residualRefinement: { maxResidualExcess: 0.016 }
          }
        )
      )
    ).build(**input)

    assert_equal('accepted', result.fetch(:status))
    refute_includes(result.keys, :fallbackReason)
  end

  def test_material_residual_excess_is_diagnostic_not_current_backend_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(
          metrics: {
            maxHeightError: 0.095,
            residualRefinement: { maxResidualExcess: 0.045 }
          }
        )
      )
    ).build(**input)

    assert_equal('accepted', result.fetch(:status))
    refute_includes(result.keys, :fallbackReason)
  end

  def test_strict_quality_gate_can_restore_residual_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(metrics: { maxHeightError: 0.25 })
      ),
      strict_quality_gates: true,
      max_residual_error: 0.05
    ).build(**input)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('residual_gate_failed', result.fetch(:fallbackReason))
  end

  def test_topology_gate_failure_maps_to_closed_fallback_reason
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(
          metrics: {
            topologyChecks: { downFaceCount: 0, nonManifoldEdgeCount: 1, invalidFaceCount: 0 }
          }
        )
      )
    ).build(**input)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('topology_gate_failed', result.fetch(:fallbackReason))
  end

  def test_completed_runtime_budget_overrun_is_diagnostic_not_current_backend_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(budget_status: 'max_runtime_budget_exceeded')
      )
    ).build(**input)

    assert_equal('accepted', result.fetch(:status))
    refute_includes(result.keys, :fallbackReason)
    assert_equal('max_runtime_budget_exceeded', result.dig(:metrics, :budgetStatus))
  end

  def test_strict_quality_gate_can_restore_runtime_budget_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(budget_status: 'max_runtime_budget_exceeded')
      ),
      strict_quality_gates: true
    ).build(**input)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('runtime_budget_exceeded', result.fetch(:fallbackReason))
  end

  def test_firm_feature_residual_high_is_diagnostic_not_current_backend_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(failure_category: 'firm_feature_residual_high')
      )
    ).build(**input)

    assert_equal('accepted', result.fetch(:status))
    refute_includes(result.keys, :fallbackReason)
  end

  def test_strict_quality_gate_can_restore_firm_feature_residual_fallback
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(failure_category: 'firm_feature_residual_high')
      ),
      strict_quality_gates: true
    ).build(**input)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('constraint_recovery_failed', result.fetch(:fallbackReason))
  end

  def test_point_budget_status_still_maps_to_closed_fallback_reason
    result = backend(
      residual_engine: RecordingResidualEngine.new(
        engine_result(budget_status: 'max_point_budget_exceeded')
      )
    ).build(**input)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('point_budget_exceeded', result.fetch(:fallbackReason))
  end

  def test_residual_engine_exception_maps_to_adapter_exception_fallback
    result = backend(residual_engine: RaisingResidualEngine.new).build(**input)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('adapter_exception', result.fetch(:fallbackReason))
    refute_includes(JSON.generate(result), 'boom')
    refute_includes(JSON.generate(result), 'RaisingResidualEngine')
  end

  def test_production_cdt_files_do_not_depend_on_probe_harness_vocabulary
    production_files = %w[
      residual_cdt_engine.rb
      terrain_production_cdt_result.rb
      terrain_cdt_primitive_request.rb
      terrain_triangulation_adapter.rb
      terrain_production_cdt_backend.rb
    ].map do |name|
      File.expand_path("../../../src/su_mcp/terrain/output/#{name}", __dir__)
    end
    serialized = production_files.map { |path| File.read(path, encoding: 'utf-8') }.join("\n")

    %w[
      Mta24 mta24 candidateRow candidateRows comparisonRows HostedBakeoff ThreeWay
      from_candidate_row candidate_row
    ].each do |term|
      refute_includes(serialized, term)
    end
  end

  private

  def backend(**options)
    SU_MCP::Terrain::TerrainProductionCdtBackend.new(**options)
  end

  def input
    {
      state: Object.new,
      feature_geometry: Object.new,
      state_digest: 'state-digest',
      feature_geometry_digest: 'feature-digest',
      reference_geometry_digest: 'reference-digest'
    }
  end

  def engine_result(metrics: {}, limitations: [], budget_status: 'ok',
                    failure_category: 'none')
    {
      status: 'accepted',
      mesh: { vertices: [[0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0]],
              triangles: [[0, 1, 2]] },
      metrics: {
        maxHeightError: 0.01,
        hardViolationCounts: {},
        topologyChecks: { downFaceCount: 0, nonManifoldEdgeCount: 0, invalidFaceCount: 0 },
        budgetStatus: budget_status
      }.merge(metrics),
      limits: { pointBudget: 256, faceBudget: 512 },
      limitations: limitations,
      timing: { totalSeconds: 0.01 },
      budgetStatus: budget_status,
      failureCategory: failure_category,
      featureGeometryDigest: 'feature-digest',
      referenceGeometryDigest: 'reference-digest',
      stateDigest: 'state-digest'
    }
  end

  def refute_internal_vocabulary(result)
    serialized = JSON.generate(result)
    %w[
      backend candidateRow comparisonRows Mta24 mta24 rawTriangles expandedConstraints
      solverPredicates triangulatorKind triangulatorVersion ruby_bowyer_watson
    ].each { |term| refute_includes(serialized, term) }
  end

  class RecordingResidualEngine
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = 0
    end

    def run(...)
      @calls += 1
      @result
    end
  end

  class RaisingResidualEngine
    def run(...)
      raise 'boom'
    end
  end
end
