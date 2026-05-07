# Task: MTA-24 Prototype Constrained Delaunay/CDT Terrain Output Backend And Three-Way Bakeoff
**Task ID**: `MTA-24`
**Title**: `Prototype Constrained Delaunay/CDT Terrain Output Backend And Three-Way Bakeoff`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-05-07`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-23 proved that the intent-aware adaptive-grid candidate is a serious upgrade candidate over the
current simplifier, especially on scene-level face count and clean SketchUp topology. It also showed
that hard preserve/fixed-anchor enforcement, rough-terrain accuracy, high-relief residuals, and
runtime need more evidence before production replacement.

MTA-24 must prototype a real constrained Delaunay/CDT or breakline-aware terrain output candidate
that consumes the production `TerrainFeatureGeometry` substrate delivered by MTA-23, then compare it
against both the current production simplifier and the MTA-23 adaptive-grid prototype on the same
local and hosted cases. The task ends with a production recommendation: current backend, MTA-23
adaptive-grid, CDT, or a hybrid/fallback strategy.

## Goals

- Prototype a real constrained Delaunay/CDT or breakline-aware terrain output backend for
  comparison, without production-wiring it.
- Consume production `TerrainFeatureGeometry` primitives as the backend-neutral constraint input.
- Compare current simplifier, MTA-23 adaptive-grid, and CDT on shared terrain states and metrics.
- Preserve final edited heightmap detail with residual-driven CDT refinement instead of treating
  feature count or a fixed sparse ratio as the primary budget.
- Run the same live SketchUp case families used to close MTA-23:
  - MTA-22 created/adopted/stress cases
  - hard preserve and fixed-anchor cases
  - aggressive varied terrain cases
  - high-relief and corridor-pressure cases
- Recommend a production backend or hybrid strategy with explicit evidence and residuals.

## Acceptance Criteria

```gherkin
Scenario: CDT prototype consumes feature geometry
  Given a managed terrain state with MTA-20 feature intent
  And MTA-23 TerrainFeatureGeometry has been derived for that state
  When the CDT prototype generates candidate terrain output
  Then it consumes output anchors, protected regions, pressure regions, reference segments, and affected windows from TerrainFeatureGeometry
  And it does not read raw SketchUp objects or public response internals as its constraint source

Scenario: Prototype remains comparison-only
  Given the CDT candidate is implemented for MTA-24 comparison
  When terrain output is generated through existing production workflows
  Then the production terrain backend remains unchanged
  And public MCP request and response contracts remain stable
  And CDT raw triangles, solver internals, expanded constraints, and diagnostic rows do not leak into public terrain responses

Scenario: Valid heightmap still emits candidate mesh
  Given a valid managed terrain heightmap state
  And its feature geometry includes hard or firm requirements the CDT candidate cannot fully satisfy
  When the CDT candidate generates comparison output
  Then it still emits a candidate mesh row for the valid heightmap
  And unsatisfied constraints and CDT diagnostic gaps are recorded as residuals, limitations, or failure categories
  And terrain edit kernels are not rejected by the comparison backend

Scenario: CDT point budget follows final edited surface complexity
  Given a final edited terrain heightmap with MTA-20 feature intent
  When the CDT prototype selects candidate points
  Then hard anchors and required boundaries are mandatory
  And firm or soft feature intent guides local tolerance and residual sampling
  But firm or soft feature intent does not by itself consume a dense support grid
  And additional non-mandatory points are added where the CDT mesh poorly reconstructs the final heightmap
  And a complex source terrain flattened by an edit can still simplify to a very small mesh
  And an edited terrain that preserves meaningful bumps can receive a larger point budget when residuals justify it

Scenario: Three-way local bakeoff uses shared states
  Given representative MTA-22 and MTA-23 comparison cases
  When current, MTA-23 adaptive-grid, and CDT candidates are evaluated
  Then each backend is run against the same terrain state and feature geometry where applicable
  And the comparison records face count, vertex count, dense ratio, height error, hard preserve crossings, fixed-anchor residuals, topology residuals, runtime, and failure category
  And the comparison does not rely on non-equivalent source geometry between backends

