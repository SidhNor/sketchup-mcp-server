# frozen_string_literal: true

require 'json'

require_relative '../../src/su_mcp/terrain/edits/corridor_transition_edit'
require_relative '../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../src/su_mcp/terrain/output/terrain_output_plan'
require_relative '../../src/su_mcp/terrain/state/tiled_heightmap_state'

# Test-owned loader seam for the MTA-22 adaptive terrain regression fixture pack.
class AdaptiveTerrainRegressionFixtures
  CANONICAL_PATH = File.expand_path(
    '../terrain/fixtures/adaptive_terrain_regression_cases.json',
    __dir__
  )
  ROOT_FIELDS = %w[
    schemaVersion sourceTask baseline baselineResults coverageLimitations cases validationCommands
  ].freeze
  CASE_FIELDS = %w[
    id family replayableLocally terrain edits provenance
  ].freeze
  CASE_RESULT_EVIDENCE_KEYS = %w[
    expectations residuals expectedResiduals capturedBaseline
  ].freeze
  FAMILIES = %w[
    created_corridor adopted_baseline adopted_corridor stress
  ].freeze
  TERRAIN_RECIPES = %w[
    created_flat_grid created_crossfall_grid created_steep_grid created_non_square_grid
    adopted_irregular_grid aggressive_stack_created_grid high_relief_seam_stress_grid
  ].freeze
  EDIT_MODES = %w[corridor_transition bounded_grade planar_region_fit].freeze
  EXPECTATION_TYPES = %w[corridor_endpoint_profile].freeze
  TOPOLOGY_CHECK_TYPES = %w[no_down_faces no_non_manifold_edges].freeze
  SEAM_CHECK_TYPES = %w[no_t_rips_or_folded_seams seam_conformance].freeze
  RESIDUAL_STATUSES = %w[known_residual].freeze
  DIAGNOSTIC_TYPES = %w[sharp_normal_breaks].freeze
  RESULT_SCHEMA_VERSION = 1
  BASELINE_RESULT_FIELDS = %w[
    caseId resultSchemaVersion backend evidenceMode metrics knownResiduals provenance limitations
  ].freeze
  METRIC_FIELDS = %w[
    meshType faceCount faceCountRange denseEquivalentFaceCount denseRatio profileChecks
    topologyChecks seamChecks diagnosticChecks timing
  ].freeze
  BASELINE_BACKENDS = %w[mta21_current_adaptive].freeze
  EVIDENCE_MODES = %w[hosted_capture local_backend_capture provenance_capture].freeze
  COVERAGE_LIMITATION_KINDS = %w[terrain_trait edit_family].freeze
  REQUIRED_EDIT_FAMILY_SIGNALS = %w[
    corridor off_grid_corridor target_or_flat_stamp planar_region_fit preserve_zone_adjacent
    fixed_or_survey_control fairing_or_smoothing combined_edit
  ].freeze
  RATIO_TOLERANCE = 0.000_001

  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  attr_reader :document

  def self.load(path: CANONICAL_PATH)
    validate_document(JSON.parse(File.read(path)))
  end

  def self.validate_document(document)
    new(document).validate!
  end

  def initialize(document)
    @document = document
  end

  def validate!
    validate_root
    validate_cases
    validate_baseline_results
    validate_coverage_limitations
    validate_edit_family_coverage
    self
  end

  def cases
    document.fetch('cases')
  end

  def baseline_results
    document.fetch('baselineResults')
  end

  def coverage_limitations
    document.fetch('coverageLimitations')
  end

  def case(id)
    cases.find { |fixture_case| fixture_case.fetch('id') == id } ||
      raise(ArgumentError, "Unknown adaptive terrain regression fixture: #{id}")
  end

  def baseline_result(case_id)
    baseline_results.find { |result| result.fetch('caseId') == case_id } ||
      raise(ArgumentError, "Unknown adaptive terrain baseline result: #{case_id}")
  end

  def family_counts
    cases.each_with_object(Hash.new(0)) do |fixture_case, counts|
      counts[fixture_case.fetch('family')] += 1
    end
  end

  def local_replay_cases
    cases.select { |fixture_case| fixture_case.fetch('replayableLocally') }
  end

  def coverage_summary
    {
      total_cases: cases.length,
      baseline_result_count: baseline_results.length,
      family_counts: family_counts,
      evidence_mode_counts: evidence_mode_counts,
      replayable_locally_count: local_replay_cases.length,
      provenance_only_count: cases.count do |fixture_case|
        !fixture_case.fetch('replayableLocally')
      end,
      coverage_limitation_count: coverage_limitations.length,
      known_residual_count: known_residual_count,
      baseline_dense_ratios: baseline_dense_ratios
    }
  end

  def replay_case(fixture_case)
    unless fixture_case.fetch('replayableLocally')
      raise ArgumentError, "Fixture #{fixture_case.fetch('id')} is not locally replayable"
    end

    state = build_state(fixture_case)
    edited = apply_edits(state, fixture_case.fetch('edits'))
    plan = SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: edited,
      terrain_state_summary: { digest: "#{fixture_case.fetch('id')}-local",
                               revision: edited.revision }
    )
    {
      outcome: 'edited',
      state: edited,
      output: plan.to_summary
    }
  end

  private

  def validate_root
    ROOT_FIELDS.each { |field| require_field(document, field, 'root') }
    raise ArgumentError, 'cases must be an array' unless cases.is_a?(Array)
    raise ArgumentError, 'baselineResults must be an array' unless baseline_results.is_a?(Array)
    return if coverage_limitations.is_a?(Array)

    raise ArgumentError, 'coverageLimitations must be an array'
  end

  def validate_cases
    validate_unique_case_ids
    cases.each { |fixture_case| validate_case(fixture_case) }
  end

  def validate_unique_case_ids
    ids = cases.map { |fixture_case| fixture_case.fetch('id', nil) }
    duplicate = ids.compact.find { |id| ids.count(id) > 1 }
    raise ArgumentError, "duplicate fixture id: #{duplicate}" if duplicate
  end

  def validate_case(fixture_case)
    CASE_FIELDS.each do |field|
      require_field(fixture_case, field, fixture_case.fetch('id', 'case'))
    end
    validate_recipe_first_case(fixture_case)
    validate_enum('family', fixture_case.fetch('family'), FAMILIES)
    validate_terrain(fixture_case)
    validate_edits(fixture_case)
    validate_provenance(fixture_case.fetch('provenance'), fixture_case.fetch('id'), 'case')
  end

  def validate_recipe_first_case(fixture_case)
    result_key = CASE_RESULT_EVIDENCE_KEYS.find { |key| fixture_case.key?(key) }
    return unless result_key

    raise ArgumentError,
          "case #{fixture_case.fetch('id')} must be recipe-first; move #{result_key} " \
          'to baselineResults'
  end

  def validate_terrain(fixture_case)
    terrain = fixture_case.fetch('terrain')
    validate_enum('terrain.recipe', terrain.fetch('recipe'), TERRAIN_RECIPES)
    require_field(terrain, 'recipeVersion', fixture_case.fetch('id'))
    require_field(terrain, 'dimensions', fixture_case.fetch('id'))
    require_field(terrain, 'spacing', fixture_case.fetch('id'))
    require_field(terrain, 'parameters', fixture_case.fetch('id'))
  end

  def validate_edits(fixture_case)
    edits = fixture_case.fetch('edits')
    unless edits.is_a?(Array)
      raise ArgumentError,
            "edits must be an array for #{fixture_case.fetch('id')}"
    end

    sequences = edits.map { |edit| edit.fetch('sequence', nil) }
    expected = (1..edits.length).to_a
    unless sequences == expected
      raise ArgumentError,
            "edit sequence for #{fixture_case.fetch('id')} must be #{expected.inspect}, " \
            "got #{sequences.inspect}"
    end
    edits.each do |edit|
      validate_enum('edit.mode', edit.fetch('mode'), EDIT_MODES)
      require_field(edit, 'controls', fixture_case.fetch('id'))
    end
  end

  def validate_baseline_results
    validate_unique_baseline_result_case_ids
    validate_baseline_result_case_coverage
    baseline_results.each { |result| validate_baseline_result(result) }
  end

  def validate_unique_baseline_result_case_ids
    ids = baseline_results.map { |result| result.fetch('caseId', nil) }
    duplicate = ids.compact.find { |id| ids.count(id) > 1 }
    raise ArgumentError, "duplicate baselineResults caseId: #{duplicate}" if duplicate
  end

  def validate_baseline_result_case_coverage
    case_ids = cases.map { |fixture_case| fixture_case.fetch('id') }
    result_ids = baseline_results.map { |result| result.fetch('caseId') }
    unknown = result_ids - case_ids
    missing = case_ids - result_ids
    if unknown.any?
      raise ArgumentError, "baselineResults reference unknown caseId: #{unknown.first}"
    end
    raise ArgumentError, "baselineResults missing caseId: #{missing.first}" if missing.any?
  end

  def validate_baseline_result(result)
    case_id = result.fetch('caseId')
    BASELINE_RESULT_FIELDS.each do |field|
      require_field(result, field, "baselineResult #{case_id}")
    end
    validate_result_schema_version(result, case_id)
    validate_enum('backend', result.fetch('backend'), BASELINE_BACKENDS)
    validate_enum('evidenceMode', result.fetch('evidenceMode'), EVIDENCE_MODES)
    validate_baseline_metrics(result, case_id)
    validate_baseline_residuals(result, case_id)
    validate_provenance(result.fetch('provenance', nil), case_id, 'baselineResult')
  end

  def validate_result_schema_version(result, case_id)
    version = result.fetch('resultSchemaVersion')
    return if version == RESULT_SCHEMA_VERSION

    raise ArgumentError,
          "resultSchemaVersion for #{case_id} must be #{RESULT_SCHEMA_VERSION}, got #{version}"
  end

  def validate_baseline_metrics(result, case_id)
    metrics = result.fetch('metrics')
    METRIC_FIELDS.each do |field|
      require_field(metrics, field, "baselineResult #{case_id} metrics")
    end
    fixture_case = self.case(case_id)
    dense = metrics.fetch('denseEquivalentFaceCount')
    expected_dense = dense_equivalent_face_count(fixture_case)
    unless dense == expected_dense
      raise ArgumentError,
            "denseEquivalentFaceCount for #{case_id} must be #{expected_dense}, got #{dense}"
    end
    validate_baseline_face_count(result, metrics, case_id)
    validate_dense_ratio(metrics, case_id)
    validate_result_checks(metrics, case_id)
  end

  def validate_baseline_face_count(_result, metrics, case_id)
    face_count = metrics.fetch('faceCount')
    range = metrics.fetch('faceCountRange')
    min = range.fetch('min')
    max = range.fetch('max')
    return if face_count.between?(min, max)

    raise ArgumentError, "faceCountRange for #{case_id} must contain #{face_count}"
  end

  def validate_dense_ratio(metrics, case_id)
    expected = metrics.fetch('faceCount').to_f / metrics.fetch('denseEquivalentFaceCount')
    actual = metrics.fetch('denseRatio')
    return if (actual - expected).abs <= RATIO_TOLERANCE

    raise ArgumentError, "denseRatio for #{case_id} must be #{expected}, got #{actual}"
  end

  def validate_result_checks(metrics, case_id)
    validate_checks(metrics, case_id, 'profileChecks', EXPECTATION_TYPES)
    validate_checks(metrics, case_id, 'topologyChecks', TOPOLOGY_CHECK_TYPES)
    validate_checks(metrics, case_id, 'seamChecks', SEAM_CHECK_TYPES)
    validate_checks(metrics, case_id, 'diagnosticChecks', DIAGNOSTIC_TYPES)
  end

  def validate_baseline_residuals(result, case_id)
    result.fetch('knownResiduals', []).each do |residual|
      validate_enum('knownResiduals.status', residual.fetch('status'), RESIDUAL_STATUSES)
      %w[type requested sampled delta].each do |field|
        require_field(residual, field, "#{case_id} knownResiduals")
      end
      unless residual.key?('tolerance') || residual.key?('note')
        raise ArgumentError, "knownResiduals for #{case_id} requires tolerance or note"
      end

      validate_provenance(residual.fetch('provenance', nil), case_id, 'knownResiduals')
    end
  end

  def validate_checks(metrics, case_id, field, allowed)
    metrics.fetch(field, []).each do |check|
      validate_enum(field, check.fetch('type'), allowed)
      validate_provenance(check.fetch('provenance', nil), case_id, field)
    end
  end

  def validate_coverage_limitations
    coverage_limitations.each do |limitation|
      validate_enum('coverageLimitations.kind', limitation.fetch('kind'),
                    COVERAGE_LIMITATION_KINDS)
      %w[name reason impact downstreamAction].each do |field|
        require_field(limitation, field, 'coverageLimitations')
        value = limitation[field]
        next if value.is_a?(String) && !value.strip.empty?

        raise ArgumentError, "coverageLimitations #{field} must be non-empty"
      end
    end
  end

  def validate_edit_family_coverage
    REQUIRED_EDIT_FAMILY_SIGNALS.each do |family|
      next if edit_family_covered_or_limited?(family)

      raise ArgumentError,
            "coverageLimitations missing edit_family #{family}"
    end
  end

  def edit_family_covered_or_limited?(family)
    cases.any? { |fixture_case| edit_family_covered?(fixture_case, family) } ||
      coverage_limitations.any? do |limitation|
        limitation.fetch('kind') == 'edit_family' && limitation.fetch('name') == family
      end
  end

  def edit_family_covered?(fixture_case, family)
    case family
    when 'corridor'
      edit_modes_for(fixture_case).include?('corridor_transition')
    when 'off_grid_corridor'
      fixture_case.fetch('id').include?('off_grid')
    when 'target_or_flat_stamp'
      edit_modes_for(fixture_case).include?('bounded_grade')
    when 'planar_region_fit'
      edit_modes_for(fixture_case).include?('planar_region_fit')
    when 'preserve_zone_adjacent'
      controls_text(fixture_case).include?('preserve')
    when 'fixed_or_survey_control'
      controls_text(fixture_case).match?(/fixed|survey/)
    when 'fairing_or_smoothing'
      controls_text(fixture_case).match?(/fair|smooth/)
    when 'combined_edit'
      fixture_case.fetch('edits').length > 1
    else
      raise ArgumentError, "Unknown required edit family: #{family}"
    end
  end

  def edit_modes_for(fixture_case)
    fixture_case.fetch('edits').map { |edit| edit.fetch('mode') }
  end

  def controls_text(fixture_case)
    JSON.generate(fixture_case.fetch('edits').map { |edit| edit.fetch('controls') }).downcase
  end

  def validate_provenance(value, case_id, context)
    return if value.is_a?(Hash) && value.fetch('source', '').match?(/\bMTA-21\b/)

    raise ArgumentError, "provenance for #{case_id} #{context} must reference MTA-21"
  end

  def require_field(hash, field, context)
    return if hash.key?(field)

    raise ArgumentError, "Missing #{context} field: #{field}"
  end

  def validate_enum(field, value, allowed)
    return if allowed.include?(value)

    raise ArgumentError, "#{field} #{value.inspect} is not allowed; allowed: #{allowed.join(', ')}"
  end

  def dense_equivalent_face_count(fixture_case)
    dimensions = fixture_case.fetch('terrain').fetch('dimensions')
    (dimensions.fetch('columns') - 1) * (dimensions.fetch('rows') - 1) * 2
  end

  def known_residual_count
    baseline_results.sum do |result|
      result.fetch('knownResiduals', []).count do |residual|
        residual.fetch('status') == 'known_residual'
      end
    end
  end

  def baseline_dense_ratios
    baseline_results.each_with_object({}) do |result, ratios|
      metrics = result.fetch('metrics')
      ratios[result.fetch('caseId')] = metrics.fetch('denseRatio')
    end
  end

  def evidence_mode_counts
    baseline_results.each_with_object(Hash.new(0)) do |result, counts|
      counts[result.fetch('evidenceMode')] += 1
    end
  end

  def build_state(fixture_case)
    terrain = fixture_case.fetch('terrain')
    dimensions = terrain.fetch('dimensions')
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: terrain.fetch('origin', { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 }),
      spacing: terrain.fetch('spacing'),
      dimensions: dimensions,
      elevations: elevations_for(terrain),
      revision: 1,
      state_id: "#{fixture_case.fetch('id')}-state"
    )
  end

  def elevations_for(terrain)
    dimensions = terrain.fetch('dimensions')
    columns = dimensions.fetch('columns')
    rows = dimensions.fetch('rows')
    parameters = terrain.fetch('parameters')
    Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      recipe_elevation(terrain.fetch('recipe'), parameters, column, row)
    end
  end

  def recipe_elevation(recipe, parameters, column, row)
    case recipe
    when 'created_flat_grid', 'created_non_square_grid'
      parameters.fetch('elevation')
    when 'created_crossfall_grid'
      parameters.fetch('baseElevation') + (column * parameters.fetch('xSlope'))
    when 'created_steep_grid'
      parameters.fetch('baseElevation') +
        (column * parameters.fetch('xSlope')) +
        (row * parameters.fetch('ySlope'))
    else
      raise ArgumentError, "Fixture recipe #{recipe} is not locally replayable"
    end
  end

  def apply_edits(state, edits)
    edits.reduce(state) do |current_state, edit|
      case edit.fetch('mode')
      when 'corridor_transition'
        apply_corridor_transition(current_state, edit)
      else
        raise ArgumentError, "Edit mode #{edit.fetch('mode')} is not locally replayable"
      end
    end
  end

  def apply_corridor_transition(state, edit)
    result = SU_MCP::Terrain::CorridorTransitionEdit.new.apply(
      state: state,
      request: corridor_request(edit.fetch('controls'))
    )
    unless result.fetch(:outcome) == 'edited'
      raise ArgumentError,
            "Local replay refused: #{result.dig(:refusal,
                                                :code)}"
    end

    result.fetch(:state)
  end

  def corridor_request(controls)
    {
      'operation' => { 'mode' => 'corridor_transition' },
      'region' => {
        'type' => 'corridor',
        'startControl' => {
          'point' => controls.fetch('start').slice('x', 'y'),
          'elevation' => controls.fetch('start').fetch('elevation')
        },
        'endControl' => {
          'point' => controls.fetch('end').slice('x', 'y'),
          'elevation' => controls.fetch('end').fetch('elevation')
        },
        'width' => controls.fetch('width'),
        'sideBlend' => controls.fetch('sideBlend', { 'distance' => 0.0, 'falloff' => 'none' })
      },
      'constraints' => controls.fetch('constraints', {})
    }
  end
end
