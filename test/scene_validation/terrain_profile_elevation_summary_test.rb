# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/scene_query/sample_surface_evidence'
require_relative '../../src/su_mcp/scene_validation/terrain_profile_elevation_summary'

class TerrainProfileElevationSummaryTest < Minitest::Test
  def setup
    @summary = SU_MCP::TerrainProfileElevationSummary.new
  end

  def test_all_hit_profile_returns_complete_elevation_summary
    result = @summary.measure(
      [
        sample(0, elevation: 1.0, distance: 0.0, progress: 0.0),
        sample(1, elevation: 1.4, distance: 5.0, progress: 0.333333),
        sample(2, elevation: 1.1, distance: 10.0, progress: 0.666667),
        sample(3, elevation: 2.0, distance: 15.0, progress: 1.0)
      ]
    )

    assert_equal('measured', result.fetch(:outcome))
    assert_equal('m', result.dig(:measurement, :unit))
    assert_equal(
      {
        minElevation: 1.0,
        maxElevation: 2.0,
        elevationRange: 1.0,
        sampledLengthMeters: 15.0,
        totalSamples: 4,
        hitCount: 4,
        missCount: 0,
        ambiguousCount: 0,
        startElevation: 1.0,
        endElevation: 2.0,
        netElevationDelta: 1.0,
        totalRise: 1.3,
        totalFall: 0.3
      },
      result.dig(:measurement, :value)
    )
  end

  def test_partial_profile_keeps_stable_keys_and_omits_rise_fall
    result = @summary.measure(
      [
        sample(0, elevation: 1.0, distance: 0.0, progress: 0.0),
        sample(1, status: 'miss', distance: 5.0, progress: 0.5),
        sample(2, elevation: 2.0, distance: 10.0, progress: 1.0)
      ]
    )

    value = result.dig(:measurement, :value)
    assert_equal('measured', result.fetch(:outcome))
    assert_equal(1.0, value.fetch(:minElevation))
    assert_equal(2.0, value.fetch(:maxElevation))
    assert_equal(1.0, value.fetch(:startElevation))
    assert_equal(2.0, value.fetch(:endElevation))
    assert_equal(1.0, value.fetch(:netElevationDelta))
    assert_nil(value.fetch(:totalRise))
    assert_nil(value.fetch(:totalFall))
    assert_includes(
      result.dig(:measurement, :evidence, :omittedQuantities),
      { field: 'totalRise', reason: 'requires_all_samples_hit' }
    )
  end

  def test_endpoint_miss_omits_endpoint_and_net_delta_quantities
    result = @summary.measure(
      [
        sample(0, status: 'miss', distance: 0.0, progress: 0.0),
        sample(1, elevation: 2.0, distance: 10.0, progress: 1.0)
      ]
    )

    value = result.dig(:measurement, :value)
    assert_nil(value.fetch(:startElevation))
    assert_equal(2.0, value.fetch(:endElevation))
    assert_nil(value.fetch(:netElevationDelta))
  end

  def test_ambiguous_samples_count_but_do_not_contribute_elevations
    result = @summary.measure(
      [
        sample(0, elevation: 1.0, distance: 0.0, progress: 0.0),
        sample(1, status: 'ambiguous', distance: 5.0, progress: 0.5),
        sample(2, elevation: 3.0, distance: 10.0, progress: 1.0)
      ]
    )

    value = result.dig(:measurement, :value)
    assert_equal(3, value.fetch(:totalSamples))
    assert_equal(2, value.fetch(:hitCount))
    assert_equal(0, value.fetch(:missCount))
    assert_equal(1, value.fetch(:ambiguousCount))
    assert_equal(1.0, value.fetch(:minElevation))
    assert_equal(3.0, value.fetch(:maxElevation))
  end

  def test_zero_hit_profile_returns_unavailable
    result = @summary.measure(
      [
        sample(0, status: 'miss', distance: 0.0, progress: 0.0),
        sample(1, status: 'miss', distance: 10.0, progress: 1.0)
      ]
    )

    assert_equal('unavailable', result.fetch(:outcome))
    assert_equal('no_profile_hits', result.dig(:measurement, :reason))
  end

  def test_zero_hit_ambiguous_profile_returns_specific_unavailable_reason
    result = @summary.measure(
      [
        sample(0, status: 'ambiguous', distance: 0.0, progress: 0.0),
        sample(1, status: 'ambiguous', distance: 10.0, progress: 1.0)
      ]
    )

    assert_equal('unavailable', result.fetch(:outcome))
    assert_equal('no_unambiguous_profile_hits', result.dig(:measurement, :reason))
    assert_equal(2, result.dig(:measurement, :evidence, :summary, :ambiguousCount))
  end

  def test_evidence_samples_are_capped_but_include_last_sample
    samples = Array.new(52) do |index|
      sample(index, elevation: index.to_f, distance: index.to_f, progress: index / 51.0)
    end

    result = @summary.measure(samples)
    evidence = result.dig(:measurement, :evidence)

    assert_equal(50, evidence.fetch(:sampleLimit))
    assert_equal(true, evidence.fetch(:samplesTruncated))
    assert_equal(50, evidence.fetch(:samples).length)
    assert_equal(0, evidence.dig(:samples, 0, :index))
    assert_equal(51, evidence.dig(:samples, -1, :index))
  end

  private

  def sample(index, distance:, progress:, status: 'hit', elevation: nil)
    SU_MCP::SampleSurfaceEvidence::Sample.new(
      index: index,
      x: index.to_f,
      y: 0.0,
      z: elevation,
      distance_along_path_meters: distance,
      path_progress: progress,
      status: status
    )
  end
end
