# frozen_string_literal: true

require_relative '../../src/su_mcp/terrain/features/terrain_feature_geometry'
require_relative '../../src/su_mcp/terrain/output/terrain_output_plan'
require_relative '../../src/su_mcp/terrain/regions/sample_window'
require_relative '../../src/su_mcp/terrain/state/tiled_heightmap_state'

module PatchCdtTestSupport
  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def patch_state(columns: 9, rows: 9, id: 'patch-cdt-state')
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      patch_elevation(column, row)
    end
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: id
    )
  end

  def flat_state(columns: 9, rows: 9)
    state_with_elevations(columns: columns, rows: rows, elevations: Array.new(columns * rows, 0.0),
                          id: 'patch-cdt-flat')
  end

  def rough_state(columns: 17, rows: 17)
    elevations = Array.new(columns * rows) do |index|
      column = index % columns
      row = index / columns
      (Math.sin(column * 0.8) * 0.2) + (Math.cos(row * 0.7) * 0.15) +
        ([column, row] == [columns / 2, rows / 2] ? 1.0 : 0.0)
    end
    state_with_elevations(columns: columns, rows: rows, elevations: elevations,
                          id: 'patch-cdt-rough')
  end

  def state_with_elevations(columns:, rows:, elevations:, id:)
    SU_MCP::Terrain::TiledHeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: { 'columns' => columns, 'rows' => rows },
      elevations: elevations,
      revision: 1,
      state_id: id
    )
  end

  def patch_window(min_column: 3, min_row: 3, max_column: 5, max_row: 5)
    SU_MCP::Terrain::SampleWindow.new(
      min_column: min_column,
      min_row: min_row,
      max_column: max_column,
      max_row: max_row
    )
  end

  def dirty_output_plan(state:, window: patch_window)
    SU_MCP::Terrain::TerrainOutputPlan.dirty_window(
      state: state,
      terrain_state_summary: { digest: "#{state.state_id}-digest", revision: state.revision },
      window: window
    )
  end

  def empty_feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new
  end

  def boundary_feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      referenceSegments: [
        {
          id: 'feature-crosses-patch',
          featureId: 'corridor',
          role: 'centerline',
          strength: 'firm',
          ownerLocalStart: [2.0, 4.0],
          ownerLocalEnd: [8.0, 4.0]
        }
      ]
    )
  end

  def patch_feature_geometry
    SU_MCP::Terrain::TerrainFeatureGeometry.new(
      outputAnchorCandidates: [
        {
          id: 'inside-hard-anchor',
          featureId: 'fixed',
          role: 'control',
          strength: 'hard',
          ownerLocalPoint: [4.0, 4.0]
        },
        {
          id: 'outside-hard-anchor',
          featureId: 'fixed-outside',
          role: 'control',
          strength: 'hard',
          ownerLocalPoint: [8.0, 8.0]
        }
      ],
      referenceSegments: [
        {
          id: 'crossing-segment',
          featureId: 'segment',
          role: 'centerline',
          strength: 'firm',
          ownerLocalStart: [2.0, 4.0],
          ownerLocalEnd: [8.0, 4.0]
        }
      ]
    )
  end

  def assert_json_safe(value)
    JSON.parse(JSON.generate(value))
  end

  private

  def patch_elevation(column, row)
    (column * 0.05) + (row * 0.03) + ([column, row] == [4, 4] ? 0.75 : 0.0)
  end
end
