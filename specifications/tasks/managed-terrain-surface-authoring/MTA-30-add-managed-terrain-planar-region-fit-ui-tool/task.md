# Task: MTA-30 Add Managed Terrain Planar Region Fit UI Tool
**Task ID**: `MTA-30`
**Title**: `Add Managed Terrain Planar Region Fit UI Tool`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-05-08`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The managed terrain runtime supports explicit planar region fitting as a separate terrain intent from survey correction. Without a SketchUp-facing UI, users still need to construct planar controls indirectly through MCP requests even when they can see the intended support region and control points in the model.

This task adds a `Planar Region Fit` UI tool after the survey point task has established point-list and support-region UX. It should reuse that control-point foundation while preserving the explicit semantic distinction between planar fitting and survey correction.

## Goals

- Add a `Planar Region Fit` toolbar button/tool under the existing Managed Terrain toolbar.
- Let a user add, remove, inspect, and select planar controls for the active managed terrain edit.
- Show a bounded support region and planar control markers in the viewport.
- Enforce the user-visible requirement for enough planar controls before apply.
- Expose planar-specific tolerance or refusal feedback where supported.
- Apply edits through the existing `planar_region_fit` managed terrain command behavior.

## Acceptance Criteria

```gherkin
Scenario: planar region fit tool is available
  Given the SketchUp extension is loaded
  And the Managed Terrain toolbar is shown
  When the user inspects the toolbar
  Then a Planar Region Fit tool button is available
  And it uses the same Managed Terrain toolbar container as the existing terrain UI tools

Scenario: planar controls can be managed in the shared panel
  Given a managed terrain surface is selected
  And the Planar Region Fit tool is active
  When the user adds planar controls
  Then the shared panel lists the planar controls
  And the user can remove planar controls from the pending request
  And the UI indicates whether enough controls exist for an apply attempt

Scenario: support region and planar markers are visible
  Given the Planar Region Fit tool has a support region and planar controls
  When the user previews the pending edit
  Then the viewport shows the support region
  And the viewport shows planar control markers
  And invalid, out-of-region, or insufficient-control states are indicated before apply

Scenario: planar region fit applies through managed terrain commands
  Given a managed terrain surface is selected
  And the Planar Region Fit tool has valid planar controls and support-region settings
  When the user applies the edit
  Then the edit routes through the existing `planar_region_fit` managed terrain command behavior
  And generated terrain output is refreshed as derived geometry
  And success, refusal, or planar-fit-specific command feedback is user-visible

Scenario: planar UI remains distinct from survey correction
  Given the Planar Region Fit UI is available
  When the Managed Terrain UI is inspected
  Then planar controls are presented as explicit planar-fit intent
  And the UI does not imply that survey point correction is equivalent to planar fitting
```

## Non-Goals

- adding survey point constraint behavior beyond the reusable point-list foundation
- adding corridor transition behavior
- adding new planar fitting math
- changing public MCP planar contracts
- adding implicit planar fitting under survey correction
- adding broad validation dashboards or acceptance verdicts
- adding freeform polygon regions or localized-detail representation changes
- turning planar controls into semantic hardscape objects

## Business Constraints

- Planar region fit UI must keep planar intent explicit and separate from survey correction semantics.
- The workflow must reduce MCP-only trial-and-error for bounded plane edits while preserving managed state, evidence, refusals, and undo posture.
- Unsupported or unsafe planar requests must refuse clearly rather than silently approximating unrelated terrain behavior.
- Semantic hardscape objects remain separate from terrain state.

## Technical Constraints

- Ruby remains the owner of SketchUp extension UI, terrain commands, SketchUp API usage, and model mutation.
- UI-triggered durable edits must route through managed terrain state and command/use-case boundaries or an equivalent managed service path.
- The task must reuse existing `planar_region_fit` command behavior rather than changing terrain edit math.
- Point-list UI must return JSON-serializable command inputs and must not expose raw SketchUp objects across public boundaries.
- Automated coverage should verify planar-control state, support-region request construction, refusal behavior, and command-boundary routing where practical, with hosted SketchUp smoke for real interaction and overlay behavior.

## Dependencies

- `MTA-29`
- `MTA-16`
- existing implemented `planar_region_fit` edit mode
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows `MTA-29` by reusing control-point and support-region UX for a second concrete tool
- complements `MTA-13` by preserving the product distinction between survey correction and explicit planar fitting
- completes the current control-point region UI milestone for existing managed terrain edit modes

## Related Technical Plan

- none yet

## Success Metrics

- Planar Region Fit is available as a tool button in the single Managed Terrain toolbar
- users can create and review a pending planar-fit request through SketchUp UI
- support region and planar control markers are visible before apply
- applied edits route through existing `planar_region_fit` command behavior
- validation includes focused automated checks and hosted SketchUp smoke where practical
