# Task: MTA-29 Add Managed Terrain Survey Point Constraint UI Tool
**Task ID**: `MTA-29`
**Title**: `Add Managed Terrain Survey Point Constraint UI Tool`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-05-08`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The managed terrain runtime already supports survey point constraint edits, but invoking them through MCP-only request construction is indirect for SketchUp users working from visible measured points or local terrain defects. Survey correction also introduces a different UI primitive from round brushes and corridors: a bounded support region plus a managed list of control points with tolerances.

This task adds the first control-point region UI tool by exposing `survey_point_constraint` through the Managed Terrain toolbar and shared panel. It should introduce point-list and support-region interaction through one concrete tool before planar controls reuse or extend the same foundation in a later task.

## Goals

- Add a `Survey Point Constraint` toolbar button/tool under the existing Managed Terrain toolbar.
- Let a user add, remove, inspect, and select survey points for the active managed terrain edit.
- Show a bounded support region and survey point markers in the viewport.
- Expose survey-specific settings such as correction scope and point tolerance.
- Apply edits through the existing `survey_point_constraint` managed terrain command behavior.
- Establish reusable control-point region UX for later planar region fit UI.

## Acceptance Criteria

```gherkin
Scenario: survey point constraint tool is available
  Given the SketchUp extension is loaded
  And the Managed Terrain toolbar is shown
  When the user inspects the toolbar
  Then a Survey Point Constraint tool button is available
  And it uses the same Managed Terrain toolbar container as the existing terrain UI tools

Scenario: survey points can be managed in the shared panel
  Given a managed terrain surface is selected
  And the Survey Point Constraint tool is active
  When the user adds valid survey points
  Then the shared panel lists the survey points
  And the user can remove survey points from the pending request
  And survey point tolerance is visible or editable according to the supported workflow

Scenario: support region and survey markers are visible
  Given the Survey Point Constraint tool has survey points and a support region
  When the user previews the pending edit
  Then the viewport shows the support region
  And the viewport shows survey point markers
  And invalid or out-of-region points are indicated before apply

Scenario: survey correction applies through managed terrain commands
  Given a managed terrain surface is selected
  And the Survey Point Constraint tool has valid survey points, support region, and correction settings
  When the user applies the edit
  Then the edit routes through the existing `survey_point_constraint` managed terrain command behavior
  And generated terrain output is refreshed as derived geometry
  And success, refusal, or survey-specific command feedback is user-visible

Scenario: planar region fit is not introduced by the survey task
  Given the Survey Point Constraint UI is available
  When the Managed Terrain UI is inspected
  Then planar region fit controls and planar-control validation are not introduced by this task
```

## Non-Goals

- adding planar region fit UI
- adding corridor transition behavior
- adding new survey correction math
- changing public MCP survey contracts
- adding implicit planar fitting under survey correction
- adding broad validation dashboards or acceptance verdicts
- adding continuous stroke behavior
- turning survey points into semantic hardscape objects

## Business Constraints

- Survey correction UI must preserve the distinction between smooth survey correction fields and explicit planar fitting.
- The workflow must make measured-point correction easier in SketchUp without hiding command refusals or evidence.
- Survey point UI must not imply that regional correction creates a forced plane.
- Semantic hardscape objects remain separate from terrain state.

## Technical Constraints

- Ruby remains the owner of SketchUp extension UI, terrain commands, SketchUp API usage, and model mutation.
- UI-triggered durable edits must route through managed terrain state and command/use-case boundaries or an equivalent managed service path.
- The task must reuse existing `survey_point_constraint` command behavior rather than changing terrain edit math.
- Point-list UI must return JSON-serializable command inputs and must not expose raw SketchUp objects across public boundaries.
- Automated coverage should verify point-list state, support-region request construction, refusal behavior, and command-boundary routing where practical, with hosted SketchUp smoke for real interaction and overlay behavior.

## Dependencies

- `MTA-27`
- `MTA-13`
- existing implemented `survey_point_constraint` edit mode
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows `MTA-27` by adding the first control-point region tool to the shared Managed Terrain panel
- blocks `MTA-30` by establishing reusable point-list and support-region UX
- complements `MTA-16` by preserving the product distinction between survey correction and explicit planar fitting

## Related Technical Plan

- none yet

## Success Metrics

- Survey Point Constraint is available as a tool button in the single Managed Terrain toolbar
- users can create and review a pending survey-point request through SketchUp UI
- support region and survey markers are visible before apply
- applied edits route through existing `survey_point_constraint` command behavior
- validation includes focused automated checks and hosted SketchUp smoke where practical
