# Task: MTA-21 Make Adaptive Terrain Output Conforming
**Task ID**: `MTA-21`
**Title**: `Make Adaptive Terrain Output Conforming`
**Status**: `implemented`
**Priority**: `P0`
**Date**: `2026-05-04`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain output now uses tiled heightmap state with adaptive TIN-derived SketchUp geometry
to keep detailed terrain practical without rendering every heightmap cell. Live inspection found
that adaptive output can contain internal T-junction-like seams: one larger terrain face edge can
meet two or more smaller terrain face edges without a conforming shared vertex split. These seams
are subtle on some terrains but can become visible when viewed closely, especially on adopted or
irregular heightfields and after regeneration changes the adaptive subdivision pattern.

The stored heightmap remains the source of truth. The defect is in derived adaptive output topology,
not in source-state ownership. Regular full-grid output would avoid the cracks, but it is not an
acceptable production fallback for detailed terrain because the face count is too high. Managed
terrain therefore needs adaptive output that remains compact while generating conforming, gap-free
SketchUp geometry.

## Goals

- Ensure adaptive terrain output has conforming shared boundaries across mixed-resolution adaptive
  cells.
- Preserve adaptive output as the production path for detailed/tiled terrain rather than falling
  back to full regular-grid output.
- Prove that clean created terrain, adopted terrain, and edited terrain do not contain internal
  terrain-output T-junction/gap seams.
- Hide generated terrain edges using SketchUp hidden-geometry edge state so adaptive terrain reads
  as a continuous derived surface by default.
- Preserve the repository-backed heightmap source-of-truth model and compact public MCP responses.
- Establish regression fixtures that catch internal naked terrain edges or equivalent
  non-conforming adaptive seams before live verification.

## Acceptance Criteria

```gherkin
Scenario: adaptive output is conforming for mixed-resolution cells
  Given a tiled managed terrain heightmap whose adaptive simplification produces adjacent cells of different sizes
  When derived terrain output is generated
  Then adjacent adaptive cells share conforming edges without T-junctions
  And internal terrain-output edges do not appear as one-face naked edges
  And generated terrain edges use SketchUp hidden-geometry edge state
  And the public output summary remains compact and JSON-serializable

Scenario: adopted terrain output is gap-free before and after edits
  Given an adopted managed terrain surface with irregular sampled elevations
  When the terrain is adopted and derived output is generated
  Then the output has no internal T-junction or gap seams between terrain faces
  When bounded target-height and corridor edits regenerate that terrain
  Then the regenerated output still has no internal T-junction or gap seams

Scenario: clean flat terrain remains conforming under aggressive edits
  Given a flat created managed terrain surface using adaptive output
  When sharp pads, sharp depressions, off-grid circular edits, and off-grid corridor edits are applied
  Then output regeneration preserves zero internal terrain-output gap seams
  And the terrain remains represented through adaptive output rather than regular full-grid output
  And generated terrain edges remain hidden SketchUp geometry after regeneration

Scenario: source heightmap remains authoritative
  Given a managed terrain surface with repository-backed heightmap state
  When conforming adaptive output is regenerated
  Then the stored heightmap payload, revision, digest, and owner identity remain the source of truth
  And generated SketchUp faces, edges, vertices, adaptive cells, or stitch geometry are not persisted as terrain state

Scenario: public contract remains stable
  Given an MCP client creates, adopts, or edits managed terrain
  When conforming adaptive output is generated
  Then public request fields, response fields, tool names, and output summary vocabulary remain compatible
  And public responses do not expose raw triangles, stitch internals, adaptive cell graphs, or SketchUp objects
```

## Non-Goals

- replacing the adaptive output path with regular full-grid production output
- implementing a new RTIN, Delaunay, constrained Delaunay, DELATIN, or feature-aware output backend
- reviving the reverted MTA-19 adaptive TIN replacement path
- changing the public `create_terrain_surface` or `edit_terrain_surface` request contract
- changing the persisted heightmap source-of-truth model
- persisting generated mesh vertices, faces, edges, stitch triangles, or adaptive-cell graphs as
  terrain state
- solving all future terrain visual-quality or feature-aware simplification needs
- changing adoption so source mesh faces remain durable geometry after adoption

## Business Constraints

- Detailed managed terrain must remain practical to render and edit; full-grid output is not an
  acceptable production workaround for large or dense terrain.
- Existing managed terrain workflows should continue to treat generated SketchUp mesh as disposable
  derived output from stored terrain state.
- The fix should reduce visible terrain cracking without widening the public MCP terrain contract.
- Existing complex terrain scenes should remain usable after deployment without requiring users to
  understand adaptive output internals.

## Technical Constraints

- SketchUp-facing geometry mutation remains owned by the Ruby extension runtime.
- Terrain state remains the authoritative `heightmap_grid` payload; output topology repairs must be
  derived during output generation.
- The fix should repair the current adaptive-cell output path rather than replacing it with a new
  terrain triangulation backend.
- Generated terrain edge hiding must use SketchUp edge hidden state; smoothing or soft-edge behavior
  is not a substitute unless separately justified by implementation evidence.
- Public MCP responses must stay compact and JSON-serializable.
- Adaptive output must remain bounded by simplification/performance goals; the task cannot silently
  degrade detailed terrain back to regular full-grid output.
- Validation must include deterministic topology checks and live SketchUp-hosted evidence on at
  least one adopted/irregular terrain fixture.
- The task must not rely on raw SketchUp object handles crossing runtime-facing command boundaries.

## Dependencies

- `MTA-08`
- `MTA-10`
- `MTA-11`
- `MTA-20`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-11` because adaptive TIN output introduced compact detailed terrain generation
- follows `MTA-20` because feature intent work clarified that current output generation remains
  the production baseline until a later feature-aware backend is intentionally planned
- blocks future RTIN, Delaunay, DELATIN, or feature-aware output comparisons from using a
  topologically invalid current adaptive baseline
- informs future terrain output diagnostics by defining measurable topology evidence for internal
  adaptive seams

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- deterministic tests can reproduce the previous mixed-resolution adaptive seam defect before the
  fix and pass after the fix
- generated adaptive output has zero internal terrain-output naked edges or equivalent T-junction
  seams on created, adopted, and edited fixtures
- live SketchUp verification records gap-free output on at least one adopted irregular terrain and
  one aggressive/off-grid edited flat terrain
- output remains adaptive for tiled terrain, with face count materially below full regular-grid
  output on representative dense terrain
- public MCP contract fixtures remain unchanged except for expected derived-output counts or
  non-public diagnostics
