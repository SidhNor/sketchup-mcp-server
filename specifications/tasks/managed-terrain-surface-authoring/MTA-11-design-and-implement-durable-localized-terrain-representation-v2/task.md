# Task: MTA-11 Design And Implement Localized Survey Detail Zones
**Task ID**: `MTA-11`
**Title**: `Design And Implement Localized Survey Detail Zones`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain currently persists a uniform `heightmap_grid` v1 state. MTA-07 selected a heightmap-derived scalable direction and deferred durable localized-detail storage. MTA-13 will first attempt survey point constraint editing on the existing v1 heightmap substrate. That is the right first proof point, but it may expose survey cases where small tolerances, dense measured points, or localized grading detail cannot be represented without globally increasing terrain density.

This task defines and implements localized survey/detail zones as the durable escalation path for those cases. It preserves v1 terrain loading and the architecture rule that materialized terrain state, not generated SketchUp TIN geometry, is authoritative.

## Goals

- define durable localized survey/detail zones beyond uniform `heightmap_grid` v1
- support localized-detail, tiled/chunked state, patch-overlay, or equivalent heightmap-derived representation units for survey fidelity
- add serializer and repository dispatch for the localized detail representation
- preserve v1 terrain state loading, integrity checks, and compatibility
- define migration, unsupported-version, corrupt-payload, and refusal behavior
- define any public evidence or contract evolution needed for representation units

## Acceptance Criteria

```gherkin
Scenario: localized survey detail zones are persisted and loaded
  Given a Managed Terrain Surface uses localized survey/detail zones
  When the terrain state is saved and loaded through the terrain repository
  Then the repository returns the correct localized terrain state
  And payload integrity checks, version fields, and state summaries are deterministic
  And raw SketchUp objects are not exposed through the domain-facing repository contract

Scenario: existing v1 terrain remains compatible
  Given an existing Managed Terrain Surface uses `heightmap_grid` schema version 1
  When repository load, edit, or regeneration behavior is exercised
  Then v1 terrain state round trips exactly according to the existing migration baseline
  And unsupported localized-detail-only behavior refuses clearly rather than corrupting v1 state

Scenario: migration and refusal behavior is explicit
  Given stored terrain state is missing, corrupt, unsupported, or cannot be safely migrated
  When the terrain repository attempts to load or migrate it
  Then it returns a structured refusal or recovery outcome
  And callers are not expected to fabricate terrain state or fall back to generated SketchUp mesh as source of truth

Scenario: edit kernels remain storage-agnostic
  Given terrain edit kernels operate on materialized terrain state
  When the persisted backing uses localized survey/detail zones
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
- localized detail must support survey fidelity and practical terrain authoring without forcing unnecessary density across an entire terrain surface
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
- follows `MTA-13` unless MTA-13 planning proves v1 heightmap state cannot support representative survey constraints
- informs future edit kernels that need localized survey/detail fidelity beyond uniform-grid state

## Related Technical Plan

- none yet

## Success Metrics

- localized survey/detail state saves, loads, validates, and refuses unsupported cases through the repository seam
- v1 `heightmap_grid` terrain round trips exactly after localized survey/detail support is added
- edit kernels remain storage-agnostic and do not depend on generated mesh identity
- migration, corrupt-payload, unsupported-version, and compatibility behavior are covered by tests
