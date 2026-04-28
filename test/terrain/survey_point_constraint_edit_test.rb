# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../support/terrain_survey_correction_evaluation'
begin
  require_relative '../../src/su_mcp/terrain/survey_point_constraint_edit'
rescue LoadError
  # Skeleton-first TDD: production survey editor is introduced by MTA-13.
end

class SurveyPointConstraintEditTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_local_single_point_satisfies_constraint_and_reports_survey_evidence
    result = editor.apply(
      state: flat_state,
      request: survey_request(points: [survey_point(id: 'center', x: 1.0, y: 1.0, z: 2.0)])
    )

    assert_equal('edited', result.fetch(:outcome))
    assert_in_delta(2.0, elevation_at(result.fetch(:state), 1, 1), 1e-9)
    survey = result.dig(:diagnostics, :survey)
    assert_equal('local', survey.dig(:correction, :correctionScope))
    assert_equal('rectangle', survey.dig(:correction, :supportRegionType))
    assert_equal('satisfied', survey.fetch(:points).first.fetch(:status))
    assert_in_delta(0.0, survey.fetch(:points).first.fetch(:residual), 1e-9)
  end

  def test_local_multiple_points_and_repeated_correction_use_current_state
    first = editor.apply(
      state: flat_state,
      request: survey_request(points: [
                                survey_point(id: 'west', x: 0.0, y: 0.0, z: 1.0),
                                survey_point(id: 'east', x: 2.0, y: 2.0, z: 3.0)
                              ])
    )
    second = editor.apply(
      state: first.fetch(:state),
      request: survey_request(points: [survey_point(id: 'west-corrected', x: 0.0, y: 0.0, z: 1.25)])
    )

    assert_equal('edited', second.fetch(:outcome))
    assert_in_delta(1.25, elevation_at(second.fetch(:state), 0, 0), 1e-9)
    assert_equal(3, second.fetch(:state).revision)
    assert_operator(second.dig(:diagnostics, :survey, :correction, :cumulativeDrift, :max), :>=,
                    0.0)
  end

  def test_duplicate_identical_survey_points_are_reported_without_singular_solve
    result = editor.apply(
      state: flat_state,
      request: survey_request(points: [
                                survey_point(id: 'duplicate-a', x: 1.0, y: 1.0, z: 1.5),
                                survey_point(id: 'duplicate-b', x: 1.0, y: 1.0, z: 1.5)
                              ])
    )

    assert_equal('edited', result.fetch(:outcome))
    points = result.dig(:diagnostics, :survey, :points)
    assert_equal(%w[duplicate-a duplicate-b], points.map { |point| point.fetch(:id) })
    assert_equal(%w[satisfied satisfied], points.map { |point| point.fetch(:status) })
  end

  def test_regional_correction_changes_coherent_support_field_not_only_survey_stencils
    result = editor.apply(
      state: sloped_state,
      request: survey_request(
        correction_scope: 'regional',
        region: {
          'type' => 'rectangle',
          'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 4.0, 'maxY' => 4.0 },
          'blend' => { 'distance' => 0.0, 'falloff' => 'none' }
        },
        points: [
          survey_point(id: 'west', x: 0.0, y: 0.0, z: 0.5),
          survey_point(id: 'east', x: 4.0, y: 4.0, z: 8.5)
        ]
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    correction = result.dig(:diagnostics, :survey, :correction)
    assert_equal('regional', correction.fetch(:correctionScope))
    assert_operator(correction.fetch(:changedSampleCount), :>, 8)
    assert_equal('satisfied', correction.fetch(:regionalCoherence).fetch(:status))
    assert_operator(correction.dig(:distortion, :slopeProxy, :maxIncrease), :>=, 0.0)
  end

  def test_regional_full_support_replaces_planar_crossfall_without_edge_bowing
    result = editor.apply(
      state: crossfall_state,
      request: survey_request(
        correction_scope: 'regional',
        region: {
          'type' => 'rectangle',
          'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 30.0, 'maxY' => 30.0 },
          'blend' => { 'distance' => 0.0, 'falloff' => 'none' }
        },
        points: [
          survey_point(id: 'sw', x: 0.0, y: 0.0, z: 1.0, tolerance: 0.0),
          survey_point(id: 'se', x: 30.0, y: 0.0, z: 1.0, tolerance: 0.0),
          survey_point(id: 'nw', x: 0.0, y: 30.0, z: 2.2, tolerance: 0.0),
          survey_point(id: 'ne', x: 30.0, y: 30.0, z: 2.2, tolerance: 0.0)
        ]
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    state = result.fetch(:state)
    assert_in_delta(1.0, elevation_at(state, 15, 0), 1e-9)
    assert_in_delta(2.2, elevation_at(state, 15, 30), 1e-9)
    assert_in_delta(1.6, elevation_at(state, 0, 15), 1e-9)
    assert_in_delta(1.6, elevation_at(state, 30, 15), 1e-9)
    assert_in_delta(0.0, elevation_at(state, 30, 15) - elevation_at(state, 0, 15), 1e-9)
    assert_in_delta(1.2, elevation_at(state, 15, 30) - elevation_at(state, 15, 0), 1e-9)
  end

  def test_regional_full_support_respects_piecewise_planar_crowned_breakline
    result = editor.apply(
      state: crossfall_state,
      request: survey_request(
        correction_scope: 'regional',
        region: {
          'type' => 'rectangle',
          'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 30.0, 'maxY' => 30.0 },
          'blend' => { 'distance' => 0.0, 'falloff' => 'none' }
        },
        points: crowned_breakline_points
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    state = result.fetch(:state)
    assert_in_delta(1.0, elevation_at(state, 0, 8), 1e-9)
    assert_in_delta(1.6, elevation_at(state, 15, 8), 1e-9)
    assert_in_delta(1.0, elevation_at(state, 30, 8), 1e-9)
    assert_in_delta(0.0, max_crowned_error(state), 1e-9)
  end

  def crowned_breakline_points
    [0.0, 15.0, 30.0].flat_map do |y|
      [
        survey_point(id: "w-#{y}", x: 0.0, y: y, z: 1.0, tolerance: 0.0),
        survey_point(id: "c-#{y}", x: 15.0, y: y, z: 1.6, tolerance: 0.0),
        survey_point(id: "e-#{y}", x: 30.0, y: y, z: 1.0, tolerance: 0.0)
      ]
    end
  end

  def max_crowned_error(state)
    state.elevations.each_index.map do |index|
      column = index % state.dimensions.fetch('columns')
      row = index / state.dimensions.fetch('columns')
      (elevation_at(state, column, row) - (1.0 + (0.04 * [column, 30 - column].min))).abs
    end.max
  end

  def test_production_solver_matches_mta14_base_detail_oracle_for_representative_local_detail
    survey_points = [survey_point(id: 'center', x: 2.0, y: 2.0, z: 2.0)]
    oracle = SU_MCP::Terrain::SurveyCorrectionEvaluation.run(
      strategy: :base_detail,
      state: flat_with_local_detail_state,
      survey_points: survey_points,
      parameters: mta14_default_parameters
    )

    result = editor.apply(
      state: flat_with_local_detail_state,
      request: survey_request(
        points: survey_points,
        region: {
          'type' => 'rectangle',
          'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 4.0, 'maxY' => 4.0 },
          'blend' => { 'distance' => 0.0, 'falloff' => 'none' }
        }
      )
    )

    assert_equal('edited', result.fetch(:outcome))
    survey = result.dig(:diagnostics, :survey)
    assert_in_delta(
      oracle.dig('surveyPoints', 0, 'residual'),
      survey.fetch(:points).first.fetch(:residual),
      1e-9
    )
    assert_equal(
      oracle.dig('metrics', 'changedRegion', 'sampleCount'),
      survey.dig(:correction, :changedSampleCount)
    )
    assert_in_delta(
      oracle.dig('metrics', 'detailRetention', 'outsideInfluenceRatio'),
      survey.dig(:correction, :detailPreservation, :outsideInfluenceRatio),
      1e-9
    )
    assert_in_delta(
      oracle.dig('metrics', 'detailSuppression', 'coreEnergy'),
      survey.dig(:correction, :detailSuppression, :coreEnergy),
      1e-9
    )
    assert_in_delta(
      oracle.dig('metrics', 'detailSuppression', 'blendEnergy'),
      survey.dig(:correction, :detailSuppression, :blendEnergy),
      1e-9
    )
  end

  def test_refuses_out_of_bounds_outside_support_no_data_and_contradictory_points
    no_data = flat_state.elevations.dup
    no_data[4] = nil
    assert_refusal(
      editor.apply(
        state: state(elevations: no_data, columns: 3, rows: 3),
        request: survey_request(points: [survey_point(id: 'no-data', x: 1.0, y: 1.0, z: 1.0)])
      ),
      'survey_point_over_no_data'
    )
    assert_refusal(
      editor.apply(
        state: flat_state,
        request: survey_request(points: [survey_point(id: 'outside', x: 99.0, y: 99.0, z: 1.0)])
      ),
      'survey_point_outside_bounds'
    )
    assert_refusal(
      editor.apply(
        state: flat_state,
        request: survey_request(
          region: {
            'type' => 'circle',
            'center' => { 'x' => 0.0, 'y' => 0.0 },
            'radius' => 0.25,
            'blend' => { 'distance' => 0.0, 'falloff' => 'none' }
          },
          points: [survey_point(id: 'outside-support', x: 2.0, y: 2.0, z: 1.0)]
        )
      ),
      'survey_point_outside_support_region'
    )
    assert_refusal(
      editor.apply(
        state: flat_state,
        request: survey_request(points: [
                                  survey_point(id: 'a', x: 1.0, y: 1.0, z: 1.0),
                                  survey_point(id: 'b', x: 1.0, y: 1.0, z: 2.0)
                                ])
      ),
      'contradictory_survey_points'
    )
  end

  def test_refuses_fixed_control_preserve_zone_and_unsafe_delta_conflicts
    assert_refusal(
      editor.apply(
        state: flat_state,
        request: survey_request(
          points: [survey_point(id: 'near-control', x: 0.5, y: 0.5, z: 9.0)],
          fixed_controls: [
            { 'id' => 'control', 'point' => { 'x' => 0.0, 'y' => 0.0 },
              'elevation' => 0.0, 'tolerance' => 0.01 }
          ]
        )
      ),
      'fixed_control_conflict'
    )
    assert_refusal(
      editor.apply(
        state: flat_state,
        request: survey_request(
          points: [survey_point(id: 'protected-point', x: 1.0, y: 1.0, z: 2.0)],
          preserve_zones: [
            { 'id' => 'protected', 'type' => 'circle',
              'center' => { 'x' => 1.0, 'y' => 1.0 }, 'radius' => 0.5 }
          ]
        )
      ),
      'survey_point_preserve_zone_conflict'
    )
    assert_refusal(
      editor.apply(
        state: flat_state,
        request: survey_request(points: [survey_point(id: 'too-high', x: 1.0, y: 1.0, z: 100.0)])
      ),
      'required_sample_delta_exceeds_threshold'
    )
  end

  def test_refuses_unsafe_regional_correction_when_coherence_thresholds_are_exceeded
    result = editor.apply(
      state: flat_state,
      request: survey_request(
        correction_scope: 'regional',
        points: [
          survey_point(id: 'a', x: 0.0, y: 0.0, z: 0.0),
          survey_point(id: 'b', x: 1.0, y: 1.0, z: 10.0),
          survey_point(id: 'c', x: 2.0, y: 2.0, z: 0.0)
        ]
      )
    )

    assert_refusal(result, 'regional_correction_unsafe')
  end

  private

  def editor
    SU_MCP::Terrain::SurveyPointConstraintEdit.new
  end

  def assert_refusal(result, code)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end

  def survey_request(points:, correction_scope: 'local', region: default_region,
                     fixed_controls: [], preserve_zones: [])
    {
      'operation' => {
        'mode' => 'survey_point_constraint',
        'correctionScope' => correction_scope
      },
      'region' => region,
      'constraints' => {
        'surveyPoints' => points,
        'fixedControls' => fixed_controls,
        'preserveZones' => preserve_zones
      }
    }
  end

  def survey_point(id:, x:, y:, z:, tolerance: 0.01)
    { 'id' => id, 'point' => { 'x' => x, 'y' => y, 'z' => z }, 'tolerance' => tolerance }
  end

  def default_region
    {
      'type' => 'rectangle',
      'bounds' => { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 2.0, 'maxY' => 2.0 },
      'blend' => { 'distance' => 0.0, 'falloff' => 'none' }
    }
  end

  def flat_state
    state(elevations: Array.new(9, 0.0), columns: 3, rows: 3)
  end

  def sloped_state
    state(
      elevations: [
        0.0, 1.0, 2.0, 3.0, 4.0,
        1.0, 2.0, 3.0, 4.0, 5.0,
        2.0, 3.0, 4.0, 5.0, 6.0,
        3.0, 4.0, 5.0, 6.0, 7.0,
        4.0, 5.0, 6.0, 7.0, 8.0
      ],
      columns: 5,
      rows: 5
    )
  end

  def flat_with_local_detail_state
    state(
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

  def crossfall_state
    elevations = (0...31).flat_map do |_row|
      (0...31).map { |column| 1.0 + (0.04 * column) }
    end
    state(elevations: elevations, columns: 31, rows: 31)
  end

  def mta14_default_parameters
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

  def state(elevations:, columns:, rows:)
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
    state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
  end
end
