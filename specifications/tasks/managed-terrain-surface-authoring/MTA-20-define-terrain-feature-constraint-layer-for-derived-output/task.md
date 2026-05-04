# Task: MTA-20 Define Terrain Feature Constraint Layer For Derived Output
**Task ID**: `MTA-20`
**Title**: `Define Terrain Feature Constraint Layer For Derived Output`
**Status**: `implemented`
**Priority**: `P1`
**Date**: `2026-05-02`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-19 showed that trying to improve derived terrain output through a generic triangulation
backend alone is not enough. Corridor-heavy and adopted irregular terrains can have correct
heightmap state and correct public samples while the generated output mesh still contains
visually suspicious topology. The weakness is not only corridor-specific behavior; corridors are
the first feature family that exposed a broader gap.

Managed terrain needs an internal way to describe terrain features that matter to output
generation and diagnostics. These features may come from explicit edit intent, such as corridor
controls, target-height regions, circular regions, planar-fit regions, preserve zones, or survey
constraints, and may also be inferred from final heightfield discontinuities. Derived output
generation should consume those feature constraints instead of guessing all terrain structure from
elevations after the fact.

This task defines and proves the internal feature-constraint layer that future simplification and
diagnostic work can use without changing public terrain source-of-truth semantics.

## Goals

- Introduce an internal terrain feature-constraint model that can describe hard boundaries, soft
  transition bands, control points, endpoint caps, protected zones, and feature priorities.
- Allow terrain edit kernels and output planning to carry feature constraints alongside the
  authoritative `heightmap_grid` state without making generated mesh the source of truth.
- Preserve only the durable feature intent and regeneration metadata needed to rebuild internal
  constraints across output-regeneration boundaries.
- Provide enough feature information for derived output diagnostics to distinguish expected sharp
  changes along a feature from suspicious cross-feature triangulation.
- Preserve compact public MCP responses and avoid exposing feature-constraint internals unless a
  later task intentionally defines public evidence fields.
- Establish a backend-agnostic foundation that can support the existing simplifier, a future
  feature-aware simplifier, or a future constrained Delaunay / DELATIN prototype.

## Acceptance Criteria

```gherkin
Scenario: corridor edit emits generic feature constraints
  Given a managed terrain corridor-transition edit with start and end controls, width, side falloff, and end behavior
  When the edit produces its updated terrain state and edit diagnostics
  Then the internal output-planning data includes feature constraints for the corridor centerline, side transition bands, endpoint control zones, and control role or priority
  And those constraints are expressed in terrain owner-local/grid-aware coordinates rather than raw SketchUp entity references
  And the public MCP response does not expose raw feature-constraint internals

Scenario: non-corridor edits emit the same feature vocabulary
  Given target-height rectangle, circular target-height, planar-fit, preserve-zone, and survey-correction edits
  When each edit produces terrain output-planning data
  Then each edit can describe its important terrain features using the same internal constraint vocabulary
  And the vocabulary does not require corridor-specific branches in derived output generation

Scenario: inferred heightfield features supplement explicit edit features
  Given a managed terrain state with sharp or smooth transitions but no usable edit-intent history
  When feature constraints are prepared for derived output
  Then the system can identify heightfield-derived candidate features such as hard slope breaks, transition bands, ridges, valleys, and plateaus
  And inferred features are marked separately from explicit edit features so later diagnostics can explain confidence and priority

Scenario: feature-aware diagnostics classify topology warnings
  Given a derived terrain output with adjacent-face normal breaks or long simplification edges
  When topology diagnostics are evaluated against internal feature constraints
  Then expected discontinuities along hard features are classified separately from suspicious triangles that cross protected or incompatible feature regions
  And the diagnostic result can be used by tests and hosted verification without becoming a public validation verdict

Scenario: public contract remains compact
  Given a public MCP client creates, adopts, or edits managed terrain
  When terrain output is regenerated with internal feature constraints available
  Then public responses remain JSON-serializable and compact
  And responses do not expose raw feature graphs, raw triangle lists, solver matrices, SketchUp objects, or low-level algorithm names

Scenario: feature intent survives regeneration boundaries
  Given a managed terrain edit changes terrain state and derived output is regenerated
  When output planning and generation run
  Then the durable terrain data includes enough feature intent and regeneration metadata to rebuild internal feature constraints before geometry replacement
  And expanded feature geometry and pointified lanes are derived during output planning rather than treated as durable source state
  And refusal paths that can be detected before output mutation leave previous valid output intact
```

