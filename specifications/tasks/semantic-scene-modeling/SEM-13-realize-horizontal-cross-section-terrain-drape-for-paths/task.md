# Task: SEM-13 Realize Horizontal Cross-Section Terrain Drape for Paths
**Task ID**: `SEM-13`
**Title**: `Realize Horizontal Cross-Section Terrain Drape for Paths`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-20`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The semantic path surface already accepts sectioned `hosting` input and documents `hosting.mode: "surface_drape"` for `path`, but the current runtime does not yet realize the intended terrain-following geometry behavior. The public contract can accept a drape-style request while the builder still creates a planar corridor that ignores the hosting target, which leaves the path surface semantically misleading for terrain-aware workflows.

That gap matters because `path` is part of the first semantic creation wave and terrain-aware site circulation is a practical modeling case, not a speculative next-wave family. The capability needs one explicit follow-on task that makes `path + surface_drape` materially true without broadening into full terrain authoring, edge-projected drape, or terrain modification.

## Goals

- realize `path + surface_drape` as a true terrain-aware semantic creation flow rather than a validation-only contract branch
- ensure draped paths follow terrain along their length while remaining horizontally flat across each width-wise cross-section
- preserve explicit refusal behavior when terrain-aware path creation cannot be satisfied from the targeted host surface

## Acceptance Criteria

```gherkin
Scenario: surface-draped paths follow terrain along travel while staying level across width
  Given a sampleable terrain or surface target is available
  And a valid semantic `path` request uses `hosting.mode: "surface_drape"` with a target reference
  When `create_site_element` creates the path
  Then the resulting managed path geometry varies along the path length in response to the targeted surface
  And each representative cross-section of the created path remains horizontally level across the requested width
  And the realized top path surface does not sink below the targeted surface at sampled stations
  And any downward path thickness is subordinate to that top-surface guarantee rather than a requirement that the full body clear terrain

Scenario: surface-draped paths remain non-destructive to terrain
  Given a valid semantic `path` request uses `hosting.mode: "surface_drape"`
  When the path is created against a targeted terrain or surface host
  Then the runtime creates a path ribbon or equivalent managed path geometry above or on the surface
  And the operation does not cut, boolean, or otherwise modify the targeted terrain geometry

Scenario: unsupported or unsatisfied drape requests refuse cleanly
  Given a semantic `path` request uses `hosting.mode: "surface_drape"`
  When the centerline is invalid, the width is non-positive, the host cannot be sampled, or required terrain samples cannot be resolved
  Then the runtime returns a structured refusal instead of falling back to planar unhosted path creation
  And the refusal remains JSON-serializable and does not expose raw SketchUp objects

Scenario: public contract and examples match the realized drape behavior
  Given `create_site_element` is the primary semantic creation surface
  When `path + surface_drape` is reviewed in runtime schemas, tests, and user-facing docs
  Then the documented request shape matches the live sectioned contract actually required by the runtime
  And the documented behavior states that draped paths follow terrain longitudinally while each cross-section stays level and clear of terrain
```

## Non-Goals

- full terrain modeling, grading, or `terrain_patch` authoring
- projected-edge or terrain-cutting drape behavior that modifies the host surface
- widening terrain-aware drape behavior to semantic families other than `path`
- introducing a new public semantic creation tool outside `create_site_element`

## Business Constraints

- the delivered behavior must make the existing semantic path contract more trustworthy rather than adding another nominally supported but weakly realized mode
- the task must improve practical terrain-aware site-path authoring without broadening into a general terrain-authoring initiative
- the path result must remain semantically legible and suitable for later managed-object revision flows
- the primary visual correctness rule is that the draped top surface clears terrain; downward thickness may intersect below the surface where needed to avoid an unnaturally floating result

## Technical Constraints

- Ruby remains the owner of hosting interpretation, terrain sampling consumption, geometry construction, refusal behavior, and result serialization
- the task must build on the existing sectioned `create_site_element` contract and the bounded hosting posture already established for semantic creation
- public inputs must remain aligned with the current semantic unit boundary and avoid mixed-unit ambiguity between public meters and SketchUp internal units
- successful and refused drape flows must remain JSON-safe and undo-safe, and contract changes must update schemas, tests, and user-facing docs in the same change
- the task's terrain-clearance guarantee applies to the realized top path surface; downward thickness may extend below that surface for visual grounding and is not itself a terrain-clearance contract

## Dependencies

- `SEM-06`
- `SEM-09`

## Relationships

- informs deferred terrain-aware semantic follow-ons

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- `path + surface_drape` no longer behaves like a planar unhosted path when a valid surface target is supplied
- representative terrain-aware path requests succeed through `create_site_element` without requiring fallback Ruby for the drape behavior itself
- unsupported or unsatisfied drape requests fail through structured refusals rather than silent degradation or raw internal errors
