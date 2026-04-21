# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/path_drape_builder'

# rubocop:disable Metrics/ClassLength
class PathDrapeBuilderTest < Minitest::Test
  include SemanticTestSupport

  METERS_TO_INTERNAL = SU_MCP::Semantic::LengthConverter::METERS_TO_INTERNAL

  class FakeSurfaceSampler
    attr_reader :prepare_context_calls, :sampleable_face_entry_calls, :sample_z_from_context_calls

    def initialize(sampleable: true, &sample_block)
      @sampleable = sampleable
      @sample_block = sample_block
      @prepare_context_calls = 0
      @sampleable_face_entry_calls = 0
      @sample_z_from_context_calls = 0
    end

    def sampleable_face_entries_for(_entity)
      @sampleable_face_entry_calls += 1
      @sampleable ? [{}] : []
    end

    def prepare_context(entity)
      @prepare_context_calls += 1
      { entity: entity, face_entries: sampleable_face_entries_for(entity) }
    end

    def sample_z(entity:, **kwargs)
      @sample_block.call(
        entity: entity,
        x_value: kwargs.fetch(:x_value),
        y_value: kwargs.fetch(:y_value)
      )
    end

    def sample_z_from_context(context:, **kwargs)
      @sample_z_from_context_calls += 1
      sample_z(
        entity: context.fetch(:entity),
        x_value: kwargs.fetch(:x_value),
        y_value: kwargs.fetch(:y_value)
      )
    end
  end

  def setup
    @model = build_semantic_model
    @group = @model.active_entities.add_group
    @host_target = Object.new
  end

  def test_preserves_caller_vertices_without_decimating_dense_centerline_points
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: constant_sampler(1.0),
      station_spacing: 1.0,
      clearance: 0.2
    )

    builder.build(
      group: @group,
      host_target: @host_target,
      payload: {
        'centerline' => [[0.0, 0.0], [0.2, 0.0], [0.4, 0.0]],
        'width' => 2.0
      }
    )

    top_points = @group.entities.faces.flat_map(&:points).uniq

    assert_includes(top_points, [0.0, 1.0, 1.2])
    assert_includes(top_points, [0.2, 1.0, 1.2])
    assert_includes(top_points, [0.4, 1.0, 1.2])
  end

  def test_reclamps_smoothed_profile_to_local_raw_peak
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: FakeSurfaceSampler.new do |**kwargs|
        if within_delta?(kwargs[:x_value], 5.0)
          5.0
        else
          1.0
        end
      end,
      station_spacing: 5.0,
      clearance: 0.2
    )

    builder.build(
      group: @group,
      host_target: @host_target,
      payload: {
        'centerline' => [[0.0, 0.0], [10.0, 0.0]],
        'width' => 2.0
      }
    )

    top_points = @group.entities.faces.flat_map(&:points).uniq

    assert_includes(top_points, [0.0, 1.0, 1.2])
    assert_includes(top_points, [5.0, 1.0, 5.2])
    assert_includes(top_points, [10.0, 1.0, 1.2])
  end

  def test_smooths_non_peak_interior_station_profile
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: FakeSurfaceSampler.new do |**kwargs|
        within_delta?(kwargs[:x_value], 10.0) ? 5.0 : 1.0
      end,
      station_spacing: 5.0,
      clearance: 0.2
    )

    builder.build(
      group: @group,
      host_target: @host_target,
      payload: {
        'centerline' => [[0.0, 0.0], [10.0, 0.0], [20.0, 0.0]],
        'width' => 2.0
      }
    )

    top_points = @group.entities.faces.flat_map(&:points).uniq

    assert_includes(top_points, [5.0, 1.0, 2.533333333333333])
    assert_includes(top_points, [15.0, 1.0, 2.5333333333333337])
  end

  def test_keeps_endpoints_raw_when_smoothing
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: FakeSurfaceSampler.new do |**kwargs|
        kwargs[:x_value].zero? ? 3.0 : 1.0
      end,
      station_spacing: 5.0,
      clearance: 0.2
    )

    builder.build(
      group: @group,
      host_target: @host_target,
      payload: {
        'centerline' => [[0.0, 0.0], [10.0, 0.0]],
        'width' => 2.0
      }
    )

    top_points = @group.entities.faces.flat_map(&:points).uniq

    assert_includes(top_points, [0.0, 1.0, 3.2])
    assert_includes(top_points, [10.0, 1.0, 1.2])
  end

  def test_refuses_unsampleable_host_target
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: FakeSurfaceSampler.new(sampleable: false)
    )

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      builder.build(
        group: @group,
        host_target: @host_target,
        payload: {
          'centerline' => [[0.0, 0.0], [1.0, 0.0]],
          'width' => 2.0
        }
      )
    end

    assert_equal('invalid_hosting_target', error.code)
    assert_equal('hosting', error.details[:section])
  end

  def test_refuses_when_station_limit_would_be_exceeded
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: constant_sampler(1.0),
      station_spacing: 1.0,
      clearance: 0.2,
      station_limit: 3
    )

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      builder.build(
        group: @group,
        host_target: @host_target,
        payload: {
          'centerline' => [[0.0, 0.0], [10.0, 0.0]],
          'width' => 2.0
        }
      )
    end

    assert_equal('path_tessellation_limit_exceeded', error.code)
  end

  def test_applies_thickness_downward_without_raising_the_top_surface
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: constant_sampler(1.0),
      station_spacing: 100.0,
      clearance: 0.2
    )

    builder.build(
      group: @group,
      host_target: @host_target,
      payload: {
        'centerline' => [[0.0, 0.0], [10.0, 0.0]],
        'width' => 2.0,
        'thickness' => 0.5
      }
    )

    assert_thickness_shell_geometry
  end

  def test_exact_one_meter_multiple_segment_length_does_not_duplicate_terminal_station
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: constant_sampler(0.0)
    )

    builder.build(
      group: @group,
      host_target: @host_target,
      payload: {
        'centerline' => [
          [102.0 * METERS_TO_INTERNAL, 10.0 * METERS_TO_INTERNAL],
          [118.0 * METERS_TO_INTERNAL, 10.0 * METERS_TO_INTERNAL]
        ],
        'width' => 2.0 * METERS_TO_INTERNAL
      }
    )

    refute_empty(@group.entities.faces)

    endpoint_points = @group.entities.faces.flat_map(&:points).select do |point|
      within_delta?(point[0], 118.0 * METERS_TO_INTERNAL)
    end

    assert_equal(2, endpoint_points.uniq.length)
  end

  def test_prepares_host_sampling_context_once_per_build
    sampler = FakeSurfaceSampler.new do |**_kwargs|
      1.0
    end
    builder = SU_MCP::Semantic::PathDrapeBuilder.new(
      surface_sampler: sampler,
      station_spacing: 5.0,
      clearance: 0.2
    )

    builder.build(
      group: @group,
      host_target: @host_target,
      payload: {
        'centerline' => [[0.0, 0.0], [20.0, 0.0]],
        'width' => 2.0
      }
    )

    assert_equal(1, sampler.prepare_context_calls)
    assert_operator(sampler.sample_z_from_context_calls, :>, 1)
  end

  private

  def constant_sampler(sampled_z)
    FakeSurfaceSampler.new do |**_kwargs|
      sampled_z
    end
  end

  def within_delta?(value, target, delta = 1e-6)
    (value - target).abs <= delta
  end

  def assert_shell_points(top_points, bottom_points)
    assert_includes(top_points, [0.0, 1.0, 1.2])
    assert_includes(top_points, [10.0, 1.0, 1.2])
    assert_includes(bottom_points, [0.0, 1.0, 0.7])
    assert_includes(bottom_points, [10.0, 1.0, 0.7])
  end

  def assert_thickness_shell_geometry
    all_points = @group.entities.faces.flat_map(&:points).uniq
    top_points = all_points.select { |point| within_delta?(point[2], 1.2) }
    bottom_points = all_points.select { |point| within_delta?(point[2], 0.7) }
    pushpull_calls = @group.entities.faces.flat_map(&:pushpull_calls)

    assert_shell_points(top_points, bottom_points)
    assert_empty(pushpull_calls)
    assert_equal(12, @group.entities.faces.length)
    assert_equal(1, @group.entities.build_calls)
  end
end

# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
