# Task: MTA-19 Implement Detail Preserving Adaptive Terrain Output Simplification
**Task ID**: `MTA-19`
**Title**: `Implement Detail Preserving Adaptive Terrain Output Simplification`
**Status**: `failed; implementation reverted`
**Priority**: `P1`
**Date**: `2026-05-01`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-11 proved that managed terrain can use tiled heightmap v2 state and regenerate adaptive
SketchUp output from that authoritative state. The first adaptive output slice is deliberately
simple: it simplifies planar and flat terrain aggressively and keeps more detail where error is
high, but it is not yet a high-quality terrain meshing strategy. It can still over-triangulate
some irregular areas, miss feature-aware simplification opportunities, and rely on a basic
corner-fit subdivision model rather than a stronger detail-preserving output strategy.

This task upgrades adaptive terrain output so generated SketchUp geometry better balances visual
quality, local terrain fidelity, face count, seams, and regeneration performance while preserving
the managed terrain source-of-truth model.

## Goals

- Improve adaptive terrain output quality beyond the MTA-11 first-slice simplifier.
- Preserve important terrain features such as ridges, valleys, bumps, crossfall planes, hard
  grade breaks, and planar fitted regions within documented tolerances.
- Reduce unnecessary faces in flat, planar, smooth-slope, and simplified edit regions.
- Keep generated SketchUp mesh output disposable and derived from `heightmap_grid` v2 state.
- Keep public output summaries compact: expose tolerance/status evidence needed for client
  confidence without returning bulky solver justification data or mesh-construction internals.
- Prove the improved simplifier through automated tests and live SketchUp MCP verification on
  representative terrain shapes.

## Acceptance Criteria

```gherkin
Scenario: flat and planar terrain remain highly simplified
  Given a managed terrain surface with flat or single-plane crossfall source elevations
  When adaptive output is regenerated
  Then the generated output uses a minimal or near-minimal face count for the supported grid
  And terrain profile samples match the source surface within the documented tolerance
  And the response does not expose internal solver, tile, or raw SketchUp object details

Scenario: irregular terrain keeps meaningful local detail
  Given a managed terrain surface with ridges, valleys, saddle variation, and localized bumps
  When adaptive output is regenerated
  Then visible output retains those terrain features within the documented simplification tolerance
  And profile samples across the features remain coherent with the authoritative terrain state
  And unnecessary triangles are reduced compared with a dense full-grid output

Scenario: edits shift simplification detail where terrain changes
  Given an irregular managed terrain has an adaptive output
  When a target-height, local-fairing, corridor-transition, or planar-region-fit edit changes part of the terrain
  Then regenerated output changes detail density in the edited and blend regions
  And unrelated regions do not gain avoidable extra faces
  And no stale generated output remains under the terrain owner

Scenario: feature-sensitive boundaries do not introduce mesh artifacts
  Given adaptive output crosses terrain features, edit boundaries, and simplification transitions
  When the generated SketchUp output is inspected
  Then there are no holes, loose edges, down-facing terrain faces, visible cracks, or unacceptable seam gaps
  And shared boundary elevations remain consistent within the documented tolerance

Scenario: simplification behavior is observable without leaking internals
  Given a client calls create, adopt, or edit terrain tools that regenerate adaptive output
  When the response is reviewed
  Then public summaries include compact output status, face-count, and tolerance/error fields
  And detailed simplification proof remains in automated and hosted verification rather than bulky response JSON
  And the response does not expose raw mesh IDs, raw SketchUp objects, solver matrices, tile payloads, or implementation class names

Scenario: unsupported or unsafe simplification cases refuse cleanly
  Given the terrain state contains unsupported no-data, corrupt state, or geometry that cannot be simplified safely
  When adaptive output regeneration is requested
  Then the command returns a structured refusal before destructive output mutation
  And any previous valid output remains available unless the operation has already committed a documented replacement
```

## Non-Goals

- changing `heightmap_grid` as the public or persisted payload kind
- making generated SketchUp mesh the terrain source of truth
- direct raw TIN editing, broad mesh repair, or unrestricted in-place mesh surgery
- adding freeform sculpting, stroke replay, erosion, weathering, or procedural terrain generation
- requiring clients to choose a low-level simplification algorithm by name
- selecting a specific advanced meshing algorithm in the task definition; candidates such as
  constrained Delaunay, breakline-aware triangulation, global mesh optimization, or hybrid
  quadtree approaches belong in the technical plan tradeoff analysis
- implementing visual terrain edit UI behavior from `MTA-18`
- changing terrain edit intent modes or their public request contracts except for documented output-summary evidence

## Business Constraints

- The improved output must reduce visual artifacts and manual cleanup risk for supported terrain edits.
- Terrain simplification should make managed terrain feel better in SketchUp without weakening the managed state and evidence model.
- Public MCP clients need compact stable summaries and tolerances, not algorithm-specific internals or verbose proof payloads.
- The first improved simplification slice should remain bounded enough to validate in live SketchUp rather than becoming an open-ended terrain-engine rewrite.

## Technical Constraints

- Ruby extension runtime remains the owner of terrain output planning, SketchUp API usage, and model mutation.
- `heightmap_grid` v2 terrain state remains authoritative; generated mesh output is disposable derived geometry.
- Output summaries must remain compact, JSON-serializable, and avoid raw SketchUp objects, durable generated face/vertex IDs, tile payload internals, solver internals, and verbose proof dumps.
- Regeneration must preserve coherent SketchUp undo behavior and owner metadata.
- Refusals must occur before destructive output mutation when unsafe input is detectable up front.
- The implementation must include automated coverage for simplification quality, contract shape, refusals, and mesh artifact checks, plus live SketchUp MCP verification on representative flat, planar crossfall, irregular, and edited terrains.

## Dependencies

- `MTA-11`
- `MTA-16`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)

## Relationships

- follows `MTA-11` because the first adaptive output path and tiled heightmap v2 state are now proven
- complements `MTA-16` by preserving planar-fit output quality and simplifying fitted planar regions
- may inform `MTA-18` because better generated output improves visual edit preview/apply quality
- may inform future profile QA work by producing clearer output-quality summaries for shape review

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- flat and planar crossfall terrains simplify to minimal or near-minimal output while sampling within tolerance
- representative irregular terrains preserve ridge, valley, bump, saddle, and crossfall shape within documented tolerance
- edited terrains show detail-density changes in edited/blend regions without broad unnecessary face growth
- live SketchUp verification finds no holes, loose edges, down-facing terrain faces, visible cracks, or unacceptable seam gaps in representative cases
- public MCP responses expose compact status/tolerance summaries without leaking implementation internals or bulky simplification proof
