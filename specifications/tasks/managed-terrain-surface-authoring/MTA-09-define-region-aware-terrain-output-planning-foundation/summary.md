# MTA-09 Implementation Summary

**Status**: completed  
**Task**: `MTA-09 Define Region-Aware Terrain Output Planning Foundation`  
**Captured**: 2026-04-26

## Implemented

- Extended `SU_MCP::Terrain::TerrainOutputPlan` with internal `intent`, `execution_strategy`, and dirty-window construction.
- Added `TerrainOutputPlan.dirty_window(state:, terrain_state_summary:, window:)`, rejecting empty dirty windows as internal invalid-plan input.
- Preserved the public `output.derivedMesh` summary shape for both full-grid and dirty-window plans.
- Threaded optional `output_plan:` through `TerrainMeshGenerator#generate` and `#regenerate`.
- Kept production terrain output execution as full-grid regeneration; dirty-window intent affects internal planning and returned summary linkage only.
- Updated `TerrainSurfaceCommands` so successful terrain edits derive an internal dirty-window plan from existing `changedRegion` diagnostics and pass it to regeneration.
- Preserved edit-kernel ownership: bounded grade and corridor transition kernels remain SketchUp-free and do not mutate SketchUp entities.
- Added no-leak coverage for private planning diagnostics including `sampleWindow`, `outputPlan`, `dirtyWindow`, `outputRegions`, `chunks`, and `tiles`.
- Added a shared test helper for private output-planning diagnostics used by evidence and contract tests.
- Clarified the existing public `operation.regeneration: "full"` recap as distinct from forbidden `output.*` planning/strategy vocabulary.

## Public Contract

No public MCP request fields, response fields, loader schema entries, dispatcher routes, or user-facing tool options were added.

Public output remains:

- `output.derivedMesh.meshType`
- `output.derivedMesh.vertexCount`
- `output.derivedMesh.faceCount`
- `output.derivedMesh.derivedFromStateDigest`

Persisted terrain state remains `heightmap_grid` schema version `1`. Internal output planning terms are not persisted and do not appear in public MCP responses.

## Validation

Local automated validation:

- Focused MTA-09 terrain suite: `40 runs, 279 assertions, 0 failures, 0 errors, 0 skips`.
- Full terrain suite: `117 runs, 1101 assertions, 0 failures, 0 errors, 2 skips`.
- Full Ruby suite: `699 runs, 3255 assertions, 0 failures, 0 errors, 35 skips`.
- RuboCop: `186 files inspected, no offenses detected`.
- Package verification: `bundle exec rake package:verify` produced `dist/su_mcp-0.22.0.rbz`.
- `git diff --check`: passed.

Code review:

- `mcp__pal__.codereview` with `grok-4.20` completed.
- Required planning-review findings were incorporated into the test queue before implementation.
- Final review found no critical or high issues.
- Follow-up maintainability items were addressed with comments, shared no-leak test diagnostics, and explicit tests around the `operation.regeneration` versus `output.*` vocabulary distinction.

Hosted SketchUp validation:

- User deployed the initial functional implementation once; no redeploy was performed for later comment/test-support-only review followups.
- Existing scene contained prior geometry, so live test terrain was created to the side of the scene.
- Small hosted terrain `MTA-09-live-region-plan-20260426`:
  - Created 5x4 grid: 20 vertices, 24 faces.
  - Target-height edit advanced revision `1 -> 2`, changed region `{ column: 1..3, row: 1..2 }`, full-grid output stayed 20 vertices / 24 faces.
  - Corridor edit advanced revision `2 -> 3`, changed region `{ column: 0..4, row: 0..3 }`, full-grid output stayed 20 vertices / 24 faces.
  - Greybox inspection found all generated faces and edges marked derived, no down-facing faces, no non-positive-Z faces, persisted `heightmap_grid` v1, and no planning leak terms.
  - Undo restored revision `3 -> 2` with the expected digest and 24-face output intact.
  - Runtime `ping` passed after hosted operations.
- Larger hosted performance baseline terrain `MTA-09-live-perf-100x100-20260426`:
  - Created 100x100 grid: 10,000 vertices, 19,602 faces, wrapper call about `0.56s`.
  - Small bounded edit with 121 affected samples regenerated full-grid output in about `2.18s`.
  - A later 9-sample edit also regenerated full-grid output, as expected for MTA-09.
  - Mesh inspection after large edit found 19,602 faces, 29,601 edges, all faces/edges marked derived, no down-facing or non-positive-Z faces, and minimum normal Z about `0.272`.
- Greybox MTA-10-enabling seam check:
  - Installed a narrow temporary in-process tracer around `TerrainMeshGenerator#regenerate`.
  - A real MCP `edit_terrain_surface` call passed an actual `SU_MCP::Terrain::TerrainOutputPlan` into regeneration.
  - Captured plan had `intent: :dirty_window`, `execution_strategy: :full_grid`, dirty window `{ column: 40..42, row: 40..42 }`, and dirty sample count `9`.
  - Captured dirty window matched public `changedRegion` evidence exactly.
  - Plan summary matched regeneration result summary.
  - No planning terms appeared in the public summary.
  - Temporary trace recording was disabled after evidence capture.

## Notes For MTA-10

MTA-09 proves the internal handoff that MTA-10 needs:

- command orchestration can produce dirty-window intent from edit diagnostics;
- `TerrainMeshGenerator#regenerate` can receive that intent;
- the current execution strategy is still explicitly full-grid;
- public and persisted contracts remain stable while the internal plan carries enough information for partial-regeneration implementation.

The 100x100 hosted performance baseline reinforces the motivation for MTA-10: even a 9-sample dirty edit still regenerates all 19,602 faces in MTA-09.

## Remaining Gaps

- MTA-09 intentionally does not implement partial terrain output replacement.
- No public strategy selection or planning diagnostics were exposed.
- The deployed live validation used the initial functional implementation. Later review followups were comments and test-support/test-assertion refinements only and were validated locally, not redeployed.
