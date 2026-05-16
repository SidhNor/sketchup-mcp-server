# Task: SAR-05 Orientation-Aware Asset Placement

**Task ID**: `SAR-05`
**Title**: `Orientation-Aware Asset Placement`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-05-15`

## Linked HLD

- [Asset Exemplar Reuse](../../../hlds/hld-asset-exemplar-reuse.md)

## Related Technical Plan

- [Technical Plan](./plan.md)

## Problem Statement

`SAR-02` establishes editable Asset Instance creation from curated staged assets, but its initial placement semantics are position-first and do not yet define orientation beyond whatever transform happens to exist on the source asset. That is too narrow for single rigid assets such as rocks, stepping stones, small groundcover clumps, square groundcover tiles, and manually placed decorative patches that may need heading control or alignment to a local surface.

Game-engine foliage systems generally treat this as mesh placement behavior, not texture placement. Unreal foliage exposes separate controls for normal alignment, maximum alignment angle, random yaw, random pitch, slope limits, and offsets. Unity Terrain details expose mesh instancing with an Align to Ground percentage that rotates the detail toward the terrain normal. Godot-style MultiMesh and Terrain3D instancing workflows separate spin, tilt, normal alignment, slope filtering, and height offset.

The SketchUp MCP staged-asset workflow needs the same conceptual separation for single-instance authoring: optional heading/yaw and optional surface-derived alignment. Callers should not have to provide a surface basis manually. Surface-aware placement should use a concrete surface reference plus placement point when the runtime can derive the local frame. Arbitrary transforms belong to the existing entity transform workflow rather than a second placement contract on `instantiate_staged_asset`. Trees and upright shrubs should not be silently tilted just because they are placed on a slope; small surface-hugging assets should be able to opt into that behavior through explicit placement input.

## Scope

### Goals

- Extend staged asset instantiation semantics to support optional orientation input for single rigid Asset Instance creation.
- Preserve optional staged asset orientation metadata as JSON-safe property-bag information when present, without making it required for placement behavior.
- Support optional yaw/heading rotation around the selected placement up axis while preserving source heading when yaw is omitted.
- Support surface-aware placement when explicitly requested by deriving the local placement frame from a referenced surface and placement point.
- Validate orientation request shape and surface references before mutating the SketchUp model.
- Preserve the existing `SAR-02` position/scale-only instantiation behavior.
- Return compact JSON-serializable placement evidence that includes the applied orientation mode, yaw/heading behavior, derived surface hit evidence when applicable, and refusal details when applicable.

### Non-Goals

- Procedural scatter painting, density fields, brush tools, distribution jitter, or random placement.
- Area coverage, tiling, repeated groundcover placement, or "cover this region" workflows.
- A new arbitrary transform contract for `instantiate_staged_asset`; callers that need arbitrary post-placement transforms should use the existing entity transform workflow.
- Texture, decal, or material-only vegetation workflows.
- Automatic terrain inference from asset category alone.
- Broad terrain sampling, terrain-conforming mesh generation, or arbitrary raycast search beyond resolving a specific referenced surface/point for this single instance.
- Reworking the curated garden vegetation inventory or normalizing source component definitions.
- Replacement/proxy consumption of orientation behavior.

## Requirements

### Functional Requirements

1. `instantiate_staged_asset` accepts an optional orientation request without changing existing required parameters.
2. Orientation input supports optional yaw rotation in degrees.
3. Orientation input supports a finite mode set:
   - `upright`: keep the asset's up axis aligned to model vertical and apply any requested yaw around model vertical.
   - `surface_aligned`: align the asset to the local frame derived from `placement.orientation.surfaceReference` at the request `placement.position` XY, then apply any requested yaw around that local up axis.
4. Optional staged asset metadata may carry orientation hints in the existing JSON-safe property bag, but SAR-05 placement behavior is driven by explicit `placement.orientation` input rather than by metadata policy.
5. When yaw is omitted, instantiation preserves the source asset heading rather than forcing an arbitrary rotation.
6. A `surface_aligned` request requires `placement.orientation.surfaceReference`; the surface sample point is the request `placement.position` XY and the applied Z comes from the resolved surface hit.
7. The command refuses a `surface_aligned` request before mutation when a supported surface reference or unambiguous surface hit is not available.
8. The command refuses before mutation when the referenced surface cannot produce one unambiguous local placement frame.
9. The command does not allow staged asset metadata to veto explicit caller orientation intent in this task.
10. The response includes applied orientation evidence for successful placement.
11. Refusal responses include the refused field, requested value, allowed values or bounds, and a human-readable reason.
12. Existing position-only and position-plus-scale requests remain valid and produce the same orientation behavior as `SAR-02`.

### Technical Requirements

- Keep public MCP tool registration, schema updates, dispatcher wiring, docs, and tests in sync.
- Keep SketchUp-specific mutation inside the extension runtime path.
- Wrap the creation mutation in a SketchUp operation so standard SketchUp undo behavior remains intact.
- Return only JSON-serializable hashes, arrays, strings, numbers, booleans, or nil.
- Do not pass raw SketchUp objects or raw surface geometry across command boundaries.
- Keep orientation request parsing strict so unknown request modes or misplaced fields fail clearly during validation.
- Prefer reusable transform construction in the staged asset command layer rather than duplicating transform math across callers.
- Include unit-level or runtime integration coverage for validation and transform intent where SketchUp-hosted verification is not practical.

## Acceptance Criteria

### Scenario 1: Explicit Upright Yaw

**Given** a curated staged asset
**When** `instantiate_staged_asset` is called with `placement.orientation.mode = "upright"` and `placement.orientation.yawDegrees = 45`
**Then** the created Asset Instance is rotated around model vertical by 45 degrees
**And** the response reports `placement.orientation.mode = "upright"` and `placement.orientation.yawDegrees = 45`.

### Scenario 2: Omitted Yaw Preserves Source Heading

**Given** a curated staged asset with a known source heading
**When** `instantiate_staged_asset` is called without `placement.orientation.yawDegrees`
**Then** the created Asset Instance preserves the source asset heading
**And** the response reports that no yaw override was applied.

### Scenario 3: Surface-Aligned Placement From Referenced Surface

**Given** a curated staged asset
**And** a supported target surface reference is provided under `placement.orientation.surfaceReference`
**When** `instantiate_staged_asset` is called with `placement.orientation.mode = "surface_aligned"` and optional `placement.orientation.yawDegrees`
**Then** the command derives the local placement frame from the referenced surface at the request `placement.position` XY
**And** the created Asset Instance aligns to that local frame
**And** yaw is applied around the local up axis
**And** the response reports derived surface evidence and computed slope.

### Scenario 4: Surface Ambiguity Refusal

**Given** a supported target surface reference and placement point that resolve to multiple conflicting local frames
**When** `instantiate_staged_asset` is called with `placement.orientation.mode = "surface_aligned"`
**Then** no model mutation occurs
**And** the command returns a refusal identifying the ambiguous surface frame.

### Scenario 5: Missing Or Invalid Surface Reference Refusal

**Given** a staged asset
**When** `instantiate_staged_asset` is called with `placement.orientation.mode = "surface_aligned"` without a supported surface reference
**Then** no model mutation occurs
**And** the command returns a refusal identifying the missing or invalid surface reference.

### Scenario 6: Compact Surface-Aligned Evidence

**Given** a staged asset is placed with a valid `surface_aligned` request
**When** the command succeeds
**Then** the response includes compact applied orientation evidence
**And** the evidence includes the applied mode, yaw behavior, surface hit point, and slope degrees without verbose raw geometry.

### Scenario 7: Backward Compatibility

**Given** a valid `SAR-02` style instantiation request with position and optional scale only
**When** `instantiate_staged_asset` is called without orientation input
**Then** the command succeeds using the existing `SAR-02` placement semantics and source-heading preservation
**And** no caller is required to provide orientation metadata.

### Scenario 8: Optional Metadata Discoverability

**Given** a curated staged asset with orientation metadata
**When** staged assets are listed or serialized for caller inspection
**Then** the response preserves those orientation hints in JSON-safe property-bag form
**And** those hints do not change explicit SAR-05 placement behavior.

## Dependencies

- `SAR-01` curated staged asset discovery and metadata.
- `SAR-02` editable Asset Instance creation.
- [PRD: Staged Asset Reuse](../../../prds/prd-staged-asset-reuse.md).
- [Low Poly Garden Vegetation Inventory](../../../research/asset-reuse/low_poly_garden_vegetation_inventory.md).

## Relationships

- informs `SAR-06` tiled groundcover area placement by defining the single-instance orientation primitive it can reuse.

## Open Questions

- What exact tolerances should define an ambiguous surface frame when several faces are hit at the same placement point?

## Implementation Notes

- Keep the first implementation intentionally deterministic: no random yaw, random tilt, jitter, or distribution parameters.
- Keep area coverage and tiling in `SAR-06`; `SAR-05` places one rigid Asset Instance.
- Treat engine precedent as conceptual guidance rather than copying engine-specific behavior.
- Do not use asset category names or metadata hints to silently tilt assets; surface alignment is explicit request behavior in SAR-05.
- Prefer a transform-building helper that can be tested with numeric vectors and serialized evidence outside a live SketchUp scene.
