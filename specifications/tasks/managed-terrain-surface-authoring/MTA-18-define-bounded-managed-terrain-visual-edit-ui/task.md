# Task: MTA-18 Implement Minimal Bounded Managed Terrain Visual Edit UI
**Task ID**: `MTA-18`
**Title**: `Implement Minimal Bounded Managed Terrain Visual Edit UI`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-30`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain edit commands are safe and evidence-producing, but they are too indirect as the only SketchUp-facing interaction path for fine visual grading. Small shoulders, tight hardscape-adjacent transitions, and local terrain feel currently require callers to infer numeric bounds and controls, apply an edit, sample the result, and repeat. That loop protects semantics and metadata, but it is slower than a direct SketchUp interaction for cases where the user is already working visually in the model.

This task implements the smallest useful SketchUp-facing UI slice for Managed Terrain Surface Authoring. The first slice should prove that a user can invoke one supported bounded terrain edit from SketchUp toolbar-driven interaction while still routing durable changes through the managed terrain command/use-case path. It should deliberately avoid a broad visual grading system, live sculpting, or custom region-drawing workflow until the managed UI boundary is proven.

## Goals

- Add the initial `Managed Terrain` SketchUp toolbar container and its first bounded edit tool button.
- Let a user apply the existing `target_height` managed terrain edit mode as a circular brush to an already selected managed terrain surface.
- Collect only the bounded numeric parameters needed for the first-slice circular target-height brush through a small settings dialog.
- Apply durable edits through managed terrain command/use-case behavior or an equivalent managed service path.
- Preserve terrain state as the source of truth and generated mesh as derived output.
- Surface basic success or refusal feedback from the managed terrain command result.
- Leave richer visual selection, preview, review, and follow-up orchestration for later tasks.

## Acceptance Criteria

```gherkin
Scenario: minimal terrain edit UI entrypoint is available
  Given the SketchUp extension is loaded
  When the user opens the `Target Height Brush` button on the `Managed Terrain` toolbar
  Then the user is presented with a bounded circular brush terrain edit flow
  And the flow supports exactly one existing managed terrain edit mode: target_height
  And bounded brush parameters are captured through a settings dialog
  And the flow does not expose broad sculpting, stroke replay, pressure-sensitive brush behavior, or raw TIN editing

Scenario: selected managed terrain can be edited through the UI
  Given a managed terrain surface is selected in SketchUp
  And the user enters valid bounded circular brush parameters for target-height editing
  When the user applies the edit through the UI
  Then durable terrain changes are represented in managed terrain state
  And generated terrain output is refreshed as derived geometry
  And the UI reports the command success in a user-visible way

Scenario: invalid selection or unsafe parameters refuse without mesh surgery
  Given the selected context is invalid or the entered parameters are refused by the managed terrain command
  When the user attempts to apply the edit through the UI
  Then the UI reports the refusal in a user-visible way
  And raw SketchUp terrain mesh is not edited as durable source state

Scenario: managed command boundaries and undo posture are preserved
  Given a valid terrain edit is applied through the UI
  When the result is inspected or undone
  Then the mutation uses the existing managed terrain command or service path
  And undo behavior is coherent for the first slice where practical
  And any remaining hosted undo limitation is documented as a validation gap

Scenario: validation and review ownership stays outside the UI
  Given a terrain edit has been applied through the UI
  When the user or agent needs to accept the result
  Then MCP sampling, terrain profile measurement, validation, labels, redrape, and capture workflows remain available as follow-up steps
  And the UI does not redefine sampling, validation, redrape, labeling, or capture ownership
```

## Non-Goals

- implementing a polished or comprehensive visual grading workflow
- adding custom click-and-drag region drawing or continuous brush strokes
- adding live preview overlays or preview geometry
- adding multiple UI-driven terrain edit modes in this first slice
- adding multiple brush types in this first slice
- adding rich evidence panels or validation dashboards
- adding broad freeform sculpting or pressure-sensitive brush systems
- replaying arbitrary mouse strokes as the public terrain edit contract
- editing generated SketchUp terrain mesh as durable source state
- changing `edit_terrain_surface` into a live sculpting protocol
- replacing MCP sampling, profile measurement, validation, labeling, redrape, or capture workflows
- modeling surveyed hardscape slabs as terrain state
- solving localized-detail representation limits that belong to `MTA-11`

## Business Constraints

- The UI must make visual grading faster without weakening managed terrain semantics.
- The first slice should prove a small SketchUp-facing command handoff, not broad terrain-authoring ambition.
- The user-facing workflow must remain understandable to SketchUp users and still produce evidence usable by agent-driven review.
- Semantic hardscape objects remain separate from terrain state.

## Technical Constraints

- Ruby remains the owner of SketchUp extension UI, terrain commands, SketchUp API usage, and model mutation.
- The root loader must remain small; UI wiring belongs in the support tree.
- Toolbar icons should use packaged SVG assets.
- UI-triggered durable edits must use managed terrain state and command/use-case boundaries or an equivalent managed service path.
- Mutating UI actions must preserve coherent SketchUp undo behavior where practical.
- UI outputs and any MCP-facing handoff data must remain JSON-serializable and must not expose raw SketchUp objects.
- The first slice should use an already implemented managed terrain edit mode rather than introducing new terrain math.
- The first slice must include focused automated coverage where the UI command boundary can be tested outside SketchUp and SketchUp-hosted smoke coverage where practical.

## Dependencies

- `MTA-04`
- `MTA-12`
- existing implemented `target_height` circular region support
- `MTA-15`
- [Terrain Session Exposes Local Detail, Hardscape, Sampling, And Identity Gaps](../../../signals/2026-04-30-terrain-session-exposes-local-detail-hardscape-and-identity-gaps.md)
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows the terrain session signal's supplemental finding that visual terrain grading is too slow through MCP-only trial-and-error
- depends on existing managed edit modes rather than creating a new terrain source model or new terrain math
- informs later visual terrain UI tasks for custom selection tools, preview overlays, richer evidence review, and multi-mode workflows
- complements `MTA-11`; UI improves interaction speed, while localized detail zones address representation fidelity

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- one minimal SketchUp-facing UI entrypoint can apply one existing managed terrain edit mode to a selected managed terrain surface
- the UI path applies durable changes through managed terrain state rather than raw generated mesh mutation
- invalid selection or refused parameters produce user-visible refusal feedback without mutating raw mesh
- the implementation is validated by focused automated checks and SketchUp-hosted smoke coverage where practical, or the hosted gap is explicitly called out
- broad sculpting, stroke replay, and direct TIN surgery remain explicitly out of scope
