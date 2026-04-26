# Task: MTA-10 Implement Partial Terrain Output Regeneration
**Task ID**: `MTA-10`
**Title**: `Implement Partial Terrain Output Regeneration`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](specifications/hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

After bulk full-grid output and region-aware planning are in place, managed terrain can know which sample windows changed, but production output still regenerates the complete derived mesh. That is simple and safe, but it can remain expensive for repeated localized edits on larger terrain. Partial output regeneration should update only affected output regions when the output state is safe enough to do so.

This task implements partial terrain output regeneration as a bounded output-layer capability for the current managed terrain state model. It must prove mesh-region ownership, seams, derived markers, normals, cleanup, undo, and save/reopen behavior before partial output can become production behavior. Durable localized-detail terrain representation work remains outside this task.

## Goals

- regenerate only affected derived terrain output regions when partial regeneration is safe
- define output-region ownership and cleanup behavior for partial replacement
- preserve adjacent terrain coherence, derived markers, positive-Z normals, and output summary digest linkage
- fall back or refuse clearly when partial output cannot be trusted
- validate partial output behavior in live SketchUp, including undo and save/reopen where applicable
- keep the task scoped to local output regeneration rather than broad localized-detail representation

## Acceptance Criteria

```gherkin
Scenario: a bounded edit regenerates only affected output regions
  Given a Managed Terrain Surface has region-aware output planning available
  And a supported edit changes a bounded sample window
  When partial output regeneration is safe for that output state
  Then only the affected derived output region is replaced or updated
  And unchanged adjacent output remains coherent with the regenerated region

Scenario: partial output preserves derived mesh invariants
  Given a partial output region has been regenerated
  When the resulting terrain output is inspected
  Then derived markers are present on the relevant generated entities
  And terrain face normals remain upward
  And mesh seams remain coherent at the boundary between regenerated and unchanged output
  And output digest or consistency evidence remains tied to the saved terrain state

Scenario: unsafe partial output falls back or refuses
  Given output-region ownership, seams, undo safety, or cleanup cannot be proven for a terrain output state
  When partial regeneration is requested by the output layer
  Then the system either falls back to full bulk regeneration or returns a structured refusal
  And it does not leave partially corrupted derived terrain output as the expected state

Scenario: hosted validation proves output coherence
  Given representative terrain cases include small, non-square, near-cap, and high-variation boundary edits
  When partial regeneration is validated in SketchUp
  Then validation records changed and unchanged output behavior, seams, markers, normals, undo, save/reopen where applicable, responsiveness, and fallback or refusal behavior
```

## Non-Goals

- implementing durable localized-detail terrain representation v2
- adding broad terrain storage migration or representation-unit dispatch
- adding new public terrain edit modes
- changing terrain source state from persisted heightmap-derived state to generated SketchUp mesh
- implementing broad mesh repair or unrestricted TIN surgery
- replacing validation and review policy with terrain output checks

## Business Constraints

- partial regeneration must improve localized edit performance without reducing terrain output trustworthiness
- supported terrain edits must remain undo-safe and recoverable
- full bulk output must remain available when partial regeneration cannot be made safe

## Technical Constraints

- SketchUp entity mutation remains isolated to terrain output adapter/generator boundaries
- partial output must preserve derived marker, normal, output summary digest, cleanup, and ownership invariants
- fallback or refusal behavior must be explicit when seam coherence or undo atomicity is not proven
- any minimal output-region bookkeeping must be justified by partial-output safety and must not become broad localized-detail representation work
- hosted SketchUp validation is mandatory before partial output is treated as production-ready

## Dependencies

- `MTA-08`
- `MTA-09`
- [Managed Terrain Surface Authoring HLD](specifications/hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](specifications/prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-09`
- keeps durable localized-detail representation work separated for `MTA-11`
- informs later scalable terrain output, localized representation, and validation diagnostics

## Related Technical Plan

- [Technical plan](./plan.md)

## Success Metrics

- supported localized edits can regenerate only affected output regions without corrupting adjacent terrain
- live SketchUp validation proves seams, markers, normals, undo, cleanup, and responsiveness
- unsafe partial-output states fall back or refuse clearly
- no generated face or vertex identity becomes durable terrain source state
- durable localized-detail representation remains outside the MTA-10 implementation scope
