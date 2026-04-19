# Task: SEM-12 Add Governed Duplication and Managed Deletion Policy
**Task ID**: `SEM-12`
**Title**: `Add Governed Duplication and Managed Deletion Policy`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-18`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The semantic capability now has a first creation surface, hierarchy-maintenance primitives, and a planned maintenance-alignment slice, but it still does not define how Managed Scene Objects should behave when duplicated or removed. Those two operations are where business identity rules become most vulnerable: duplication can accidentally clone identity that should be derived or regenerated, and deletion can erase governed semantic objects without enough product-owned protection or refusal behavior.

The capability therefore needs one explicit policy task for duplication and managed deletion. That task should extend the current narrow hierarchy-maintenance and explicit single-target deletion posture into governed semantic behavior without widening into broad cleanup tooling or scene-orchestration APIs.

## Goals

- define governed duplication behavior for Managed Scene Objects, including identity-derivation rules for supported duplicate flows
- define managed deletion protections and refusal behavior for supported semantic deletion workflows
- align duplication and deletion policy with the existing hierarchy-maintenance and explicit-target deletion posture

## Acceptance Criteria

```gherkin
Scenario: supported managed-object duplication derives identity predictably
  Given a Managed Scene Object already exists in the scene
  When a supported semantic duplication workflow is exercised
  Then the resulting duplicated object follows documented business-identity derivation rules
  And the operation returns a structured, JSON-serializable result suitable for downstream semantic workflows

Scenario: managed deletion applies explicit product protections
  Given a supported Managed Scene Object is targeted for removal
  When the governed semantic deletion workflow is exercised
  Then the runtime applies documented managed-object protection and refusal rules before deletion
  And successful deletion returns a structured result describing the affected managed object rather than a silent erase

Scenario: duplication and deletion remain explicit rather than broad cleanup behavior
  Given semantic modeling should keep destructive and identity-sensitive behavior narrow
  When this task is completed
  Then duplication and deletion are exercised only through explicit target-based semantic workflows
  And the task does not introduce broad search-and-delete or unrestricted hierarchy-orchestration behavior

Scenario: duplication and deletion preserve semantic architecture boundaries
  Given hierarchy maintenance, maintenance alignment, and semantic creation already exist as separate slices
  When governed duplication and managed deletion are implemented
  Then the task reuses those existing semantic and targeting seams where appropriate
  And the task does not redefine the current semantic create contract or generic scene-query architecture
```

## Non-Goals

- widening non-destructive maintenance behavior already covered by `SEM-11`
- terrain-authoring or grading workflows
- broad batch cleanup, scene reset, or unrestricted destructive scene control
- next-wave semantic-family promotion

## Business Constraints

- duplication and deletion behavior must keep business identity reviewable rather than silently cloning or erasing semantic meaning
- the task must preserve a narrow, explicit destructive posture suitable for workflow clients and agentic use
- the delivered policy must fit the current semantic-scene-modeling product boundary rather than becoming a broad scene-governance effort

## Technical Constraints

- the task depends on the managed-object maintenance posture established by `SEM-11`
- duplication and deletion behavior must remain Ruby-owned and JSON-safe
- the task must build on explicit target references and the current hierarchy-maintenance or deletion seams rather than inventing a second targeting model
- the task must keep destructive behavior explicit and reviewable, with structured refusals where product protections apply

## Dependencies

- `SEM-11`

## Relationships

- informs deferred next-wave semantic-family work

## Related Technical Plan

- none yet

## Success Metrics

- supported semantic duplication flows produce predictable identity behavior instead of copying business identity silently
- managed deletion behavior exposes explicit protections and structured outcomes for supported semantic targets
- duplication and deletion no longer rely on ad hoc primitive behavior for common governed semantic workflows
