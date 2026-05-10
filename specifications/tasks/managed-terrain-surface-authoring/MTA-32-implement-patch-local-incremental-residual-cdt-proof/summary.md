# Summary: MTA-32 Implement Patch-Local Incremental Residual CDT Proof

**Task ID**: `MTA-32`
**Status**: `implemented`
**Date**: `2026-05-10`

## Shipped Behavior

- Added runtime-owned patch CDT proof collaborators under `src/su_mcp/terrain/output/cdt/patches/`.
- Derives bounded patch domains from dirty `SampleWindow` data with the planned two-sample margin.
- Builds hard patch boundary topology with budgeted anchors and patch-local feature participation counts.
- Measures residual quality only inside the patch domain.
- Runs bounded residual insertion using affected-region triangulation updates after the initial seed triangulation.
- Records per-insertion diagnostics including affected/removed/created triangles, recomputation scope, recomputation counts, point counts, rebuild detection, and stop/fallback reason.
- Adds topology quality gating so accepted proof meshes require no out-of-domain vertices, degenerate triangles, inverted triangles, non-manifold edges, long edges, missing boundary coverage, or area coverage drift.
- Adds opt-in internal `debugMesh` evidence and a debug-only renderer for scene inspection.
- Preserves default terrain output behavior and public MCP request/response shapes.

## Scope Boundary

This remains an MTA-32 proof. It does not default-enable CDT output, does not replace production
SketchUp terrain geometry, and does not implement MTA-34 patch replacement or seam lifecycle. The
feature-intersection fixture only exercises proof input participation; durable patch-relevant
feature ownership remains MTA-33.

## Validation

- Focused MTA-32 tests: `42 runs`, `660 assertions`, `0 failures`, `0 errors`.
- Full Ruby test suite: `1215 runs`, `12045 assertions`, `0 failures`, `0 errors`, `37 skips`.
- RuboCop on touched MTA-32 Ruby surface: `22 files inspected`, `0 offenses`.
- Package verification: `bundle exec rake package:verify` produced `dist/su_mcp-1.6.0.rbz`.
- Public contract check: no MCP tool names, schemas, request shapes, or public response shapes changed.

## Code Review

`mcp__pal__codereview` ran with `model: "grok-4.3"`.

Findings addressed before final closeout:

- Debug proof renderer initially reused one source element id for every proof mesh. It now accepts
  a per-render `source_element_id`, and tests assert the value.
- Live visual inspection showed sample residual alone could hide poor topology. The proof now
  includes `PatchTopologyQualityMeter` and rejects folded/sparse topology instead of accepting only
  by height error.

Final review reported no required MTA-32 compliance fixes. It noted low-priority proof-only cleanup
opportunities, including documenting the initial full-patch candidate queue and removing the
test-only rebuild hook after the proof matures.

## Live SketchUp Verification

Live verification ran in `TestGround.skp` after review follow-up and redeployment into the installed
SketchUp plugin. It used fresh side managed terrains only.

Run id: `20260510165448`

| Fixture | Status | Stop reason | Topology | Final max error | Insertions | Runtime |
|---|---|---|---|---:|---:|---:|
| `flat_smooth` | `accepted` | `residual_satisfied` | `passed` | `0.0` | `45` | `<0.05s` |
| `rough_high_relief` | `accepted` | `residual_satisfied` | `passed` | `0.0` | `45` | `<0.05s` |
| `boundary_constraint` | `accepted` | `residual_satisfied` | `passed` | `0.0` | `50` | `<0.05s` |
| `feature_intersection` | `accepted` | `residual_satisfied` | `passed` | `0.0` | `42` | `<0.05s` |
| `budget_exceeded` | `fallback` | `topology_quality_failed` | `failed as expected` | `0.8887767459927298` | `9` | `<0.05s` |

The five debug proof meshes were rendered and selected in the scene:

- `mta32-clean-proof-flat_smooth-20260510165448`
- `mta32-clean-proof-rough_high_relief-20260510165448`
- `mta32-clean-proof-boundary_constraint-20260510165448`
- `mta32-clean-proof-feature_intersection-20260510165448`
- `mta32-clean-proof-budget_exceeded-20260510165448`

Accepted proof meshes are magenta; the deterministic fallback mesh is orange.

## Remaining Gaps

- This is proof evidence, not production patch replacement.
- The residual candidate queue uses the allowed initial full-patch scan plus bounded affected
  recomputation. That is acceptable for MTA-32 but remains proof-only until production replacement
  semantics are defined.
- MTA-33 still owns durable patch-relevant feature selection.
- MTA-34 still owns SketchUp patch replacement, seam mutation, and entity lifecycle.

## Validation-Only Cleanup Markers

These runtime surfaces are intentionally marked `MTA-32 VALIDATION-ONLY` in code so MTA-33/MTA-34
can remove, rehome, or harden them instead of leaving proof scaffolding in the production path:

- `PatchLocalCdtProof#run(... include_debug_mesh:)`: opt-in raw debug mesh evidence for live proof
  rendering. It defaults to `false` and should not become public MCP output.
- `PatchDebugMeshRenderer`: scene renderer for proof mesh inspection only. Production terrain
  replacement must not route through it.
- `PatchAffectedRegionUpdater#insert(force_rebuild_detection:)`: deterministic test hook for
  rebuild-failure coverage. It should be removed once production replacement telemetry covers the
  same failure mode.
- `PatchLocalCdtProof#refine_residuals` candidate queue policy: acceptable proof behavior using the
  initial full-patch scan plus bounded affected recomputation. Revisit when durable candidate
  indexing or replacement cadence is defined.
