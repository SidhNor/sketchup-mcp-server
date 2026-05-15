# SAR-02 Implementation Summary

**Status**: `completed`  
**Task**: `SAR-02 Instantiate Editable Asset Instances`  
**Captured**: `2026-05-15`

## Delivered

- Added `instantiate_staged_asset` as a first-class native MCP tool for approved Asset Exemplars.
- Added staged asset instance support:
  - `AssetInstanceCreator` for model-root component and group instance creation.
  - `AssetInstanceMetadata` for managed object identity, lean source lineage, and exemplar-field cleanup.
  - `AssetInstanceSerializer` for JSON-safe instance, source asset, lineage, placement, and bounds evidence.
- Updated `StagedAssetCommands` with pre-mutation target, approval, placement, scale, and `metadata.sourceElementId` validation.
- Wrapped instantiation in one SketchUp operation named `Instantiate Staged Asset`.
- Wired the public tool through:
  - native MCP catalog schema and annotations
  - runtime dispatcher
  - runtime command factory and facade tests
  - native contract fixtures and public contract sweep
  - README and MCP tool reference docs
- Corrected live low-poly vegetation exemplar metadata for all 24 manually staged assets so `assetAttributes` include catalogue `representedSpecies`, `usageHints`, design-height evidence, and variant fields for asset numbers 7 and 13.

## Contract Notes

- `metadata.sourceElementId` is required and identifies the created Asset Instance, not the source exemplar.
- Created instances write `managedSceneObject: true`, `semanticType: "asset_instance"`, `assetRole: "instance"`, `assetInstanceSchemaVersion: 1`, their own `sourceElementId`, and lean `sourceAssetElementId` lineage.
- Created instances clear exemplar-only fields and are not returned by `list_staged_assets`.
- Placement is model-root only. `placement.position` is public meters and `placement.scale` is an optional positive scalar variation.
- SAR-02 does not add parent placement, replacement, status lifecycle, target-height fitting, generated identity, or a universal vegetation schema.
- Source `assetAttributes` remain category-specific JSON-safe evidence surfaced through the `sourceAsset` response.

## Tests Added

- Metadata tests for required instance identity, managed object fields, lean lineage, and exemplar-field cleanup.
- Serializer tests for JSON-safe `instance`, `sourceAsset`, `lineage`, `placement`, and optional `bounds`.
- Creator tests for component creation, group creation, source non-erasure, symbol/string placement keys, scalar scale, and preservation of curated component transform matrix axes while replacing only origin.
- Command tests for success, source stability, instance classification, placement/scale validation, missing metadata, unapproved exemplars, unsupported targets, ambiguous targets, and operation abort behavior.
- Runtime tests for dispatcher routing, command factory exposure, facade method exposure, native catalog/schema registration, contract fixtures, and public contract posture.

## Validation

- Focused creator regression after code review: `6 runs, 18 assertions, 0 failures`.
- Full CI after the final code-review fix:
  - RuboCop inspected 340 files with no offenses.
  - Ruby tests: `1385 runs, 15328 assertions, 0 failures, 40 skips`.
  - Package verification passed and produced `dist/su_mcp-1.8.0.rbz`.
- `mcp__pal__.codereview` with `model: "grok-4.3"` completed on the final change set.
  - Confirmed issue: transient component copies needed `ensure` cleanup on exception.
  - Fix applied: `AssetInstanceCreator#add_component_copy` now erases transient component copies in an `ensure` block.
  - Follow-up validation after review: a safe hosted group smoke passed through the production explicit reconstruction path.
  - Remaining review note: complex group fidelity beyond the simple primitive group smoke should still be expanded before relying on materials, UVs, softened edges, or richer nested assets.

## Live SketchUp Validation

- Live curation:
  - The scene group `Reusable Assets` was found and its 24 component-instance vegetation assets were curated as approved Asset Exemplars.
  - Curation was rerun after review with corrected catalogue-backed metadata from `low_poly_garden_vegetation_inventory.md`.
  - Verification showed all 24 assets have `representedSpecies` and `usageHints`, and no longer carry the earlier over-derived `nameDerivedRole`, `nameTokens`, or `sourceEvidence` fields.
- Live component instantiation:
  - Instantiated `asset-low-poly-garden-vegetation-12-bamboo-screen` through `McpRuntimeFacade#instantiate_staged_asset`.
  - Created `placed-sar02-live-bamboo-screen-002` as a component Asset Instance with lineage to the bamboo source exemplar.
  - Verified `list_staged_assets` still returned exactly the 24 approved exemplars; the created instance was not discoverable as an exemplar.
  - Verified curated component transform preservation: source bamboo bounds were about `2.09 x 2.06 x 2.98 m`; `placement.scale: 1.25` produced about `2.61 x 2.57 x 3.72 m`, and matrix axes retained the source orientation with the scalar variation applied.
- Live group instantiation:
  - A temporary staged group exemplar was created and curated for smoke validation.
  - A group exact-copy implementation using `add_group(existing_entities)` crashed SketchUp during hosted instantiation and was removed from production.
  - Production group support now uses explicit reconstruction.
  - Safe group smoke passed after reloading the final creator:
    - source group remained valid with persistent ID `26601008`
    - source bounds were about `1.8168 x 1.4237 x 0.4877 m`
    - created instance `placed-sar02-safe-group-copy-probe-001` had `semanticType: "asset_instance"` and lineage to `asset-sar02-safe-group-copy-probe`
    - instance bounds were about `1.9985 x 1.5660 x 0.5364 m`, matching the requested `scale: 1.1`
    - source and instance both contained 12 edges and 6 faces
    - cleanup removed both temporary source and created instance, with zero remaining metadata matches

## Remaining Follow-Up

- Expand hosted group-exemplar smoke coverage after defining the supported fidelity envelope for materials, softened edges, UVs, and richer nested assets.
- Consider a separate library-normalization command for baking manually resized component-instance transforms into definitions when that is the desired asset-management policy.
- Existing temporary group probe entities were not found after SketchUp recovered, but future group smoke should run in a clean throwaway model to avoid scene pollution.

## Task Metadata Updates

- Updated [task.md](./task.md) status to `completed`.
- Updated [plan.md](./plan.md) status to `implemented`.
- Updated [size.md](./size.md) status to `calibrated` with actual profile, validation evidence, and estimation delta.
