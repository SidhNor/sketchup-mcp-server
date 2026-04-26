# frozen_string_literal: true

module TerrainOutputPlanningDiagnostics
  def private_output_planning_diagnostics
    {
      sampleWindow: { min: { column: 0, row: 0 }, max: { column: 1, row: 1 } },
      outputPlan: { intent: 'dirty_window' },
      dirtyWindow: { min: { column: 0, row: 0 }, max: { column: 1, row: 1 } },
      outputRegions: [{ kind: 'dirty_window' }],
      chunks: [{ id: 'chunk-1' }],
      tiles: [{ id: 'tile-1' }]
    }
  end
end
