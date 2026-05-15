# frozen_string_literal: true

require 'tmpdir'

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_capture'

class FeatureAwareAdaptiveBaselineCaptureTest < Minitest::Test
  def test_capture_writes_repeatable_durable_results_with_phase_timing_and_error_bounds
    Dir.mktmpdir do |dir|
      paths = write_replay_fixture(dir)

      document = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineCapture.capture_live!(
        replay_path: paths.fetch(:replay_path),
        results_path: paths.fetch(:results_path),
        command_surface: RecordingCommandSurface.new,
        model: nil,
        clock: FixedClock,
        include_timing: false,
        clear_existing: false
      )

      assert_path_exists(paths.fetch(:results_path))
      written = JSON.parse(File.read(paths.fetch(:results_path)))
      assert_equal('feature-aware-adaptive-baseline-results', written.fetch('corpusId'))
      assert_equal(document.fetch(:fixture).fetch(:sha256), written.dig('fixture', 'sha256'))
      assert_capture_row(document.fetch(:rows).first)
    end
  end

  private

  def write_replay_fixture(dir)
    replay_path = File.join(dir, 'feature_aware_adaptive_baseline.json')
    results_path = File.join(dir, 'feature_aware_adaptive_baseline_results.json')
    File.write(replay_path, JSON.generate(minimal_replay_document))
    { replay_path: replay_path, results_path: results_path }
  end

  def assert_capture_row(row)
    assert_equal('capture-terrain-create', row.fetch(:rowId))
    assert_equal('capture-terrain', row.fetch(:sourceElementId))
    assert(row.fetch(:timingBuckets).fetch(:total).positive?)
    assert_equal(0.02, row.fetch(:timingBuckets).fetch(:commandOutputPlanning))
    assert_equal(0.01, row.fetch(:simplificationTolerance))
    assert_equal(0.008, row.fetch(:maxSimplificationError))
  end

  def minimal_replay_document
    {
      'schemaVersion' => 1,
      'corpusId' => 'feature-aware-adaptive-baseline',
      'units' => 'meters',
      'terrain' => {
        'sourceElementId' => 'capture-terrain',
        'dimensions' => { 'columns' => 3, 'rows' => 3 },
        'spacingMeters' => { 'x' => 1.0, 'y' => 1.0 },
        'placement' => { 'origin' => { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 } },
        'elevationRecipe' => { 'kind' => 'test' },
        'createTerrainSurface' => {
          'metadata' => { 'sourceElementId' => 'capture-terrain' },
          'lifecycle' => { 'mode' => 'create' },
          'definition' => {
            'kind' => 'heightmap_grid',
            'grid' => {
              'dimensions' => { 'columns' => 3, 'rows' => 3 },
              'elevations' => [0.0, 0.1, 0.2, 0.1, 0.3, 0.4, 0.2, 0.4, 0.5]
            }
          }
        }
      },
      'sequences' => [
        {
          'sequenceId' => 'capture-sequence',
          'rows' => [
            {
              'rowId' => 'capture-terrain-create',
              'commandKind' => 'create',
              'expectedStatus' => 'accepted',
              'terrainPosition' => { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
              'featureContextClass' => 'none',
              'publicCommandPayload' => {
                'metadata' => { 'sourceElementId' => 'capture-terrain' },
                'lifecycle' => { 'mode' => 'create' }
              }
            }
          ]
        }
      ]
    }
  end

  module FixedClock
    module_function

    def now
      Time.utc(2026, 5, 16, 8, 0, 0)
    end
  end

  class RecordingCommandSurface
    attr_reader :last_baseline_evidence

    def create_terrain_surface(_payload)
      @last_baseline_evidence = {
        timingBuckets: {
          commandOutputPlanning: 0.02,
          featureSelectionDiagnostics: 0.03,
          dirtyWindowMapping: 0.04,
          adaptivePlanning: 0.05,
          mutation: 0.06,
          total: 0.21
        },
        affectedPatchScope: {
          affectedPatchCount: 1,
          replacementPatchCount: 1,
          conformanceRing: 1
        },
        renderingSummary: { status: 'captured', meshType: 'adaptive_tin' },
        simplificationTolerance: 0.01,
        maxSimplificationError: 0.008
      }
      {
        outcome: 'created',
        terrain: { after: { revision: 1 } },
        output: {
          derivedMesh: {
            meshType: 'adaptive_tin',
            faceCount: 2,
            vertexCount: 4,
            simplificationTolerance: 0.01,
            maxSimplificationError: 0.008
          }
        }
      }
    end
  end
end
