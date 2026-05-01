# Task: MTA-11 Migrate To Dense Tiled Heightfield V2 With Adaptive Output
**Task ID**: `MTA-11`
**Title**: `Migrate To Dense Tiled Heightfield V2 With Adaptive Output`
**Status**: `implemented`
**Priority**: `P1`
**Date**: `2026-05-01`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain currently persists a uniform `heightmap_grid` v1 state and derives SketchUp mesh output directly from that stored sample grid. MTA-13 and MTA-16 proved useful survey and planar editing behavior on the v1 substrate, but terrain-session feedback exposed two related limits:

- coarse source spacing cannot support small hardscape-adjacent shoulders, off-grid survey controls, and fine visual grading without spillover or local artifacts
- localized base/detail-zone representation would force edit kernels to reason across coarse, detailed, and coarse-again regions, adding mixed-resolution math and commit complexity before improving the editing model

The stronger v2 direction is to migrate Managed Terrain Surface state to a tiled heightmap as the universal authoritative edit substrate, then generate adaptive SketchUp TIN output from that tiled source. Edit kernels should operate on uniform raster windows, not mixed-resolution terrain sections. Generated SketchUp geometry remains disposable derived output, but v2 representation and first adaptive output generation must ship together because a terrain state that cannot regenerate usable SketchUp geometry is not a complete Managed Terrain Surface.

This task intentionally drops v1 backward-compatibility as an implementation requirement. Existing v1 model migration, if needed, is a one-way conversion into v2 state rather than a permanent dual-format runtime.

## Goals

- define tiled heightmap v2 as the authoritative terrain state for Managed Terrain Surfaces
- make edit kernels operate on uniform raster edit windows over v2 terrain rather than mixed-resolution base/detail sections
- implement one-way v1-to-v2 migration posture without preserving v1 as a supported runtime format
- store and load v2 tiled terrain state through the terrain repository with deterministic summaries and integrity checks
- track dirty tiles or windows affected by terrain edits
- generate adaptive SketchUp TIN output from dense v2 heightfield source as part of the same task
- use a bounded first adaptive output algorithm, such as deterministic quadtree/error-based simplification, instead of starting with constrained Delaunay or advanced mesh optimization
- preserve terrain state as source of truth and generated mesh as disposable derived output
- keep sampling, validation, and evidence handoff understandable to downstream MCP workflows

## Acceptance Criteria

```gherkin
Scenario: tiled heightmap v2 is persisted and loaded
  Given a Managed Terrain Surface uses tiled heightmap v2 state
  When the terrain state is saved and loaded through the terrain repository
  Then the repository returns the correct tiled heightfield state
  And payload integrity checks, version fields, and state summaries are deterministic
  And raw SketchUp objects are not exposed through the domain-facing repository contract

Scenario: v1 compatibility is not a permanent runtime requirement
  Given an existing Managed Terrain Surface uses `heightmap_grid` schema version 1
  When MTA-11 migration behavior is planned or implemented
  Then the supported posture is one-way migration into tiled heightmap v2
  And runtime terrain editing and output generation are not required to preserve v1 round-trip compatibility

Scenario: edit kernels operate on uniform raster windows
  Given a terrain edit crosses areas that previously would have been modeled as coarse, detailed, and coarse terrain sections
  When the edit kernel runs
  Then the kernel receives a uniform raster edit window over the requested support bounds
  And the kernel math is independent of source tile boundaries or output triangulation
  And committing the result updates dense v2 terrain state in the affected dirty tiles or windows

Scenario: slope or planar edits cross former representation boundaries
  Given a user applies a slope, corridor, fairing, survey correction, or planar edit across a local detail area and adjacent terrain
  When the edit is evaluated against v2 terrain state
  Then target elevations are computed from terrain-local XY coordinates over a uniform edit raster
  And source representation boundaries do not change the mathematical meaning of the edit
  And generated output is regenerated from the updated heightfield rather than edited directly

Scenario: adaptive SketchUp output is generated from dense heightfield source
  Given a tiled heightmap v2 terrain has flat, planar, and locally detailed regions
  When derived SketchUp terrain output is regenerated
  Then flat or planar regions may collapse to fewer faces when they remain within documented height-error tolerance
  And locally detailed or high-error regions retain enough output detail to satisfy the configured simplification tolerance
  And generated face or vertex identity is not exposed as durable terrain state

Scenario: adaptive output simplification is bounded for the first v2 slice
  Given advanced constrained Delaunay, breakline preservation, or global mesh optimization would produce better output
  When the first v2 adaptive output scope is reviewed
  Then the task starts with a deterministic bounded simplifier such as quadtree or error-based subdivision
  And stronger simplification techniques remain explicit follow-on work

Scenario: corrupt or unsupported v2 state refuses explicitly
  Given stored terrain state is missing, corrupt, unsupported, or cannot be safely migrated
  When the terrain repository attempts to load or migrate it
  Then it returns a structured refusal or recovery outcome
  And callers are not expected to fabricate terrain state or fall back to generated SketchUp mesh as source of truth
```

