# Task: SEM-03 Add Metadata Mutation for Managed Scene Objects
**Task ID**: `SEM-03`
**Title**: `Add Metadata Mutation for Managed Scene Objects`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-14`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

Semantic creation alone is not enough for revision-safe workflows. Managed Scene Objects also need an explicit product-owned path for updating provenance, status, and semantic metadata without rebuilding geometry or weakening the identity rules established at creation time.

The PRD defines `set_entity_metadata` as a P0 part of the semantic surface, but the current repository does not yet provide a semantic-side metadata mutation command or a clear rule for how managed-object invariants are preserved during updates. This task delivers that mutation path while making the dependency on the targeting slice explicit instead of inventing a second lookup subsystem inside semantic modeling.

## Goals

- deliver `set_entity_metadata` as the public metadata mutation path for Managed Scene Objects
- preserve hard identity and management invariants while allowing supported semantic metadata updates
- make semantic metadata mutation depend on the delivered targeting contract rather than duplicating lookup behavior inside the semantic capability

## Acceptance Criteria

```gherkin
Scenario: set_entity_metadata updates supported semantic metadata through the public semantic surface
  Given Managed Scene Objects exist in the scene with semantic metadata owned by the capability
  When `set_entity_metadata` is exercised through the MCP surface
  Then the tool applies supported metadata updates through one explicit semantic command
  And the Python adapter remains a thin bridge over Ruby-owned metadata behavior

Scenario: metadata mutation preserves required identity and invariant rules
  Given a metadata update request targets a Managed Scene Object
  When the request attempts to add, change, or remove semantic fields
  Then supported mutable fields are updated inside one SketchUp operation boundary
  And removal or corruption of required identity or management fields is blocked or returned as a structured failure

Scenario: metadata mutation reuses the delivered targeting dependency
  Given semantic modeling depends on the scene-targeting capability for lookup behavior
  When `set_entity_metadata` resolves its target
  Then the task consumes the delivered targeting contract from `STI-01` or its equivalent
  And the task does not introduce a second semantic-owned lookup subsystem

Scenario: metadata mutation lands with unit and contract coverage
  Given this task adds a new public semantic command
  When the task is reviewed
  Then automated Ruby and Python tests cover the supported request and response behavior for `set_entity_metadata`
  And the shared contract artifact and both native contract suites are updated in the same change
```

## Non-Goals

- defining managed-object compatibility behavior for `transform_component` or `set_material`
- delivering identity-preserving rebuild or replacement flows
- broad semantic query or collection-discovery behavior beyond the delivered targeting dependency

## Business Constraints

- metadata mutation must support revision-friendly workflows without forcing recreate-from-scratch behavior
- the task must preserve stable business identity and required managed-object metadata instead of allowing silent degradation
- the public semantic mutation surface must remain compact and predictable for workflow clients

## Technical Constraints

- the task is explicitly blocked by `STI-01` or an equivalent delivered targeting contract because target resolution must not be reimplemented in the semantic slice
- Ruby must own invariant enforcement, metadata writes, operation bracketing, and serialized mutation results
- Python must remain a thin MCP adapter that validates boundary shape and forwards `set_entity_metadata` over the existing bridge
- the task must add or update the shared contract artifact and native Ruby and Python contract suites for the new public mutation tool

## Dependencies

- `SEM-01`
- `STI-01`

## Relationships

- informs deferred managed-object compatibility work for generic mutation tools
- informs deferred identity-preserving rebuild and replacement work

## Related Technical Plan

- none yet

## Success Metrics

- supported metadata updates can be applied to Managed Scene Objects through `set_entity_metadata` without rebuilding geometry
- invalid attempts to remove or corrupt required managed-object identity fields are surfaced as structured failures
- the metadata mutation boundary is covered by Ruby tests, Python tests, and shared contract cases in the same task
