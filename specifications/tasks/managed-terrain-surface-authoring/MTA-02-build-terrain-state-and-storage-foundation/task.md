# Task: MTA-02 Build Terrain State And Storage Foundation
**Task ID**: `MTA-02`
**Title**: `Build Terrain State And Storage Foundation`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-24`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain authoring depends on a materialized terrain state that can be loaded, edited, validated, and regenerated without treating live SketchUp TIN geometry as the source of truth. The current runtime has Managed Scene Object metadata in the `su_mcp` dictionary and terrain sampling capabilities, but it has no terrain-specific state model or storage seam.

This task creates the terrain state and storage foundation without adding adoption, edit tools, or generated mesh output. It should prove that heightmap-based terrain state can exist as SketchUp-free Ruby domain data, that payload storage is separate from lightweight `su_mcp` identity metadata, and that storage failures are explicit.

## Goals

- define a SketchUp-free heightmap/grid terrain state suitable for later adoption and edit tasks
- establish owner-local coordinate semantics for terrain state
- create a terrain repository seam and storage adapter contract
- store terrain payloads in a terrain-specific namespace outside the existing `su_mcp` metadata dictionary
- provide deterministic version, integrity, missing-state, and unsupported-state refusal behavior

## Acceptance Criteria

```gherkin
Scenario: terrain state is independent of SketchUp entities
  Given a terrain state is created in isolated Ruby tests
  When its extents, owner-local basis, grid topology, elevations, and revision data are inspected
  Then the state can be represented without raw SketchUp objects
  And it can be serialized into JSON-safe or storage-safe primitives

Scenario: terrain payload storage is separate from su_mcp metadata
  Given a stable terrain owner test double or host-backed entity supports attributes
  When terrain state is saved through the terrain repository seam
  Then lightweight identity metadata remains in `su_mcp`
  And the heightmap terrain payload is stored in a terrain-specific namespace
  And raw terrain payload data is not written into the `su_mcp` dictionary

Scenario: stored terrain state round trips through the repository
  Given a supported terrain state payload has been saved
  When the terrain repository loads that payload
  Then the loaded state matches the original owner-local state values
  And the repository does not expose raw attribute-dictionary handles to terrain domain services

Scenario: unsupported or corrupt stored state refuses explicitly
  Given stored terrain state is missing, corrupt, unsupported, or fails integrity validation
  When the terrain repository attempts to load it
  Then the result is a structured refusal or recovery outcome
  And no caller is expected to continue with fabricated terrain state
```

## Non-Goals

- adopting existing SketchUp terrain
- creating or regenerating terrain mesh output
- adding public MCP terrain tools
- implementing grade, transition, smoothing, or fairing edits
- storing terrain state in sidecar files

## Business Constraints

- terrain state must be durable enough to support later managed authoring workflows
- payload storage must not overload the existing Managed Scene Object metadata dictionary
- unsupported or unsafe state must refuse clearly rather than encouraging fallback `eval_ruby`

## Technical Constraints

- terrain domain values must not expose raw SketchUp objects
- terrain state must use a stable owner-local coordinate basis
- storage must support version and integrity checks from the first persisted format
- outputs and refusals must remain JSON-serializable where they cross runtime-facing boundaries
- implementation must be testable without SketchUp where practical

## Dependencies

- `MTA-01`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- unblocks `MTA-03`
- establishes storage and state contracts consumed by `MTA-04`, `MTA-05`, and `MTA-06`

## Related Technical Plan

- [Technical implementation plan](./plan.md)

## Success Metrics

- terrain state round-trip coverage passes without SketchUp
- tests prove payload storage is outside `su_mcp`
- unsupported version, corrupt payload, and missing-state cases return explicit refusal or recovery outcomes
