# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
begin
  require_relative '../support/terrain_survey_correction_evaluation'
rescue LoadError
  # Skeleton-first TDD: the private evaluation harness is introduced after this surface exists.
end

class SurveyCorrectionEvaluationTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_report_shape_is_json_safe_and_contains_required_metrics
    result = evaluate(
      strategy: :base_detail,
      state: flat_with_local_detail_state,
      survey_points: [survey_point(id: 'survey-1', x: 2.0, y: 2.0, z: 2.0)]
    )
    parsed = JSON.parse(JSON.generate(result))

    assert_equal('base_detail', parsed.fetch('strategy'))
    assert_equal(%w[
      changedRegion cumulativeDrift curvatureProxy detailRetention detailSuppression
      fixedControlDrift maxSampleDelta preserveZoneDrift slopeProxy
    ].sort, parsed.fetch('metrics').keys.sort)
    assert_equal(%w[parameters recommendationInputs refusals strategy surveyPoints warnings].sort,
                 parsed.keys.reject { |key| %w[metrics state].include?(key) }.sort)
    refute_includes(JSON.generate(result), 'Sketchup')
  end

  def test_minimum_change_single_point_uses_bilinear_minimum_norm_delta
    result = evaluate(
      strategy: :minimum_change,
      state: terrain_state(elevations: [0.0, 0.0, 0.0, 0.0], columns: 2, rows: 2),
      survey_points: [survey_point(id: 'center', x: 0.5, y: 0.5, z: 4.0)]
    )

    assert_equal('satisfied', result.dig('recommendationInputs', 'status'))
    assert_equal([4.0, 4.0, 4.0, 4.0], result.dig('state', 'elevations'))
    assert_in_delta(0.0, result.dig('surveyPoints', 0, 'residual'), 1e-9)
    assert_in_delta(4.0, result.dig('metrics', 'maxSampleDelta'), 1e-9)
    assert_equal(4, result.dig('metrics', 'changedRegion', 'sampleCount'))
    assert_equal({ 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 1, 'row' => 1 } },
                 result.dig('metrics', 'changedRegion', 'bounds'))
  end

  def test_minimum_change_multi_point_solve_satisfies_independent_samples
    result = evaluate(
      strategy: :minimum_change,
      state: terrain_state(elevations: Array.new(6, 0.0), columns: 3, rows: 2),
      survey_points: [
        survey_point(id: 'west', x: 0.0, y: 0.0, z: 2.0),
        survey_point(id: 'east', x: 2.0, y: 1.0, z: 5.0)
      ]
    )

    assert_equal(%w[satisfied satisfied], result.fetch('surveyPoints').map do |point|
      point.fetch('status')
    end)
    assert_in_delta(2.0, elevation_at(result.fetch('state'), 0, 0), 1e-9)
    assert_in_delta(5.0, elevation_at(result.fetch('state'), 2, 1), 1e-9)
    assert_equal(2, result.dig('metrics', 'changedRegion', 'sampleCount'))
  end

  def test_base_detail_preserves_outside_detail_and_suppresses_core_detail
    result = evaluate(
      strategy: :base_detail,
      state: flat_with_local_detail_state,
      survey_points: [survey_point(id: 'center', x: 2.0, y: 2.0, z: 2.0)]
    )

    assert_in_delta(0.0, result.dig('surveyPoints', 0, 'residual'), 1e-9)
    assert_operator(result.dig('metrics', 'detailSuppression', 'coreEnergy'), :>, 0.0)
    assert_operator(result.dig('metrics', 'detailSuppression', 'blendEnergy'), :>, 0.0)
    assert_operator(result.dig('metrics', 'detailRetention', 'outsideInfluenceRatio'), :>=, 0.99)
    assert_equal(true, result.dig('recommendationInputs', 'detailPreserving'))
  end

  def test_base_detail_accounts_for_retained_detail_when_solving_base_target
    state = terrain_state(elevations: [
                            1.0, 1.0, 1.0,
                            1.0, 2.0, 1.0,
                            1.0, 1.0, 1.0
                          ], columns: 3, rows: 3)
    result = evaluate(
      strategy: :base_detail,
      state: state,
      survey_points: [survey_point(id: 'blend-point', x: 1.5, y: 1.0, z: 3.0)],
      parameters: default_parameters.merge('coreRadiusM' => 0.0, 'blendRadiusM' => 2.0)
    )

    assert_in_delta(3.0, result.dig('surveyPoints', 0, 'afterElevation'), 1e-9)
    assert_in_delta(0.0, result.dig('surveyPoints', 0, 'residual'), 1e-9)
    assert_operator(
      result.dig('recommendationInputs',
                 'retainedDetailAtSurveyPoints').fetch('blend-point').abs, :>, 0.0
    )
  end

  def test_metric_proxies_report_slope_curvature_fixed_and_preserve_drift
    result = evaluate(
      strategy: :minimum_change,
      state: sloped_noise_state,
      survey_points: [survey_point(id: 'center', x: 2.0, y: 2.0, z: 6.0)],
      fixed_controls: [
        { 'id' => 'edge-control', 'point' => { 'x' => 0.0, 'y' => 0.0 }, 'elevation' => 0.0,
          'tolerance' => 0.01 }
      ],
      preserve_zones: [
        { 'id' => 'corner-preserve', 'type' => 'rectangle',
          'bounds' => rectangle_bounds(min: [4.0, 4.0], max: [4.0, 4.0]) }
      ]
    )

    assert_operator(result.dig('metrics', 'slopeProxy', 'afterMax'), :>=,
                    result.dig('metrics', 'slopeProxy', 'beforeMax'))
    assert_operator(result.dig('metrics', 'curvatureProxy', 'afterMax'), :>=, 0.0)
    assert_in_delta(0.0, result.dig('metrics', 'fixedControlDrift', 'max'), 1e-9)
    assert_in_delta(0.0, result.dig('metrics', 'preserveZoneDrift', 'max'), 1e-9)
  end

  def test_refuses_no_data_out_of_bounds_contradictory_preserve_and_fixed_conflicts
    no_data = flat_with_local_detail_state.elevations.dup
    no_data[12] = nil
    assert_refusal(
      evaluate(
        strategy: :minimum_change,
        state: terrain_state(elevations: no_data, columns: 5, rows: 5),
        survey_points: [survey_point(id: 'center', x: 2.0, y: 2.0, z: 2.0)]
      ),
      'survey_point_over_no_data'
    )
    assert_refusal(evaluate(strategy: :minimum_change,
                            survey_points: [survey_point(id: 'outside', x: 99.0, y: 99.0, z: 1.0)]),
                   'survey_point_outside_bounds')
    assert_refusal(evaluate(strategy: :minimum_change,
                            survey_points: [
                              survey_point(id: 'a', x: 2.0, y: 2.0, z: 1.0),
                              survey_point(id: 'b', x: 2.0, y: 2.0, z: 3.0)
                            ]),
                   'contradictory_survey_points')
    assert_refusal(evaluate(strategy: :minimum_change,
                            survey_points: [survey_point(id: 'center', x: 2.0, y: 2.0, z: 2.0)],
                            preserve_zones: [
                              { 'id' => 'protected', 'type' => 'circle',
                                'center' => { 'x' => 2.0, 'y' => 2.0 }, 'radius' => 0.5 }
                            ]),
                   'survey_point_preserve_zone_conflict')
    assert_refusal(evaluate(strategy: :minimum_change,
                            state: terrain_state(elevations: [0.0, 0.0, 0.0, 0.0],
                                                 columns: 2,
                                                 rows: 2),
                            survey_points: [survey_point(id: 'overlap', x: 0.75, y: 0.75, z: 4.0)],
                            preserve_zones: [
                              { 'id' => 'protected-stencil-sample', 'type' => 'rectangle',
                                'bounds' => rectangle_bounds(min: [0.0, 0.0], max: [0.0, 0.0]) }
                            ]),
                   'survey_point_preserve_zone_conflict')
    assert_refusal(evaluate(strategy: :minimum_change,
                            survey_points: [survey_point(id: 'near-control', x: 0.5, y: 0.5,
                                                         z: 9.0)],
                            fixed_controls: [
                              { 'id' => 'control', 'point' => { 'x' => 0.0, 'y' => 0.0 },
                                'elevation' => 0.0, 'tolerance' => 0.01 }
                            ]),
                   'fixed_control_conflict')
  end

  def test_refuses_required_sample_delta_above_threshold
    result = evaluate(
      strategy: :minimum_change,
      state: terrain_state(elevations: [0.0, 0.0, 0.0, 0.0], columns: 2, rows: 2),
      survey_points: [survey_point(id: 'center', x: 0.5, y: 0.5, z: 100.0)],
      parameters: default_parameters.merge('maxSampleDelta' => 1.0)
    )

    assert_refusal(result, 'required_sample_delta_exceeds_threshold')
    assert_in_delta(100.0, result.dig('metrics', 'maxSampleDelta'), 1e-9)
  end

  def test_repeated_edit_workflow_reports_cumulative_drift_outside_current_influence
    workflow = SU_MCP::Terrain::SurveyCorrectionEvaluation.repeated_workflow(
      state: sloped_noise_state,
      steps: [
        [survey_point(id: 'first', x: 1.0, y: 1.0, z: 3.0)],
        [survey_point(id: 'batch-a', x: 3.0, y: 1.0, z: 5.0),
         survey_point(id: 'batch-b', x: 1.0, y: 3.0, z: 5.0)],
        [survey_point(id: 'first-corrected', x: 1.0, y: 1.0, z: 3.2)]
      ],
      strategy: :base_detail,
      parameters: default_parameters
    )

    assert_equal(3, workflow.fetch('steps').length)
    assert_operator(workflow.fetch('metrics').fetch('cumulativeDrift').fetch('max'), :>=, 0.0)
    assert_equal('satisfied', workflow.fetch('recommendationInputs').fetch('status'))
  end

  def test_recommendation_selects_base_detail_tuple_from_parameter_matrix
    result = SU_MCP::Terrain::SurveyCorrectionEvaluation.compare_strategies(
      state: flat_with_local_detail_state,
      survey_points: [survey_point(id: 'center', x: 2.0, y: 2.0, z: 2.0)],
      parameter_matrix: parameter_matrix
    )

    assert_equal('base_detail', result.dig('recommendation', 'strategy'))
    expected_parameters = {
      'radiusSamples' => 1,
      'passes' => 1,
      'coreRadiusM' => 0.5,
      'blendRadiusM' => 1.5,
      'falloff' => 'smoothstep'
    }
    selected_parameters = result.dig('recommendation', 'parameters').slice(
      'radiusSamples',
      'passes',
      'coreRadiusM',
      'blendRadiusM',
      'falloff'
    )

    assert_equal(expected_parameters, selected_parameters)
    assert_equal(false, result.dig('recommendation', 'thresholdOnly'))
    assert_includes(result.fetch('evaluations').map do |evaluation|
      evaluation.fetch('strategy')
    end, 'minimum_change')
  end

  def test_threshold_only_or_constrained_penalty_paths_are_not_marked_detail_preserving
    recommendation = SU_MCP::Terrain::SurveyCorrectionEvaluation.recommend_from(
      [
        {
          'strategy' => 'minimum_change',
          'recommendationInputs' => {
            'status' => 'warn',
            'detailPreserving' => false,
            'thresholdOnly' => true
          }
        }
      ]
    )

    assert_equal('escalate_mta11', recommendation.fetch('status'))
    assert_equal(false, recommendation.fetch('detailPreserving'))
    assert_equal('constrained_penalty_solver_deferred', recommendation.fetch('deferredSolver'))
  end

  def test_evaluation_harness_stays_out_of_runtime_contract_paths
    source_path = SU_MCP::Terrain::SurveyCorrectionEvaluation.instance_method(:run)
                                                             .source_location
                                                             .fetch(0)

    assert_includes(source_path, '/test/support/')
    refute_includes(source_path, '/src/su_mcp/runtime/')
    refute_includes(source_path, '/src/su_mcp/terrain/terrain_state_serializer.rb')
  end

  private

  def evaluate(strategy:, survey_points:, state: flat_with_local_detail_state,
               fixed_controls: [], preserve_zones: [], parameters: default_parameters)
    SU_MCP::Terrain::SurveyCorrectionEvaluation.run(
      state: state,
      survey_points: survey_points,
      fixed_controls: fixed_controls,
      preserve_zones: preserve_zones,
      strategy: strategy,
      parameters: parameters
    )
  end

  def assert_refusal(result, code)
    assert_equal('refuse', result.dig('recommendationInputs', 'status'))
    assert_equal(code, result.fetch('refusals').fetch(0).fetch('code'))
  end

  def survey_point(id:, x:, y:, z:, tolerance: 0.01)
    { 'id' => id, 'point' => { 'x' => x, 'y' => y, 'z' => z }, 'tolerance' => tolerance }
  end

  def default_parameters
    {
      'radiusSamples' => 1,
      'passes' => 1,
      'coreRadiusM' => 0.5,
      'blendRadiusM' => 1.5,
      'falloff' => 'smoothstep',
      'surveyTolerance' => 0.01,
      'fixedControlTolerance' => 0.01,
      'maxSampleDelta' => 20.0,
      'slopeIncreaseLimit' => 20.0,
      'curvatureIncreaseLimit' => 20.0,
      'materialDeltaTolerance' => 1e-6
    }
  end

  def parameter_matrix
    [
      default_parameters.merge('radiusSamples' => 1, 'passes' => 1, 'coreRadiusM' => 0.5,
                               'blendRadiusM' => 1.5),
      default_parameters.merge('radiusSamples' => 2, 'passes' => 2, 'coreRadiusM' => 1.0,
                               'blendRadiusM' => 2.0)
    ]
  end

  def flat_with_local_detail_state
    terrain_state(
      elevations: [
        0.0, 0.0, 0.25, 0.0, 0.0,
        0.0, 0.2, -0.2, 0.15, 0.0,
        0.25, -0.2, 1.0, -0.2, 0.25,
        0.0, 0.15, -0.2, 0.2, 0.0,
        0.0, 0.0, 0.25, 0.0, 0.0
      ],
      columns: 5,
      rows: 5
    )
  end

  def sloped_noise_state
    terrain_state(
      elevations: [
        0.0, 1.1, 2.0, 3.1, 4.0,
        1.0, 2.2, 3.0, 4.2, 5.0,
        2.0, 3.1, 4.5, 5.1, 6.0,
        3.0, 4.2, 5.0, 6.2, 7.0,
        4.0, 5.1, 6.0, 7.1, 8.0
      ],
      columns: 5,
      rows: 5
    )
  end

  def rectangle_bounds(min:, max:)
    {
      'minX' => min[0],
      'minY' => min[1],
      'maxX' => max[0],
      'maxY' => max[1]
    }
  end

  def terrain_state(elevations:, columns:, rows:)
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end

  def elevation_at(state, column, row)
    state.fetch('elevations').fetch((row * state.fetch('dimensions').fetch('columns')) + column)
  end
end
