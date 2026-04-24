# Task: SVR-04 Add Terrain-Aware Measurement Evidence
**Task ID**: `SVR-04`
**Title**: `Add Terrain-Aware Measurement Evidence`
**Status**: `planned`
**Priority**: `P2`
**Date**: `2026-04-24`

## Linked HLD

- [Scene Validation and Review](../../../hlds/hld-scene-validation-and-review.md)

## Related Signals

- [Partial terrain authoring session reveals stable patch-editing contract](../../../signals/2026-04-24-partial-terrain-authoring-session-reveals-stable-patch-editing-contract.md)

## Problem Statement

`SVR-03` establishes `measure_scene` as the bounded public measurement surface for generic direct measurements. Terrain workflows need more than generic bounds, height, distance, and area, but they should not jump directly to terrain diagnostics, validation verdicts, or authoring primitives.

This follow-on task reserves a bounded measurement-evidence slice that can consume `SVR-03` measurement internals and `STI-03` terrain profile or section evidence. It should expose terrain-aware quantities useful for review workflows while leaving pass/fail terrain diagnostics to a later validation task.

## Goals

- add terrain-aware measurement evidence after `measure_scene` and profile sampling are stable
- keep the public surface in direct-measurement territory rather than validation verdict territory
- reuse the `measure_scene` command/helper posture and `STI-03` profile evidence instead of duplicating geometry probing
- provide enough terrain-aware evidence for later diagnostics to be designed from real usage

## Acceptance Criteria

```gherkin
Scenario: terrain-aware measurement builds on shipped dependencies
  Given `measure_scene` and profile or section sampling are implemented
  When terrain-aware measurement evidence is added
  Then the task reuses those internal measurement and sampling seams
  And it does not create a validation-local terrain measurement subsystem

Scenario: terrain evidence remains measurement, not verdict
  Given a caller asks a terrain-aware measurement question
  When the result is returned
  Then the response includes unit-bearing quantities and compact evidence
  And it does not return pass/fail, grade-compliance, trench, hump, drainage, or fairness verdicts

Scenario: mode and kind names are finalized from the settled evidence contract
  Given `SVR-03` and `STI-03` have established the generic measurement and profile evidence seams
  When this task is planned in detail
  Then exact `measure_scene` mode and kind names are finalized from those upstream contracts
  And the chosen public enum set remains small, explicit, and evidence-oriented
```

## Non-Goals

- implementing terrain diagnostics or validation verdicts for slope spikes, grade breaks, trenches, humps, or fairness
- adding clearance, path length, or slope hints to the `SVR-03` MVP
- creating terrain editing, patch replacement, smoothing, fairing, or working-copy lifecycle behavior
- routing validation through the public `measure_scene` MCP tool instead of shared internal measurement helpers
- adding broad terrain-aware mode/kind names beyond the finite evidence set selected during technical planning

## Business Constraints

- the task must keep direct measurement distinct from acceptance validation
- terrain-aware measurement should reduce Ruby fallback for review evidence without implying terrain modeling support
- the evidence contract should remain compact enough for downstream agents to compare and summarize

## Technical Constraints

- Ruby must own measurement execution, profile evidence consumption, and JSON-safe serialization
- `validate_scene_update` must not call the public `measure_scene` tool
- public outputs must keep units and derivation evidence explicit
- exact mode/kind names must be chosen from the settled `SVR-03` measurement posture and `STI-03` profile evidence shape
- terrain-shaped targets must still use explicit host references where profile or section evidence is required

## Dependencies

- `SVR-03`
- `STI-03`
- [Scene Validation and Review HLD](../../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../../prds/prd-scene-validation-and-review.md)

## Relationships

- follows `SVR-03` by expanding direct measurement beyond generic bounds and area questions
- consumes `STI-03` profile or section evidence rather than owning terrain sampling
- informs a later terrain-aware validation diagnostics task if measurement evidence proves stable and useful
- keeps terrain patch helpers deferred until interrogation, measurement, and validation evidence expose a specific missing authoring primitive

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- terrain review workflows can request structured measurement evidence without arbitrary Ruby
- public outputs remain quantities and evidence rather than acceptance verdicts
- downstream diagnostics can be planned from stable terrain-aware measurement evidence
- the task does not expand the product into terrain editing or terrain solver ownership
