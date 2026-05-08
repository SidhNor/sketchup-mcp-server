# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/output/cdt/terrain_triangulation_adapter'

class TerrainTriangulationAdapterTest < Minitest::Test
  def test_native_unavailable_adapter_raises_typed_low_level_error_without_binary_detail
    error = assert_raises(SU_MCP::Terrain::TerrainTriangulationAdapter::Unavailable) do
      SU_MCP::Terrain::TerrainTriangulationAdapter.native_unavailable.triangulate(
        points: request.fetch(:points),
        constraints: request.fetch(:segments)
      )
    end

    assert_equal('native_unavailable', error.category)
    refute_includes(error.message, 'LoadError')
    refute_includes(error.message, '.so')
  end

  def test_triangulator_exception_bubbles_to_backend_for_sanitized_fallback
    adapter = SU_MCP::Terrain::TerrainTriangulationAdapter.ruby_cdt(
      triangulator: RaisingTriangulator.new
    )

    assert_raises(RuntimeError) do
      adapter.triangulate(points: request.fetch(:points), constraints: request.fetch(:segments))
    end
  end

  def test_ruby_adapter_returns_raw_triangulation_result
    triangulator = SuccessfulTriangulator.new
    result = SU_MCP::Terrain::TerrainTriangulationAdapter.ruby_cdt(
      triangulator: triangulator
    ).triangulate(points: request.fetch(:points), constraints: request.fetch(:segments))

    assert_equal(
      %i[
        constrainedEdgeCoverage
        constrainedEdges
        delaunayViolationCount
        limitations
        triangles
        vertices
      ],
      result.keys.sort
    )
    assert_equal([[0, 1, 2]], result.fetch(:triangles))
    assert_equal(
      { points: request.fetch(:points), constraints: request.fetch(:segments) },
      triangulator.last_call
    )
    refute_includes(result.keys, :status)
    refute_includes(result.keys, :fallbackReason)
  end

  def test_call_alias_uses_low_level_keyword_contract
    result = SU_MCP::Terrain::TerrainTriangulationAdapter.ruby_cdt(
      triangulator: SuccessfulTriangulator.new
    ).call(points: request.fetch(:points), constraints: request.fetch(:segments))

    assert_equal([[0, 1, 2]], result.fetch(:triangles))
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
    attr_reader :last_call

    def triangulate(points:, constraints:)
      @last_call = { points: points, constraints: constraints }
      {
        vertices: [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]],
        triangles: [[0, 1, 2]],
        constrainedEdges: [],
        constrainedEdgeCoverage: 1.0,
        delaunayViolationCount: 0,
        limitations: []
      }
    end
  end
end