## Non-Goals

- making generated SketchUp mesh geometry the durable source of truth
- supporting v1 terrain state as a permanent runtime format after v2 migration
- implementing localized base/detail-zone overlays or mixed-resolution composite edit windows
- implementing adaptive output without migrating terrain state to v2
- implementing v2 tiled heightmap state without usable SketchUp output generation
- implementing constrained Delaunay, breakline preservation, or advanced global mesh optimization as the first adaptive output algorithm
- implementing partial v2 output regeneration unless it is deliberately included in the technical plan and does not weaken v2 correctness
- adding public Unreal-style terrain tools
- mutating semantic hardscape objects as part of terrain state

## Business Constraints

- v2 terrain state and first adaptive output generation must land together so migrated Managed Terrain Surfaces remain usable in SketchUp
- tiled source data must support survey fidelity, visual terrain grading, and practical UI/MCP edits without requiring edit kernels to understand mixed source resolution
- storage evolution must remain portable with SketchUp model workflows unless a later sidecar design explicitly changes that posture
- terrain evidence and validation handoff should remain understandable to downstream MCP clients
- one-way migration means existing v1 compatibility risk is accepted rather than preserving a dual-format runtime indefinitely

## Technical Constraints

- terrain state remains behind the terrain repository seam and outside the lightweight `su_mcp` metadata dictionary
- terrain edit kernels consume a uniform raster edit-window interface, not raw v2 storage tiles or generated mesh topology
- generated output is derived from dense heightfield source and governed by documented height-error or simplification tolerances
- adaptive output must preserve terrain boundary correctness and avoid visible cracks or unsafe seams between simplified output regions
- migration and unsupported-version behavior must be deterministic and JSON-safe
- generated face or vertex identifiers must not become durable representation identifiers
- any public evidence or request-shape change requires coordinated loader schema, fixtures, tests, docs, and examples

## Dependencies

- `MTA-07`
- `MTA-09`
- `MTA-10`
- `MTA-13`
- `MTA-16`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)
- [Terrain Session Exposes Local Detail, Hardscape, Sampling, And Identity Gaps](../../../signals/2026-04-30-terrain-session-exposes-local-detail-hardscape-and-identity-gaps.md)

## Relationships

- follows the scalable representation direction selected in `MTA-07`
- follows `MTA-13` and `MTA-16`, which provide evidence for where v1 heightmap state succeeds, warns, or refuses survey and planar controls
- consumes the April 30 terrain-session signal as concrete narrow-feature pressure
- supersedes the earlier localized detail-zone direction with a tiled heightmap v2 plus adaptive output direction
- informs `MTA-18` by providing a simpler uniform raster edit substrate for bounded visual terrain controls
- informs future output-simplification tasks that may add stronger algorithms after the first deterministic adaptive output pass

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- tiled heightmap v2 state saves, loads, validates, and refuses unsupported cases through the repository seam
- v1 terrain is handled through one-way migration posture rather than required round-trip compatibility
- existing terrain edit modes operate through uniform raster edit windows over v2 state
- adaptive SketchUp output regenerates from tiled source with documented error tolerance and coherent boundaries
- flat or planar representative terrain regions generate substantially fewer output faces than full dense-grid output while remaining within tolerance
- edit kernels remain independent of storage tiles and generated mesh identity
- corrupt-payload, unsupported-version, migration, output-regeneration, undo, and hosted SketchUp behavior are covered by tests or called out as validation gaps
