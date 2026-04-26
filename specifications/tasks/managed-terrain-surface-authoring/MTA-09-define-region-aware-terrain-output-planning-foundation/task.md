# Task: MTA-09 Define Region-Aware Terrain Output Planning Foundation
**Task ID**: `MTA-09`
**Title**: `Define Region-Aware Terrain Output Planning Foundation`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain edit kernels can identify affected terrain samples, and MTA-07 introduced `SampleWindow` and a full-grid output plan. Production output still treats every regeneration as full-grid output, even when an edit only changes a bounded sample region. Before partial mesh replacement can be implemented safely, terrain output planning needs an internal vocabulary for dirty windows and output regions that does not leak into persisted state or public MCP contracts.

This task creates that region-aware planning foundation while preserving full bulk regeneration as the production fallback. It should make affected-region handoff explicit for future edit kernels without implementing partial SketchUp mesh replacement.

## Goals

- define internal output planning concepts for full-grid output and dirty sample-window intent
- let terrain edit kernels hand affected `SampleWindow` information to the output planning layer
- preserve full bulk regeneration as the production output behavior while region intent is introduced
- keep persisted `heightmap_grid` v1 and public terrain evidence stable
- establish testable boundaries for future partial output regeneration

## Acceptance Criteria

```gherkin
Scenario: output planning can represent full-grid and dirty-window intent
  Given a managed terrain edit produces affected sample-window information
  When terrain output planning is requested
  Then the planner can represent full-grid output intent
  And it can represent dirty-window intent without requiring partial SketchUp mesh replacement
  And production output can still choose full bulk regeneration as a fallback

Scenario: edit kernels hand off affected sample windows
  Given a terrain edit kernel reports changed samples or affected windows
  When command orchestration prepares terrain output
  Then the affected window is passed through an internal output-planning boundary
  And edit kernels do not mutate SketchUp entities directly

Scenario: region-aware planning preserves public and persisted contracts
  Given terrain state and public edit evidence are serialized
  When region-aware output planning has been used internally
  Then persisted terrain payloads remain `heightmap_grid` schema version 1
  And internal output-plan or `SampleWindow` keys do not leak into public MCP responses
  And existing `changedRegion` evidence vocabulary remains compatible

Scenario: future partial regeneration has a clear boundary
  Given a dirty output window is available
  When partial regeneration is not yet supported or not safe
  Then the system can fall back to full bulk regeneration
  And the output planning result records enough internal intent for later partial-regeneration implementation planning
```

## Non-Goals

- replacing only part of the SketchUp terrain mesh
- introducing chunked derived output ownership
- adding persisted terrain representation v2
- changing public MCP terrain request fields
- adding rich terrain validation verdicts

## Business Constraints

- region-aware output planning must support future performance work without disrupting current terrain-authoring workflows
- public terrain evidence should remain stable for downstream validation and review consumers
- future edit kernels such as corridor transition and fairing should be able to use the planning boundary without owning SketchUp output mutation

## Technical Constraints

- `TerrainMeshGenerator` remains the sole owner of SketchUp terrain output mutation
- edit kernels may produce `SampleWindow` or output-planning inputs but must not create, erase, or mark SketchUp entities
- internal planning data must not be persisted inside v1 terrain state unless a later explicit schema task changes that contract
- public response shapes must remain JSON-safe and contract-compatible
- full bulk regeneration must remain available as the safe production fallback

## Dependencies

- `MTA-07`
- `MTA-08`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-08`
- informs `MTA-10`
- provides an output-planning boundary that `MTA-05` and `MTA-06` may consume without depending on partial regeneration

## Related Technical Plan

- [Technical plan](./plan.md)

## Success Metrics

- output planning can model full-grid and dirty-window intent in tests
- edit kernels can hand affected-window data to output planning without touching SketchUp entities
- no internal output-plan fields leak into v1 terrain persistence or public MCP response contracts
- production full bulk regeneration remains a safe fallback
