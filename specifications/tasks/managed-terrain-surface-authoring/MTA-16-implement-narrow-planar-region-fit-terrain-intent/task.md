# Task: MTA-16 Implement Narrow Planar Region Fit Terrain Intent
**Task ID**: `MTA-16`
**Title**: `Implement Narrow Planar Region Fit Terrain Intent`
**Status**: `implemented`
**Priority**: `P1`
**Date**: `2026-04-28`

## Linked HLD

- [Managed Terrain Surface Authoring](specifications/hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The terrain modelling signal showed a repeated expectation mismatch: callers often use regional survey correction when they intend a coherent planar or near-planar surface. The current `survey_point_constraint` regional scope behaves as a smooth correction field. That can be useful, but it does not make planar intent explicit and can produce warps when sparse or non-coplanar controls are supplied.

This task adds a narrow explicit planar region fit intent under the existing terrain edit surface. The first implementation should cover the common useful case: fitting a bounded mutable region to one coherent plane from supplied controls, while preserving the distinction between planar replacement and the existing regional survey correction field.

## Goals

- Implement planar region fit as an explicit `edit_terrain_surface` intent rather than implicit behavior of regional survey correction.
- Support a narrow first slice for three or more controls over a bounded rectangle or circle support region.
- Fit coplanar and near-coplanar controls to a coherent plane and report control residual evidence.
- Refuse or warn on non-coplanar, contradictory, close-control, preserve-zone, fixed-control, or grid-spacing cases that the current `heightmap_grid` model cannot represent safely.
- Return evidence that explains the fitted plane, residuals, changed region, preserve-zone impact, and grid-spacing limits.

## Acceptance Criteria

```gherkin
Scenario: explicit planar intent fits a bounded region
  Given a managed heightmap_grid terrain and three or more coplanar planar controls
  When edit_terrain_surface is called with the explicit planar region fit intent
  Then mutable samples in the support region are adjusted toward the fitted plane within documented tolerance
  And the result includes fitted-plane, residual, changed-region, and preserve-zone evidence

Scenario: planar intent is separate from regional survey correction
  Given current survey_point_constraint regional behavior remains a smooth correction field
  When planar region fit is added
  Then the task does not redefine regional correction as planar fitting
  And callers must opt into the explicit planar intent to request planar replacement

Scenario: unsafe planar controls refuse or warn honestly
  Given a planar fit request uses non-coplanar, contradictory, too-close, or preserve-zone-conflicting controls
  When the result is reviewed
  Then unsupported exact-fit expectations are reported as structured warnings or refusals
  And the response does not hide the issue as a warped correction field
```

## Non-Goals

- changing the current `survey_point_constraint` default behavior
- implementing broad warped exact-fit behavior for arbitrary non-coplanar controls
- adding freeform polygon terrain regions
- adding broad civil grading, drainage, or terrain simulation behavior
- implementing monotonic profile constraints, edge-fall tools, or boundary-preserving patch edit modes
- moving profile sampling or validation policy into terrain mutation

## Business Constraints

- Planar fit should make the common grading intent easier without turning managed terrain into a broad sculpting system.
- Unsupported or non-coplanar control sets must fail honestly rather than creating visually misleading terrain.
- The public tool surface should stay compact and prefer extending `edit_terrain_surface` over adding a new public tool.

## Technical Constraints

- The implementation must use the current materialized `heightmap_grid` v1 terrain model unless it explicitly refuses cases that require localized detail zones.
- SketchUp API behavior must remain behind the existing terrain adapter boundaries.
- Public outputs must remain JSON-serializable and should not expose generated mesh face or vertex identifiers.
- Preserve zones and fixed controls must remain respected by the planar fit implementation.
- Runtime schema, dispatcher, native contract fixtures, docs, and tests must move together for any public request-shape change.

## Dependencies

- `MTA-13`
- `MTA-14`
- `MTA-15`
- [Terrain modelling signal](specifications/signals/2026-04-28-terrain-modelling-session-reveals-planar-intent-and-profile-qa-gaps.md)

## Relationships

- follows `MTA-15` so current regional correction semantics are discoverable before planar behavior is added
- may inform `MTA-11` if localized detail or finer spacing is required for representative planar fit cases
- establishes the first explicit planar intent under `edit_terrain_surface`

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative coplanar and near-coplanar planar fit requests succeed with tested residual and changed-region evidence
- non-coplanar, contradictory, preserve-zone, fixed-control, and grid-spacing conflicts produce structured warnings or refusals
- the implementation preserves the distinction between current regional correction and explicit planar intent
- runtime schema, docs, native contract fixtures, and terrain-domain tests describe the same planar fit contract
