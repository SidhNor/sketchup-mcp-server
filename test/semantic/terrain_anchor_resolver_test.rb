# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/semantic/builder_refusal'
require_relative '../../src/su_mcp/semantic/terrain_anchor_resolver'

class TerrainAnchorResolverTest < Minitest::Test
  class FakeSurfaceSampler
    attr_reader :prepare_context_calls, :sample_z_from_context_calls

    def initialize(face_entries: [{}], sample_z: 12.5)
      @face_entries = face_entries
      @sample_z = sample_z
      @prepare_context_calls = []
      @sample_z_from_context_calls = []
    end

    def prepare_context(host_target)
      @prepare_context_calls << host_target
      { entity: host_target, face_entries: @face_entries }
    end

    def sample_z_from_context(context:, x_value:, y_value:)
      @sample_z_from_context_calls << {
        context: context,
        x_value: x_value,
        y_value: y_value
      }
      @sample_z
    end
  end

  def test_resolve_returns_single_sampled_terrain_height
    host_target = Object.new
    sampler = FakeSurfaceSampler.new(sample_z: 12.5)
    resolver = SU_MCP::Semantic::TerrainAnchorResolver.new(surface_sampler: sampler)

    result = resolver.resolve(
      host_target: host_target,
      anchor_xy: [3.25, 4.5],
      role: 'tree_base'
    )

    assert_in_delta(12.5, result, 1e-9)
    assert_equal([host_target], sampler.prepare_context_calls)
    assert_equal(1, sampler.sample_z_from_context_calls.length)
    assert_equal(3.25, sampler.sample_z_from_context_calls.first.fetch(:x_value))
    assert_equal(4.5, sampler.sample_z_from_context_calls.first.fetch(:y_value))
  end

  def test_resolve_refuses_unsampleable_host_target
    resolver = SU_MCP::Semantic::TerrainAnchorResolver.new(
      surface_sampler: FakeSurfaceSampler.new(face_entries: [])
    )

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      resolver.resolve(
        host_target: Object.new,
        anchor_xy: [3.25, 4.5],
        role: 'structure_centroid'
      )
    end

    assert_equal('invalid_hosting_target', error.code)
    assert_equal('hosting', error.details[:section])
    assert_equal('structure_centroid', error.details[:role])
  end

  def test_resolve_refuses_sample_miss
    resolver = SU_MCP::Semantic::TerrainAnchorResolver.new(
      surface_sampler: FakeSurfaceSampler.new(sample_z: nil)
    )

    error = assert_raises(SU_MCP::Semantic::BuilderRefusal) do
      resolver.resolve(host_target: Object.new, anchor_xy: [30.0, 40.0], role: 'tree_base')
    end

    assert_equal('terrain_sample_miss', error.code)
    assert_equal('hosting', error.details[:section])
    assert_equal('tree_base', error.details[:role])
    assert_equal([30.0, 40.0], error.details[:xy])
  end
end
