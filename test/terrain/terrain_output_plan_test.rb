# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/heightmap_state'
require_relative '../../src/su_mcp/terrain/sample_window'
require_relative '../../src/su_mcp/terrain/terrain_output_cell_window'
require_relative '../../src/su_mcp/terrain/terrain_output_plan'

class TerrainOutputPlanTest < Minitest::Test
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_full_grid_plan_uses_window_vocabulary_without_changing_public_mesh_summary
    plan = SU_MCP::Terrain::TerrainOutputPlan.full_grid(
      state: state,
      terrain_state_summary: { digest: 'digest-1' }
    )

    assert_equal(:full_grid, plan.intent)
    assert_equal(:full_grid, plan.execution_strategy)
    assert_equal(SU_MCP::Terrain::SampleWindow.full_grid(state), plan.window)
    assert_equal(
      SU_MCP::Terrain::TerrainOutputCellWindow.from_sample_window(
        window: SU_MCP::Terrain::SampleWindow.full_grid(state),
        state: state
      ),
      plan.cell_window
    )
    assert_equal(
      {
        derivedMesh: {
          meshType: 'regular_grid',
          vertexCount: 12,
          faceCount: 12,
          derivedFromStateDigest: 'digest-1'
        }
      },
      plan.to_summary
    )
  end

  def test_dirty_window_plan_records_internal_intent_without_changing_public_mesh_summary
    window = SU_MCP::Terrain::SampleWindow.new(
      min_column: 1,
      min_row: 0,
      max_column: 2,
      max_row: 1
    )

    plan = SU_MCP::Terrain::TerrainOutputPlan.dirty_window(
      state: state,
      terrain_state_summary: { digest: 'digest-2' },
      window: window
    )

    assert_equal(:dirty_window, plan.intent)
    assert_equal(:full_grid, plan.execution_strategy)
    assert_equal(window, plan.window)
    assert_equal(
      SU_MCP::Terrain::TerrainOutputCellWindow.from_sample_window(window: window, state: state),
      plan.cell_window
    )
    assert_equal(expected_summary('digest-2'), plan.to_summary)
    refute_includes(JSON.generate(plan.to_summary), 'dirtyWindow')
    refute_includes(JSON.generate(plan.to_summary), 'sampleWindow')
  end

  def test_dirty_window_plan_rejects_empty_windows_as_internal_invalid_plan
    error = assert_raises(ArgumentError) do
      SU_MCP::Terrain::TerrainOutputPlan.dirty_window(
        state: state,
        terrain_state_summary: { digest: 'digest-2' },
        window: SU_MCP::Terrain::SampleWindow.new(empty: true)
      )
    end

    assert_match(/dirty window/i, error.message)
  end

  private

  def expected_summary(digest)
    {
      derivedMesh: {
        meshType: 'regular_grid',
        vertexCount: 12,
        faceCount: 12,
        derivedFromStateDigest: digest
      }
    }
  end

  def state
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => 4, 'rows' => 3 },
      elevations: Array.new(12, 1.0),
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end
end
