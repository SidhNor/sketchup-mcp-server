# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/adaptive_terrain_regression_fixtures'
require_relative '../../../src/su_mcp/terrain/edits/corridor_transition_edit'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/output/terrain_output_plan'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

# rubocop:disable Metrics/ClassLength
class AdaptiveTerrainRegressionFixtureTest < Minitest::Test
  REQUIRED_CASE_IDS = %w[
    created_flat_corridor_mta21
    created_crossfall_corridor_mta21
    created_steep_corridor_mta21
    created_non_square_corridor_mta21
    adopted_irregular_before_corridor_mta21
    adopted_irregular_grid_aligned_corridor_mta21
    adopted_irregular_off_grid_corridor_mta21
    aggressive_stacked_created_terrain_mta21
    high_relief_seam_stress_mta21
  ].freeze

  FORBIDDEN_SOURCE_TRUTH_KEYS = %w[
    sketchupObject entityId persistentId generatedMesh faces vertices rawTriangles
    adaptiveCells emissionTriangles fanCenter splitGrid boundaryVertices
  ].freeze

  FORBIDDEN_SOURCE_TRUTH_TERMS = %w[
    adaptiveCells emissionTriangles fanCenter boundaryVertices rawTriangles
  ].freeze

  REQUIRED_REPRESENTATIVENESS_TRAITS = %w[
    flat crossfall steep non_square ridge valley mound hollow ripple base_slope
    aggressive_stack high_relief_seam_stress
  ].freeze

  def test_canonical_fixture_pack_loads_from_repo_path
    assert(File.file?(AdaptiveTerrainRegressionFixtures::CANONICAL_PATH))

    pack = AdaptiveTerrainRegressionFixtures.load

    assert_equal('MTA-22', pack.document.fetch('sourceTask'))
    assert_includes(pack.document.keys, 'schemaVersion')
    assert_includes(pack.document.keys, 'baseline')
    assert_includes(pack.document.keys, 'baselineResults')
    assert_includes(pack.document.keys, 'coverageLimitations')
    assert_includes(pack.document.keys, 'validationCommands')
    assert_operator(pack.cases.length, :>=, REQUIRED_CASE_IDS.length)
  end

  def test_loader_validates_required_root_and_case_fields
    assert_validation_error(document_without('schemaVersion'), 'schemaVersion')
    assert_validation_error(document_without('baselineResults'), 'baselineResults')
    assert_validation_error(document_without('coverageLimitations'), 'coverageLimitations')
    assert_validation_error(document_with_case_without('terrain'), 'terrain')
  end

  def test_loader_rejects_missing_duplicate_and_unknown_baseline_result_rows
    second_case = created_case.merge('id' => 'created_crossfall_corridor_mta21')
    assert_validation_error(
      fixture_document(cases: [created_case, second_case],
                       baseline_results: [baseline_result_for(created_case)]),
      'baselineResults'
    )
    assert_validation_error(
      fixture_document(baseline_results: [
                         baseline_result_for(created_case),
                         baseline_result_for(created_case)
                       ]),
      'duplicate'
    )
    assert_validation_error(
      fixture_document(baseline_results: [
                         baseline_result_for(created_case).merge('caseId' => 'unknown_case')
                       ]),
      'unknown_case'
    )
  end

  def test_loader_exposes_baseline_result_lookup_by_case_id
    pack = AdaptiveTerrainRegressionFixtures.validate_document(fixture_document)

    result = pack.baseline_result('created_flat_corridor_mta21')

    assert_equal('created_flat_corridor_mta21', result.fetch('caseId'))
    assert_equal('mta21_current_adaptive', result.fetch('backend'))
  end

  def test_loader_validates_baseline_result_schema_backend_and_evidence_mode
    assert_validation_error(
      fixture_document(baseline_results: [
                         baseline_result_for(created_case).merge('resultSchemaVersion' => 2)
                       ]),
      'resultSchemaVersion'
    )
    assert_validation_error(
      fixture_document(baseline_results: [
                         baseline_result_for(created_case).merge('backend' => 'future_backend')
                       ]),
      'backend'
    )
    assert_validation_error(
      fixture_document(baseline_results: [
                         baseline_result_for(created_case).merge('evidenceMode' => 'local_guess')
                       ]),
      'evidenceMode'
    )
  end

  def test_loader_derives_and_validates_baseline_result_dense_ratio
    broken = baseline_result_for(created_case)
    broken.fetch('metrics')['denseRatio'] = 99.0

    assert_validation_error(
      fixture_document(baseline_results: [broken]),
      'denseRatio'
    )
  end

  def test_loader_requires_provenance_for_baseline_result_rows
    broken = baseline_result_for(created_case)
    broken.delete('provenance')

    assert_validation_error(
      fixture_document(baseline_results: [broken]),
      'provenance'
    )
  end

  def test_loader_validates_structured_coverage_limitations
    broken = coverage_limitation.merge('impact' => '')

    assert_validation_error(
      fixture_document(coverage_limitations: coverage_limitations_with(broken)),
      'coverageLimitations'
    )
    assert_validation_error(
      fixture_document(
        coverage_limitations: coverage_limitations_with(
          coverage_limitation.merge('downstreamAction' => '')
        )
      ),
      'downstreamAction'
    )
    assert_validation_error(
      fixture_document(
        coverage_limitations: coverage_limitations_with(
          coverage_limitation.tap { |limitation| limitation.delete('downstreamAction') }
        )
      ),
      'downstreamAction'
    )
  end

  def test_loader_requires_edit_families_to_be_covered_or_limited
    limitations = coverage_limitations.reject do |limitation|
      limitation.fetch('name') == 'fairing_or_smoothing'
    end

    assert_validation_error(
      fixture_document(coverage_limitations: limitations),
      'fairing_or_smoothing'
    )
  end

  def test_loader_rejects_duplicate_fixture_ids
    document = fixture_document(cases: [created_case, created_case])

    assert_validation_error(document, 'duplicate')
    assert_validation_error(document, created_case.fetch('id'))
  end

  def test_loader_rejects_unknown_fixture_enums_with_allowed_set
    document = fixture_document(cases: [
                                  created_case.merge(
                                    'family' => 'surprise',
                                    'terrain' => created_case.fetch('terrain').merge(
                                      'recipe' => 'unknown_recipe'
                                    )
                                  )
                                ])

    assert_validation_error(document, 'family')
    assert_validation_error(document, 'surprise')
    assert_validation_error(document, 'allowed')
  end

  def test_loader_validates_edit_sequence_positions
    broken_case = created_case.merge(
      'edits' => [
        created_case.fetch('edits').first.merge('sequence' => 2),
        created_case.fetch('edits').first.merge('sequence' => 2)
      ]
    )

    assert_validation_error(fixture_document(cases: [broken_case]), 'sequence')
  end

  def test_loader_derives_dense_equivalent_from_baseline_result_dimensions
    broken = baseline_result_for(created_case)
    broken.fetch('metrics')['denseEquivalentFaceCount'] = 3198

    assert_validation_error(
      fixture_document(baseline_results: [broken]),
      'denseEquivalentFaceCount'
    )
  end

  def test_loader_validates_baseline_result_face_count_ranges
    broken = baseline_result_for(created_case)
    broken.fetch('metrics')['faceCountRange'] = { 'min' => 100, 'max' => 200 }

    assert_validation_error(
      fixture_document(baseline_results: [broken]),
      'faceCountRange'
    )
  end

  def test_loader_requires_provenance_for_known_residuals_in_baseline_results
    broken = baseline_result_for(off_grid_residual_case)
    broken.fetch('knownResiduals').first.delete('provenance')

    assert_validation_error(
      fixture_document(cases: [off_grid_residual_case], baseline_results: [broken]),
      'knownResiduals'
    )
  end

  def test_loader_rejects_case_level_result_evidence
    %w[expectations residuals expectedResiduals capturedBaseline].each do |key|
      assert_validation_error(
        fixture_document(cases: [created_case.merge(key => {})]),
        key
      )
    end
  end

  def test_fixture_pack_contains_every_required_mta21_case
    pack = AdaptiveTerrainRegressionFixtures.load

    REQUIRED_CASE_IDS.each { |case_id| assert_equal(case_id, pack.case(case_id).fetch('id')) }
  end

  def test_fixture_pack_preserves_required_representativeness_traits
    pack = AdaptiveTerrainRegressionFixtures.load
    traits = pack.cases.flat_map { |fixture_case| terrain_traits(fixture_case) }

    REQUIRED_REPRESENTATIVENESS_TRAITS.each do |trait|
      assert_includes(traits, trait, "expected fixture pack to include #{trait.inspect}")
    end
  end

  def test_stress_fixtures_record_edit_stack_and_diagnostic_dimensions
    pack = AdaptiveTerrainRegressionFixtures.load
    aggressive = pack.case('aggressive_stacked_created_terrain_mta21')
    high_relief = pack.case('high_relief_seam_stress_mta21')

    assert_operator(aggressive.fetch('edits').length, :>, 1)
    assert_profile_request(pack, aggressive, start: 2.4, finish: 0.6)
    assert_face_counts(pack, aggressive, dense: 4800, observed: 3578)
    assert_diagnostic(pack, aggressive, 'sharp_normal_breaks')

    assert_profile_request(pack, high_relief, start: 12.0, finish: -3.0)
    assert_face_counts(pack, high_relief, dense: 9600, observed: 6667)
    assert_seam_check(pack, high_relief, 'satisfied')
  end

  def test_fixture_pack_reports_coverage_summary_signals
    summary = AdaptiveTerrainRegressionFixtures.load.coverage_summary

    assert_operator(summary.fetch(:total_cases), :>=, REQUIRED_CASE_IDS.length)
    assert_equal(summary.fetch(:total_cases), summary.fetch(:baseline_result_count))
    assert_operator(summary.fetch(:family_counts).fetch('created_corridor'), :>=, 4)
    assert_operator(summary.fetch(:replayable_locally_count), :>=, 4)
    assert_operator(summary.fetch(:provenance_only_count), :>=, 1)
    assert_operator(summary.fetch(:known_residual_count), :>=, 1)
    assert_operator(summary.fetch(:coverage_limitation_count), :>=, 1)
    assert_operator(summary.fetch(:evidence_mode_counts).fetch('hosted_capture'), :>=, 1)
    REQUIRED_CASE_IDS.each do |case_id|
      assert_operator(summary.fetch(:baseline_dense_ratios).fetch(case_id), :>, 0.0)
    end
  end

  def test_every_case_has_at_least_one_machine_checkable_baseline_result
    pack = AdaptiveTerrainRegressionFixtures.load
    pack.cases.each do |fixture_case|
      assert(
        machine_checkable_baseline_result?(pack, fixture_case),
        "expected #{fixture_case.fetch('id')} to include a machine-checkable expectation"
      )
    end
  end

  def test_created_cases_replay_locally_through_terrain_kernel
    pack = AdaptiveTerrainRegressionFixtures.load
    created_cases = REQUIRED_CASE_IDS.grep(/\Acreated_/).map { |case_id| pack.case(case_id) }

    created_cases.each do |fixture_case|
      result = pack.replay_case(fixture_case)

      assert_equal('edited', result.fetch(:outcome))
      assert_includes(result.keys, :output)
    end
  end

  def test_adopted_off_grid_endpoint_mismatch_is_structured_known_residual
    pack = AdaptiveTerrainRegressionFixtures.load
    fixture_case = pack.case('adopted_irregular_off_grid_corridor_mta21')
    residual = pack.baseline_result(fixture_case.fetch('id')).fetch('knownResiduals').find do |item|
      item.fetch('status') == 'known_residual'
    end

    refute(fixture_case.fetch('replayableLocally'))
    assert_equal('corridor_end_profile', residual.fetch('type'))
    assert_equal(1.85, residual.fetch('requested').fetch('endElevation'))
    assert_equal(1.43, residual.fetch('sampled').fetch('endElevation'))
    assert_in_delta(0.4165, residual.fetch('delta'), 0.0001)
    assert_includes(residual.fetch('provenance').fetch('source'), 'MTA-21')
  end

  def test_grid_aligned_adopted_profile_is_satisfied_not_residual
    pack = AdaptiveTerrainRegressionFixtures.load
    fixture_case = pack.case('adopted_irregular_grid_aligned_corridor_mta21')

    profile = pack.baseline_result(fixture_case.fetch('id'))
                  .fetch('metrics')
                  .fetch('profileChecks')
                  .find do |check|
      check.fetch('type') == 'corridor_endpoint_profile'
    end

    assert_equal('satisfied', profile.fetch('status'))
    assert_equal(0.75, profile.fetch('requested').fetch('startElevation'))
    assert_equal(1.90, profile.fetch('requested').fetch('endElevation'))
    assert_includes(profile.fetch('provenance').fetch('source'), 'MTA-21')
    assert_empty(pack.baseline_result(fixture_case.fetch('id')).fetch('knownResiduals'))
  end

  def test_canonical_cases_are_recipe_first_without_baseline_result_metrics
    AdaptiveTerrainRegressionFixtures.load.cases.each do |fixture_case|
      refute_includes(fixture_case.keys, 'expectations')
      refute_includes(fixture_case.keys, 'residuals')
      refute_includes(fixture_case.keys, 'expectedResiduals')
      refute_includes(fixture_case.keys, 'capturedBaseline')
    end
  end

  def test_fixture_source_truth_omits_raw_sketchup_mesh_and_adaptive_internals
    pack = AdaptiveTerrainRegressionFixtures.load

    pack.cases.each do |fixture_case|
      all_keys_recursive(fixture_case).each do |key|
        refute_includes(FORBIDDEN_SOURCE_TRUTH_KEYS, key)
      end
      serialized = JSON.generate(source_truth_sections(fixture_case))
      FORBIDDEN_SOURCE_TRUTH_TERMS.each do |term|
        refute_includes(serialized, term)
      end
    end
    pack.baseline_results.each do |result|
      all_keys_recursive(result).each do |key|
        refute_includes(FORBIDDEN_SOURCE_TRUTH_KEYS, key)
      end
      serialized = JSON.generate(result)
      FORBIDDEN_SOURCE_TRUTH_TERMS.each do |term|
        refute_includes(serialized, term)
      end
    end
    pack.coverage_limitations.each do |limitation|
      all_keys_recursive(limitation).each do |key|
        refute_includes(FORBIDDEN_SOURCE_TRUTH_KEYS, key)
      end
    end
  end

  def test_production_runtime_does_not_depend_on_fixture_loader
    runtime_references = Dir['src/su_mcp/**/*.rb'].select do |path|
      File.read(path).include?('adaptive_terrain_regression')
    end

    assert_empty(runtime_references)
  end

  private

  def assert_validation_error(document, message)
    error = assert_raises(ArgumentError) do
      AdaptiveTerrainRegressionFixtures.validate_document(document)
    end
    assert_includes(error.message, message)
  end

  def fixture_document(
    cases: [created_case],
    baseline_results: nil,
    coverage_limitations: nil
  )
    coverage_limitations ||= self.coverage_limitations
    {
      'schemaVersion' => 1,
      'sourceTask' => 'MTA-22',
      'baseline' => { 'sourceTask' => 'MTA-21', 'status' => 'accepted_for_seam_conformance' },
      'cases' => cases,
      'baselineResults' => baseline_results ||
        cases.map { |fixture_case| baseline_result_for(fixture_case) },
      'coverageLimitations' => coverage_limitations,
      'validationCommands' => []
    }
  end

  def document_without(field)
    fixture_document.tap { |document| document.delete(field) }
  end

  def document_with_case_without(field)
    fixture_case = created_case.tap { |item| item.delete(field) }
    fixture_document(
      cases: [fixture_case],
      baseline_results: [baseline_result_for(created_case)]
    )
  end

  def created_case
    {
      'id' => 'created_flat_corridor_mta21',
      'family' => 'created_corridor',
      'replayableLocally' => true,
      'terrain' => {
        'recipe' => 'created_flat_grid',
        'recipeVersion' => 1,
        'traits' => ['flat'],
        'dimensions' => { 'columns' => 41, 'rows' => 41 },
        'spacing' => { 'x' => 1.0, 'y' => 1.0 },
        'parameters' => { 'elevation' => 0.0 }
      },
      'edits' => [
        {
          'sequence' => 1,
          'mode' => 'corridor_transition',
          'controls' => {
            'start' => { 'x' => 8.0, 'y' => 20.0, 'elevation' => 0.75 },
            'end' => { 'x' => 32.0, 'y' => 20.0, 'elevation' => 1.90 },
            'width' => 4.0
          }
        }
      ],
      'provenance' => { 'source' => 'MTA-21 hosted validation checklist' }
    }
  end

  def off_grid_residual_case
    created_case.merge(
      'id' => 'adopted_irregular_off_grid_corridor_mta21',
      'family' => 'adopted_corridor',
      'replayableLocally' => false
    )
  end

  def baseline_result_for(fixture_case)
    observed = baseline_observed_face_count(fixture_case)
    dense = dense_equivalent_face_count(fixture_case)
    {
      'caseId' => fixture_case.fetch('id'),
      'resultSchemaVersion' => 1,
      'backend' => 'mta21_current_adaptive',
      'evidenceMode' => baseline_evidence_mode(fixture_case),
      'metrics' => {
        'meshType' => 'adaptive_tin',
        'faceCount' => observed,
        'faceCountRange' => baseline_face_count_range(fixture_case, observed),
        'denseEquivalentFaceCount' => dense,
        'denseRatio' => observed.to_f / dense,
        'profileChecks' => baseline_profile_checks(fixture_case),
        'topologyChecks' => baseline_topology_checks,
        'seamChecks' => baseline_seam_checks,
        'diagnosticChecks' => [],
        'timing' => nil
      },
      'knownResiduals' => known_residuals_for(fixture_case),
      'provenance' => fixture_case.fetch('provenance'),
      'limitations' => baseline_limitations(fixture_case)
    }
  end

  def baseline_observed_face_count(fixture_case)
    case fixture_case.fetch('id')
    when 'adopted_irregular_off_grid_corridor_mta21'
      18_144
    else
      1750
    end
  end

  def dense_equivalent_face_count(fixture_case)
    dimensions = fixture_case.fetch('terrain').fetch('dimensions')
    (dimensions.fetch('columns') - 1) * (dimensions.fetch('rows') - 1) * 2
  end

  def baseline_face_count_range(_fixture_case, observed)
    { 'min' => [observed - 372, 1].max, 'max' => observed }
  end

  def baseline_profile_checks(fixture_case)
    requested = fixture_case.fetch('edits').first.fetch('controls')
    [
      {
        'type' => 'corridor_endpoint_profile',
        'status' => 'satisfied',
        'requested' => {
          'startElevation' => requested.fetch('start').fetch('elevation'),
          'endElevation' => requested.fetch('end').fetch('elevation')
        },
        'tolerance' => 0.02,
        'provenance' => { 'source' => 'MTA-21 hosted validation checklist' }
      }
    ]
  end

  def baseline_topology_checks
    [
      {
        'type' => 'no_down_faces',
        'status' => 'satisfied',
        'provenance' => { 'source' => 'MTA-21 hosted validation checklist' }
      }
    ]
  end

  def baseline_seam_checks
    [
      {
        'type' => 'no_t_rips_or_folded_seams',
        'status' => 'satisfied',
        'provenance' => { 'source' => 'MTA-21 hosted validation checklist' }
      }
    ]
  end

  def known_residuals_for(fixture_case)
    return [] unless fixture_case.fetch('id') == 'adopted_irregular_off_grid_corridor_mta21'

    [
      {
        'type' => 'corridor_end_profile',
        'status' => 'known_residual',
        'requested' => { 'endElevation' => 1.85 },
        'sampled' => { 'endElevation' => 1.43 },
        'delta' => 0.4165,
        'tolerance' => 0.02,
        'provenance' => { 'source' => 'MTA-21 hosted validation checklist' }
      }
    ]
  end

  def baseline_evidence_mode(fixture_case)
    fixture_case.fetch('replayableLocally') ? 'hosted_capture' : 'provenance_capture'
  end

  def baseline_limitations(fixture_case)
    return [] if fixture_case.fetch('replayableLocally')

    ['Hosted-sensitive facts are provenance-backed.']
  end

  def coverage_limitation
    coverage_limitations.find { |limitation| limitation.fetch('name') == 'fairing_or_smoothing' }
  end

  def coverage_limitations
    %w[
      off_grid_corridor target_or_flat_stamp planar_region_fit preserve_zone_adjacent
      fixed_or_survey_control fairing_or_smoothing combined_edit
    ].map { |name| coverage_limitation_for(name) }
  end

  def coverage_limitations_with(replacement)
    coverage_limitations.map do |limitation|
      limitation.fetch('name') == replacement.fetch('name') ? replacement : limitation
    end
  end

  def coverage_limitation_for(name)
    {
      'kind' => 'edit_family',
      'name' => name,
      'reason' => 'No MTA-21 baseline capture is available in the current fixture evidence.',
      'impact' => "MTA-23 should not treat #{name} as covered by this baseline pack.",
      'downstreamAction' => 'Add result evidence before relying on this family.'
    }
  end

  def terrain_traits(fixture_case)
    fixture_case.fetch('terrain').fetch('traits', [])
  end

  def baseline_metrics(pack, fixture_case)
    pack.baseline_result(fixture_case.fetch('id')).fetch('metrics')
  end

  def assert_profile_request(pack, fixture_case, start:, finish:)
    profile = baseline_metrics(pack, fixture_case).fetch('profileChecks').find do |check|
      check.fetch('type') == 'corridor_endpoint_profile'
    end

    assert_equal(start, profile.fetch('requested').fetch('startElevation'))
    assert_equal(finish, profile.fetch('requested').fetch('endElevation'))
  end

  def assert_face_counts(pack, fixture_case, dense:, observed:)
    metrics = baseline_metrics(pack, fixture_case)

    assert_equal(dense, metrics.fetch('denseEquivalentFaceCount'))
    assert_equal(observed, metrics.fetch('faceCount'))
  end

  def assert_diagnostic(pack, fixture_case, diagnostic_type)
    diagnostics = baseline_metrics(pack, fixture_case).fetch('diagnosticChecks')

    assert(
      diagnostics.any? do |diagnostic|
        diagnostic.fetch('type') == diagnostic_type &&
          diagnostic.fetch('provenance').fetch('source').include?('MTA-21')
      end
    )
  end

  def assert_seam_check(pack, fixture_case, status)
    seam_checks = baseline_metrics(pack, fixture_case).fetch('seamChecks')

    assert(seam_checks.any? { |check| check.fetch('status') == status })
  end

  def machine_checkable_baseline_result?(pack, fixture_case)
    metrics = pack.baseline_result(fixture_case.fetch('id')).fetch('metrics')

    metrics.fetch('profileChecks', []).any? ||
      metrics.fetch('topologyChecks', []).any? ||
      metrics.fetch('seamChecks', []).any? ||
      metrics.fetch('diagnosticChecks', []).any?
  end

  def source_truth_sections(fixture_case)
    {
      'terrain' => fixture_case.fetch('terrain'),
      'edits' => fixture_case.fetch('edits')
    }
  end

  def all_keys_recursive(value)
    case value
    when Hash
      value.keys + value.values.flat_map { |nested| all_keys_recursive(nested) }
    when Array
      value.flat_map { |nested| all_keys_recursive(nested) }
    else
      []
    end
  end
end
# rubocop:enable Metrics/ClassLength
