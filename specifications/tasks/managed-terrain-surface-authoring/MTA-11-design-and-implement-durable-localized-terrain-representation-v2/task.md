# Task: MTA-11 Design And Implement Durable Localized Terrain Representation v2
**Task ID**: `MTA-11`
**Title**: `Design And Implement Durable Localized Terrain Representation v2`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain currently persists a uniform `heightmap_grid` v1 state. MTA-07 selected a heightmap-derived scalable direction and deferred durable localized-detail storage. Bulk full-grid output and partial output regeneration can improve derived mesh performance, but they do not by themselves solve the need for localized terrain detail, tiled or chunked storage, serializer and repository dispatch, migration behavior, or explicit compatibility guarantees for existing terrain states.

This task defines and implements the next persisted terrain representation version for localized detail while preserving v1 terrain loading and the architecture rule that materialized terrain state, not generated SketchUp TIN geometry, is authoritative.

## Goals

- define a durable terrain representation beyond uniform `heightmap_grid` v1
- support localized-detail, tiled/chunked state, patch-overlay, or equivalent heightmap-derived representation units
- add serializer and repository dispatch for the new representation version
- preserve v1 terrain state loading, integrity checks, and compatibility
- define migration, unsupported-version, corrupt-payload, and refusal behavior
- define any public evidence or contract evolution needed for representation units

## Acceptance Criteria

```gherkin
Scenario: v2 terrain representation is persisted and loaded
  Given a Managed Terrain Surface uses the new localized terrain representation
  When the terrain state is saved and loaded through the terrain repository
  Then the repository returns the correct v2 terrain state
  And payload integrity checks, version fields, and state summaries are deterministic
  And raw SketchUp objects are not exposed through the domain-facing repository contract

Scenario: existing v1 terrain remains compatible
  Given an existing Managed Terrain Surface uses `heightmap_grid` schema version 1
  When repository load, edit, or regeneration behavior is exercised
  Then v1 terrain state round trips exactly according to the existing migration baseline
  And unsupported v2-only behavior refuses clearly rather than corrupting v1 state

Scenario: migration and refusal behavior is explicit
  Given stored terrain state is missing, corrupt, unsupported, or cannot be safely migrated
  When the terrain repository attempts to load or migrate it
  Then it returns a structured refusal or recovery outcome
  And callers are not expected to fabricate terrain state or fall back to generated SketchUp mesh as source of truth

Scenario: edit kernels remain storage-agnostic
  Given terrain edit kernels operate on materialized terrain state
  When the persisted backing uses localized representation units
  Then edit behavior is routed through domain-facing terrain state contracts
  And edit kernels do not depend on raw storage dictionaries, sidecar paths, or generated mesh identity
```

## Non-Goals

- making generated SketchUp mesh geometry the durable source of truth
- implementing faster full-grid output by itself
- implementing partial output regeneration unless deliberately combined after prior output milestones
- adding public Unreal-style terrain tools
- mutating semantic hardscape objects as part of terrain state

## Business Constraints

- existing terrain models created with v1 `heightmap_grid` must remain loadable and recoverable
- localized detail must support practical terrain authoring without forcing unnecessary density across an entire terrain surface
- storage evolution must remain portable with SketchUp model workflows unless a later sidecar design explicitly changes that posture
- terrain evidence and validation handoff should remain understandable to downstream MCP clients

## Technical Constraints

- terrain state remains behind the terrain repository seam and outside the lightweight `su_mcp` metadata dictionary
- serializer and repository dispatch must preserve v1 round-trip behavior
- migration and unsupported-version behavior must be deterministic and JSON-safe
- generated face or vertex identifiers must not become durable representation identifiers
- any public evidence or request-shape change requires coordinated loader schema, fixtures, tests, docs, and examples

## Dependencies

- `MTA-07`
- `MTA-09`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows the scalable representation direction selected in `MTA-07`
- may be pulled earlier or narrowed if `MTA-10` proves partial output requires durable output-region metadata
- informs future edit kernels that need localized detail beyond uniform-grid state

## Related Technical Plan

- none yet

## Success Metrics

- v2 terrain state saves, loads, validates, and refuses unsupported cases through the repository seam
- v1 `heightmap_grid` terrain round trips exactly after v2 support is added
- edit kernels remain storage-agnostic and do not depend on generated mesh identity
- migration, corrupt-payload, unsupported-version, and compatibility behavior are covered by tests
