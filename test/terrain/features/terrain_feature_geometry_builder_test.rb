# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/features/terrain_feature_geometry_builder'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class TerrainFeatureGeometryBuilderTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_derives_hard_preserve_region_and_fixed_control_primitives
    geometry = builder.build(state: state_with_features([
                                                          preserve_feature('preserve-1'),
                                                          fixed_feature('fixed-1')
                                                        ]))

    assert_equal('rectangle', geometry.protected_regions.first.fetch('primitive'))
    assert_equal('hard', geometry.output_anchor_candidates.first.fetch('strength'))
    assert_equal([2.0, 2.0], geometry.output_anchor_candidates.first.fetch('ownerLocalPoint'))
    assert_equal([2, 2], geometry.output_anchor_candidates.first.fetch('gridPoint'))
  end

  def test_derives_corridor_firm_centerline_side_band_endpoint_cap_and_reference_segments
    geometry = builder.build(state: state_with_features([corridor_feature('corridor-1')]))

    assert_equal(%w[centerline endpoint_cap side_transition],
                 geometry.reference_segments.map { |segment| segment.fetch('role') }.uniq.sort)
    corridor = geometry.pressure_regions.find { |region| region.fetch('primitive') == 'corridor' }
    assert_equal('firm', corridor.fetch('strength'))
    assert_equal([[0.0, 2.0], [6.0, 2.0]], corridor.dig('ownerLocalShape', 'centerline'))
  end

  def test_derives_survey_planar_target_fairing_and_inferred_pressure_strengths
    geometry = builder.build(state: state_with_features([
                                                          survey_feature('survey-1'),
                                                          planar_feature('planar-1'),
                                                          target_feature('target-1'),
                                                          fairing_feature('fairing-1'),
                                                          inferred_feature('inferred-1')
                                                        ]))
    strengths_by_role = geometry.pressure_regions.to_h do |region|
      [region.fetch('role'), region.fetch('strength')]
    end

    assert_equal('firm', strengths_by_role.fetch('survey_anchor'))
    assert_equal('firm', strengths_by_role.fetch('planar_support'))
    assert_equal('soft', strengths_by_role.fetch('target_support'))
    assert_equal('soft', strengths_by_role.fetch('fairing_support'))
    assert_equal('soft', strengths_by_role.fetch('hard_break'))
  end

  def test_derives_exact_geometry_for_all_geometry_producing_intents
    geometry = all_geometry_intent_geometry

    assert_exact_geometry_collection_counts(geometry)
    assert_exact_hard_and_firm_anchor_geometry(geometry)
    assert_exact_region_pressure_geometry(geometry)
    assert_exact_corridor_reference_geometry(geometry)
  end

  def test_hard_derivation_failure_sets_feature_geometry_failed
    feature = preserve_feature('broken-preserve', region: { 'type' => 'polygon' })
    geometry = builder.build(state: state_with_features([feature]))

    assert_equal('feature_geometry_failed', geometry.failure_category)
    assert_includes(JSON.generate(geometry.limitations), 'broken-preserve')
  end

  def test_firm_and_soft_derivation_gaps_continue_with_limitations
    feature = corridor_feature('weak-corridor', width: nil, side_blend: nil)
    geometry = builder.build(state: state_with_features([feature]))

    assert_equal('none', geometry.failure_category)
    assert_includes(JSON.generate(geometry.limitations), 'weak-corridor')
    assert(geometry.reference_segments.any? { |segment| segment.fetch('role') == 'centerline' })
  end

  private

  def builder
    @builder ||= SU_MCP::Terrain::TerrainFeatureGeometryBuilder.new
  end

  def all_geometry_intent_geometry
    builder.build(state: state_with_features([
                                               preserve_feature('preserve-1'),
                                               fixed_feature('fixed-1'),
                                               corridor_feature('corridor-1'),
                                               survey_feature('survey-1'),
                                               planar_feature('planar-1'),
                                               target_feature('target-1'),
                                               fairing_feature('fairing-1'),
                                               inferred_feature('inferred-1')
                                             ]))
  end

  def assert_exact_geometry_collection_counts(geometry)
    assert_empty(geometry.limitations)
    assert_equal('none', geometry.failure_category)
    assert_equal(2, geometry.output_anchor_candidates.length)
    assert_equal(1, geometry.protected_regions.length)
    assert_equal(7, geometry.pressure_regions.length)
    assert_equal(5, geometry.reference_segments.length)
    assert_equal(8, geometry.affected_windows.length)
  end

  def assert_exact_hard_and_firm_anchor_geometry(geometry)
    assert_equal(
      [['preserve-1:protected', 'rectangle', [[1.0, 1.0], [4.0, 4.0]]]],
      geometry.protected_regions.map do |region|
        [region.fetch('id'), region.fetch('primitive'), region.fetch('ownerLocalBounds')]
      end
    )
    assert_includes(anchor_payloads(geometry), ['fixed-1', 'control', 'hard', [2.0, 2.0], [2, 2]])
    assert_includes(anchor_payloads(geometry),
                    ['survey-1', 'survey_anchor', 'firm', [3.0, 3.0], [3, 3]])
  end

  def anchor_payloads(geometry)
    geometry.output_anchor_candidates.map do |anchor|
      [anchor.fetch('id'), anchor.fetch('role'), anchor.fetch('strength'),
       anchor.fetch('ownerLocalPoint'), anchor.fetch('gridPoint', nil)]
    end
  end

  def assert_exact_region_pressure_geometry(geometry)
    pressures_by_role = geometry.pressure_regions.to_h do |region|
      [region.fetch('role'), [region.fetch('strength'), region.fetch('primitive')]]
    end
    assert_equal(%w[firm rectangle], pressures_by_role.fetch('protected_boundary'))
    assert_equal(%w[firm circle], pressures_by_role.fetch('survey_anchor'))
    assert_equal(%w[firm rectangle], pressures_by_role.fetch('planar_support'))
    assert_equal(%w[soft circle], pressures_by_role.fetch('target_support'))
    assert_equal(%w[soft rectangle], pressures_by_role.fetch('fairing_support'))
    assert_equal(%w[soft rectangle], pressures_by_role.fetch('hard_break'))
  end

  def assert_exact_corridor_reference_geometry(geometry)
    corridor_pressure = geometry.pressure_regions.find do |region|
      region.fetch('id') == 'corridor-1:corridor_pressure'
    end
    assert_equal('corridor', corridor_pressure.fetch('primitive'))
    assert_equal([[0.0, 2.0], [6.0, 2.0]], corridor_pressure.dig('ownerLocalShape', 'centerline'))
    assert_equal(2.0, corridor_pressure.dig('ownerLocalShape', 'width'))
    assert_equal(1.0, corridor_pressure.dig('ownerLocalShape', 'blendDistance'))

    roles = geometry.reference_segments.map { |segment| segment.fetch('role') }
    assert_equal(1, roles.count('centerline'))
    assert_equal(2, roles.count('side_transition'))
    assert_equal(2, roles.count('endpoint_cap'))
  end

  def state_with_features(features)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 8, 'rows' => 6 },
      elevations: Array.new(48, 1.0),
      revision: 1,
      state_id: 'mta23-state',
      feature_intent: {
        'schemaVersion' => 3,
        'revision' => 1,
        'generation' => SU_MCP::Terrain::FeatureIntentSet::DEFAULT_GENERATION,
        'features' => features
      }
    )
  end

  def feature(id:, kind:, roles:, payload:, affected_window: default_affected_window)
    {
      'id' => id,
      'kind' => kind,
      'sourceMode' => kind == 'inferred_heightfield' ? 'inferred_heightfield' : 'explicit_edit',
      'roles' => roles,
      'priority' => 1,
      'payload' => payload,
      'affectedWindow' => affected_window,
      'provenance' => { 'originClass' => 'test', 'originOperation' => kind,
                        'createdAtRevision' => 1, 'updatedAtRevision' => 1 }
    }
  end

  def preserve_feature(id, region: { 'type' => 'rectangle', 'bounds' => bounds })
    feature(id: id, kind: 'preserve_region', roles: %w[protected boundary],
            payload: { 'region' => region })
  end

  def fixed_feature(id)
    feature(id: id, kind: 'fixed_control', roles: %w[control protected],
            payload: { 'control' => { 'id' => id, 'point' => { 'x' => 2.0, 'y' => 2.0 },
                                      'tolerance' => 0.05 } })
  end

  def corridor_feature(id, width: 2.0, side_blend: { 'distance' => 1.0, 'falloff' => 'cosine' })
    payload = {
      'startControl' => { 'point' => { 'x' => 0.0, 'y' => 2.0 }, 'elevation' => 1.0 },
      'endControl' => { 'point' => { 'x' => 6.0, 'y' => 2.0 }, 'elevation' => 2.0 }
    }
    payload['width'] = width if width
    payload['sideBlend'] = side_blend if side_blend
    feature(id: id, kind: 'linear_corridor',
            roles: %w[centerline side_transition endpoint_cap control], payload: payload)
  end

  def survey_feature(id)
    support_region = {
      'type' => 'circle',
      'center' => { 'x' => 3.0, 'y' => 3.0 },
      'radius' => 1.5
    }
    feature(id: id, kind: 'survey_control', roles: %w[control support],
            payload: { 'control' => { 'id' => id, 'point' => { 'x' => 3.0, 'y' => 3.0 } },
                       'supportRegion' => support_region })
  end

  def planar_feature(id)
    feature(id: id, kind: 'planar_region', roles: %w[support boundary],
            payload: { 'region' => { 'type' => 'rectangle', 'bounds' => bounds } })
  end

  def target_feature(id)
    region = {
      'type' => 'circle',
      'center' => { 'x' => 3.0, 'y' => 3.0 },
      'radius' => 2.0
    }
    feature(id: id, kind: 'target_region', roles: %w[support falloff],
            payload: { 'region' => region })
  end

  def fairing_feature(id)
    feature(id: id, kind: 'fairing_region', roles: %w[support],
            payload: { 'region' => { 'type' => 'rectangle', 'bounds' => bounds } })
  end

  def inferred_feature(id)
    feature(id: id, kind: 'inferred_heightfield', roles: %w[hard_break soft_transition],
            payload: { 'region' => { 'type' => 'rectangle', 'bounds' => bounds } })
  end

  def default_affected_window
    { 'min' => { 'column' => 0, 'row' => 0 }, 'max' => { 'column' => 6, 'row' => 4 } }
  end

  def bounds
    { 'minX' => 1.0, 'minY' => 1.0, 'maxX' => 4.0, 'maxY' => 4.0 }
  end
end
