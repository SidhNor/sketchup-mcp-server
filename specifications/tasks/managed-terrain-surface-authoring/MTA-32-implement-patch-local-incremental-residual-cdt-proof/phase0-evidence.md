# Phase 0 Evidence: MTA-32 Patch-Local CDT Proof

**Date**: `2026-05-10`

## Runtime Fixture Evidence

The Phase 0 probe exercises the runtime-owned internal proof seam with dirty-window output plans and
feature-geometry inputs. It does not route through public MCP responses or production SketchUp
replacement.

| Fixture class | Status | Stop reason | Max height error |
|---|---|---|---:|
| `flat_smooth` | `accepted` | `residual_satisfied` | `0.0` |
| `rough_high_relief` | `accepted` | `residual_satisfied` | `0.0` |
| `boundary_constraint` | `accepted` | `residual_satisfied` | `0.0` |
| `feature_intersection` | `accepted` | `residual_satisfied` | `0.0` |

## Live SketchUp Side-Terrain Evidence

Live verification ran inside `TestGround.skp` after deploying the MTA-32 proof files into the
installed SketchUp plugin. The run created fresh side managed terrains only, using public
`create_terrain_surface` and `edit_terrain_surface` calls, then derived the patch proof from the
post-edit stored state and actual dirty windows.

Run id: `20260510165448`

| Fixture class | Source element id | Dirty window | Patch bounds | Status | Stop reason | Initial max error | Final max error | Topology passed | Insertions | Rebuild detected | Runtime |
|---|---|---|---|---|---|---:|---:|---|---:|---|---:|
| `flat_smooth` | `mta32-clean-terrain-flat_smooth-20260510165448` | `7..9 x 7..9` | `5..11 x 5..11` | `accepted` | `residual_satisfied` | `0.14500000000000002` | `0.0` | `true` | `45` | `false` | `<0.05s` |
| `rough_high_relief` | `mta32-clean-terrain-rough_high_relief-20260510165448` | `7..9 x 7..9` | `5..11 x 5..11` | `accepted` | `residual_satisfied` | `1.6361914706861858` | `0.0` | `true` | `45` | `false` | `<0.05s` |
| `boundary_constraint` | `mta32-clean-terrain-boundary_constraint-20260510165448` | `0..3 x 2..6` | `0..5 x 0..8` | `accepted` | `residual_satisfied` | `0.47` | `0.0` | `true` | `50` | `false` | `<0.05s` |
| `feature_intersection` | `mta32-clean-terrain-feature_intersection-20260510165448` | `7..9 x 7..9` | `5..11 x 5..11` | `accepted` | `residual_satisfied` | `0.38119989275577437` | `0.0` | `true` | `42` | `false` | `<0.05s` |
| `budget_exceeded` | `mta32-clean-terrain-budget_exceeded-20260510165448` | `7..9 x 7..9` | `5..11 x 5..11` | `fallback` | `topology_quality_failed` | `1.7861914706861857` | `0.8887767459927298` | `false` | `9` | `false` | `<0.05s` |

Topology diagnostics for the four accepted fixtures reported `longEdgeCount = 0`,
`nonManifoldEdgeCount = 0`, `degenerateTriangleCount = 0`, `invertedTriangleCount = 0`,
`outOfDomainVertexCount = 0`, `boundaryConstraintPreserved = true`, and `areaCoverageRatio = 1.0`.
The forced budget fixture returned deterministic fallback evidence instead of accepting a sparse
topology with long edges.

## Debug Proof Meshes

The latest five proof meshes were rendered as separate debug-only scene groups on side terrains:

| Fixture class | Proof mesh source element id | Material | Bounds in meters |
|---|---|---|---|
| `flat_smooth` | `mta32-clean-proof-flat_smooth-20260510165448` | `MTA32-Proof-Magenta` | `x 52.5..55.5`, `y 24.5..27.5` |
| `rough_high_relief` | `mta32-clean-proof-rough_high_relief-20260510165448` | `MTA32-Proof-Magenta` | `x 52.5..55.5`, `y 34.5..37.5` |
| `boundary_constraint` | `mta32-clean-proof-boundary_constraint-20260510165448` | `MTA32-Proof-Magenta` | `x 50.0..52.5`, `y 42.0..46.0` |
| `feature_intersection` | `mta32-clean-proof-feature_intersection-20260510165448` | `MTA32-Proof-Magenta` | `x 52.5..55.5`, `y 54.5..57.5` |
| `budget_exceeded` | `mta32-clean-proof-budget_exceeded-20260510165448` | `MTA32-Proof-Fallback-Orange` | `x 52.5..55.5`, `y 64.5..67.5` |

## Frozen Thresholds

- `maxPatchSeconds`: `0.05`
- `maxAcceptedHeightError`: `0.05`
- `maxAcceptedP95Error`: `0.05`
- `maxAcceptedRmsError`: `0.05`
- `maxAcceptedLongEdgeCount`: `0`
- `maxAcceptedNonManifoldEdgeCount`: `0`
- `maxAcceptedDegenerateTriangleCount`: `0`
- `maxAcceptedInvertedTriangleCount`: `0`
- `maxAcceptedOutOfDomainVertexCount`: `0`
- `maxAcceptedInsertionCount`: `50`
- `maxAcceptedFaceCount`: `80`

## Hosted Status

Hosted SketchUp validation was run live against fresh side terrains after code review follow-up.
No existing site terrain was edited during the final verification. Debug mesh rendering is evidence
only and does not implement production patch replacement or seam lifecycle; that remains MTA-34.
