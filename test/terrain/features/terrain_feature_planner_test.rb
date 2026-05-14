# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_set'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_planner'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

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

  def test_pre_save_keeps_affected_window_pointification_projection_diagnostic_only
    broad_feature = feature('linear_corridor').merge(
      'payload' => { 'generation' => { 'pointificationPolicy' => 'grid_relative_v1' } },
      'affectedWindow' => { 'min' => { 'column' => 0, 'row' => 0 },
                            'max' => { 'column' => 40, 'row' => 40 } }
    )

    result = planner.pre_save(state: state_with_features([broad_feature]))

    assert_equal('ready', result.fetch(:outcome))
    assert_equal(1681, result.dig(:diagnostics, :capProjection, :projectedSampleCount))
    assert_equal(2, result.dig(:diagnostics, :capProjection, :maxLaneSamplesPerFeature))
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
    result = planner.prepare(
      state: state_with_features([feature('fixed_control')]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true
    )

    assert_equal('prepared', result.fetch(:outcome))
    assert_equal('digest-feature', result.dig(:context, :terrainStateDigest))
    assert_equal(1, result.dig(:context, :constraintCount))
    assert_equal('explicit_edit', result.dig(:context, :constraints, 0, :sourceMode))
    assert_equal('feature_window', result.dig(:outputWindowReconciliation, :mode))
    assert_respond_to(result.dig(:context, :featureGeometry), :feature_geometry_digest)
    assert_match(/\A[a-f0-9]{64}\z/, result.dig(:context, :featureGeometryDigest))
  end

  def test_prepare_uses_effective_active_features_for_constraints_and_cdt_geometry
    active = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:active-fixed:aaaaaaaaaaaa',
      'semanticScope' => 'active-fixed',
      'payload' => { 'control' => { 'point' => { 'x' => 1.0, 'y' => 1.0 } } }
    )
    retired = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:retired-fixed:bbbbbbbbbbbb',
      'semanticScope' => 'retired-fixed',
      'payload' => { 'control' => { 'point' => { 'x' => 2.0, 'y' => 2.0 } } },
      'lifecycle' => { 'status' => 'retired', 'updatedAtRevision' => 2 }
    )

    result = normal_planner.prepare(
      state: state_with_features([active, retired]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true
    )

    assert_equal(1, result.dig(:context, :constraintCount))
    assert_equal(['feature:fixed_control:explicit_edit:active-fixed:aaaaaaaaaaaa'],
                 result.dig(:context, :constraints).map { |item| item.fetch(:id) })
    assert_equal(1, result.dig(:context, :featureGeometry).output_anchor_candidates.length)
  end

  def test_prepare_ignores_retired_broken_hard_geometry
    active = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:active-fixed:aaaaaaaaaaaa',
      'semanticScope' => 'active-fixed',
      'payload' => { 'control' => { 'point' => { 'x' => 1.0, 'y' => 1.0 } } }
    )
    retired_broken_preserve = feature('preserve_region').merge(
      'id' => 'feature:preserve_region:explicit_edit:old-preserve:bbbbbbbbbbbb',
      'semanticScope' => 'old-preserve',
      'roles' => %w[protected boundary],
      'payload' => { 'region' => { 'type' => 'polygon' } },
      'lifecycle' => { 'status' => 'retired', 'updatedAtRevision' => 2 }
    )

    result = normal_planner.prepare(
      state: state_with_features([retired_broken_preserve, active]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true
    )
    geometry = result.dig(:context, :featureGeometry)

    assert_equal('prepared', result.fetch(:outcome))
    assert_equal('none', geometry.failure_category)
    assert_empty(geometry.limitations)
    assert_equal(1, geometry.output_anchor_candidates.length)
  end

  def test_prepare_large_history_uses_effective_active_relevant_records_only
    active = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:active-fixed:aaaaaaaaaaaa',
      'semanticScope' => 'active-fixed',
      'payload' => { 'control' => { 'point' => { 'x' => 1.0, 'y' => 1.0 } } }
    )
    historical = 50.times.map do |index|
      feature('target_region').merge(
        'id' => format(
          'feature:target_region:explicit_edit:old-%<index>02d:%<suffix>012x',
          index: index,
          suffix: index
        ),
        'semanticScope' => "old-#{index}",
        'roles' => %w[support falloff],
        'lifecycle' => { 'status' => 'superseded', 'updatedAtRevision' => index + 1 }
      )
    end

    result = normal_planner.prepare(
      state: state_with_features(historical + [active]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true,
      selection_window: output_window
    )

    assert_equal(1, result.dig(:context, :constraintCount))
    assert_equal(['feature:fixed_control:explicit_edit:active-fixed:aaaaaaaaaaaa'],
                 result.dig(:context, :constraints).map { |item| item.fetch(:id) })
    assert_equal(1, result.dig(:context, :featureGeometry).output_anchor_candidates.length)
  end

  def test_prepare_filters_hard_firm_and_soft_features_by_patch_relevance
    hard = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:hard-far:aaaaaaaaaaaa',
      'semanticScope' => 'hard-far',
      'affectedWindow' => far_window,
      'relevanceWindow' => far_window,
      'payload' => { 'control' => { 'point' => { 'x' => 10.0, 'y' => 10.0 } } }
    )
    soft_near = feature('target_region').merge(
      'id' => 'feature:target_region:explicit_edit:soft-near:bbbbbbbbbbbb',
      'semanticScope' => 'soft-near',
      'roles' => %w[support falloff],
      'affectedWindow' => output_window,
      'relevanceWindow' => output_window
    )
    soft_far = feature('target_region').merge(
      'id' => 'feature:target_region:explicit_edit:soft-far:cccccccccccc',
      'semanticScope' => 'soft-far',
      'roles' => %w[support falloff],
      'affectedWindow' => far_window,
      'relevanceWindow' => far_window
    )

    result = normal_planner.prepare(
      state: state_with_features([soft_far, hard, soft_near]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true,
      selection_window: output_window
    )

    assert_equal(
      %w[
        feature:target_region:explicit_edit:soft-near:bbbbbbbbbbbb
      ],
      result.dig(:context, :constraints).map { |item| item.fetch(:id) }.sort
    )
    diagnostics = result.dig(:context, :featureSelectionDiagnostics)
    assert_equal('patch_relevant', diagnostics.fetch(:selectionMode))
    assert_equal(1, diagnostics.fetch(:excludedByStrength).fetch(:hard))
  end

  def test_prepare_keeps_all_active_effective_features_for_full_grid_generation
    hard = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:hard-far:aaaaaaaaaaaa',
      'semanticScope' => 'hard-far',
      'affectedWindow' => far_window,
      'relevanceWindow' => far_window,
      'payload' => { 'control' => { 'point' => { 'x' => 10.0, 'y' => 10.0 } } }
    )
    soft = feature('target_region').merge(
      'id' => 'feature:target_region:explicit_edit:soft-far:bbbbbbbbbbbb',
      'semanticScope' => 'soft-far',
      'roles' => %w[support falloff],
      'affectedWindow' => far_window,
      'relevanceWindow' => far_window
    )

    result = normal_planner.prepare(
      state: state_with_features([hard, soft]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true,
      selection_window: nil
    )

    assert_equal(
      %w[
        feature:fixed_control:explicit_edit:hard-far:aaaaaaaaaaaa
        feature:target_region:explicit_edit:soft-far:bbbbbbbbbbbb
      ],
      result.dig(:context, :constraints).map { |item| item.fetch(:id) }.sort
    )
    assert_equal('full_grid', result.dig(:context, :featureSelectionDiagnostics, :selectionMode))
    assert_equal({ status: 'eligible' }, result.dig(:context, :cdtParticipation))
  end

  def test_prepare_reports_effective_selection_diagnostics_for_large_history
    active_hard = feature('fixed_control').merge(
      'id' => 'feature:fixed_control:explicit_edit:hard-active:aaaaaaaaaaaa',
      'semanticScope' => 'hard-active',
      'payload' => { 'control' => { 'point' => { 'x' => 1.0, 'y' => 1.0 } } }
    )
    active_soft_near = feature('target_region').merge(
      'id' => 'feature:target_region:explicit_edit:soft-near:bbbbbbbbbbbb',
      'semanticScope' => 'soft-near',
      'roles' => %w[support falloff],
      'affectedWindow' => output_window,
      'relevanceWindow' => output_window
    )
    active_soft_far = feature('target_region').merge(
      'id' => 'feature:target_region:explicit_edit:soft-far:cccccccccccc',
      'semanticScope' => 'soft-far',
      'roles' => %w[support falloff],
      'affectedWindow' => far_window,
      'relevanceWindow' => far_window
    )
    historical = 240.times.map do |index|
      feature('target_region').merge(
        'id' => format(
          'feature:target_region:explicit_edit:history-%<index>03d:%<suffix>012x',
          index: index,
          suffix: index
        ),
        'semanticScope' => "history-#{index}",
        'roles' => %w[support falloff],
        'lifecycle' => { 'status' => 'superseded', 'updatedAtRevision' => index + 1 }
      )
    end

    result = normal_planner.prepare(
      state: state_with_features(historical + [active_soft_far, active_hard, active_soft_near]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true,
      selection_window: output_window
    )

    assert_large_history_selection_diagnostics(
      result.dig(:context, :featureSelectionDiagnostics)
    )
    assert_equal(2, result.dig(:context, :constraintCount))
  end

  def test_prepare_marks_cdt_skip_for_patch_relevant_unsupported_hard_geometry
    unsupported = feature('preserve_region').merge(
      'id' => 'feature:preserve_region:explicit_edit:unsupported:aaaaaaaaaaaa',
      'semanticScope' => 'unsupported',
      'roles' => %w[protected boundary],
      'payload' => { 'region' => { 'type' => 'polygon' } },
      'affectedWindow' => output_window,
      'relevanceWindow' => output_window
    )

    result = normal_planner.prepare(
      state: state_with_features([unsupported]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true,
      selection_window: output_window
    )

    assert_equal('prepared', result.fetch(:outcome))
    assert_equal({ status: 'skip' }, result.dig(:context, :cdtParticipation))
    assert_equal('feature_geometry_failed',
                 result.dig(:context, :featureGeometry).failure_category)
    assert_equal(
      1,
      result.dig(
        :context, :featureSelectionDiagnostics, :cdtFallbackTriggers,
        :patch_relevant_feature_geometry_failed
      )
    )
  end

  def test_prepare_budget_overflow_stays_cdt_eligible_with_internal_diagnostics
    broad = feature('linear_corridor').merge(
      'id' => 'feature:linear_corridor:explicit_edit:broad:aaaaaaaaaaaa',
      'semanticScope' => 'broad',
      'payload' => {
        'sampleEstimate' => 9000,
        'startControl' => { 'point' => { 'x' => 0.0, 'y' => 0.0 } },
        'endControl' => { 'point' => { 'x' => 1.0, 'y' => 1.0 } },
        'width' => 1.0,
        'sideBlend' => { 'distance' => 1.0, 'falloff' => 'cosine' }
      },
      'affectedWindow' => output_window,
      'relevanceWindow' => output_window
    )

    result = normal_planner.prepare(
      state: state_with_features([broad]),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true,
      selection_window: output_window
    )

    assert_equal('prepared', result.fetch(:outcome))
    assert_equal(
      { status: 'eligible', budgetStatus: 'over_limit' },
      result.dig(:context, :cdtParticipation)
    )
    assert_equal(
      1,
      result.dig(
        :context, :featureSelectionDiagnostics, :cdtFallbackTriggers,
        :patch_relevant_budget_overflow
      )
    )
  end

  def test_prepare_refuses_stale_effective_index_without_public_feature_leak
    result = normal_planner.prepare(
      state: state_with_features([feature('fixed_control')], stale_effective_index: true),
      terrain_state_summary: { digest: 'digest-feature' },
      include_feature_geometry: true
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('terrain_feature_effective_index_invalid', result.dig(:refusal, :code))
    refute_public_feature_leak(result.fetch(:refusal))
  end

  def test_prepare_omits_feature_geometry_when_cdt_output_is_not_enabled
    result = planner.prepare(state: state_with_features([feature('fixed_control')]),
                             terrain_state_summary: { digest: 'digest-feature' })

    assert_equal('prepared', result.fetch(:outcome))
    assert_equal(1, result.dig(:context, :constraintCount))
    refute(result.fetch(:context).key?(:featureGeometry))
    refute(result.fetch(:context).key?(:featureGeometryDigest))
    refute(result.fetch(:context).key?(:referenceGeometryDigest))
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

  def test_prepare_patch_batch_tags_conformance_retained_boundary_and_safety_roles
    result = normal_planner.prepare_patch_batch(
      state: state_with_features([feature('target_region')]),
      terrain_state_summary: { digest: 'digest-feature' },
      lifecycle_resolution: {
        affectedPatchIds: ['cdt-patch-v1-c0-r0'],
        replacementPatchIds: %w[cdt-patch-v1-c0-r0 cdt-patch-v1-c1-r0],
        affectedPatches: [lifecycle_patch('cdt-patch-v1-c0-r0')],
        replacementPatches: [
          lifecycle_patch('cdt-patch-v1-c0-r0'),
          lifecycle_patch('cdt-patch-v1-c1-r0')
        ],
        retainedBoundaryPatches: [lifecycle_patch('cdt-patch-v1-c0-r1')],
        safetyMarginPatches: [lifecycle_patch('cdt-patch-v1-c1-r1')]
      },
      base_context: {}
    )

    bundles = result.fetch(:patchFeatureBundles)
    assert_includes(bundles.fetch('cdt-patch-v1-c1-r0').fetch(:inclusionReasons), 'conformance')
    assert_includes(
      bundles.fetch('cdt-patch-v1-c0-r1').fetch(:inclusionReasons),
      'retained_boundary'
    )
    assert_includes(bundles.fetch('cdt-patch-v1-c1-r1').fetch(:inclusionReasons),
                    'safety_margin')
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

  def state_with_features(features, stale_effective_index: false)
    feature_intent = SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 1,
      'features' => features,
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    ).to_h
    if stale_effective_index
      feature_intent['effectiveIndex'] = feature_intent.fetch('effectiveIndex')
                                                       .merge('sourceDigest' => '0' * 64)
    end
    build_state.with_feature_intent(feature_intent)
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

  def output_window
    { 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 1, 'row' => 1 } }
  end

  def far_window
    { 'min' => { 'column' => 10, 'row' => 10 }, 'max' => { 'column' => 12, 'row' => 12 } }
  end

  def lifecycle_patch(patch_id)
    {
      patchId: patch_id,
      bounds: { minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 1 },
      sampleBounds: { minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 1 }
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

  def assert_large_history_selection_diagnostics(diagnostics)
    assert_equal('patch_relevant', diagnostics.fetch(:selectionMode))
    assert_equal(3, diagnostics.fetch(:active))
    assert_equal(2, diagnostics.fetch(:included))
    assert_equal(240, diagnostics.fetch(:excludedByStatus))
    assert_equal(1, diagnostics.fetch(:excludedByRelevance))
    assert_equal({ hard: 1, firm: 0, soft: 1 }, diagnostics.fetch(:includedByStrength))
    assert_equal({ hard: 0, firm: 0, soft: 1 }, diagnostics.fetch(:excludedByStrength))
    assert_equal({ outside_patch_relevance: 1 }, diagnostics.fetch(:excludedByReason))
  end
end
