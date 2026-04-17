# Task: SEM-07 Add Limited Hierarchy Maintenance Primitives
**Task ID**: `SEM-07`
**Title**: `Add Limited Hierarchy Maintenance Primitives`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-17`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The updated semantic direction now treats atomic creation and multipart composition as separate concerns. That boundary is important because composite features such as grouped planting, composed water features, or assembled site packages should not force `create_site_element` to become an oversized catch-all constructor.

At the same time, the hierarchy-aware maintenance posture is only useful if the repo exposes a small first-class surface that can perform narrow organization changes safely through explicit target-based operations. This task exists to add the smallest useful hierarchy-maintenance primitives so managed-object organization and accepted-scene repair can stay inside the public semantic surface without turning semantic modeling into a broad hierarchy platform.

## Goals

- add a limited hierarchy-maintenance surface centered on explicit group creation and explicit reparenting
- preserve managed-object identity and parent intent during supported hierarchy edits
- keep hierarchy-aware maintenance clearly separate from atomic semantic creation and from later replacement-heavy lifecycle work

## Acceptance Criteria

```gherkin
Scenario: hierarchy maintenance can create a group container for semantic scene work
  Given managed scene objects already exist in the model
  When the hierarchy-maintenance surface requests group creation with an explicit parent target when needed
  Then the system creates a group container and returns a structured, JSON-serializable result
  And the operation executes inside one undo-safe SketchUp operation boundary

Scenario: hierarchy maintenance can reparent supported entities explicitly
  Given one or more entities are eligible to move into a target group
  When the hierarchy-maintenance surface requests reparenting
  Then the selected entities are reparented in one coherent operation
  And the result is returned as structured, JSON-serializable data

Scenario: grouping and reparenting preserve child managed-object identity
  Given one or more child entities are Managed Scene Objects
  When those entities are grouped or reparented through the hierarchy-maintenance surface
  Then each child retains its own managed-object identity and metadata
  And the container relationship does not silently rewrite child business identity

Scenario: limited hierarchy maintenance remains intentionally narrow
  Given hierarchy-aware lifecycle needs extend beyond simple organization changes
  When this task is complete
  Then the new surface provides supported first-class behavior for group creation and explicit reparenting
  And the task does not introduce duplicate-into-parent, identity-preserving replacement, or broad hierarchy-query behavior
```

## Non-Goals

- adding duplicate-into-parent or identity-preserving replacement behavior in this task
- adding a broad hierarchy query or scene-pass orchestration surface
- expanding multipart feature semantics inside `create_site_element`
- redefining generic scene-query or targeting architecture
- promoting a full composition or feature-assembly framework

## Business Constraints

- the task must keep hierarchy-heavy managed-object maintenance inside the semantic capability without widening into general scene orchestration
- the task must stay intentionally lean rather than becoming a broad hierarchy or composition platform effort
- the task must preserve managed-object identity rules so later revision and replacement workflows remain reliable

## Technical Constraints

- group creation and reparenting behavior must remain Ruby-owned and SketchUp-facing
- the new hierarchy-maintenance surface must return only structured, JSON-serializable data
- the task should reuse existing managed-object metadata and targeting posture rather than inventing a second semantic lookup system
- the scope must stay limited to `create_group` and `reparent_entities`

## Dependencies

- `SEM-03`

## Relationships

- introduces the first limited hierarchy-maintenance slice established by the updated semantic HLD
- protects the atomic/composite boundary established by the updated semantic HLD without widening into replacement-heavy lifecycle work

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the repo has one limited hierarchy-maintenance slice that can create groups and reparent entities in a structured, undo-safe way
- grouping and reparenting do not silently rewrite child managed-object identity
- hierarchy-heavy managed-object maintenance no longer needs to lean on fallback Ruby for normal explicit organization changes
