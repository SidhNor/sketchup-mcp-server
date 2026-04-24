# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/scene_query/sample_surface_profile_generator'

class SampleSurfaceProfileGeneratorTest < Minitest::Test
  def setup
    @generator = SU_MCP::SampleSurfaceProfileGenerator.new
  end

  def test_generates_even_count_samples_including_start_and_end
    samples = @generator.generate(
      path: [{ x: 0.0, y: 0.0 }, { x: 10.0, y: 0.0 }],
      sample_count: 3
    )

    assert_equal(
      [
        { index: 0, x: 0.0, y: 0.0, distance_along_path_meters: 0.0, path_progress: 0.0 },
        { index: 1, x: 5.0, y: 0.0, distance_along_path_meters: 5.0, path_progress: 0.5 },
        { index: 2, x: 10.0, y: 0.0, distance_along_path_meters: 10.0, path_progress: 1.0 }
      ],
      samples
    )
  end

  def test_generates_interval_samples_and_appends_endpoint_without_duplicate
    samples = @generator.generate(
      path: [{ x: 0.0, y: 0.0 }, { x: 10.0, y: 0.0 }],
      interval_meters: 4.0
    )

    assert_equal(
      [
        { index: 0, x: 0.0, y: 0.0, distance_along_path_meters: 0.0, path_progress: 0.0 },
        { index: 1, x: 4.0, y: 0.0, distance_along_path_meters: 4.0, path_progress: 0.4 },
        { index: 2, x: 8.0, y: 0.0, distance_along_path_meters: 8.0, path_progress: 0.8 },
        { index: 3, x: 10.0, y: 0.0, distance_along_path_meters: 10.0, path_progress: 1.0 }
      ],
      samples
    )
  end

  def test_interpolates_across_multi_segment_paths
    samples = @generator.generate(
      path: [{ x: 0.0, y: 0.0 }, { x: 0.0, y: 3.0 }, { x: 4.0, y: 3.0 }],
      sample_count: 3
    )

    assert_equal(
      [
        { index: 0, x: 0.0, y: 0.0, distance_along_path_meters: 0.0, path_progress: 0.0 },
        { index: 1, x: 0.5, y: 3.0, distance_along_path_meters: 3.5, path_progress: 0.5 },
        { index: 2, x: 4.0, y: 3.0, distance_along_path_meters: 7.0, path_progress: 1.0 }
      ],
      samples
    )
  end

  def test_ignores_zero_length_internal_segments
    samples = @generator.generate(
      path: [{ x: 0.0, y: 0.0 }, { x: 0.0, y: 0.0 }, { x: 10.0, y: 0.0 }],
      sample_count: 2
    )

    assert_equal(
      [
        { index: 0, x: 0.0, y: 0.0, distance_along_path_meters: 0.0, path_progress: 0.0 },
        { index: 1, x: 10.0, y: 0.0, distance_along_path_meters: 10.0, path_progress: 1.0 }
      ],
      samples
    )
  end

  def test_refuses_all_zero_length_paths
    error = assert_raises(RuntimeError) do
      @generator.generate(
        path: [{ x: 1.0, y: 1.0 }, { x: 1.0, y: 1.0 }],
        sample_count: 2
      )
    end

    assert_equal('Profile path must contain at least two distinct XY positions', error.message)
  end

  def test_refuses_generated_sample_count_above_cap_with_counts
    generator = SU_MCP::SampleSurfaceProfileGenerator.new(sample_cap: 3)

    error = assert_raises(SU_MCP::SampleSurfaceProfileGenerator::SampleCapExceeded) do
      generator.generate(
        path: [{ x: 0.0, y: 0.0 }, { x: 10.0, y: 0.0 }],
        sample_count: 4
      )
    end

    assert_equal(4, error.generated_count)
    assert_equal(3, error.allowed_cap)
  end
end
