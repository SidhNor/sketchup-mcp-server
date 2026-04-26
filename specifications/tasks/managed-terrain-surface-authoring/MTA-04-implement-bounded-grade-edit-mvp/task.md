# Task: MTA-04 Implement Bounded Grade Edit MVP
**Task ID**: `MTA-04`
**Title**: `Implement Bounded Grade Edit MVP`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-24`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain adoption proves that existing terrain can become state-driven, but the core product need is bounded terrain authoring without live-TIN surgery. Current fallback workflows modify SketchUp triangulation directly and produce holes, drift, topology damage, and manual cleanup loops.

This task delivers the first terrain edit MVP. It should modify materialized terrain state through one bounded grade or elevation adjustment, respect fixed controls and preserve zones, regenerate derived output from updated state, and return before/after terrain evidence.

## Goals

- apply one bounded grade or elevation edit to adopted managed terrain state
- support explicit edit region, fixed controls, preserve zones, and blend boundary behavior
- regenerate derived terrain output from updated state
- return before/after edit evidence for changed region and preservation checks
- refuse ambiguous, unsafe, or unsupported edit requests without falling back to live-TIN mutation

## Acceptance Criteria

```gherkin
Scenario: bounded grade edit modifies managed terrain state
  Given an adopted Managed Terrain Surface exists with saved terrain state
  When a supported bounded grade edit is requested
  Then the terrain state changes only within the allowed edit and blend region
  And the derived terrain output is regenerated from updated state
  And the original arbitrary source TIN is not edited in place as the normal path

Scenario: fixed controls and preserve zones are respected
  Given a bounded grade edit includes fixed controls and preserve zones
  When the edit is applied
  Then fixed controls remain within documented tolerance
  And preserve zones remain unchanged within documented tolerance
  And any unsupported control or preserve-zone input returns a structured refusal

Scenario: edit evidence describes the result
  Given a bounded grade edit completes
  When the result is reviewed
  Then it includes JSON-safe before/after evidence for changed region, controls, preserve zones, and warnings
  And evidence references terrain-domain coordinates, sample indices, regions, or stable owner identity rather than durable generated face or vertex IDs

Scenario: edit mutation is coherent in SketchUp
  Given the edit mutates the SketchUp model
  When the edit succeeds, fails, or is undone
  Then terrain state storage and derived output remain coherent
  And a failure does not leave partial managed terrain state as the expected outcome
```

## Non-Goals

- implementing corridor transition or ramp-like kernels
- implementing local smoothing or fairing
- supporting unrestricted terrain sculpting
- modifying semantic hardscape as part of terrain editing
- adding terrain validation verdicts beyond terrain edit evidence

## Business Constraints

- this task must prove the PRD goal of replacing recurring `eval_ruby` terrain mesh edits for a representative bounded case
- supported edits must be bounded, evidence-producing, and refusal-oriented
- hardscape remains separate from terrain state

## Technical Constraints

- edit math must operate on materialized terrain state, not raw SketchUp entities
- terrain state must be loaded and saved through the repository seam
- generated mesh output must remain derived and replaceable
- public outputs must be JSON-serializable
- TDD and live verification must cover bounded change, controls, preserve zones, regeneration, and undo behavior

## Dependencies

- `MTA-03`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- unblocks `MTA-05`
- unblocks `MTA-06`
- creates the first terrain edit evidence consumed by later validation and review integration

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- a representative bounded grade edit completes without live-TIN mutation or `eval_ruby`
- fixed controls and preserve zones are preserved within documented tolerance
- before/after evidence is sufficient for review and downstream validation planning
- failure and undo cases preserve terrain storage/output coherence
