# Task: MTA-18 Define Bounded Managed Terrain Visual Edit UI
**Task ID**: `MTA-18`
**Title**: `Define Bounded Managed Terrain Visual Edit UI`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-30`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain edit commands are safe and evidence-producing, but they are too indirect as the primary interface for fine visual grading. Small shoulders, tight hardscape-adjacent transitions, and local terrain feel currently require callers to infer numeric bounds and controls, apply an edit, sample the result, and repeat. That loop protects semantics and metadata, but it is slower than a direct SketchUp visual interaction for cases where the user is judging whether a local shoulder or plane reads correctly.

This task defines the first bounded SketchUp-facing visual edit UI slice for Managed Terrain Surface Authoring. The UI must improve target selection, local support sizing, operation parameter adjustment, and apply/review ergonomics while preserving the managed terrain source-of-truth model, command/use-case boundaries, undo behavior, and structured evidence.

## Goals

- Define a first bounded visual terrain edit UI slice for Managed Terrain Surfaces.
- Let users visually select or preview local terrain support regions before applying supported managed terrain edits.
- Support bounded parameter controls such as operation mode, support size, blend distance, fairing strength, target elevation, or planar controls where appropriate for the chosen first slice.
- Apply durable edits through managed terrain command/use-case behavior or an equivalent managed service path.
- Preserve terrain state as the source of truth and generated mesh as derived output.
- Surface success, refusal, and evidence summaries so MCP sampling, profile validation, redrape, labeling, and capture workflows can continue after visual editing.

## Acceptance Criteria

```gherkin
Scenario: bounded visual terrain edit scope is defined
  Given the Managed Terrain Surface Authoring PRD and HLD allow bounded visual controls
  When the MTA-18 technical plan is reviewed
  Then it identifies the first supported visual edit workflow and the SketchUp UI mechanism to use
  And it defines which managed terrain edit mode or modes the first UI slice can invoke
  And it excludes broad freeform sculpting and raw TIN editing

Scenario: visual UI applies through managed terrain state
  Given a user applies a bounded visual terrain edit
  When the resulting design is reviewed
  Then durable terrain changes are represented in managed terrain state
  And generated terrain mesh remains derived output rather than source state
  And the edit produces success or refusal information compatible with managed terrain evidence review

Scenario: visual edit workflow preserves validation handoff
  Given a visual terrain edit has been applied
  When the user or agent needs to accept the result
  Then MCP sampling, terrain profile measurement, validation, labels, redrape, and capture workflows remain available as follow-up steps
  And the UI task does not redefine sampling or validation ownership

Scenario: unsupported visual editing behavior is refused or excluded
  Given a desired interaction requires continuous sculpting, stroke replay, pressure-sensitive brush behavior, or direct live-TIN surgery
  When the first visual UI slice is scoped
  Then that behavior is explicitly excluded or deferred
  And the task preserves bounded managed terrain edit semantics
```

## Non-Goals

- implementing the UI before a technical plan is written
- adding broad freeform sculpting or pressure-sensitive brush systems
- replaying arbitrary mouse strokes as the public terrain edit contract
- editing generated SketchUp terrain mesh as durable source state
- changing `edit_terrain_surface` into a live sculpting protocol
- replacing MCP sampling, profile measurement, validation, labeling, redrape, or capture workflows
- modeling surveyed hardscape slabs as terrain state
- solving localized-detail representation limits that belong to `MTA-11`

## Business Constraints

- The UI must make visual grading faster without weakening managed terrain semantics.
- The first slice should focus on bounded terrain feel and local correction workflows, not broad terrain-authoring ambition.
- The user-facing workflow must remain understandable to SketchUp users and still produce evidence usable by agent-driven review.
- Semantic hardscape objects remain separate from terrain state.

## Technical Constraints

- Ruby remains the owner of SketchUp extension UI, terrain commands, SketchUp API usage, and model mutation.
- The root loader must remain small; UI wiring belongs in the support tree.
- UI-triggered durable edits must use managed terrain state and command/use-case boundaries or an equivalent managed service path.
- Mutating UI actions must preserve coherent SketchUp undo behavior where practical.
- UI outputs and any MCP-facing handoff data must remain JSON-serializable and must not expose raw SketchUp objects.
- The first slice must define verification across unit-level command behavior and SketchUp-hosted UI or smoke coverage where practical.

## Dependencies

- `MTA-04`
- `MTA-06`
- `MTA-12`
- `MTA-15`
- `MTA-16`
- [Terrain Session Exposes Local Detail, Hardscape, Sampling, And Identity Gaps](../../../signals/2026-04-30-terrain-session-exposes-local-detail-hardscape-and-identity-gaps.md)
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows the terrain session signal's supplemental finding that visual terrain grading is too slow through MCP-only trial-and-error
- depends on existing managed edit modes rather than creating a new terrain source model
- informs future UI implementation tasks after the first slice, UI mechanism, preview/apply posture, and validation handoff are planned
- complements `MTA-11`; UI improves interaction speed, while localized detail zones address representation fidelity

## Related Technical Plan

- none yet

## Success Metrics

- the technical plan identifies one coherent first visual edit workflow and the SketchUp UI mechanism for it
- the planned UI path applies durable changes through managed terrain state rather than raw generated mesh mutation
- success/refusal/evidence handoff is defined well enough for MCP sampling and validation follow-up
- broad sculpting, stroke replay, and direct TIN surgery remain explicitly out of scope
