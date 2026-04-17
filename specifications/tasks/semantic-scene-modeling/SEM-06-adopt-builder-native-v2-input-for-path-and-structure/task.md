# Task: SEM-06 Cut Over Create Site Element To The Sectioned Contract And Adopt Builder-Native V2 Input For Path And Structure
**Task ID**: `SEM-06`
**Title**: `Cut Over Create Site Element To The Sectioned Contract And Adopt Builder-Native V2 Input For Path And Structure`
**Status**: `planned`
**Priority**: `P0`
**Date**: `2026-04-17`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

`SEM-05` proved that the sectioned semantic contract direction can survive the live Ruby seam for `path` and `structure`, but the current repository still exposes a dual create posture:

- the native MCP runtime still advertises the older flat `create_site_element` request shape
- the Ruby semantic seam already accepts the newer sectioned shape for bounded flows
- the command layer still translates sectioned requests into older builder-facing payloads

That dual posture is now more confusing than helpful. It weakens the public contract, obscures the actual architecture direction, and leaves the first proven families in a transitional state even though the repo has already chosen the sectioned semantic direction.

This task exists to remove that ambiguity in one coherent slice. It makes the sectioned semantic contract the only public `create_site_element` shape and migrates `path` and `structure` to builder-native sectioned input while preserving the lifecycle and hosting behavior already validated in `SEM-05`.

## Goals

- cut over `create_site_element` so the sectioned semantic contract is the only public create shape exposed through the native MCP runtime
- migrate `path` and `structure` from command-level translation to builder-native sectioned input
- preserve the proven `SEM-05` lifecycle and hosting behaviors for the two migrated families
- align runtime schemas, semantic tests, and task-facing documentation with the single public create-contract posture

## Acceptance Criteria

```gherkin
Scenario: create_site_element exposes one public sectioned contract
  Given the semantic capability has chosen the sectioned contract direction
  When a caller inspects or invokes `create_site_element` through the native MCP runtime
  Then the tool advertises only the sectioned semantic request shape
  And the public create surface no longer depends on the older flat request contract

Scenario: path and structure builders accept the sectioned contract natively
  Given the public semantic create surface now uses one sectioned contract
  When a valid `path` or `structure` request is executed through `create_site_element`
  Then the selected builder consumes the sectioned family input without requiring family-specific command-level translation into the older builder payload shape

Scenario: proven v2 behaviors remain valid for path and structure after builder-native adoption
  Given `SEM-05` proved bounded sectioned-contract support for `path` and `structure`
  When retained adoption, bounded replace-preserve-identity, and hosting-aware create flows are exercised for those families
  Then the migrated builders preserve the same managed-object identity, metadata, and structured-result behavior required by the current semantic contract

Scenario: scene-facing create fields align with the sectioned contract posture
  Given the sectioned create contract distinguishes workflow identity, scene-facing organization, representation, hosting, placement, and lifecycle intent
  When `path` or `structure` requests include supported naming, tag, or material choices
  Then those fields are accepted only through the approved sectioned contract posture
  And the task does not preserve older flat compatibility fields as a second public create shape

Scenario: family-specific translation debt is reduced for the migrated families
  Given the command seam currently performs transitional `v2` translation for spike-proven families
  When this task is complete
  Then `path` and `structure` no longer depend on that family-specific translation path as their primary execution route
  And any remaining compatibility glue is narrow enough to be clearly transitional

Scenario: the native runtime, semantic tests, and task-facing docs align on the new baseline
  Given this task changes the public create posture for semantic scene modeling
  When the task is reviewed
  Then native runtime schema coverage and semantic command coverage reflect the sectioned-only create contract
  And the semantic task set no longer implies that the older flat create shape remains an active public baseline
```

## Non-Goals

- migrating every semantic family to builder-native sectioned input
- introducing composition primitives or multipart feature assembly behavior
- widening `SEM-06` to absorb the remaining first-wave families beyond `path` and `structure`
- expanding next-wave semantic families such as `seat`, `water_feature_proxy`, or `terrain_patch`

## Business Constraints

- the task must turn the `SEM-05` spike into an actual public-baseline migration rather than leaving it as stranded compatibility code
- the task must preserve the compact semantic creation surface rather than expanding into multiple overlapping creation tools
- the task must remove the confusing dual public create posture rather than hide it behind documentation wording alone
- the task must keep the chosen direction practical for the current repo without introducing migration ceremony for its own sake

## Technical Constraints

- the native Ruby MCP runtime remains the public schema owner for `create_site_element`
- Ruby remains the owner of semantic interpretation, lifecycle handling, hosting handling, builder routing, and refusal behavior
- `path` and `structure` must stay aligned with the section boundaries established by the updated HLD
- command-level translation should be reduced for the migrated families rather than reintroduced under a different shape
- the task must not leave both flat and sectioned public create schemas active at the same time

## Dependencies

- `SEM-02`
- `SEM-05`

## Relationships

- turns the bounded `SEM-05` proof into the first real public-baseline contract migration
- turns the bounded `SEM-05` proof into builder-native architecture for the first proven families
- establishes the adoption pattern that later `v2` family tasks should follow

## Related Technical Plan

- [Draft technical plan](./plan.md)

## Success Metrics

- `create_site_element` exposes one public sectioned create contract through the native runtime instead of dual flat and sectioned postures
- `path` and `structure` are the first semantic families that accept sectioned input natively at the builder layer
- the semantic command seam carries less family-specific translation logic for those families than it did after `SEM-05`
- the repo retains the proven `SEM-05` lifecycle and hosting behavior for `path` and `structure` after the migration