Scenario: Hosted SketchUp bakeoff covers prior live evidence families
  Given the deployed SketchUp scene contains or can generate the MTA-22 and MTA-23 validation cases
  When hosted validation runs through MCP wrapper eval_ruby
  Then current, MTA-23 adaptive-grid, and CDT sidecars are generated as comparison-only geometry for MTA-22, hard preserve/fixed, aggressive varied, high-relief, and corridor-pressure cases
  And each sidecar records topology, face count, residual, timing, metadata, undo, and save-copy or save/reopen evidence where practical
  And the three generated methods are available for joint live visual validation before a production-direction recommendation is accepted
  And existing scene geometry is not mutated except for explicitly named validation sidecar groups

Scenario: Recommendation selects production direction or hybrid
  Given local and hosted three-way bakeoff evidence is complete
  When MTA-24 is summarized
  Then the summary recommends one of current backend, MTA-23 adaptive-grid, CDT, or a hybrid/fallback strategy
  And the recommendation cites concrete evidence for topology, hard constraints, rough-terrain accuracy, runtime, and production risk
  And any production follow-up task has explicit acceptance gates rather than assuming the prototype is already production-ready
```

## Non-Goals

- Production-wiring CDT as the default terrain backend.
- Removing or renaming MTA-23 prototype files before a production backend is selected.
- Adding public user-facing simplification controls or backend selection options.
- Persisting generated CDT mesh, raw triangles, expanded constraints, or solver internals as terrain state.
- Rewriting unrelated terrain edit kernels.
- Treating manual visual inspection alone as acceptance evidence.

## Business Constraints

- The task exists because MTA-23 did not justify an unconditional production swap.
- MTA-24 must compare CDT against both current production behavior and the MTA-23 adaptive-grid
  candidate, not only against an idealized target.
- Production implementation should move to a later task after this bakeoff selects a backend or
  hybrid direction.
- Any recommendation must be grounded in local tests and live SketchUp evidence.

## Technical Constraints

- Terrain state remains authoritative; generated output remains disposable derived geometry.
- Production `TerrainFeatureGeometry` is the CDT constraint input boundary.
- Outputs from prototype commands and comparison rows must be JSON-serializable.
- Public MCP contracts must remain stable unless a separate contract task is defined.
- Hosted validation must use the MCP wrapper and `eval_ruby`, not ad hoc transport scripts.
- Scene sidecars must be explicitly marked as validation artifacts and must not overwrite existing geometry.
- Current, MTA-23 adaptive-grid, and CDT sidecars must be jointly live-validated visually before any
  backend or hybrid recommendation is accepted.
- Validation must include topology checks for down faces and non-manifold edges.
- Mesh generation is downstream of a valid terrain state. Unsatisfied constraints and CDT diagnostic
  failures must not reject terrain edits or prevent candidate mesh generation for a valid heightmap.
- CDT simplification must be driven by residual error against the final edited heightmap. Fixed dense
  ratios are safety guards only, not success targets, and feature intent alone must not justify
  preserving thousands of faces on a flat final surface.

## Dependencies

- `MTA-20`
- `MTA-21`
- `MTA-22`
- `MTA-23`

## Relationships

- follows `MTA-23` because MTA-23 produced the production feature-geometry substrate and
  adaptive-grid prototype baseline
- consumes the MTA-22 fixture/replay framework for repeatable comparison
- informs the later production backend implementation task

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- CDT candidate can emit comparison-only SketchUp geometry from `TerrainFeatureGeometry`.
- CDT candidate reports residual-driven stop reasons and selected-point provenance, including seed,
  mandatory, and residual point counts.
- Three-way comparison rows exist for current, MTA-23 adaptive-grid, and CDT on shared states.
- Hosted SketchUp sidecars cover MTA-22, hard preserve/fixed, aggressive varied, high-relief, and
  corridor-pressure cases.
- The final recommendation states whether to productionize current, MTA-23 adaptive-grid, CDT, or a
  hybrid/fallback strategy.
- Public contract and no-leak checks remain green.
