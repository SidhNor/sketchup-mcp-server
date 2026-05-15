# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/scene_query_test_support'
require_relative '../../../src/su_mcp/terrain/adoption/terrain_surface_adoption_sampler'

class TerrainSurfaceAdoptionSamplerTest < Minitest::Test
  def test_derives_adaptive_dimensions_for_representative_source_extent
    dimensions = SU_MCP::Terrain::TerrainSurfaceAdoptionSampler.new.derive_dimensions(
      width: 40.0,
      depth: 70.0
    )

    assert_equal(147, dimensions.fetch(:columns))
    assert_equal(
      SU_MCP::Terrain::CreateTerrainSurfaceRequest::MAX_TERRAIN_ROWS,
      dimensions.fetch(:rows)
    )
    assert_operator(
      dimensions.fetch(:columns) * dimensions.fetch(:rows),
      :<=,
      SU_MCP::Terrain::CreateTerrainSurfaceRequest::MAX_TERRAIN_SAMPLES
    )
  end

  def test_refuses_zero_extent_sources
    result = SU_MCP::Terrain::TerrainSurfaceAdoptionSampler.new.derive_dimensions(
      width: 0.0,
      depth: 70.0
    )

    assert_refusal(result, 'source_not_sampleable', 'source.bounds')
  end

  def test_refuses_incomplete_or_ambiguous_sampling_without_partial_state
    sampler = SU_MCP::Terrain::TerrainSurfaceAdoptionSampler.new(
      sample_query: IncompleteSampleQuery.new,
      profile_evidence_mode: true
    )

    result = sampler.derive('sourceElementId' => 'terrain-source')

    assert_refusal(result, 'source_sampling_incomplete', 'lifecycle.target')
    assert_equal(2, result.dig(:refusal, :details, :sampleCount))
    assert_equal(1, result.dig(:refusal, :details, :hitCount))
    assert_equal(1, result.dig(:refusal, :details, :missCount))
    assert_equal([{ index: 1, status: 'miss', samplePoint: { x: 1.0, y: 0.0 } }],
                 result.dig(:refusal, :details, :firstMisses))
  end

  def test_converts_source_bounds_to_public_meters_before_sampling
    sample_query = CompleteGridSampleQuery.new
    sampler = SU_MCP::Terrain::TerrainSurfaceAdoptionSampler.new(
      sample_query: sample_query,
      target_resolver: ResolvingTargetResolver.new(source_with_internal_bounds),
      adapter: RecordingAdapter.new,
      length_converter: ScalingLengthConverter.new(multiplier: 10.0)
    )

    result = sampler.derive('sourceElementId' => 'terrain-source')

    assert_equal('sampled', result.fetch(:outcome))
    points = sample_query.points
    assert_equal({ 'x' => 1.0, 'y' => 2.0 }, points.first)
    assert_equal({ 'x' => 5.0, 'y' => 8.0 }, points.last)
    assert_equal({ width: 4.0, depth: 6.0 },
                 result.fetch(:sampling_summary).fetch(:extent))
    assert_equal(points.length, result.fetch(:sampling_summary).fetch(:sampleCount))
  end

  def test_incomplete_grid_sampling_refusal_includes_public_diagnostics
    sample_query = IncompleteGridSampleQuery.new
    sampler = SU_MCP::Terrain::TerrainSurfaceAdoptionSampler.new(
      sample_query: sample_query,
      target_resolver: ResolvingTargetResolver.new(source_with_internal_bounds),
      adapter: RecordingAdapter.new,
      length_converter: ScalingLengthConverter.new(multiplier: 10.0)
    )

    result = sampler.derive('sourceElementId' => 'terrain-source')

    assert_refusal(result, 'source_sampling_incomplete', 'lifecycle.target')
    assert_incomplete_grid_details(result.fetch(:refusal).fetch(:details), sample_query.points)
  end

  class IncompleteSampleQuery
    def profile_evidence(...)
      {
        success: true,
        evidence: [
          Struct.new(:status, :x, :y, :z).new('hit', 0.0, 0.0, 1.0),
          Struct.new(:status, :x, :y, :z).new('miss', 1.0, 0.0, nil)
        ]
      }
    end
  end

  class CompleteGridSampleQuery
    attr_reader :points

    def execute(entities:, entity_entries:, scene_entities:, params:)
      @entities = entities
      @entity_entries = entity_entries
      @scene_entities = scene_entities
      @points = params.fetch('sampling').fetch('points')
      {
        success: true,
        results: @points.map do |point|
          { samplePoint: point, status: 'hit', hitPoint: point.merge(z: 7.0) }
        end
      }
    end
  end

  class IncompleteGridSampleQuery < CompleteGridSampleQuery
    def execute(**keywords)
      result = super
      result.fetch(:results)[0] = {
        samplePoint: @points.first,
        status: 'miss'
      }
      result
    end
  end

  class ResolvingTargetResolver
    def initialize(source)
      @source = source
    end

    def resolve(_target_reference)
      { resolution: 'unique', entity: @source }
    end
  end

  class RecordingAdapter
    def all_entities_recursive
      []
    end

    def all_entity_paths_recursive
      []
    end

    def queryable_entities
      []
    end
  end

  class ScalingLengthConverter
    def initialize(multiplier:)
      @multiplier = multiplier
    end

    def internal_to_public_meters(value)
      value.to_f / @multiplier
    end
  end

  def source_with_internal_bounds
    Struct.new(:bounds).new(
      SceneQueryTestSupport::FakeBounds.new(
        min: SceneQueryTestSupport::FakePoint.new(10.0, 20.0, 0.0),
        max: SceneQueryTestSupport::FakePoint.new(50.0, 80.0, 30.0),
        center: SceneQueryTestSupport::FakePoint.new(30.0, 50.0, 15.0),
        size: [40.0, 60.0, 30.0]
      )
    )
  end

  private

  def assert_refusal(result, code, field)
    assert_equal(true, result.fetch(:success))
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
    assert_equal(field, result.dig(:refusal, :details, :field))
  end

  def assert_incomplete_grid_details(details, points)
    assert_equal(points.length, details.fetch(:sampleCount))
    assert_equal(points.length - 1, details.fetch(:hitCount))
    assert_equal(1, details.fetch(:missCount))
    assert_equal({ width: 4.0, depth: 6.0 }, details.fetch(:extent))
    assert_equal({ 'x' => 1.0, 'y' => 2.0 }, details.fetch(:firstMisses).first.fetch(:samplePoint))
  end
end