## Non-Goals

- implementing a new Delaunay, constrained Delaunay, DELATIN, RTIN, or other replacement
  triangulation backend
- changing `heightmap_grid` as the public or persisted terrain source-of-truth payload kind
- exposing feature constraints as public MCP request or response fields
- persisting expanded feature graphs, pointified lanes, raw triangle lists, or solver internals as
  durable terrain source state
- creating a public Landscape Spline authoring tool or SketchUp UI for splines
- adding corridor-specific mesh patches that bypass a generic feature-constraint model
- making generated SketchUp mesh vertices, faces, or edges durable terrain state
- solving all terrain visual-quality diagnostics or validation policy in this task

## Business Constraints

- The task must improve the path toward reliable terrain output without reintroducing the failed
  MTA-19 simplifier as production behavior.
- Public MCP clients should not need to understand internal feature graphs to use terrain tools.
- Targeted Unreal Engine Landscape source research should inform internal feature mechanics, but it
  must not define public MCP vocabulary or override this repository's Ruby runtime boundaries.
- Corridor-heavy workflows are important evidence, but the solution must generalize to other
  terrain features and edit families.
- The previous reliable simplifier remains the production baseline until feature-aware output work
  proves a better replacement.

## Technical Constraints

- The Ruby extension runtime remains the owner of terrain edit orchestration, terrain output
  planning, SketchUp API mutation, and serialization.
- Terrain state remains authoritative; expanded feature constraints are auxiliary internal planning
  and diagnostic data rebuilt from terrain state, feature intent, and regeneration metadata.
- Feature constraints must be JSON-serializable internally and must not carry raw SketchUp object
  handles across runtime-facing boundaries.
- Feature coordinates must be normalized to terrain owner-local/grid-aware coordinates so they can
  work for created terrain, adopted terrain, non-square grids, and off-grid controls.
- The model must distinguish explicit edit-derived features from inferred heightfield features.
- Tests must cover corridor endpoints, side transitions, rectangle/circle boundaries, planar-fit
  regions, preserve zones, adopted irregular terrain, and off-grid controls at the layer that owns
  the behavior.

## Dependencies

- `MTA-05`
- `MTA-11`
- `MTA-12`
- `MTA-13`
- `MTA-16`
- `MTA-19`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Managed Terrain Phase 1 UE Research Reference](../../../research/managed-terrain/ue-reference-phase1.md)

## Relationships

- follows `MTA-19` because the failed replacement simplifier showed that output generation needs
  feature constraints before another triangulation backend is attempted
- informs future adaptive simplification, Delaunay/CDT, DELATIN, or breakline-aware terrain output
  tasks
- informs terrain diagnostics by providing feature context for interpreting sharp normal breaks,
  long edges, and cross-feature triangles
- complements `MTA-18` because future visual terrain controls may collect or preview feature
  intent, but this task does not implement UI behavior

## Related Technical Plan

- [Technical plan](./plan.md)

## Success Metrics

- corridor, rectangle, circle, planar-fit, preserve-zone, and survey-related terrain edits can
  produce or prepare feature constraints through one internal vocabulary
- feature constraints are available to derived output planning without public MCP response
  expansion
- topology diagnostics can classify at least one expected feature-aligned sharp break separately
  from one suspicious cross-feature triangulation case
- created terrain, adopted terrain, non-square grids, and off-grid controls are covered by
  deterministic tests
- future simplifier planning can consume this task as a stable feature-constraint foundation
