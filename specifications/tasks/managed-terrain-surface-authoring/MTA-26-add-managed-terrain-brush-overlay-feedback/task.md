# Task: MTA-26 Add Managed Terrain Brush Overlay Feedback
**Task ID**: `MTA-26`
**Title**: `Add Managed Terrain Brush Overlay Feedback`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-05-08`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

`MTA-18` proved the first SketchUp-facing managed terrain edit path, but the active brush still has weak in-model feedback. A user can adjust bounded target-height brush parameters and apply an edit, yet the model view does not clearly show the current support radius, blend or falloff area, or whether the hovered point is a usable managed terrain target before clicking.

This task adds the first bounded visual feedback layer for the existing `Target Height Brush`. It should make the current brush state visible while preserving the managed terrain command boundary, terrain state source of truth, and click-to-apply behavior already established by `MTA-18`.

## Goals

- Show the active target-height brush footprint in the SketchUp viewport before apply.
- Distinguish the full-strength support area from the blend or falloff area where practical.
- Surface valid and invalid terrain hover states without mutating terrain state.
- Keep overlay behavior transient and tied to the active SketchUp tool.
- Establish the minimum overlay feedback foundation needed by later managed terrain UI tools.

## Acceptance Criteria

```gherkin
Scenario: active target-height brush shows its support footprint
  Given a managed terrain surface is selected
  And the Target Height Brush tool is active
  When the user moves the cursor over a valid terrain point
  Then the SketchUp viewport shows the current circular brush support area
  And the displayed support area reflects the current brush radius setting

Scenario: active target-height brush shows falloff information
  Given the Target Height Brush tool has a non-zero blend distance
  When the user hovers over a valid terrain point
  Then the viewport distinguishes the full-strength brush area from the blend or falloff area
  And changing the brush radius or blend setting updates the visual cue before the next apply

Scenario: invalid hover target is visible without applying an edit
  Given the Target Height Brush tool is active
  When the user hovers over a point that cannot produce a managed terrain brush edit
  Then the viewport or status feedback indicates the target is invalid
  And no terrain edit command is applied
  And generated terrain mesh is not edited as durable source state

Scenario: overlay remains transient
  Given the Target Height Brush tool has displayed brush feedback
  When the user deactivates the tool or closes the managed terrain UI
  Then the brush feedback is removed from the viewport
  And no persistent SketchUp geometry is created for the overlay

Scenario: existing target-height apply behavior is preserved
  Given the Target Height Brush overlay is visible on a valid managed terrain point
  When the user clicks to apply the edit
  Then the edit still routes through the managed terrain command or equivalent managed service path
  And success or refusal feedback remains user-visible
```

## Non-Goals

- adding new managed terrain edit modes
- adding a shared multi-tool panel
- adding corridor, survey point, or planar control overlays
- adding continuous stroke replay or drag painting
- adding persistent preview geometry
- changing public MCP terrain edit contracts
- editing generated terrain mesh as durable source state
- replacing MCP sampling, profile measurement, validation, labeling, redrape, or capture workflows

## Business Constraints

- Visual feedback must make bounded terrain edits easier to understand without weakening managed terrain semantics.
- The first overlay slice must remain focused on the existing target-height tool rather than becoming a broad visual grading system.
- SketchUp users must be able to distinguish whether a click will target managed terrain before applying an edit.
- Semantic hardscape objects remain separate from terrain state.

## Technical Constraints

- Ruby remains the owner of SketchUp extension UI, SketchUp API usage, and model mutation.
- Overlay feedback must be transient tool/view feedback, not durable terrain source state.
- UI-triggered durable edits must continue to route through managed terrain state and command/use-case boundaries or an equivalent managed service path.
- The implementation must not introduce terrain edit math or public MCP contract changes.
- Focused automated coverage should verify overlay state and command-boundary behavior where practical, with SketchUp-hosted smoke coverage for real viewport behavior.

## Dependencies

- `MTA-18`
- `MTA-04`
- `MTA-12`
- existing implemented `target_height` circular region support
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows `MTA-18` as the first visual feedback refinement for the initial Managed Terrain toolbar button
- blocks `MTA-27` if the shared round-brush tools are expected to reuse the same overlay feedback family
- informs later corridor and control-point overlay tasks without implementing their distinct visual cue families

## Related Technical Plan

- [plan.md](./plan.md)

## Success Metrics

- the active Target Height Brush shows a viewport cue for its current radius on valid managed terrain hover
- blend or falloff state is visible or explicitly represented in the active brush feedback
- invalid hover states refuse visibly before apply and do not mutate terrain
- click-to-apply behavior still uses managed terrain command boundaries
- automated checks and hosted SketchUp smoke cover the changed behavior where practical
