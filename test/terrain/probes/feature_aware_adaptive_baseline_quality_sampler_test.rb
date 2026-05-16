# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/probes/' \
                 'feature_aware_adaptive_baseline_quality_sampler'
require_relative '../../../src/su_mcp/terrain/features/feature_intent_set'
require_relative '../../../src/su_mcp/terrain/state/tiled_heightmap_state'

class FeatureAwareAdaptiveBaselineQualitySamplerTest < Minitest::Test
  def test_captures_compact_feature_local_error_summary_from_live_mesh_samples
    state = build_state(feature_intent: feature_intent_with_rectangle)
    sampler = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineQualitySampler.new(
      model: FakeModel.new(FakeOwner.new('terrain-main')),
      repository: FakeRepository.new(state),
      surface_query: PlanarSurfaceQuery.new(offset: 0.002),
      sample_budget: 16,
      clock: SteppingClock.new
    )

    result = sampler.capture(
      row: {
        'rowId' => 'target-region',
        'publicCommandPayload' => {
          'targetReference' => { 'sourceElementId' => 'terrain-main' }
        }
      },
      result: {
        output: {
          derivedMesh: {
            simplificationTolerance: 0.01
          }
        }
      },
      baseline_evidence: {}
    )

    summary = result.fetch(:summary)
    assert_quality_summary(summary)
    assert_equal(
      {
        sampleCount: 16,
        hitCount: 16,
        missCount: 0,
        maxErrorMeters: 0.002,
        meanErrorMeters: 0.002,
        p95ErrorMeters: 0.002,
        withinLocalTolerancePercent: 100.0,
        localToleranceRangeMeters: { min: 0.01, max: 0.01 }
      },
      summary.fetch(:families).fetch(:target_region)
    )
    assert_equal(0.123, result.fetch(:seconds))
  end

  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  private

  def assert_quality_summary(summary)
    assert_equal('captured', summary.fetch(:status))
    assert_equal(16, summary.fetch(:sampleCount))
    assert_equal(16, summary.fetch(:hitCount))
    assert_equal(0, summary.fetch(:missCount))
    assert_in_delta(0.002, summary.fetch(:maxErrorMeters), 1e-9)
    assert_in_delta(0.002, summary.fetch(:meanErrorMeters), 1e-9)
    assert_equal(100.0, summary.fetch(:withinLocalTolerancePercent))
    assert_equal({ min: 0.01, max: 0.01 }, summary.fetch(:localToleranceRangeMeters))
  end

  def build_state(feature_intent:)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 3, 'rows' => 3 },
      elevations: [
        0.0, 1.0, 2.0,
        1.0, 2.0, 3.0,
        2.0, 3.0, 4.0
      ],
      revision: 1,
      state_id: 'state-1',
      source_summary: { 'sourceElementId' => 'terrain-main' },
      constraint_refs: [],
      owner_transform_signature: nil,
      feature_intent: feature_intent
    )
  end

  def feature_intent_with_rectangle
    features = [
      {
        'id' => 'feature:target_region:explicit_edit:region-a:aaaaaaaaaaaa',
        'kind' => 'target_region',
        'sourceMode' => 'explicit_edit',
        'semanticScope' => 'region-a',
        'strengthClass' => 'soft',
        'roles' => ['support'],
        'priority' => 30,
        'payload' => {
          'region' => {
            'type' => 'rectangle',
            'bounds' => {
              'minX' => 0.0, 'minY' => 0.0, 'maxX' => 2.0, 'maxY' => 2.0
            }
          }
        },
        'affectedWindow' => {
          'min' => { 'column' => 0, 'row' => 0 },
          'max' => { 'column' => 2, 'row' => 2 }
        },
        'relevanceWindow' => {
          'min' => { 'column' => 0, 'row' => 0 },
          'max' => { 'column' => 2, 'row' => 2 }
        },
        'lifecycle' => {
          'status' => 'active',
          'supersededBy' => nil,
          'updatedAtRevision' => 1
        },
        'provenance' => {
          'originClass' => 'edit_terrain_surface',
          'originOperation' => 'target_height',
          'createdAtRevision' => 1,
          'updatedAtRevision' => 1
        }
      }
    ]
    {
      'schemaVersion' => 3,
      'revision' => 1,
      'effectiveRevision' => 1,
      'features' => features,
      'effectiveIndex' => SU_MCP::Terrain::FeatureIntentSet.effective_index_for(
        features,
        effective_revision: 1
      ),
      'generation' => SU_MCP::Terrain::FeatureIntentSet.default_h.fetch('generation')
    }
  end

  class FakeOwner
    def initialize(source_element_id)
      @source_element_id = source_element_id
    end

    def get_attribute(dictionary, key)
      return @source_element_id if dictionary == 'su_mcp' && key == 'sourceElementId'

      nil
    end
  end

  class FakeModel
    attr_reader :entities

    def initialize(owner)
      @entities = FakeEntities.new([owner])
    end
  end

  class FakeEntities
    def initialize(items)
      @items = items
    end

    def to_a
      @items
    end
  end

  class FakeRepository
    def initialize(state)
      @state = state
    end

    def load(_owner)
      { outcome: 'loaded', state: @state }
    end
  end

  class PlanarSurfaceQuery
    def initialize(offset:)
      @offset = offset
    end

    def execute(entities:, params:, scene_entities: nil)
      raise 'owner missing' if entities.empty? || scene_entities.empty?

      points = params.fetch('sampling').fetch('points')
      {
        success: true,
        results: points.map do |point|
          {
            status: 'hit',
            hitPoint: {
              z: point.fetch(:x) + point.fetch(:y) + @offset
            }
          }
        end
      }
    end
  end

  class SteppingClock
    def initialize
      @values = [10.0, 10.123]
    end

    def monotonic_seconds
      @values.shift
    end
  end
end
