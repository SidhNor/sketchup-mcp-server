# Task: MTA-06 Implement Local Terrain Fairing Kernel
**Task ID**: `MTA-06`
**Title**: `Implement Local Terrain Fairing Kernel`
**Status**: `planned`
**Priority**: `P1`
**Date**: `2026-04-24`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain workflows need a way to improve local roughness, harsh triangulation artifacts, and abrupt transitions without falling back to manual mesh cleanup. “Smooth” or “fair” is too vague to implement safely unless the task defines measurable behavior and evidence.

This task adds a local terrain fairing kernel, exposed through the existing `edit_terrain_surface` terrain edit surface, that operates on materialized terrain state. It should improve a bounded local region according to a measurable roughness, variance, or continuity proxy while preserving fixed controls and preserve zones.

Local Unreal Engine Landscape source inspection supports starting with bounded neighborhood-average smoothing controlled by strength, kernel radius, and region falloff. That research is implementation input only; public naming, runtime ownership, and evidence shape remain product-shaped for SketchUp MCP.

## Goals

- define a concrete local fairing edit contract with measurable before/after behavior
- expose the supported fairing behavior as a narrow operation mode on the existing terrain edit command rather than as a broad smoothing tool
- support bounded fairing regions, fixed controls, preserve zones, and blend boundary behavior
- update terrain state and refresh derived output through the managed terrain flow, using current dirty-region and partial-output support where safe
- return before/after evidence for roughness or continuity change, controls, preserve zones, and warnings
- refuse unsupported or unsafe fairing requests clearly

## Acceptance Criteria

```gherkin
Scenario: local fairing improves a measurable terrain condition
  Given an adopted Managed Terrain Surface has a bounded local roughness or abrupt-transition condition
  When a supported fairing request is applied
  Then the materialized terrain state is updated in the fairing region
  And the selected roughness, variance, or continuity proxy improves according to the documented metric
  And derived output is refreshed from updated state through the current terrain output flow

Scenario: fairing preserves required controls
  Given fixed controls and preserve zones are supplied with a fairing request
  When local fairing is applied
  Then fixed controls remain within documented tolerance
  And preserve zones remain unchanged within documented tolerance
  And the fairing change remains bounded to the allowed region and blend area

Scenario: fairing evidence supports review
  Given local fairing completes
  When the result is reviewed
  Then the evidence includes before/after metric values, changed-region summary, control-preservation status, preserve-zone status, and warnings where applicable
  And the evidence remains JSON-safe and avoids raw generated face or vertex references as durable identifiers

Scenario: unsupported fairing requests refuse
  Given the requested fairing region, controls, terrain state, or metric is unsupported
  When fairing is requested
  Then the command returns a structured refusal
  And it does not perform arbitrary live mesh smoothing as a fallback
```

## Non-Goals

- implementing broad sculpting or brush UI
- implementing erosion, weathering, drainage, or procedural terrain simulation
- replacing the corridor transition kernel
- implementing FFT-backed or detail-preserving smoothing
- mutating semantic hardscape objects
- returning validation pass/fail verdicts for terrain fairness
- exposing a public tool named for broad smoothing behavior

## Business Constraints

- fairing must address representative local terrain cleanup needs without becoming a general-purpose sculpting system
- the behavior must be measurable enough to review and test
- supported fairing must preserve the managed-state and regeneration architecture

## Technical Constraints

- the fairing kernel must operate on materialized terrain state
- roughness, variance, or continuity evidence must be computed from terrain-domain data or explicit samples
- generated output must remain derived from state
- any public fairing operation fields must remain provider-compatible and follow the existing terrain edit request shape
- fairing diagnostics must support existing dirty-window output planning and partial output regeneration fallback behavior
- outputs and refusals must remain JSON-serializable
- implementation must include TDD for kernel behavior and live verification for regenerated output where practical

## Dependencies

- `MTA-04`
- `MTA-08`
- `MTA-09`
- `MTA-10`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- complements `MTA-05`
- informs later validation diagnostics for roughness, abrupt transitions, humps, trenches, or fairness concerns

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- a representative local fairing request improves a documented measurable terrain condition
- controls and preserve zones remain within documented tolerance
- output is refreshed from managed terrain state without live-TIN smoothing
- fairing evidence is sufficient for human review and downstream validation planning
