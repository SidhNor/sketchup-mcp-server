# Task: STI-01 Targeting MVP and `find_entities`
**Task ID**: `STI-01`
**Title**: `Targeting MVP and find_entities`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-14`

## Linked HLD

- [Scene Targeting and Interrogation](../../../hlds/hld-scene-targeting-and-interrogation.md)

## Problem Statement

The platform currently exposes only broad scene-inspection helpers. That leaves downstream workflows without a product-owned way to resolve the intended target before mutation, placement, or validation work begins. The HLD and PRD define `find_entities` as the first workflow-facing targeting surface, but the current repository does not yet provide the cross-runtime contract, identity preference rules, or explicit ambiguity handling needed for that behavior.

This first iteration deliberately narrows the targeting task to an MVP that the current repo can support now. Metadata-aware and collection-aware filtering are not yet backed by implemented conventions, so this task must establish the explicit targeting contract and deliver the supported lookup paths without overstating the current capability.

## Goals

- establish the first explicit cross-runtime target-reference and match-summary contract for scene targeting
- deliver `find_entities` for the supported MVP query paths available in the current repo
- make targeting outcomes deterministic and reviewable through explicit resolution states and automated boundary checks

## Acceptance Criteria

```gherkin
Scenario: find_entities supports the confirmed MVP query surface
  Given the scene contains entities identifiable by supported targeting criteria
  When `find_entities` is exercised through the MCP surface
  Then the tool accepts the confirmed MVP criteria of `sourceElementId` where present, `persistentId`, compatibility `entityId`, name, tag or layer, and material
  And the Ruby runtime remains the owner of lookup and match behavior

Scenario: find_entities returns explicit resolution states
  Given a query that yields no match, one match, or multiple matches
  When the result is reviewed
  Then the response reports a resolution state of `none`, `unique`, or `ambiguous`
  And the response does not silently choose one match when multiple candidates satisfy the query

Scenario: find_entities returns compact serializable match summaries
  Given a supported targeting query resolves one or more entities
  When the result payload is reviewed at the Python or Ruby boundary
  Then each match summary is fully JSON-serializable
  And each summary includes runtime and stable identifiers when available without exposing raw SketchUp objects

Scenario: the MVP boundary is explicit and testable
  Given metadata and workflow collection conventions are not yet implemented for this capability
  When the task is reviewed
  Then automated Ruby and Python tests cover the supported MVP request and response behavior
  And the task does not claim metadata-aware or collection-aware filtering as completed behavior
```

## Non-Goals

- implementing metadata-aware filtering
- implementing collection-aware filtering or `get_named_collections`
- delivering bounds, surface interrogation, or topology analysis behavior

## Business Constraints

- the task must provide a workflow-facing targeting surface without forcing clients back to broad inspection or arbitrary Ruby
- the MVP scope must stay honest about what the current repository can support now
- targeting behavior must prefer workflow-stable identity where available rather than making runtime ids the primary user-facing model

## Technical Constraints

- Ruby must own entity resolution, ambiguity handling, and JSON-safe match serialization
- Python must remain a thin MCP adapter over the Ruby command and must not reimplement targeting logic
- the targeting contract must align with the HLD's explicit resolution-state model and stay compatible with the existing bridge boundary
- the task must build on the current shared Ruby adapter and serializer seams rather than bypassing them

## Dependencies

- `PLAT-02`
- `PLAT-03`

## Relationships

- blocks `STI-02`
- informs the deferred targeting-expansion follow-on for metadata and collection filtering

## Related Technical Plan

- none yet

## Success Metrics

- representative supported lookup scenarios can resolve targets through `find_entities` without falling back to broad scene inspection
- ambiguous and not-found targeting outcomes are visible as explicit structured states rather than inferred from missing data
- the Python/Ruby contract for `find_entities` is covered by automated tests for supported MVP request and response behavior
