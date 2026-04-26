# Task: MTA-08 Adopt Bulk Full-Grid Terrain Output In Production
**Task ID**: `MTA-08`
**Title**: `Adopt Bulk Full-Grid Terrain Output In Production`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

Managed terrain create and edit workflows currently regenerate the full derived SketchUp terrain mesh through a per-face output path. MTA-07 proved that a bulk full-grid candidate can produce equivalent derived output much faster in live grey-box validation, including near-cap high-relief terrain. That candidate is still validation-only, so production terrain workflows continue to pay the slower per-face regeneration cost.

This task promotes the validated bulk full-grid output path into production while preserving the current terrain ownership model: persisted `heightmap_grid` v1 remains authoritative, generated SketchUp TIN remains disposable derived output, and public MCP request and response shapes remain stable.

## Goals

- use the bulk full-grid output path for production terrain create and regenerate behavior
- preserve current full-grid terrain output semantics, output summaries, derived markers, positive-Z normals, and digest linkage
- keep persisted terrain state as `heightmap_grid` schema version 1
- retain a per-face output fallback or diagnostic baseline until hosted validation supports removing or demoting it
- prove production behavior through public MCP and live SketchUp validation on representative terrain cases

## Acceptance Criteria

```gherkin
Scenario: production terrain output uses the bulk full-grid path
  Given a supported Managed Terrain Surface is created or regenerated
  When production terrain output is generated
  Then the generated mesh uses the production bulk full-grid path
  And the output summary remains compatible with the existing `output.derivedMesh` response shape
  And persisted terrain state remains `payloadKind: "heightmap_grid"` with schema version 1

Scenario: bulk output preserves existing derived mesh invariants
  Given a representative terrain state is generated through the bulk output path
  When the derived mesh is inspected
  Then vertex and face counts match the expected regular-grid output
  And derived face and edge markers are present
  And terrain face normals are oriented upward
  And output digest linkage remains tied to the saved terrain state

Scenario: public create and edit workflows remain coherent
  Given public MCP create and edit terrain workflows are exercised
  When terrain output is generated through the bulk full-grid path
  Then create and edit responses remain JSON-safe and contract-compatible
  And undo restores prior terrain state and output coherently
  And unrelated unmanaged scene content is not deleted

Scenario: hosted validation covers representative terrain cases
  Given small, non-square, near-cap, and high-variation terrain cases are available
  When the production bulk output path is validated in SketchUp
  Then each case records success or refusal, timing, mesh counts, normals, derived markers, undo behavior, responsiveness, and unmanaged-scene safety
  And the per-face baseline remains available until the bulk path is accepted as the production default
```

## Non-Goals

- implementing partial terrain output regeneration
- introducing dirty-region output patching or chunked output ownership
- changing persisted terrain representation or adding schema v2
- changing public MCP terrain request fields or response vocabulary
- adding new terrain edit modes

## Business Constraints

- terrain authoring must remain usable for iterative workflows on representative near-cap terrain
- production output changes must not make generated SketchUp mesh geometry the source of truth
- public MCP clients should not need request-shape changes to benefit from faster output generation
- performance improvement must not come at the cost of undo, safety, or evidence reliability

## Technical Constraints

- `TerrainMeshGenerator` remains the owner of SketchUp terrain output mutation
- persisted terrain state must remain behind the terrain repository seam and stay compatible with v1 `heightmap_grid`
- public output summaries and edit evidence must remain JSON-serializable and contract-compatible
- derived output must preserve marker, normal-orientation, digest-linkage, and unmanaged-child safety invariants
- live SketchUp validation is required before the bulk path is considered production-ready

## Dependencies

- `MTA-07`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-07`
- informs `MTA-09`
- improves the output baseline consumed by `MTA-05` and `MTA-06`

## Related Technical Plan

- none yet

## Success Metrics

- public terrain create and edit workflows produce equivalent derived output through the bulk full-grid path
- near-cap terrain output is materially faster than the per-face baseline recorded in MTA-07
- hosted validation confirms undo, responsiveness, derived markers, positive-Z normals, digest linkage, and unmanaged-scene safety
- no persisted schema or public MCP contract drift is introduced
