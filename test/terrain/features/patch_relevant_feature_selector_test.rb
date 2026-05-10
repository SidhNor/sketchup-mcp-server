# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_set'
require_relative '../../../src/su_mcp/terrain/features/patch_relevant_feature_selector'
require_relative '../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_domain'
require_relative '../../../src/su_mcp/terrain/regions/sample_window'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class PatchRelevantFeatureSelectorTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_normalizes_hash_sample_window_and_patch_domain_to_same_expanded_patch
    features = normalized_features([
                                     fixed_feature('inside-hard', point: [5.0, 5.0]),
                                     fixed_feature('far-hard', point: [14.0, 14.0],
                                                               window: window(14, 14, 14, 14))
                                   ])
    hash_selection = selector.select(state: state, features: features, window: changed_region)
    sample_selection = selector.select(state: state, features: features, window: sample_window)
    domain_selection = selector.select(
      state: state,
      features: features,
      window: SU_MCP::Terrain::PatchCdtDomain.from_window(state: state, window: sample_window)
    )

    assert_equal(%w[inside-hard], selected_ids(hash_selection))
    assert_equal(selected_ids(hash_selection), selected_ids(sample_selection))
    assert_equal(selected_ids(hash_selection), selected_ids(domain_selection))
    assert_equal(
      { minColumn: 2, minRow: 2, maxColumn: 7, maxRow: 7 },
      hash_selection.fetch(:diagnostics).fetch(:patchWindow)
    )
  end

  def test_full_grid_mode_keeps_all_active_effective_features
    features = normalized_features([
                                     fixed_feature(
                                       'hard-a',
                                       point: [14.0, 14.0],
                                       window: window(14, 14, 14, 14)
                                     ),
                                     target_feature(
                                       'soft-a',
                                       region: circle([16.0, 16.0], 1.0),
                                       window: window(15, 15, 17, 17)
                                     )
                                   ])

    selection = selector.select(state: state, features: features, window: nil)

    assert_equal(%w[hard-a soft-a], selected_ids(selection))
    assert_equal('full_grid', selection.fetch(:diagnostics).fetch(:selectionMode))
    assert_equal({ status: 'eligible' }, selection.fetch(:cdtParticipation))
  end

  def test_selects_patch_relevant_hard_features_and_excludes_far_hard_features
    features = normalized_features([
                                     fixed_feature('inside-hard', point: [5.0, 5.0]),
                                     fixed_feature('near-hard', point: [7.0, 5.0],
                                                                window: window(7, 5, 7, 5)),
                                     fixed_feature('far-hard', point: [14.0, 14.0],
                                                               window: window(14, 14, 14, 14)),
                                     preserve_feature('crossing-preserve',
                                                      region: rectangle([1.0, 5.0], [9.0, 6.0]),
                                                      window: window(1, 5, 9, 6))
                                   ])

    selection = selector.select(state: state, features: features, window: sample_window)

    assert_equal(%w[crossing-preserve inside-hard near-hard], selected_ids(selection))
    assert_equal('eligible', selection.fetch(:cdtParticipation).fetch(:status))
    assert_equal(3, selection.dig(:diagnostics, :includedByStrength, :hard))
    assert_equal(1, selection.dig(:diagnostics, :excludedByStrength, :hard))
    assert_equal(1, selection.dig(:diagnostics, :excludedByReason, :outside_patch_relevance))
  end

  def test_unsupported_far_hard_is_excluded_without_disabling_cdt_but_touched_unsupported_hard_skips
    far = preserve_feature('far-unsupported',
                           region: { 'type' => 'polygon' },
                           window: window(14, 14, 15, 15))
    touched = preserve_feature('touched-unsupported',
                               region: { 'type' => 'polygon' },
                               window: window(4, 4, 5, 5))

    far_selection = selector.select(state: state, features: normalized_features([far]),
                                    window: sample_window)
    touched_selection = selector.select(state: state, features: normalized_features([touched]),
                                        window: sample_window)

    assert_empty(selected_ids(far_selection))
    assert_equal({ status: 'eligible' }, far_selection.fetch(:cdtParticipation))
    assert_equal(%w[touched-unsupported], selected_ids(touched_selection))
    assert_equal('skip', touched_selection.fetch(:cdtParticipation).fetch(:status))
    assert_equal(
      1,
      touched_selection.dig(
        :diagnostics, :cdtFallbackTriggers,
        :patch_relevant_hard_primitive_unsupported
      )
    )
  end

  def test_degenerate_touched_hard_region_is_selected_and_skips_cdt_internally
    feature = preserve_feature('degenerate-preserve',
                               region: rectangle([5.0, 5.0], [5.0, 5.0]),
                               window: window(5, 5, 5, 5))

    selection = selector.select(state: state, features: normalized_features([feature]),
                                window: sample_window)

    assert_equal(%w[degenerate-preserve], selected_ids(selection))
    assert_equal('skip', selection.fetch(:cdtParticipation).fetch(:status))
    assert_equal(
      1,
      selection.dig(:diagnostics, :cdtFallbackTriggers, :patch_relevant_hard_clip_degenerate)
    )
  end

  def test_firm_and_soft_features_are_selected_only_by_patch_relevance
    features = normalized_features([
                                     corridor_feature('firm-crossing', start_point: [1.0, 5.0],
                                                                       end_point: [9.0, 5.0],
                                                                       window: window(1, 5, 9, 5)),
                                     corridor_feature('firm-far', start_point: [14.0, 14.0],
                                                                  end_point: [16.0, 14.0],
                                                                  window: window(14, 14, 16, 14)),
                                     target_feature('soft-inside',
                                                    region: circle([5.0, 5.0], 1.0)),
                                     target_feature('soft-far',
                                                    region: circle([16.0, 16.0], 1.0),
                                                    window: window(15, 15, 17, 17))
                                   ])

    selection = selector.select(state: state, features: features, window: sample_window)

    assert_equal(%w[firm-crossing soft-inside], selected_ids(selection))
    assert_equal(1, selection.dig(:diagnostics, :includedByStrength, :firm))
    assert_equal(1, selection.dig(:diagnostics, :includedByStrength, :soft))
    assert_equal(1, selection.dig(:diagnostics, :excludedByStrength, :firm))
    assert_equal(1, selection.dig(:diagnostics, :excludedByStrength, :soft))
  end

  def test_survey_feature_without_geometry_uses_relevance_window_for_patch_selection
    local = survey_window_only_feature('survey-window-local', window: window(4, 4, 5, 5))
    far = survey_window_only_feature('survey-window-far', window: window(14, 14, 15, 15))

    selection = selector.select(state: state, features: normalized_features([local, far]),
                                window: sample_window)

    assert_equal(%w[survey-window-local], selected_ids(selection))
    assert_equal('eligible', selection.fetch(:cdtParticipation).fetch(:status))
    assert_equal(1, selection.dig(:diagnostics, :includedByStrength, :firm))
    assert_equal(1, selection.dig(:diagnostics, :excludedByReason, :outside_patch_relevance))
  end

  def test_cardinality_fixture_reduces_far_hard_participation_by_at_least_forty_percent
    touched = touched_hard_fixture
    far = far_hard_fixture

    selection = selector.select(state: state, features: normalized_features(touched + far),
                                window: sample_window)

    assert_equal(touched.map { |feature| feature.fetch('id') }.sort, selected_ids(selection))
    reduction = 1.0 - (selected_ids(selection).length.to_f / (touched.length + far.length))
    assert_operator(reduction, :>=, 0.40)
    assert_equal(22, selection.dig(:diagnostics, :excludedByStrength, :hard))
  end

  def touched_hard_fixture
    8.times.map do |index|
      fixed_feature("touched-hard-#{index}", point: [4.0 + (index % 2), 4.0 + (index / 2)],
                                             window: window(4, 4, 5, 7))
    end
  end

  def far_hard_fixture
    22.times.map do |index|
      column = 12 + (index % 5)
      row = 12 + (index / 5)
      fixed_feature("far-hard-#{index}", point: [column.to_f, row.to_f],
                                         window: window(column, row, column, row))
    end
  end

  private

  def selector
    @selector ||= SU_MCP::Terrain::PatchRelevantFeatureSelector.new
  end

  def selected_ids(selection)
    selection.fetch(:features).map { |feature| feature.fetch('id') }.sort
  end

  def normalized_features(features)
    SU_MCP::Terrain::FeatureIntentSet.new(
      'schemaVersion' => 3,
      'revision' => 1,
      'features' => features,
      'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION
    ).features
  end

  def state
    @state ||= SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 20, 'rows' => 20 },
      elevations: Array.new(400, 1.0),
      revision: 1,
      state_id: 'patch-selector-state'
    )
  end

  def changed_region
    { 'min' => { 'column' => 4, 'row' => 4 }, 'max' => { 'column' => 5, 'row' => 5 } }
  end

  def sample_window
    SU_MCP::Terrain::SampleWindow.new(
      min_column: 4,
      min_row: 4,
      max_column: 5,
      max_row: 5
    )
  end

  def window(min_column, min_row, max_column, max_row)
    { 'min' => { 'column' => min_column, 'row' => min_row },
      'max' => { 'column' => max_column, 'row' => max_row } }
  end

  def fixed_feature(id, point:, window: nil)
    feature(
      id: id,
      kind: 'fixed_control',
      strength: 'hard',
      roles: %w[control protected],
      payload: { 'control' => { 'id' => id, 'point' => { 'x' => point[0], 'y' => point[1] } } },
      window: window || self.window(point[0].to_i, point[1].to_i, point[0].to_i, point[1].to_i)
    )
  end

  def preserve_feature(id, region:, window:)
    feature(
      id: id,
      kind: 'preserve_region',
      strength: 'hard',
      roles: %w[protected boundary],
      payload: { 'region' => region },
      window: window
    )
  end

  def corridor_feature(id, start_point:, end_point:, window:)
    feature(
      id: id,
      kind: 'linear_corridor',
      strength: 'firm',
      roles: %w[centerline side_transition endpoint_cap],
      payload: {
        'startControl' => { 'point' => { 'x' => start_point[0], 'y' => start_point[1] } },
        'endControl' => { 'point' => { 'x' => end_point[0], 'y' => end_point[1] } },
        'width' => 1.0,
        'sideBlend' => { 'distance' => 1.0, 'falloff' => 'cosine' }
      },
      window: window
    )
  end

  def target_feature(id, region:, window: changed_region)
    feature(
      id: id,
      kind: 'target_region',
      strength: 'soft',
      roles: %w[support falloff],
      payload: { 'region' => region },
      window: window
    )
  end

  def survey_window_only_feature(id, window:)
    feature(
      id: id,
      kind: 'survey_control',
      strength: 'firm',
      roles: %w[support],
      payload: {},
      window: window
    )
  end

  def feature(id:, kind:, strength:, roles:, payload:, window:)
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => 'explicit_edit',
      'semanticScope' => id,
      'strengthClass' => strength,
      'roles' => roles,
      'priority' => 1,
      'payload' => payload.merge('semanticScope' => id),
      'affectedWindow' => window,
      'relevanceWindow' => window,
      'lifecycle' => { 'status' => 'active', 'updatedAtRevision' => 1 },
      'provenance' => {
        'originClass' => 'test',
        'originOperation' => kind,
        'createdAtRevision' => 1,
        'updatedAtRevision' => 1
      }
    }
  end

  def rectangle(min, max)
    {
      'type' => 'rectangle',
      'bounds' => { 'minX' => min[0], 'minY' => min[1], 'maxX' => max[0], 'maxY' => max[1] }
    }
  end

  def circle(center, radius)
    { 'type' => 'circle', 'center' => { 'x' => center[0], 'y' => center[1] }, 'radius' => radius }
  end
end
