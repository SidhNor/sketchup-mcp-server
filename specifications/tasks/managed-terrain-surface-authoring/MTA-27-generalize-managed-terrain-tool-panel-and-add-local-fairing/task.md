# Task: MTA-27 Generalize Managed Terrain Tool Panel And Add Local Fairing
**Task ID**: `MTA-27`
**Title**: `Generalize Managed Terrain Tool Panel And Add Local Fairing`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-05-08`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The initial managed terrain UI from `MTA-18` is intentionally shaped around one toolbar button and one target-height settings dialog. That proved the command handoff, but it does not yet prove the intended `Managed Terrain` toolbar model where one toolbar container can host multiple terrain tools and a shared panel can show tool-specific controls.

This task generalizes the current target-height-specific UI just enough to support a second round-brush tool: `Local Fairing`. It should prove shared selection, status, refusal, and parameter-panel behavior across two existing managed terrain edit modes without adding new terrain math or prematurely building abstractions for corridor or control-point tools.

## Goals

- Convert the current target-height-specific dialog into a shared Managed Terrain tool panel.
- Keep one `Managed Terrain` toolbar container while adding a second toolbar button for `Local Fairing`.
- Let the shared panel switch between target-height and local-fairing settings based on the active tool.
- Apply local fairing through the existing managed terrain command path.
- Reuse the round-brush interaction and overlay family for both target-height and local-fairing tools.
- Preserve shared selected-terrain, status, success, and refusal feedback.

## Acceptance Criteria

```gherkin
Scenario: managed terrain toolbar hosts two round-brush tools
  Given the SketchUp extension is loaded
  When the Managed Terrain toolbar is shown
  Then the toolbar contains a Target Height Brush button
  And the toolbar contains a Local Fairing button
  And the toolbar remains one toolbar container rather than separate per-tool toolbars

Scenario: shared panel changes with the active tool
  Given the Managed Terrain panel is open
  When the user activates the Target Height Brush tool
  Then the panel shows target-height brush settings
  When the user activates the Local Fairing tool
  Then the panel shows local-fairing settings
  And the shared selected-terrain and status area remains available

Scenario: local fairing applies through managed terrain commands
  Given a managed terrain surface is selected
  And the Local Fairing tool is active with valid fairing parameters
  When the user applies the fairing brush through the UI
  Then the edit routes through the existing `local_fairing` managed terrain command behavior
  And generated terrain output is refreshed as derived geometry
  And the UI reports success or refusal in a user-visible way

Scenario: round-brush overlay behavior is reused
  Given either Target Height Brush or Local Fairing is active
  When the user hovers over a valid managed terrain point
  Then the viewport shows the relevant round-brush support cue for the active tool
  And the cue reflects the active tool's radius and blend settings where applicable

Scenario: unsupported future tool families are not implied
  Given the shared Managed Terrain panel supports target-height and local-fairing tools
  When the UI is inspected
  Then it does not expose corridor, survey point, planar fit, continuous stroke, or validation-dashboard behavior
```

## Non-Goals

- adding corridor transition UI
- adding survey point constraint UI
- adding planar region fit UI
- adding control-point list UX
- adding continuous brush strokes or pressure-sensitive sculpting
- changing `local_fairing` terrain math or public MCP contracts
- adding validation verdict ownership to the UI
- creating multiple toolbar containers for managed terrain tools

## Business Constraints

- The UI must clarify the distinction between the `Managed Terrain` toolbar container and individual terrain tool buttons.
- The second tool must prove shared UI behavior through a real existing terrain command rather than a placeholder.
- The panel should improve SketchUp-facing parameter adjustment without weakening managed terrain state, evidence, refusal, or undo posture.
- Semantic hardscape objects remain separate from terrain state.

## Technical Constraints

- Ruby remains the owner of SketchUp extension UI, terrain commands, SketchUp API usage, and model mutation.
- UI-triggered durable edits must route through managed terrain state and command/use-case boundaries or an equivalent managed service path.
- The shared panel must remain a controller over existing managed terrain commands, not a second terrain runtime.
- The task must reuse existing `target_height` and `local_fairing` edit behavior rather than adding new terrain math.
- Automated coverage should verify panel state, tool switching, request construction, and refusal behavior where practical, with hosted SketchUp smoke for toolbar/panel/tool lifecycle.

## Dependencies

- `MTA-18`
- `MTA-26`
- `MTA-06`
- existing implemented `target_height` and `local_fairing` edit modes
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows `MTA-26` by reusing the round-brush overlay family for a second tool
- blocks `MTA-28`, `MTA-29`, and `MTA-30` by establishing the shared toolbar, panel, and tool-selection model
- supersedes the target-height-specific panel shape from `MTA-18` while preserving the `Managed Terrain` toolbar container concept

## Related Technical Plan

- none yet

## Success Metrics

- one Managed Terrain toolbar hosts at least Target Height Brush and Local Fairing buttons
- one shared panel switches visible settings by active tool
- Local Fairing can be applied from SketchUp UI through existing managed terrain command behavior
- shared selected-terrain, status, success, and refusal UX works for both round-brush tools
- validation includes focused automated checks and hosted SketchUp smoke where practical
