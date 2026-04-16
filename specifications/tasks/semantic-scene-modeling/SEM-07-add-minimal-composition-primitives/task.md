# Task: SEM-07 Add Minimal Composition Primitives
**Task ID**: `SEM-07`
**Title**: `Add Minimal Composition Primitives`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-16`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The updated semantic direction now treats atomic creation and multipart composition as separate concerns. That boundary is important because composite features such as grouped planting, composed water features, or assembled site packages should not force `create_site_element` to become an oversized catch-all constructor.

At the same time, that boundary is only useful if the repo has a minimal composition surface that can actually assemble managed objects after creation. This task exists to add the smallest useful composition primitives so multipart semantic work can proceed without pushing composition pressure back into atomic creation.

## Goals

- add a minimal composition surface centered on group creation and batched reparenting
- preserve managed-object identity for children during grouping and hierarchy edits
- keep composition clearly separate from atomic semantic creation

## Acceptance Criteria

```gherkin
Scenario: composition can create a group container for semantic scene work
  Given managed scene objects already exist in the model
  When the composition surface requests group creation
  Then the system creates a group container and returns a structured, JSON-serializable result
  And the operation executes inside one undo-safe SketchUp operation boundary

Scenario: composition can reparent multiple entities in one batched operation
  Given one or more entities are eligible to move into a target group
  When the composition surface requests batched reparenting
  Then the selected entities are reparented in one coherent operation
  And the result is returned as structured, JSON-serializable data

Scenario: grouping and reparenting preserve child managed-object identity
  Given one or more child entities are Managed Scene Objects
  When those entities are grouped or reparented through the composition surface
  Then each child retains its own managed-object identity and metadata
  And the container relationship does not silently rewrite child business identity

Scenario: composition remains separate from atomic semantic creation
  Given the semantic capability uses `create_site_element` for atomic create flows
  When this task is complete
  Then multipart feature assembly is not required to be expressed as one atomic `create_site_element` call
  And the new composition primitives provide the supported path for that work instead
```

## Non-Goals

- adding duplication, identity-preserving replacement, or broader composition orchestration in this task
- expanding multipart feature semantics inside `create_site_element`
- redefining generic scene-query or targeting architecture
- promoting a full feature-assembly framework

## Business Constraints

- the task must keep multipart feature pressure out of the atomic semantic creation contract
- the task must stay intentionally lean rather than becoming a broad composition-platform effort
- the task must preserve managed-object identity rules so later revision workflows remain reliable

## Technical Constraints

- grouping and reparenting behavior must remain Ruby-owned and SketchUp-facing
- the new composition surface must return only structured, JSON-serializable data
- the task should reuse existing managed-object metadata and targeting posture rather than inventing a second semantic lookup system
- the scope must stay limited to `create_group` and `reparent_entities`

## Dependencies

- `SEM-03`

## Relationships

- protects the atomic/composite boundary established by the updated semantic HLD
- enables multipart semantic features to be assembled without overloading `create_site_element`

## Related Technical Plan

- none yet

## Success Metrics

- the repo has one minimal composition slice that can create groups and reparent entities in a structured, undo-safe way
- grouping and reparenting do not silently rewrite child managed-object identity
- multipart semantic work no longer needs to lean on atomic creation for composition semantics
