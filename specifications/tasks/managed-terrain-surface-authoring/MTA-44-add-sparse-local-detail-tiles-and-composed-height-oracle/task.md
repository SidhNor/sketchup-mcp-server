# Task: MTA-44 Add Sparse Local Detail Tiles And Composed Height Oracle
**Task ID**: `MTA-44`
**Title**: `Add Sparse Local Detail Tiles And Composed Height Oracle`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Feature-aware output density can allocate more triangles near important terrain features, but it
cannot create true sub-grid elevation detail where the authoritative base heightmap lacks that
resolution. Increasing the whole source grid to support one road, pad, swale, survey-controlled
zone, or fine grading area would undermine large-terrain scalability.

This task adds sparse local detail state and a composed height oracle so selected regions can carry
higher local elevation detail without globally increasing base heightmap spacing.

## Goals

- Add sparse local detail tiles or equivalent local high-resolution terrain state for bounded
  patch/window regions.
- Provide a composed height oracle that combines hard/control values, preserve-region behavior,
  local detail, analytic feature surfaces where available, and base heightmap interpolation.
- Ensure adaptive output can query composed height consistently during create/edit/regeneration.
- Preserve seam safety, component planning, PatchLifecycle ownership, no-delete mutation,
  registry/readback, and public command contracts.
- Prove local high-detail behavior with hosted replay evidence, including comparison against
  equivalent global refinement pressure.

## Acceptance Criteria

```gherkin
Scenario: Local detail provides high resolution without global source-grid refinement
  Given a managed terrain replay row that requires fine local detail in a bounded region
  When local detail state is applied and output is regenerated through hosted public commands
  Then the bounded region can represent detail finer than the base heightmap spacing
  And the base heightmap does not need to be globally refined for that local detail
  And unaffected terrain regions do not gain unexplained face count or state resolution growth

Scenario: Composed height oracle is consistent across output and validation
  Given base heightmap state, feature intent, preserve behavior, and local detail state
  When output planning, adaptive meshing, validation, and readback query terrain height
  Then they use a consistent composed height oracle
  And hard/control, preserve, local detail, analytic feature, and base interpolation precedence is deterministic
  And validation failures leave old output intact

Scenario: Local detail boundaries remain seam-safe and component-aware
  Given local detail tiles near patch boundaries or crossing multiple patches
  When output planning runs
  Then local detail boundaries participate in seam contracts and component planning
  And required patch promotion remains bounded by policy
  And unsupported local detail boundaries refuse or safely fall back before mutation

Scenario: Live evidence is recorded for the same baseline corpus
  Given the MTA-38 replay corpus extended with local high-detail rows
  When MTA-44 verification completes
  Then every relevant replay row records before/after timing
  And every relevant replay row records before/after face count
  And every relevant replay row records local detail extent, component size, dirty-window scope, and patch scope
  And local-detail rows compare against the face-count and timing impact of equivalent global refinement pressure where practical
  And the task records a verdict of improved, neutral, regressed, or failed for each row
```

## Non-Goals

- Globally increasing source grid spacing to solve local detail needs.
- Adding local CDT islands, native acceleration, public backend selection, or making triangles the
  terrain source of truth.
- Replacing existing edit kernels wholesale unless later planning explicitly scopes that work.
- Exposing local detail internals, patch ids, or raw mesh data in public command responses.

## Business Constraints

- Local high detail must preserve large-terrain scalability.
- The task must not regress the MTA-36 production patch lifecycle or the MTA-43 bounded component
  behavior.
- Hosted evidence must compare local detail against the current baseline and, where practical,
  against the cost of equivalent global refinement.

## Technical Constraints

- `MTA-42` seam contracts and `MTA-43` patch component planning must exist first.
- Local detail state must remain terrain state or terrain-owned overlay state, not generated mesh
  topology.
- The composed height oracle must be deterministic and SketchUp-free at the domain/planning layer.
- SketchUp mutation must remain PatchLifecycle-backed and must preserve no-delete behavior.
- Public MCP contracts and response shapes must remain unchanged.

## Dependencies

- `MTA-43`
- `MTA-42`
- `MTA-39`
- `MTA-38`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- follows `MTA-43` because local detail boundaries can require patch component promotion
- follows `MTA-42` because local detail boundaries must be seam-safe
- informs any later optional local CDT island or native acceleration task
- does not require optional `MTA-41`

## Related Technical Plan

- none yet

## Success Metrics

- Local high-detail replay rows show finer local elevation representation without global source-grid refinement.
- Timing and face-count evidence demonstrates local detail is cheaper than equivalent global refinement pressure where practical.
- Component and seam evidence remains bounded and valid for local detail boundaries.
- Repeated edit, fallback/refusal, no-delete, and reload/readback evidence remains reliable.
- Public terrain command contracts remain unchanged.
