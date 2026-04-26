# Task: MTA-07 Define Scalable Terrain Representation Strategy
**Task ID**: `MTA-07`
**Title**: `Define Scalable Terrain Representation Strategy`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-26`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The first managed terrain slices establish a uniform heightmap grid as the authoritative terrain state and regenerate derived SketchUp output from that state. Live MTA-03 performance evidence shows the current near-cap terrain path is workable, but repeat terrain edits can become expensive if every workflow depends on a uniformly fine grid and full derived-output regeneration.

Managed terrain needs a scalable representation strategy before later editing workflows are pushed toward globally dense sampling. The follow-up must determine how Managed Terrain Surface state and derived output should support localized detail, larger terrain extents, and future edit kernels without returning to live-TIN surgery or making generated SketchUp mesh geometry the source of truth.

Relevant UE research notes from MTA-04 planning:

- UE Landscape uses componentized heightmap data rather than one naive global mesh.
- UE terrain scale is handled through components, subsections, heightmap textures, LOD, LOD blending, streaming proxies, World Partition, and edit layers.
- UE height edits operate through rectangular heightmap read/write regions.
- UE Landscape Patch and edit-layer systems support local procedural effects, but they still operate against the landscape heightmap/edit-layer system rather than making arbitrary generated mesh geometry authoritative.
- UE does not appear to use arbitrary adaptive per-small-area heightmap resolution as the baseline core Landscape model.
- The planning lesson for this repository is not to copy UE architecture, but to evaluate comparable concepts such as tiled/chunked terrain state, output LOD or simplification, local patch/constraint overlays, and representation boundaries that avoid globally dense sampling.

## Goals

- define the supported next representation direction for terrain detail beyond one uniform heightmap grid
- evaluate tiled or chunked heightmaps, localized refinement, patch or constraint overlays, richer sampled representations, and storage/output implications as candidate approaches
- preserve the core managed terrain rule that materialized terrain state is authoritative and generated SketchUp geometry is derived output
- identify how future bounded edits, corridor transitions, and fairing kernels should interact with the selected representation direction
- define testable storage, regeneration, evidence, and migration expectations for the selected direction

## Acceptance Criteria

```gherkin
Scenario: scalable representation direction is selected
  Given MTA-03 live performance evidence and MTA-04 planning constraints are available
  When the scalable terrain representation task is completed
  Then it identifies a selected representation direction for terrain detail beyond one uniform heightmap grid
  And it records why candidate approaches such as tiled grids, local refinement, patch overlays, richer sampled state, or sidecar-backed storage were accepted, rejected, or deferred
  And it uses UE terrain findings as non-normative comparison evidence rather than as public API or architecture requirements

Scenario: selected representation preserves managed terrain ownership
  Given a Managed Terrain Surface uses materialized terrain state and derived SketchUp output
  When the scalable representation direction is reviewed
  Then terrain state remains the source of truth
  And generated SketchUp mesh geometry remains disposable derived output
  And stable terrain owner identity, metadata, name, tag, and terrain-state payload ownership remain protected

Scenario: representation strategy defines edit and output expectations
  Given future terrain edits may require localized detail or larger terrain extents
  When the representation strategy is reviewed
  Then it defines how bounded edits identify affected terrain regions or representation units
  And it defines expected output regeneration granularity or explicitly documents why full regeneration remains acceptable
  And it defines how evidence reports changed regions without durable generated face or vertex identifiers

Scenario: storage and migration implications are explicit
  Given existing terrain state is stored through the terrain repository seam
  When the representation strategy is completed
  Then it identifies required storage schema, payload-size, chunking, compression, migration, or sidecar implications
  And it defines refusal or compatibility behavior for terrain states that cannot be loaded, migrated, edited, or regenerated safely

Scenario: follow-on implementation work is sequenced
  Given the selected representation direction may affect future edit kernels
  When the task is completed
  Then it identifies which follow-on implementation tasks are needed
  And it states whether MTA-05 or MTA-06 can proceed on the existing uniform-grid substrate or should wait for representation work
```

## Non-Goals

- implementing a new terrain representation in this task unless a later technical plan explicitly narrows the work to an implementation slice
- changing MTA-04 bounded grade edit MVP scope
- requiring chunked output regeneration for MTA-04
- importing Unreal Engine Landscape architecture wholesale into the SketchUp MCP runtime
- making semantic hardscape objects part of terrain source state
- returning to arbitrary live-TIN mutation as the supported terrain editing substrate

## Business Constraints

- the representation direction must support practical managed terrain editing without forcing unnecessary fine detail across an entire terrain surface
- the product must remain honest about terrain resolution, edit fidelity, and performance limits
- terrain authoring must continue to produce evidence that supports downstream review and validation
- hardscape objects such as paths, pads, and retaining edges must remain independent Managed Scene Objects

## Technical Constraints

- terrain state must remain behind the terrain repository seam rather than leaking storage details into edit kernels
- `su_mcp` metadata must remain lightweight identity metadata, not bulky terrain state storage
- derived SketchUp geometry must not become the durable source of truth
- any selected representation must preserve JSON-safe evidence and refusal behavior
- storage, migration, output regeneration, undo behavior, and hosted SketchUp performance must be testable before implementation is considered complete
- future representation work must account for existing `heightmap_grid` states created by MTA-03 and edited by MTA-04
- UE findings are research inputs only; public tool names, Ruby architecture, and SketchUp storage behavior must remain product-shaped for this extension

## Dependencies

- `MTA-03`
- `MTA-04`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-04`
- informs `MTA-05`
- informs `MTA-06`
- may create follow-on implementation tasks for tiled terrain state, local refinement, patch overlays, chunked output regeneration, storage migration, or sidecar-backed payloads

## Related Technical Plan

- none yet

## Success Metrics

- a selected scalable terrain representation direction is documented with accepted, rejected, and deferred alternatives
- storage and migration implications for existing `heightmap_grid` terrain states are explicit
- future edit kernels have clear guidance on whether they can use the uniform-grid substrate or need representation work first
- evidence and output-regeneration expectations are specific enough to drive later task planning
- performance and fidelity risks are captured with measurable validation expectations
