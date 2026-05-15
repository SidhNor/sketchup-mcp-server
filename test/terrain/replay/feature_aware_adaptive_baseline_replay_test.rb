# frozen_string_literal: true

require 'digest'

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_replay'

class FeatureAwareAdaptiveBaselineReplayTest < Minitest::Test
  CANONICAL_PATH = File.expand_path(
    'feature_aware_adaptive_baseline.json',
    __dir__
  )
  RESULTS_PATH = File.expand_path(
    'feature_aware_adaptive_baseline_results.json',
    __dir__
  )

  REQUIRED_ROW_IDS = %w[
    create-baseline
    target-local-center
    target-adjacent-east
    target-repeat-center
    corridor-diagonal-intersect
    planar-pad-intersect
    survey-control-intersect
    fairing-envelope-intersect
  ].freeze

  def test_canonical_replay_spec_contains_exact_public_payloads_and_required_rows
    assert_path_exists(CANONICAL_PATH)

    replay = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.load(path: CANONICAL_PATH)

    assert_canonical_replay_metadata(replay)
    assert_canonical_replay_terrain(replay)
    assert_equal(REQUIRED_ROW_IDS, replay.rows.map { |row| row.fetch('rowId') })
    assert(replay.rows.all? { |row| row.fetch('expectedStatus') == 'accepted' })
    assert(replay.rows.all? { |row| row.fetch('publicCommandPayload').is_a?(Hash) })
    refute_includes(JSON.generate(replay.document), 'savedScene')
    refute_includes(JSON.generate(replay.document), 'privateBackend')
  end

  def test_captured_live_results_match_canonical_replay_fixture
    replay = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.load(path: CANONICAL_PATH)
    results = JSON.parse(File.read(RESULTS_PATH))

    assert_live_results_identity(replay, results)
    assert_live_results_rows(replay, results)
    refute_includes(JSON.generate(results), 'savedScene')
    refute_includes(JSON.generate(results), 'privateBackend')
  end

  def test_replay_validator_rejects_missing_reproduction_fields
    invalid = valid_minimal_document
    invalid.fetch('terrain').delete('spacingMeters')

    error = assert_raises(ArgumentError) do
      SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.validate_document(invalid)
    end

    assert_match(/spacing/i, error.message)
  end

  def test_replay_validator_rejects_rows_without_coordinates_or_public_payloads
    invalid = valid_minimal_document
    invalid.fetch('sequences').first.fetch('rows').first.delete('publicCommandPayload')

    error = assert_raises(ArgumentError) do
      SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.validate_document(invalid)
    end

    assert_match(/public command payload/i, error.message)
  end

  def test_replay_runner_executes_public_command_path_and_shapes_lean_evidence_rows
    replay = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.validate_document(
      valid_minimal_document
    )
    command_surface = RecordingTerrainCommandSurface.new

    evidence = replay.execute(command_surface: command_surface)

    assert_equal(%i[create_terrain_surface edit_terrain_surface], command_surface.calls)
    assert_equal(2, evidence.fetch(:rows).length)
    row = evidence.fetch(:rows).last
    %i[
      rowId sequenceId replaySpec commandKind sourceElementId featureContextClass accepted
      verdict outcome stateRevision featureViewDigest policyFingerprint featureContext dirtyWindow
      affectedPatchScope faceCount vertexCount meshType simplificationTolerance
      maxSimplificationError renderingSummary timingBuckets
    ].each { |field| assert_includes(row.keys, field) }
    assert_replay_evidence_values(row)
    refute_includes(JSON.generate(row), 'rawTriangles')
    refute_includes(JSON.generate(row), 'Sketchup::')
  end

  def assert_replay_evidence_values(row)
    assert_equal('feature-digest-a', row.fetch(:featureViewDigest))
    assert_equal('policy-fingerprint-a', row.fetch(:policyFingerprint))
    assert_equal(2, row.fetch(:stateRevision))
    assert_equal({ selected: 2 }, row.fetch(:featureContext))
    assert_equal({ patches: %w[adaptive-patch-v1-c1-r1] }, row.fetch(:affectedPatchScope))
    assert_equal({ status: 'captured', topology: 'single_mesh' }, row.fetch(:renderingSummary))
    assert_equal(0.01, row.fetch(:simplificationTolerance))
    assert_equal(0.009, row.fetch(:maxSimplificationError))
    assert_equal(0.02, row.fetch(:timingBuckets).fetch(:commandOutputPlanning))
    assert(row.fetch(:timingBuckets).fetch(:total).positive?)
  end

  def test_replay_runner_reads_internal_baseline_evidence_from_command_surface
    replay = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.validate_document(
      valid_minimal_document
    )
    command_surface = RecordingTerrainCommandSurface.new(embed_baseline_evidence: false)

    evidence = replay.execute(command_surface: command_surface)

    row = evidence.fetch(:rows).last
    assert_equal('feature-digest-a', row.fetch(:featureViewDigest))
    assert_equal('policy-fingerprint-a', row.fetch(:policyFingerprint))
    assert_equal({ selected: 2 }, row.fetch(:featureContext))
    assert_equal({ patches: %w[adaptive-patch-v1-c1-r1] }, row.fetch(:affectedPatchScope))
  end

  def test_replay_runner_tolerates_missing_internal_baseline_evidence
    replay = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.validate_document(
      valid_minimal_document
    )
    command_surface = RecordingTerrainCommandSurface.new(
      embed_baseline_evidence: false,
      baseline_evidence: nil
    )

    evidence = replay.execute(command_surface: command_surface)

    row = evidence.fetch(:rows).first
    assert_nil(row.fetch(:featureViewDigest))
    assert(row.fetch(:timingBuckets).fetch(:total).positive?)
  end

  def test_replay_runner_keeps_timing_terrains_opt_in
    replay = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineReplay.validate_document(
      valid_document_with_timing_terrain
    )

    default_surface = RecordingTerrainCommandSurface.new
    default_evidence = replay.execute(command_surface: default_surface)

    assert_equal(%w[create-baseline target-local-center],
                 default_evidence.fetch(:rows).map { |row| row.fetch(:rowId) })
    assert_equal(%i[create_terrain_surface edit_terrain_surface], default_surface.calls)

    timing_surface = RecordingTerrainCommandSurface.new
    timing_evidence = replay.execute(
      command_surface: timing_surface,
      include_timing: true,
      timing_row_ids: ['timing-local-target']
    )

    assert_equal(
      %w[
        create-baseline
        target-local-center
        timing-terrain-create
        timing-local-target
      ],
      timing_evidence.fetch(:rows).map { |row| row.fetch(:rowId) }
    )
    assert_equal(
      %i[
        create_terrain_surface
        edit_terrain_surface
        create_terrain_surface
        edit_terrain_surface
      ],
      timing_surface.calls
    )
  end

  private

  def assert_canonical_replay_metadata(replay)
    assert_equal(1, replay.schema_version)
    assert_equal('feature-aware-adaptive-baseline', replay.corpus_id)
  end

  def assert_canonical_replay_terrain(replay)
    assert_equal({ 'columns' => 49, 'rows' => 49 }, replay.terrain.fetch('dimensions'))
    assert_equal({ 'x' => 0.5, 'y' => 0.5 }, replay.terrain.fetch('spacingMeters'))
    assert(replay.terrain.dig('placement', 'origin'))
    assert_varied_elevations(replay.terrain.fetch('createTerrainSurface'))
    assert_large_timing_terrain(replay.document.fetch('secondaryTimingTerrain'))
    assert_additional_timing_terrain(replay.document.fetch('additionalTimingTerrains').first)
  end

  def assert_varied_elevations(create_payload)
    elevations = create_payload.dig('definition', 'grid', 'elevations')
    assert_equal(49 * 49, elevations.length)
    assert_operator(elevations.max - elevations.min, :>, 0.5)
  end

  def assert_large_timing_terrain(terrain)
    assert_equal({ 'columns' => 224, 'rows' => 224 }, terrain.fetch('dimensions'))
    elevations = terrain.dig('createTerrainSurface', 'definition', 'grid', 'elevations')
    assert_equal(224 * 224, elevations.length)
    assert_operator(elevations.max - elevations.min, :>, 0.8)
    assert_equal(
      %w[
        large-varied-local-target-timing
        large-varied-corridor-diagonal-timing
        large-varied-planar-pad-timing
        large-varied-survey-control-timing
        large-varied-fairing-envelope-timing
      ],
      terrain.fetch('timingOnlyRows').map { |row| row.fetch('rowId') }
    )
  end

  def assert_additional_timing_terrain(terrain)
    assert_equal(
      'feature-aware-baseline-terrain-wide-timing',
      terrain.fetch('sourceElementId')
    )
    assert_equal({ 'columns' => 192, 'rows' => 192 }, terrain.fetch('dimensions'))
    elevations = terrain.dig('createTerrainSurface', 'definition', 'grid', 'elevations')
    assert_equal(192 * 192, elevations.length)
    assert_operator(elevations.max - elevations.min, :>, 0.8)
    assert_equal(
      %w[
        wide-varied-local-target-timing
        wide-varied-half-corridor-timing
        wide-varied-fairing-large-timing
      ],
      terrain.fetch('timingOnlyRows').map { |row| row.fetch('rowId') }
    )
  end

  def assert_live_results_identity(replay, results)
    assert_equal(1, results.fetch('schemaVersion'))
    assert_equal('feature-aware-adaptive-baseline-results', results.fetch('corpusId'))
    assert_equal(replay.corpus_id, results.fetch('baselineCorpusId'))
    assert_equal(Digest::SHA256.file(CANONICAL_PATH).hexdigest,
                 results.dig('fixture', 'sha256'))
    assert_equal(all_terrain_specs(replay.document), results.fetch('terrainSpecs'))
  end

  def assert_live_results_rows(replay, results)
    expected_row_ids = REQUIRED_ROW_IDS + timing_row_ids_by_terrain(replay.document)
    rows = results.fetch('rows')

    assert_equal(expected_row_ids, rows.map { |row| row.fetch('rowId') })
    assert(rows.all? { |row| !row.key?('refusal') || row.fetch('refusal').nil? })
    assert(rows.all? { |row| row.fetch('seconds').positive? })
    rows.each { |row| assert_live_result_row_instrumentation(row) }
  end

  def assert_live_result_row_instrumentation(row)
    buckets = row.fetch('timingBuckets')
    %w[
      commandOutputPlanning featureSelectionDiagnostics dirtyWindowMapping adaptivePlanning
      mutation total
    ].each do |bucket|
      assert_includes(buckets.keys, bucket)
      assert_operator(buckets.fetch(bucket), :>, 0.0)
    end
    assert_operator(row.fetch('simplificationTolerance'), :>, 0.0)
    assert_operator(row.fetch('maxSimplificationError'), :>=, 0.0)
    assert_operator(
      row.fetch('maxSimplificationError'),
      :<=,
      row.fetch('simplificationTolerance') + 1e-9
    )
  end

  def all_terrain_specs(document)
    [document.fetch('terrain'), *timing_terrains(document)].map do |terrain|
      dimensions = terrain.fetch('dimensions')
      {
        'sourceElementId' => terrain.fetch('sourceElementId'),
        'dimensions' => dimensions,
        'samples' => dimensions.fetch('columns') * dimensions.fetch('rows'),
        'regularGridFaces' => (dimensions.fetch('columns') - 1) *
          (dimensions.fetch('rows') - 1) * 2
      }
    end
  end

  def timing_row_ids_by_terrain(document)
    timing_terrains(document).flat_map do |terrain|
      [
        "#{terrain.fetch('sourceElementId')}-create",
        *terrain.fetch('timingOnlyRows').map { |row| row.fetch('rowId') }
      ]
    end
  end

  def timing_terrains(document)
    [document['secondaryTimingTerrain']].compact + Array(document['additionalTimingTerrains'])
  end

  def valid_minimal_document
    {
      'schemaVersion' => 1,
      'corpusId' => 'feature-aware-adaptive-baseline',
      'units' => 'meters',
      'terrain' => {
        'sourceElementId' => 'feature-aware-baseline-terrain',
        'dimensions' => { 'columns' => 49, 'rows' => 49 },
        'spacingMeters' => { 'x' => 0.5, 'y' => 0.5 },
        'placement' => { 'origin' => { 'x' => 320.0, 'y' => 0.0, 'z' => 0.0 } },
        'elevationRecipe' => { 'kind' => 'deterministic_wave_v1' },
        'createTerrainSurface' => {
          'metadata' => { 'sourceElementId' => 'feature-aware-baseline-terrain' },
          'lifecycle' => { 'mode' => 'create' }
        }
      },
      'sequences' => [
        {
          'sequenceId' => 'smoke-sequence',
          'rows' => [
            {
              'rowId' => 'create-baseline',
              'commandKind' => 'create',
              'expectedStatus' => 'accepted',
              'terrainPosition' => { 'x' => 320.0, 'y' => 0.0, 'z' => 0.0 },
              'featureContextClass' => 'none',
              'publicCommandPayload' => {
                'metadata' => { 'sourceElementId' => 'feature-aware-baseline-terrain' },
                'lifecycle' => { 'mode' => 'create' }
              }
            },
            {
              'rowId' => 'target-local-center',
              'commandKind' => 'edit',
              'expectedStatus' => 'accepted',
              'terrainPosition' => { 'x' => 320.0, 'y' => 0.0, 'z' => 0.0 },
              'dirtyWindowExpectation' => {
                'min' => { 'column' => 20, 'row' => 20 },
                'max' => { 'column' => 28, 'row' => 28 }
              },
              'featureContextClass' => 'target_region',
              'publicCommandPayload' => {
                'targetReference' => { 'sourceElementId' => 'feature-aware-baseline-terrain' },
                'operation' => { 'mode' => 'target_height', 'targetElevation' => 1.5 },
                'region' => {
                  'type' => 'rectangle',
                  'bounds' => {
                    'minX' => 10.0, 'minY' => 10.0, 'maxX' => 14.0, 'maxY' => 14.0
                  }
                }
              }
            }
          ]
        }
      ]
    }
  end

  def valid_document_with_timing_terrain
    valid_minimal_document.merge(
      'secondaryTimingTerrain' => {
        'sourceElementId' => 'timing-terrain',
        'dimensions' => { 'columns' => 2, 'rows' => 2 },
        'spacingMeters' => { 'x' => 1.0, 'y' => 1.0 },
        'placement' => { 'origin' => { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 } },
        'elevationRecipe' => { 'kind' => 'test' },
        'createTerrainSurface' => {
          'metadata' => { 'sourceElementId' => 'timing-terrain' },
          'lifecycle' => { 'mode' => 'create' },
          'definition' => {
            'kind' => 'heightmap_grid',
            'grid' => {
              'dimensions' => { 'columns' => 2, 'rows' => 2 },
              'elevations' => [0.0, 0.1, 0.2, 0.3]
            }
          }
        },
        'timingOnlyRows' => [
          {
            'rowId' => 'timing-local-target',
            'commandKind' => 'edit',
            'expectedStatus' => 'accepted',
            'terrainPosition' => { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
            'featureContextClass' => 'timing_local_target',
            'publicCommandPayload' => {
              'targetReference' => { 'sourceElementId' => 'timing-terrain' },
              'operation' => { 'mode' => 'target_height' },
              'region' => { 'type' => 'rectangle' }
            }
          }
        ]
      }
    )
  end

  class RecordingTerrainCommandSurface
    attr_reader :calls, :last_baseline_evidence

    def initialize(embed_baseline_evidence: true, baseline_evidence: :default)
      @calls = []
      @embed_baseline_evidence = embed_baseline_evidence
      @baseline_evidence = baseline_evidence
    end

    def create_terrain_surface(_payload)
      @calls << :create_terrain_surface
      accepted_response
    end

    def edit_terrain_surface(_payload)
      @calls << :edit_terrain_surface
      accepted_response
    end

    def accepted_response
      baseline = baseline_evidence
      @last_baseline_evidence = baseline
      response = {
        outcome: 'edited',
        terrain: { after: { revision: 2 } },
        output: {
          derivedMesh: {
            faceCount: 10,
            vertexCount: 8,
            meshType: 'adaptive_tin',
            simplificationTolerance: 0.01,
            maxSimplificationError: 0.009
          }
        }
      }
      response[:baselineEvidence] = baseline if @embed_baseline_evidence
      response
    end

    private

    def baseline_evidence
      return @baseline_evidence unless @baseline_evidence == :default

      {
        featureViewDigest: 'feature-digest-a',
        policyFingerprint: 'policy-fingerprint-a',
        featureContext: { selected: 2 },
        affectedPatchScope: { patches: %w[adaptive-patch-v1-c1-r1] },
        renderingSummary: { status: 'captured', topology: 'single_mesh' },
        timingBuckets: {
          commandOutputPlanning: 0.02,
          featureSelectionDiagnostics: 0.03,
          dirtyWindowMapping: 0.04,
          adaptivePlanning: 0.05,
          mutation: 0.06,
          total: 0.2
        },
        simplificationTolerance: 0.01,
        maxSimplificationError: 0.009
      }
    end
  end
end
