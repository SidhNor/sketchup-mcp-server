# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/terrain_triangulation_adapter'

class TerrainTriangulationAdapterTest < Minitest::Test
  def test_native_unavailable_adapter_returns_internal_fallback_envelope_without_binary
    result = SU_MCP::Terrain::TerrainTriangulationAdapter.native_unavailable.call(request)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('native_unavailable', result.fetch(:fallbackReason))
    refute_includes(JSON.generate(result), 'LoadError')
    refute_includes(JSON.generate(result), '.so')
  end

  def test_adapter_exception_is_sanitized
    adapter = SU_MCP::Terrain::TerrainTriangulationAdapter.ruby_cdt(
      triangulator: RaisingTriangulator.new
    )

    result = adapter.call(request)

    assert_equal('fallback', result.fetch(:status))
    assert_equal('adapter_exception', result.fetch(:fallbackReason))
    refute_includes(JSON.generate(result), 'boom')
    refute_includes(JSON.generate(result), 'RaisingTriangulator')
  end

  def test_ruby_and_native_stub_adapters_share_result_shape
    ruby_result = SU_MCP::Terrain::TerrainTriangulationAdapter.ruby_cdt(
      triangulator: SuccessfulTriangulator.new
    ).call(request)
    native_result = SU_MCP::Terrain::TerrainTriangulationAdapter.native_unavailable.call(request)

    assert_equal(ruby_result.keys.sort, native_result.keys.sort)
  end

  private

  def request
    {
      points: [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]],
      segments: [],
      limits: { pointBudget: 256, faceBudget: 512 },
      limitations: []
    }
  end

  class RaisingTriangulator
    def triangulate(...)
      raise 'boom'
    end
  end

  class SuccessfulTriangulator
    def triangulate(...)
      {
        vertices: [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]],
        triangles: [[0, 1, 2]],
        limitations: []
      }
    end
  end
end
