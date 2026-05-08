# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_intent_emitter'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class TerrainFeatureIntentEmitterTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_corridor_edit_emits_centerline_side_transition_endpoint_and_control_roles
    delta = emitter.emit(state: state, request: corridor_request, diagnostics: diagnostics)
    feature = delta.fetch('upsert_features').find do |candidate|
      candidate.fetch('kind') == 'linear_corridor'
    end

    assert_includes(feature.fetch('roles'), 'centerline')
    assert_includes(feature.fetch('roles'), 'side_transition')
    assert_includes(feature.fetch('roles'), 'endpoint_cap')
    assert_includes(feature.fetch('roles'), 'control')
    assert_equal('explicit_edit', feature.fetch('sourceMode'))
    assert_equal({ 'x' => 0.0, 'y' => 0.0 }, feature.dig('payload', 'startControl', 'point'))
    refute_includes(JSON.generate(delta), 'Sketchup::')
  end

  def test_target_circle_planar_survey_fairing_preserve_and_fixed_share_vocabulary
    features = {
      target: emitted_features(target_request),
      planar: emitted_features(planar_request),
      survey: emitted_features(survey_request),
      fairing: emitted_features(fairing_request)
    }

    assert_feature_kind(features.fetch(:target), 'target_region')
    assert_feature_kind(features.fetch(:target), 'preserve_region')
    assert_feature_kind(features.fetch(:target), 'fixed_control')
    assert_feature_kind(features.fetch(:planar), 'planar_region')
    assert_feature_kind(features.fetch(:survey), 'survey_control')
    assert_feature_kind(features.fetch(:fairing), 'fairing_region')
    refute(features.fetch(:target).any? { |feature| feature.fetch('kind').include?('corridor') })
  end

  private

  def emitted_features(request)
    emitter.emit(state: state, request: request, diagnostics: diagnostics).fetch('upsert_features')
  end

  def assert_feature_kind(features, kind)
    assert(features.any? { |feature| feature.fetch('kind') == kind }, "missing #{kind}")
  end

  def emitter
    @emitter ||= SU_MCP::Terrain::TerrainFeatureIntentEmitter.new
  end

  def state
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 2.0, 'y' => 1.0 },
      dimensions: { 'columns' => 4, 'rows' => 3 },
      elevations: Array.new(12, 1.0),
      revision: 3,
      state_id: 'state-1'
    )
  end

  def diagnostics
    {
      changedRegion: { min: { column: 0, row: 0 }, max: { column: 2, row: 2 } },
      samples: []
    }
  end

  def corridor_request
    {
      'operation' => { 'mode' => 'corridor_transition' },
      'region' => {
        'type' => 'corridor',
        'startControl' => { 'point' => { 'x' => 0.0, 'y' => 0.0 }, 'elevation' => 1.0 },
        'endControl' => { 'point' => { 'x' => 4.0, 'y' => 1.0 }, 'elevation' => 2.0 },
        'width' => 1.5,
        'sideBlend' => { 'distance' => 1.0, 'falloff' => 'cosine' }
      }
    }
  end

  def target_request
    {
      'operation' => { 'mode' => 'target_height', 'targetElevation' => 2.0 },
      'region' => { 'type' => 'circle', 'center' => { 'x' => 1.0, 'y' => 1.0 }, 'radius' => 2.0 },
      'constraints' => {
        'preserveZones' => [{ 'type' => 'rectangle', 'bounds' => bounds }],
        'fixedControls' => [{ 'id' => 'fixed-1', 'point' => { 'x' => 0.0, 'y' => 0.0 } }]
      }
    }
  end

  def planar_request
    target_request.merge(
      'operation' => { 'mode' => 'planar_region_fit' },
      'constraints' => {
        'planarControls' => [
          { 'id' => 'p1', 'point' => { 'x' => 0.0, 'y' => 0.0, 'z' => 1.0 } }
        ]
      }
    )
  end

  def survey_request
    target_request.merge(
      'operation' => { 'mode' => 'survey_point_constraint', 'correctionScope' => 'local' },
      'constraints' => {
        'surveyPoints' => [
          { 'id' => 's1', 'point' => { 'x' => 1.0, 'y' => 1.0, 'z' => 2.0 } }
        ]
      }
    )
  end

  def fairing_request
    target_request.merge('operation' => { 'mode' => 'local_fairing', 'strength' => 0.5 })
  end

  def bounds
    { 'minX' => 0.0, 'minY' => 0.0, 'maxX' => 1.0, 'maxY' => 1.0 }
  end
end
