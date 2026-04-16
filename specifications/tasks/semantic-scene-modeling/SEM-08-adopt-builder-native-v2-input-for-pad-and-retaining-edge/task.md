# Task: SEM-08 Adopt Builder-Native V2 Input for Pad and Retaining Edge
**Task ID**: `SEM-08`
**Title**: `Adopt Builder-Native V2 Input for Pad and Retaining Edge`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-16`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

After `path` and `structure`, the next core site pressure sits in `pad` and `retaining_edge`. These families carry important terrain, platform, cut-fill, and edge-hosting behavior, and they are central to whether the chosen sectioned `v2` direction remains durable for actual site work.

This task exists to extend builder-native `v2` adoption to `pad` and `retaining_edge` so the chosen direction becomes real for the next two core site families without reopening the contract decision. It should continue the adoption posture established after `SEM-05` and avoid sliding back into family-specific ad hoc fields or permanent command-level translation.

## Goals

- adopt builder-native sectioned `v2` input for `pad` and `retaining_edge`
- preserve clear `pad` and `retaining_edge` semantics under the chosen section boundaries
- keep terrain- and edge-sensitive behavior inside the chosen `v2` posture without reintroducing ad hoc root-level fields

## Acceptance Criteria

```gherkin
Scenario: pad and retaining_edge builders accept sectioned v2 input natively
  Given the semantic capability has chosen the sectioned `v2` direction
  When a valid `pad` or `retaining_edge` request is executed through `create_site_element`
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

Scenario: the task extends the v2 direction without reopening the contract choice
  Given the signal and `SEM-05` already established the chosen sectioned direction
  When this task is complete
  Then `pad` and `retaining_edge` are implemented under that chosen posture
  And the task does not introduce a second competing contract shape for those families
```

## Non-Goals

- re-running contract-direction pressure testing as a separate workstream
- migrating every remaining semantic family in this task
- adding composition primitives or multipart feature assembly behavior
- broadening the task into next-wave families such as `planting_mass`, `tree_instance`, or `seat`

## Business Constraints

- the task must continue the chosen `v2` direction as implementation work rather than reopening the direction decision
- the task must keep the semantic surface compact and avoid family-specific contract sprawl
- the task must preserve the explicit product boundary between `pad` and `structure`

## Technical Constraints

- Ruby remains the owner of semantic interpretation, hosted behavior, refusal behavior, and builder routing
- Python and the bridge boundary should remain unchanged unless a concrete technical need emerges during implementation
- the task must adopt builder-native `v2` input for `pad` and `retaining_edge` rather than deepening command-level family-specific translation
- terrain- and edge-sensitive behavior must remain disciplined within the chosen section boundaries

## Dependencies

- `SEM-05`
- `SEM-06`

## Relationships

- extends the builder-native `v2` adoption pattern established for `path` and `structure`
- proves the chosen sectioned direction across the next core site families without reopening the contract choice

## Related Technical Plan

- none yet

## Success Metrics

- `pad` and `retaining_edge` accept sectioned `v2` input natively at the builder layer
- the semantic command seam does not become the permanent family-specific translation home for those families
- the repo preserves clear `pad` and `retaining_edge` semantics under the chosen `v2` posture
