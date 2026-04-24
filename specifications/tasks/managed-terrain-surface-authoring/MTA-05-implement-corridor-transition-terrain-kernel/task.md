# Task: MTA-05 Implement Corridor Transition Terrain Kernel
**Task ID**: `MTA-05`
**Title**: `Implement Corridor Transition Terrain Kernel`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-24`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Terrain workflows need controlled transitions between terrain conditions, such as access routes, threshold changes, shoulders, and ramp-like corridors. The product should not expose Unreal-style public tool names or broad sculpting behavior, but it does need a concrete internal transition kernel with measurable behavior.

This task adds a corridor transition terrain kernel on top of the adopted terrain and bounded edit substrate. It should define and realize a transition operation that updates materialized terrain state, respects controls and preserve zones, regenerates output, and returns evidence about transition quality.

## Goals

- define a concrete internal corridor transition kernel contract
- support explicit corridor or transition controls, blend behavior, fixed controls, and preserve zones
- update terrain state and regenerate derived output through the existing managed terrain flow
- return measurable transition evidence such as before/after samples, slope or continuity summaries, changed region, and warnings
- refuse unsupported or unsafe transition inputs without live mesh surgery

## Acceptance Criteria

```gherkin
Scenario: corridor transition updates managed terrain state
  Given an adopted Managed Terrain Surface exists
  And a supported corridor transition request supplies explicit controls and region data
  When the transition kernel is applied
  Then the materialized terrain state is updated according to the transition intent
  And derived terrain output is regenerated from updated state
  And the operation does not edit arbitrary live TIN geometry in place

Scenario: transition controls and preserve zones are honored
  Given a corridor transition includes fixed controls, transition controls, and preserve zones
  When the transition is applied
  Then fixed controls and preserve zones remain within documented tolerance
  And transition behavior remains bounded to the allowed region and blend area

Scenario: transition evidence is measurable
  Given a corridor transition completes
  When the result is reviewed
  Then the evidence includes before/after terrain samples, changed-region summary, and transition quality indicators
  And the evidence can support later validation without requiring validation to own the terrain kernel

Scenario: unsupported transition requests refuse
  Given corridor controls are ambiguous, contradictory, outside supported terrain state, or unsafe
  When the transition is requested
  Then the command returns a structured refusal
  And it does not create a partially updated terrain state as the expected outcome
```

## Non-Goals

- exposing public tools named after Unreal terrain operations
- implementing local smoothing or fairing behavior
- implementing arbitrary road design, civil grading, or drainage simulation
- mutating paths, pads, or retaining edges as terrain state
- implementing broad terrain mesh repair

## Business Constraints

- transition behavior must be useful for representative ramp-like terrain workflows
- the public surface must remain product-shaped rather than imported from UE terminology
- transition evidence must support review and validation handoff without becoming validation policy

## Technical Constraints

- the kernel must operate on materialized terrain state
- state persistence and derived output regeneration must reuse the managed terrain storage and output flow
- outputs must remain JSON-serializable and avoid raw SketchUp objects
- implementation must include TDD for kernel behavior and live verification for regenerated output where practical

## Dependencies

- `MTA-04`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- complements `MTA-06`
- informs later terrain validation diagnostics for slope spikes, abrupt transitions, humps, or trenches

## Related Technical Plan

- none yet

## Success Metrics

- a representative corridor transition completes on adopted managed terrain without `eval_ruby`
- transition output is bounded, regenerated from state, and evidence-producing
- unsupported transition inputs refuse clearly
- transition evidence is measurable enough for downstream validation planning
