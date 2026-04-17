# Task: SEM-08 Adopt Builder-Native V2 Input for the Remaining First-Wave Families
**Task ID**: `SEM-08`
**Title**: `Adopt Builder-Native V2 Input for the Remaining First-Wave Families`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-17`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

After the public create-contract cutover and the first builder-native migration slice in `SEM-06`, the remaining first-wave semantic families still need to adopt the same sectioned contract posture. Those remaining families are:

- `pad`
- `retaining_edge`
- `planting_mass`
- `tree_proxy`

The underlying geometry construction for these families is already present in the repo. The main remaining work is to align them with the sectioned create contract, migrate them away from family-specific translation, and finish the first-wave semantic surface under one coherent public baseline.

This task exists to complete that remaining first-wave migration without reopening the contract decision made by `SEM-06`.

## Goals

- adopt builder-native sectioned input for `pad`, `retaining_edge`, `planting_mass`, and `tree_proxy`
- preserve the documented family semantics for those remaining first-wave types under the chosen section boundaries
- remove remaining family-specific create translation debt now that the sectioned contract is the public baseline

## Acceptance Criteria

```gherkin
Scenario: remaining first-wave builders accept sectioned input natively
  Given `SEM-06` established the sectioned create contract as the public baseline
  When a valid `pad`, `retaining_edge`, `planting_mass`, or `tree_proxy` request is executed through `create_site_element`
  Then the selected builder consumes the sectioned `v2` family input without requiring family-specific command-level translation into the older builder payload shape

Scenario: pad semantics remain clear under builder-native v2 adoption
  Given `pad` is the semantic home for surface-first hardscape and platform-like elements
  When builder-native `v2` support is added for `pad`
  Then the builder preserves documented `pad` semantics for elevation, thickness, and related hosted behavior
  And the task does not reintroduce ambiguity between `pad` and `structure`

Scenario: retaining_edge semantics remain clear under builder-native v2 adoption
  Given `retaining_edge` carries edge-sensitive site behavior
  When builder-native `v2` support is added for `retaining_edge`
  Then the builder preserves documented edge-oriented behavior through the chosen section boundaries
  And invalid or contradictory requests return structured refusals rather than silent fallback behavior

Scenario: planting_mass and tree_proxy migrate without introducing a new semantic sub-contract
  Given `planting_mass` and `tree_proxy` already have implemented geometry builders
  When those families are migrated to builder-native sectioned input
  Then the task completes the contract plumbing and translation-debt removal for those families
  And the task does not invent a separate public create shape or a separate migration stream for them

Scenario: the task completes first-wave builder migration without reopening the contract choice
  Given the signal and `SEM-06` already established the sectioned create-contract baseline
  When this task is complete
  Then the remaining first-wave semantic families are implemented under that chosen posture
  And the task does not introduce a second competing contract shape for those families
```

## Non-Goals

- re-running contract-direction pressure testing as a separate workstream
- migrating every remaining semantic family in this task
- adding composition primitives or multipart feature assembly behavior
- broadening the task into next-wave families such as `tree_instance`, `seat`, `water_feature_proxy`, or `terrain_patch`

## Business Constraints

- the task must continue the chosen sectioned-contract direction as implementation work rather than reopening the direction decision
- the task must keep the semantic surface compact and avoid family-specific contract sprawl
- the task must preserve the explicit product boundary between `pad` and `structure`
- the task must finish the remaining first-wave family migration without spawning extra backlog slices when the work is primarily plumbing

## Technical Constraints

- Ruby remains the owner of semantic interpretation, hosted behavior, refusal behavior, and builder routing
- the public `create_site_element` contract is already sectioned-only by the time this task starts
- the task must adopt builder-native sectioned input for `pad`, `retaining_edge`, `planting_mass`, and `tree_proxy` rather than deepening command-level family-specific translation
- terrain-, edge-, and planting- or proxy-specific behavior must remain disciplined within the chosen section boundaries

## Dependencies

- `SEM-05`
- `SEM-06`

## Relationships

- extends the builder-native adoption pattern established for `path` and `structure`
- completes the remaining first-wave family migration under the chosen sectioned create-contract baseline

## Related Technical Plan

- none yet

## Success Metrics

- `pad`, `retaining_edge`, `planting_mass`, and `tree_proxy` accept sectioned input natively at the builder layer
- the semantic command seam does not remain the permanent family-specific translation home for the remaining first-wave families
- the repo preserves clear family semantics for those remaining first-wave types under the chosen sectioned posture
