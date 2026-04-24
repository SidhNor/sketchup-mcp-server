# Summary: MTA-01 Establish Managed Terrain Domain And Research Reference Posture
**Task ID**: `MTA-01`
**Status**: `completed`
**Date**: `2026-04-25`

## Shipped

- Added `Managed Terrain Surface` to [`domain-analysis.md`](../../../domain-analysis.md) as a terrain-specific Managed Scene Object concept.
- Added a Scene Objects row, product-slice categorization row, and lightweight Managed Terrain Surface lifecycle mapping.
- Clarified that `path`, `pad`, and `retaining_edge` remain separate hardscape Managed Scene Objects outside terrain source state.
- Created the curated UE research note at [`ue-reference-phase1.md`](../../../research/managed-terrain/ue-reference-phase1.md).
- Removed the former active root-level UE terrain guide from repo posture.
- Updated the terrain HLD and task README to link to the curated non-normative research note.
- Updated the terrain PRD and HLD so they no longer describe Managed Terrain Surface as missing from the shared domain model.
- Updated MTA-01 task metadata and estimation calibration.

## Validation

- Pre-edit baseline was recorded with shell checks:
  - `rg -n "Managed Terrain Surface" specifications/domain-analysis.md` returned no matches.
  - `test -f specifications/research/managed-terrain/ue-reference-phase1.md` failed.
  - stale-reference search for the former root-level UE terrain guide found HLD/task-plan references.
  - `rg -n "not yet listed|currently lacks Managed Terrain Surface|Should the domain analysis add Managed Terrain Surface" specifications/prds/prd-managed-terrain-surface-authoring.md specifications/hlds/hld-managed-terrain-surface-authoring.md` found stale missing-domain language.
- Post-edit docs-posture checks passed:
  - `rg -n "Managed Terrain Surface" specifications/domain-analysis.md`
  - `rg -n "non-normative|research-only|UE Inspection Cadence|MTA-04|MTA-05|MTA-06" specifications/research/managed-terrain/ue-reference-phase1.md`
  - the former root-level UE terrain guide was absent.
  - repo-wide stale-reference search under `specifications/` returned no matches for the former root-level UE terrain guide.
  - `rg -n "not yet listed|currently lacks Managed Terrain Surface|Should the domain analysis add Managed Terrain Surface" specifications/prds/prd-managed-terrain-surface-authoring.md specifications/hlds/hld-managed-terrain-surface-authoring.md` returned no matches.
  - `rg -n "terrain\.create_surface|terrain\.flatten|terrain\.smooth|terrain\.ramp|src/su_mcp/terrain|TerrainRepository|TerrainEngine|TerrainGeometryAdapter|TerrainCommand" specifications/domain-analysis.md specifications/hlds/hld-managed-terrain-surface-authoring.md specifications/prds/prd-managed-terrain-surface-authoring.md specifications/tasks/managed-terrain-surface-authoring/README.md specifications/research/managed-terrain/ue-reference-phase1.md` returned no matches.
  - `git diff --check`
- Grok 4.20 codereview completed with no critical, high, medium, or low findings.

## Contract And Runtime Notes

- No public MCP tool names, request schemas, response schemas, dispatcher entries, runtime registrations, or README tool examples changed.
- No finite user-facing runtime option set changed.
- Runtime contract alignment checks were not applicable because this task changed only documentation and specifications.

## Remaining Manual Verification

- No live SketchUp verification was run. The changed surface is documentation-only and does not touch Ruby runtime behavior, package layout, SketchUp API usage, or hosted extension behavior.
