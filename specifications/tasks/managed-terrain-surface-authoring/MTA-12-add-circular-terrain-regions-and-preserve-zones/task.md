# Task: MTA-12 Add Circular Terrain Regions And Preserve Zones
**Task ID**: `MTA-12`
**Title**: `Add Circular Terrain Regions And Preserve Zones`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain editing currently supports rectangular bounded grade edits and corridor transitions, while the next local fairing task is planned around bounded edit regions. Real grading and cleanup workflows also need round local influence areas, especially around trees, planting islands, local mounds, depressions, and other radial site conditions. Approximating those cases with rectangles creates artificial corners and weakens the terrain-edit contract.

This task extends the existing `edit_terrain_surface` region vocabulary with circular edit regions and circular preserve zones for the shipped local-area edit modes, after local fairing exists.

## Goals

- Support circular `target_height` edit regions.
- Support circular `local_fairing` edit regions after `MTA-06` adds local fairing.
- Support circular preserve zones for `target_height` and `local_fairing`.
- Keep circular behavior inside the existing managed terrain edit command family.
- Return the same JSON-safe terrain edit evidence style used by existing edit modes.
- Preserve managed terrain state, output regeneration, undo, and refusal behavior.

## Acceptance Criteria

```gherkin
Scenario: target-height edit supports a circular region
  Given a Managed Terrain Surface exists with saved heightmap terrain state
  When edit_terrain_surface is called with operation.mode "target_height" and region.type "circle"
  Then stored terrain samples inside the circular edit influence are updated toward the target elevation
  And samples outside the circle and blend influence remain unchanged
  And the result includes changed-region and sample evidence without raw SketchUp objects

Scenario: local fairing supports a circular region
  Given MTA-06 local fairing is available for Managed Terrain Surfaces
  When edit_terrain_surface is called with operation.mode "local_fairing" and region.type "circle"
  Then fairing is bounded to the circular region and blend influence
  And fairing evidence remains compatible with the existing local fairing evidence shape

Scenario: circular preserve zones protect local terrain
  Given a target-height or local-fairing edit includes a circular preserve zone
  When the edit is applied
  Then samples protected by the circular preserve zone remain unchanged within documented tolerance
  And unprotected affected samples can still be edited

Scenario: unsupported circular combinations refuse clearly
  Given an edit request combines circle regions or preserve zones with an unsupported operation mode
  When the request is validated
  Then the command returns a structured refusal with finite allowed values
  And it does not mutate terrain state or derived output
```

## Non-Goals

- adding polygon or freeform terrain regions
- adding circular behavior to `corridor_transition` unless separately justified
- adding survey point constraints
- changing terrain state representation or adding localized detail zones
- changing public output to expose internal dirty-window, partial-regeneration, face, or vertex identifiers

## Business Constraints

- circular regions must improve practical local terrain authoring without broadening the tool into sculpting or brush UI
- existing rectangle and corridor behavior must remain stable
- terrain evidence must stay understandable to downstream validation and review workflows
- semantic hardscape objects remain separate from terrain state

## Technical Constraints

- circle coordinates, radius, and blend distances are expressed in the stored terrain state's public-meter XY frame
- edit kernels must operate on materialized terrain state, not raw SketchUp geometry
- derived SketchUp terrain output remains disposable output regenerated or partially regenerated from stored state
- request validation, loader schema, finite refusals, native contract fixtures, tests, and README documentation must stay in sync
- outputs must remain JSON-serializable and must not expose raw SketchUp objects

## Dependencies

- `MTA-04`
- `MTA-06`
- `MTA-10`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-06` so circular regions apply consistently to target-height and local-fairing modes
- informs `MTA-13` by establishing round local influence and preserve-zone vocabulary

## Related Technical Plan

- none yet

## Success Metrics

- circular target-height edits update only the intended radial influence area in automated terrain-kernel tests
- circular local fairing improves the selected fairing metric only inside the intended radial influence area
- circular preserve zones protect affected terrain samples in both supported local-area edit modes
- public schema, finite refusal payloads, docs, and contract fixtures all advertise the same supported circular combinations
