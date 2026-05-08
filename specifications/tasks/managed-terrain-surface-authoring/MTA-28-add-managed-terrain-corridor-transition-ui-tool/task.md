# Task: MTA-28 Add Managed Terrain Corridor Transition UI Tool
**Task ID**: `MTA-28`
**Title**: `Add Managed Terrain Corridor Transition UI Tool`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-05-08`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Target-height and local-fairing tools share a round-brush interaction shape. Corridor transitions are different: a user needs to define a linear transition with start and end controls, elevations, width, and side-blend behavior. Treating this as a brush would hide the geometric intent that the managed terrain contract already makes explicit.

This task adds a SketchUp-facing `Corridor Transition` tool as the first non-round-brush managed terrain UI tool. It should reuse the shared Managed Terrain toolbar and panel foundation while adding corridor-specific input and visual cues over the existing `corridor_transition` command behavior.

## Goals

- Add a `Corridor Transition` toolbar button/tool under the existing Managed Terrain toolbar.
- Let a user define or edit the corridor start and end controls needed by the existing corridor transition mode.
- Expose bounded corridor parameters such as control elevations, width, and side blend.
- Show corridor-specific visual cues in the viewport.
- Apply edits through the existing `corridor_transition` managed terrain command behavior.
- Keep corridor UI separate from survey and planar point-list workflows.

## Acceptance Criteria

```gherkin
Scenario: corridor transition tool is available in the managed terrain toolbar
  Given the SketchUp extension is loaded
  And the Managed Terrain toolbar is shown
  When the user inspects the toolbar
  Then a Corridor Transition tool button is available
  And it uses the same Managed Terrain toolbar container as the existing terrain UI tools

Scenario: corridor parameters can be collected visually
  Given a managed terrain surface is selected
  And the Corridor Transition tool is active
  When the user defines start and end corridor controls with valid elevations
  Then the shared panel shows the corridor controls
  And the panel exposes corridor width and side-blend settings

Scenario: corridor overlay shows transition geometry
  Given the Corridor Transition tool has valid start and end controls
  When the user previews the corridor before apply
  Then the viewport shows the corridor centerline
  And the viewport shows the full-width corridor band
  And the viewport shows side-blend shoulder information where applicable
  And endpoint cap information is visible or otherwise represented

Scenario: corridor transition applies through managed terrain commands
  Given a managed terrain surface is selected
  And the Corridor Transition tool has valid corridor controls and parameters
  When the user applies the edit
  Then the edit routes through the existing `corridor_transition` managed terrain command behavior
  And generated terrain output is refreshed as derived geometry
  And the UI reports success or refusal in a user-visible way

Scenario: corridor task does not introduce control-point region tools
  Given the Corridor Transition UI is available
  When the Managed Terrain UI is inspected
  Then survey point constraint and planar region fit point-list workflows are not introduced by this task
```

## Non-Goals

- adding survey point constraint UI
- adding planar region fit UI
- adding shared point-list controls
- adding new corridor terrain math
- changing public MCP corridor contracts
- adding continuous stroke behavior
- adding validation verdict ownership or review dashboards
- treating corridor controls as semantic hardscape objects

## Business Constraints

- Corridor UI must make corridor-grade intent explicit rather than presenting it as a generic brush edit.
- The workflow must reduce MCP-only trial-and-error for linear terrain transitions while preserving managed state and evidence.
- The UI must not imply survey correction, planar fitting, or hardscape mutation behavior.
- Semantic hardscape objects remain separate from terrain state.

## Technical Constraints

- Ruby remains the owner of SketchUp extension UI, terrain commands, SketchUp API usage, and model mutation.
- UI-triggered durable edits must route through managed terrain state and command/use-case boundaries or an equivalent managed service path.
- The task must reuse existing `corridor_transition` command behavior rather than changing terrain edit math.
- Corridor visual cues are a distinct overlay family from round-brush cues.
- Automated coverage should verify corridor request construction, panel/tool state, and refusal behavior where practical, with hosted SketchUp smoke for real interaction and overlay behavior.

## Dependencies

- `MTA-27`
- `MTA-05`
- existing implemented `corridor_transition` edit mode
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows `MTA-27` by adding the first non-round-brush tool to the shared Managed Terrain panel
- informs later control-point tools by proving the tool registry can host a distinct visual cue family
- remains separate from `MTA-29` and `MTA-30`, which own survey and planar point-list UX

## Related Technical Plan

- none yet

## Success Metrics

- Corridor Transition is available as a tool button in the single Managed Terrain toolbar
- valid corridor controls and parameters can be collected through SketchUp UI
- the viewport shows corridor geometry cues before apply
- applied edits route through existing `corridor_transition` command behavior
- validation includes focused automated checks and hosted SketchUp smoke where practical
