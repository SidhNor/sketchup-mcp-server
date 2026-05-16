# Task: SAR-06 Tiled Groundcover Area Placement

**Task ID**: `SAR-06`  
**Title**: `Tiled Groundcover Area Placement`  
**Status**: `draft`  
**Priority**: `P1`  
**Date**: `2026-05-16`

## Linked HLD

- [Asset Exemplar Reuse](../../../hlds/hld-asset-exemplar-reuse.md)

## Problem Statement

Some reusable vegetation assets are not best used as one scaled object. A round or oval 12cm groundcover patch can work for a single local accent, but it becomes visibly wrong when scaled over terrain with changing slope. One rigid transform can only align to one local frame, so a large carpet-style instance cannot conform to an irregular area.

For area coverage, the reusable asset should instead be treated as a tile or clump source. A square tileable groundcover mesh, small mat, or repeated clump can be placed many times across a target region. Each placement can use its own local surface frame, heading variation, slope checks, and source lineage while preserving the staged Asset Exemplar.

This task defines the area-coverage workflow that uses staged assets as repeated coverage units. It is separate from `SAR-05`, which owns single rigid-instance orientation.

## Goals

- Support area groundcover placement from approved staged Asset Exemplars that are explicitly marked as tile or coverage assets.
- Define JSON-safe metadata for tile-capable staged assets, including coverage role, tile shape, tile size, tileable edges, spacing guidance, and surface-fit constraints.
- Create editable Asset Instances across a target area without scaling one carpet asset to fit the whole region.
- Use per-instance placement behavior compatible with `SAR-05`, including upright or surface-aligned orientation where allowed.
- Preserve source Asset Exemplars and write source lineage for every created Asset Instance.
- Return a structured coverage summary with counts, skipped placements, refusals, and placement evidence.

## Acceptance Criteria

```gherkin
Scenario: Discover tile-capable groundcover assets
  Given approved staged assets include a square tileable groundcover exemplar
  When staged assets are listed or serialized for selection
  Then the response includes its coverage role, tile shape, tile size, tileable edges, recommended spacing, and surface-fit constraints
  And the metadata is JSON-safe.

Scenario: Cover a planar area with repeated tiles
  Given an approved tile-capable groundcover exemplar
  And a supported planar target area is provided
  When the area coverage workflow is executed
  Then multiple editable Asset Instances are created inside the target area
  And no single instance is uniformly scaled to cover the whole area
  And each created instance carries source lineage back to the exemplar.

Scenario: Cover a sloped area with per-tile orientation
  Given an approved tile-capable groundcover exemplar whose orientation policy allows surface-aligned placement
  And a supported target area spans a constant or gently varying slope
  When the area coverage workflow is executed
  Then each created tile uses its own local placement frame
  And the response reports per-tile or summarized surface and slope evidence.

Scenario: Refuse incompatible non-coverage assets
  Given an approved staged asset that is not marked as a tile or coverage asset
  When the area coverage workflow is requested with that asset
  Then no model mutation occurs
  And the command returns a refusal identifying the missing or incompatible coverage metadata.

Scenario: Respect slope and surface-fit constraints
  Given an approved tile-capable groundcover exemplar with configured slope or surface-fit limits
  When part of the target area exceeds those limits
  Then the workflow either skips those placements or refuses the coverage request according to the requested failure policy
  And the response reports the skipped or refused reason.

Scenario: Preserve the staged asset library
  Given an approved staged Asset Exemplar is used as the tile source
  When area coverage creates repeated Asset Instances
  Then the source Asset Exemplar remains unchanged
  And the created objects are not rediscovered as Asset Exemplars.

Scenario: Undo removes the coverage operation
  Given area coverage creates multiple Asset Instances
  When the user invokes standard SketchUp undo for the operation
  Then the created coverage instances are removed as one coherent operation
  And the source Asset Exemplar remains present.
```

## Non-Goals

- Scaling a single carpet, oval patch, or tile asset to cover an arbitrary region.
- Texture, decal, material-only, or painted groundcover workflows.
- Generating a new terrain-conforming mesh surface for continuous cover.
- Full brush painting, interactive density painting, or live editing UI.
- Random botanical simulation beyond bounded placement variation needed for repeated tile or clump placement.
- Replacement/proxy workflows unless they can reuse the coverage result without changing this task's contract.

## Business Constraints

- Area coverage must reuse human-curated approved Asset Exemplars rather than arbitrary public search or ad hoc generated assets.
- Source Asset Exemplars must remain distinct from editable design-scene Asset Instances.
- The workflow should help designers cover terrain areas believably without requiring manual placement of every tile.
- Coverage metadata must remain category-extensible; vegetation-specific fields are examples, not a universal schema for every asset category.

## Technical Constraints

- Keep public MCP tool registration, schema updates, dispatcher wiring, docs, and tests in sync when adding a coverage workflow.
- Keep SketchUp-specific mutation inside the extension runtime path.
- Wrap multi-instance creation in a SketchUp operation so standard SketchUp undo removes the coverage result coherently.
- Return only JSON-serializable hashes, arrays, strings, numbers, booleans, or nil.
- Reuse the single-instance orientation semantics from `SAR-05` instead of duplicating transform policy.
- Validate coverage metadata before mutation, including finite option values for coverage role, tile shape, edge behavior, and failure policy.
- Enforce a placement cap or refusal path so accidental dense coverage does not create an unbounded number of instances.
- Surface sampling, clipping, and edge handling must be deterministic enough to test.

## Dependencies

- `SAR-01` curated staged asset discovery and metadata.
- `SAR-02` editable Asset Instance creation.
- `SAR-05` single-instance orientation-aware placement.
- [PRD: Staged Asset Reuse](../../../prds/prd-staged-asset-reuse.md).
- [Low Poly Garden Vegetation Inventory](../../../research/asset-reuse/low_poly_garden_vegetation_inventory.md).

## Relationships

- depends on `SAR-05` for per-instance orientation semantics.
- informs future vegetation scatter, groundcover painting, or terrain-conforming cover capabilities.
- may inform `SAR-04` if proxy replacement later needs to replace a single proxy with an area coverage result.

## Related Technical Plan

- none yet

## Success Metrics

- A reviewer can identify tile-capable staged assets from structured metadata without inspecting raw SketchUp geometry.
- A supported area coverage request creates multiple editable Asset Instances with source lineage and without mutating the source exemplar.
- Coverage refuses or skips invalid placements according to documented slope, surface-fit, metadata, and count-limit rules.
- Standard SketchUp undo removes a generated coverage set as one coherent operation.
- Existing `instantiate_staged_asset` single-instance behavior remains unchanged by the area coverage workflow.
