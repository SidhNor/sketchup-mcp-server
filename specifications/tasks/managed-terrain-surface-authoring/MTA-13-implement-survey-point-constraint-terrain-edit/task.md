# Task: MTA-13 Implement Survey Point Constraint Terrain Edit
**Task ID**: `MTA-13`
**Title**: `Implement Survey Point Constraint Terrain Edit`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain workflows need to incorporate measured survey elevations at specific XY locations. Existing terrain edits can set a bounded region to a target height, transition along a corridor, and locally fair terrain after `MTA-06`, but they do not let callers say that the terrain surface should satisfy a set of surveyed `{ x, y, z }` constraints within small tolerances.

This task adds a survey point constraint edit mode for Managed Terrain Surfaces. The first implementation should operate on the current `heightmap_grid` state and use honest evidence to show whether the current grid can satisfy the requested survey constraints without unsafe terrain distortion.

## Goals

- Add a managed terrain edit mode for survey point elevation constraints.
- Treat survey points as target constraints with tolerances, not as vague influence hints.
- Operate on the current `heightmap_grid` v1 terrain state before requiring localized detail zones.
- Preserve fixed controls and preserve zones while applying survey constraints.
- Use completed local fairing behavior without drifting survey constraints beyond tolerance.
- Return per-point before/after/residual evidence that supports review and later validation.
- Refuse or warn when the current grid cannot safely represent the requested constraints.

## Acceptance Criteria

```gherkin
Scenario: survey point constraints update managed terrain state
  Given a Managed Terrain Surface exists with saved heightmap terrain state
  When edit_terrain_surface is called with survey point elevation constraints
  Then the terrain state is updated so supported survey points are satisfied within documented tolerance
  And the derived terrain output is refreshed from the updated state
  And the operation does not edit arbitrary live TIN geometry in place

Scenario: survey point evidence reports residuals
  Given a survey point constraint edit completes
  When the result is reviewed
  Then each survey point includes requested elevation, before elevation, after elevation, residual, tolerance, and status
  And the evidence remains JSON-safe and avoids raw generated face or vertex identifiers

Scenario: constraints and protected areas are respected
  Given survey point constraints overlap fixed controls or preserve zones
  When the edit is evaluated
  Then fixed controls and preserve zones remain protected within documented tolerance
  And conflicting survey points return a structured refusal or warning before unsafe mutation

Scenario: unsupported survey constraint sets fail honestly
  Given survey points are contradictory, too dense for the current grid, outside supported terrain state, or otherwise unsafe
  When the survey constraint edit is requested
  Then the command returns a structured refusal or warning with enough evidence to explain the representational limit
  And callers are not expected to rely on generated SketchUp mesh geometry as the terrain source of truth
```

## Non-Goals

- implementing localized survey/detail zones in this task
- changing the persisted terrain payload kind or schema version by default
- adding polygon or freeform edit regions
- adding broad civil grading, drainage, or terrain simulation behavior
- exposing solver internals, generated face identifiers, generated vertex identifiers, or partial-regeneration strategy in public responses
- mutating semantic hardscape objects as terrain state

## Business Constraints

- survey point editing must support practical measured-height workflows without falling back to `eval_ruby`
- tolerances must be explicit enough for review and downstream validation planning
- unsupported or under-resolved survey inputs must fail honestly rather than silently creating misleading terrain
- localized detail work remains an escalation path when v1 heightmap resolution is insufficient

## Technical Constraints

- survey coordinates and elevations are expressed in the stored terrain state's public-meter coordinate frame
- the first implementation operates on materialized `heightmap_grid` state through terrain-domain behavior
- fixed controls, preserve zones, local fairing, storage, and output regeneration must use existing managed terrain boundaries
- local fairing must not move survey constraints outside accepted tolerance
- responses and refusals must remain JSON-serializable and must not expose raw SketchUp objects
- request schema, runtime validation, command dispatch, native fixtures, README examples, and tests must stay in sync for any public contract change

## Dependencies

- `MTA-04`
- `MTA-06`
- `MTA-10`
- `MTA-12`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-06` so survey constraints can reuse constraint-preserving fairing behavior
- follows `MTA-12` so circular local regions and preserve zones are available for survey workflows when needed
- may trigger `MTA-11` if v1 heightmap state cannot satisfy representative survey constraints within acceptable tolerance

## Related Technical Plan

- none yet

## Success Metrics

- representative survey point constraint edits complete without `eval_ruby` or live-TIN surgery
- per-point residual evidence shows which survey constraints were satisfied, warned, or refused
- fixed controls and preserve zones remain protected while survey constraints are applied
- the task records clear evidence for whether localized survey/detail zones are needed as a follow-up
