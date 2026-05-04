# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/feature_intent_set'
require_relative '../../src/su_mcp/terrain/terrain_feature_planner'
require_relative '../../src/su_mcp/terrain/tiled_heightmap_state'

class TerrainFeaturePlannerTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_pre_save_refuses_projected_feature_pointification_limit_before_mutation
    result = planner.pre_save(state: state_with_features([feature('linear_corridor')]))

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_feature_pointification_limit_exceeded', result.dig(:refusal, :code))
    assert_equal(1, result.dig(:refusal, :details, :featureCount))
    refute_public_feature_leak(result.fetch(:refusal))
  end

  def test_pre_save_reports_internal_cap_diagnostics_on_ready_result
    result = normal_planner.pre_save(state: state_with_features([feature('fixed_control')]))

    assert_equal('ready', result.fetch(:outcome))
    assert_equal(
      {
        phase: 'pre_save',
        featureCount: 1,
        projectedSampleCount: 3,
        maxLaneSamplesPerFeature: 512,
        maxLaneSamplesPerPlan: 4096
      },
      result.fetch(:diagnostics).fetch(:capProjection)
    )
  end

  def test_pre_save_refuses_explicit_fixed_control_conflict_with_internal_diagnostics
    fixed = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:fixed-a:aaaaaaaaaaaa',
      'roles' => %w[control protected],
      'payload' => { 'semanticScope' => 'fixed-a' }
    )
    target = feature('target_region').merge(
      'id' => 'feature:target_region:explicit_edit:region-a:bbbbbbbbbbbb',
      'payload' => {
        'semanticScope' => 'region-a',
        'conflictsWithFeatureIds' => [fixed.fetch('id')]
      }
    )

    result = normal_planner.pre_save(state: state_with_features([fixed, target]))

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_feature_conflict', result.dig(:refusal, :code))
    assert_equal('feature_conflict', result.dig(:refusal, :details, :category))
    assert_equal(2, result.dig(:refusal, :details, :featureCount))
    assert_equal('fixed_control_conflict', result.dig(:diagnostics, :conflict, :category))
    assert_equal(
      [fixed.fetch('id'), target.fetch('id')],
      result.dig(:diagnostics, :conflict, :featureIds)
    )
    refute_public_feature_leak(result.fetch(:refusal))
  end

  def test_pre_save_refuses_preserve_region_conflict_with_internal_diagnostics
    preserve = feature('preserve_region').merge(
      'id' => 'feature:preserve_region:explicit_edit:preserve-a:aaaaaaaaaaaa',
      'roles' => %w[protected boundary],
      'payload' => { 'semanticScope' => 'preserve-a' }
    )
    corridor = feature('linear_corridor').merge(
      'id' => 'feature:linear_corridor:explicit_edit:corridor-a:bbbbbbbbbbbb',
      'payload' => {
        'semanticScope' => 'corridor-a',
        'conflictsWithFeatureIds' => [preserve.fetch('id')]
      }
    )

    result = normal_planner.pre_save(state: state_with_features([preserve, corridor]))

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_feature_conflict', result.dig(:refusal, :code))
    assert_equal('preserve_region_conflict', result.dig(:diagnostics, :conflict, :category))
  end

  def test_pre_save_refuses_corridor_tight_turn_geometry_before_mutation
    corridor = feature('linear_corridor').merge(
      'payload' => {
        'startControl' => { 'point' => { 'x' => 0.0, 'y' => 0.0 } },
        'endControl' => { 'point' => { 'x' => 0.2, 'y' => 0.0 } },
        'width' => 1.0
      }
    )

    result = normal_planner.pre_save(state: state_with_features([corridor]))

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_feature_conflict', result.dig(:refusal, :code))
    assert_equal('corridor_geometry_unsupported', result.dig(:diagnostics, :conflict, :category))
    assert_equal('tight_turn_or_self_intersection', result.dig(:diagnostics, :conflict, :reason))
  end

  def test_prepare_returns_runtime_context_with_explicit_features_and_saved_digest
    result = planner.prepare(state: state_with_features([feature('fixed_control')]),
                             terrain_state_summary: { digest: 'digest-feature' })

    assert_equal('prepared', result.fetch(:outcome))
    assert_equal('digest-feature', result.dig(:context, :terrainStateDigest))
    assert_equal(1, result.dig(:context, :constraintCount))
    assert_equal('explicit_edit', result.dig(:context, :constraints, 0, :sourceMode))
  end

  def test_prepare_adds_runtime_only_inferred_heightfield_candidate_without_persisting_it
    result = planner.prepare(
      state: build_state(elevations: [1.0, 1.0, 4.0, 4.0]),
      terrain_state_summary: { digest: 'digest-legacy' }
    )

    assert(result.dig(:context, :constraints).any? do |constraint|
      constraint[:kind] == 'inferred_heightfield' &&
        constraint[:sourceMode] == 'inferred_heightfield'
    end)
    refute_includes(JSON.generate(result.fetch(:state).feature_intent), 'inferred_heightfield')
  end

  def test_classifies_expected_feature_aligned_break_and_suspicious_cross_feature_edge
    context = planner.prepare(state: state_with_features([feature('linear_corridor')]),
                              terrain_state_summary: { digest: 'digest-feature' }).fetch(:context)

    result = planner.classify_topology(
      context: context,
      topology: {
        normal_breaks: [{ from: [0, 0], to: [1, 0], featureAligned: true }],
        long_edges: [{ from: [0, 0], to: [3, 2], crossesProtectedFeature: true }]
      }
    )

    assert_equal(1, result.fetch(:expectedFeatureBreaks).length)
    assert_equal(1, result.fetch(:suspiciousCrossFeatureEdges).length)
  end

  private

  def planner
    @planner ||= SU_MCP::Terrain::TerrainFeaturePlanner.new(
      max_lane_samples_per_feature: 2,
      max_lane_samples_per_plan: 4
    )
  end

  def normal_planner
    @normal_planner ||= SU_MCP::Terrain::TerrainFeaturePlanner.new
  end

  def state_with_features(features)
    build_state.with_feature_intent(
      {
        'schemaVersion' => 3,
        'revision' => 1,
        'features' => features,
        'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
      }
    )
  end

  def build_state(elevations: Array.new(4, 1.0))
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 2, 'rows' => 2 },
      elevations: elevations,
      revision: 1,
      state_id: 'state-1'
    )
  end

  def feature(kind)
    {
      'id' => "feature:#{kind}:explicit_edit:scope:aaaaaaaaaaaa",
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'roles' => kind == 'fixed_control' ? ['control'] : %w[centerline hard_break],
      'priority' => 70,
      'payload' => { 'sampleEstimate' => 3 },
      'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                            'max' => { 'column' => 1, 'row' => 1 } },
      'provenance' => {
        'originClass' => 'edit_terrain_surface',
        'originOperation' => kind,
        'createdAtRevision' => 1,
        'updatedAtRevision' => 1
      }
    }
  end

  def refute_public_feature_leak(result)
    serialized = JSON.generate(result)
    %w[
      feature: linear_corridor fixed_control affectedWindow roles payload FeatureIntent
    ].each do |term|
      refute_includes(serialized, term)
    end
  end
end
