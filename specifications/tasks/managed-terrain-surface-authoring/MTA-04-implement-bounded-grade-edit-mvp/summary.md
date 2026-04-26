# MTA-04 Implementation Summary

**Status**: completed  
**Task**: `MTA-04 Implement Bounded Grade Edit MVP`  
**Captured**: 2026-04-26

This summary records the completed MTA-04 implementation, local validation, code review follow-up, and final live SketchUp/public MCP verification.

## Implemented So Far

- Added public MCP tool support for `edit_terrain_surface`.
- Added request validation and normalization for:
  - `targetReference`
  - `operation.mode: "target_height"`
  - `operation.targetElevation`
  - rectangle edit regions
  - `region.blend.falloff: "none" | "linear" | "smooth"`
  - `constraints.fixedControls`
  - rectangle `constraints.preserveZones`
  - sample evidence output options
- Added `BoundedGradeEdit`, a SketchUp-free kernel that mutates `HeightmapState`.
- Added JSON-safe edit evidence.
- Added full derived terrain output regeneration with derived-output marking and unsupported-child refusal.
- Added terrain face normal normalization at the mesh writer boundary so generated and regenerated terrain faces point upward.
- Wired the public contract through dispatcher, runtime facade, command factory, native loader schema, native contract fixtures, tests, and README.

## Local Validation

Latest local validation after live-smoke follow-up fixes, including the face-winding fix:

- `bundle exec rake ruby:test`: 620 runs, 2376 assertions, 0 failures, 31 skips.
- `bundle exec ruby -Itest test/terrain/terrain_mesh_generator_test.rb`: 6 runs, 22 assertions, 0 failures.
- `bundle exec rake ruby:lint`: 164 files inspected, no offenses.
- `bundle exec rake package:verify`: passed and produced `dist/su_mcp-0.20.0.rbz`.
- `git diff --check`: passed.
- `pal.codereview` with `grok-4.20`: completed; follow-up fixes were applied.
- Focused `grok-4.20` review for the face-winding fix: completed; nil-safe normal guard follow-up was applied.

Native transport contract tests remain present but skipped locally when the staged vendor runtime is unavailable.

## Live Verification Captured

Public MCP smoke, edge cases, and the final retest suite have passed after fixing the live regeneration and face-winding blockers. The only partial item is no-data coverage because there is no public API path to create a valid real no-data terrain state.

| Scenario | Result | Notes |
|---|---:|---|
| Create baseline | PASS | 5x5, revision 1, 25 vertices / 32 faces, public lookup/sampling OK. |
| Hard rectangle edit | PASS | Valid target-height edit succeeds through public MCP path. |
| Smooth blend edit | PASS | Smoothstep blend edit succeeds. |
| Edge-touching edit | PASS | Boundary samples updated. |
| Partial outside edit | PASS | In-bounds samples updated without corruption. |
| Single-sample edit | PASS | One-sample `changedRegion`; only that sample changed. |
| Whole-terrain edit | PASS | All 25 samples changed. |
| Repeated edits chain | PASS | Revisions advanced `1 -> 2 -> 3 -> 4`. |
| Undo then edit again | PASS | Undo restored prior output; subsequent edit succeeded. |
| Preserve zone in blend ring | PASS | Protected sample stayed unchanged. |
| Multiple fixed controls | PASS | Conflicting implicit-elevation control refused. |
| Invalid target | PASS | Refused `terrain_target_not_found`. |
| Unsupported finite option | PASS | Refused with `allowedValues`. |
| Evidence cap 0 | PASS | Returned no sample rows with summary. |
| Evidence cap 100 | PASS | Returned all 25 affected samples. |
| Evidence cap 101 | PASS | Refused `invalid_edit_request`. |
| Unsafe output child | PASS | Structured refusal after regeneration child-inspection fix. |
| Near-cap edit perf | PASS | 100x100 terrain edit completed; SketchUp stayed responsive. |

Additional live verification found inconsistent derived terrain face winding: create-only terrain could be all-down, partial edit regeneration could be mixed up/down, and whole-terrain edits could become all-up. This was fixed in `TerrainMeshGenerator` by normalizing each added terrain face after `add_face` and reversing faces whose `normal.z` is negative. A regression test now forces the writer seam to receive downward faces and verifies generated terrain faces are all up-facing.

Final public MCP retest:

| ID | Result | Notes |
|---|---:|---|
| F01 | PASS | Fresh create plus hard rectangle edit worked; revision `1 -> 2`; bounds, mesh, state, and samples agreed. |
| F02 | PASS | Adopted irregular terrain edited using state/world XY coordinates; adopted origin semantics worked correctly. |
| F03 | PASS | Smooth blend reached target in core: center `4.0`, shoulder `2.17`, outside `0.0`. |
| F04 | PASS | Preserve zone overlapping blend/edit protected sample stayed unchanged; evidence reported protected samples. |
| F05 | PASS | Fixed-control conflict refused before mutation with `fixed_control_conflict`, tolerance, and predicted delta. |
| F06 | PASS | Unsupported mode/falloff refused with `unsupported_option` and finite `allowedValues`. |
| F07 | PASS | Unsafe unmanaged child refused before deleting/regenerating existing output. |
| F08 | PASS | Partial outside / edge edit clamped correctly to edge samples only. |
| F09 | PASS | Single-sample edit affected exactly one sample and stayed localized. |
| F10 | PASS | Whole-terrain edit changed all 25 samples and regenerated coherently. |
| F11 | PASS | Repeated edits advanced revisions correctly through `1 -> 4`; samples matched latest state. |
| F12 | PASS | SketchUp undo restored prior state/output, then a subsequent edit worked correctly. |
| F13 | PASS | Evidence modes behaved correctly: default compact, cap `0`, cap `100`, and cap `101` refusal. |
| F14 | PARTIAL | No public way found to create real no-data terrain. Grey-box missing-state stub refused before mutation with `terrain_state_load_failed`, not `terrain_no_data_unsupported`. |
| F15 | PASS | Near-cap 100x100 edit completed; create about 20.2s, edit/regenerate about 23.2s; 10k vertices / 19,602 faces; MCP responsive after. |
| F16 | PASS | Output face normals fixed across final-suite terrains; all inspected generated terrain faces were up-facing, down `0`. |
| F17 | PASS | Large irregular terrain with stepped/complex preserve footprint approximated by 3 rectangles; protected samples stayed unchanged, unprotected sample moved. |
| F18 | PASS | Three preserve rectangles partially outside the edit rectangle worked; protected overlap samples unchanged, unprotected interior sample changed, outside preserve sample unchanged. |

## Important Findings

### Coordinate Semantics

Edit regions, fixed-control points, and preserve-zone bounds are interpreted in the stored terrain state's XY coordinate frame in public meters.

For adopted terrain, the state origin comes from sampled source bounds. A zero-based region can correctly refuse as out-of-state/no affected samples when the adopted terrain state origin is not zero.

Observed representative case:

- Source: 50m x 50m wavy terrain, 441 vertices, 800 faces.
- Adopted output: 100x100, 10,000 vertices, 19,602 faces.
- State origin: approximately `(500, 500)`.
- Edit `20..30`: refused `edit_region_has_no_affected_samples`.
- Edit `520..530`: succeeded.
- Result: revision `1 -> 2`, 400 affected samples.
- Public profile saw updated peak at 6.0m.

README, native loader schema descriptions, and `plan.md` were updated to clarify this.

### Performance

Near-cap full regeneration remains a known MTA-04 tradeoff:

- Grid: 100x100.
- Edit region: `30..70`.
- Affected samples: 1,681.
- Output mesh: 10,000 vertices / 19,602 faces.
- MCP edit time observed around 23.2-23.62s.
- External wall-clock observed around 29.65s in the earlier near-cap run.
- Create time observed around 20.2s in the final retest.
- SketchUp stayed responsive; `ping` succeeded.

### Remaining Product Gap

The preserve-zone MVP supports rectangles only. Final live testing showed complex stepped preserve footprints can be approximated with multiple rectangles, but true irregular/polygonal preserve zones require a future public schema addition rather than hidden behavior inside MTA-04.

## Residual Notes

- F14 no-data live verification remains partially covered because the public API does not expose a way to create a valid real no-data terrain state. Automated no-data domain coverage remains in place; the grey-box live stub proved refusal-before-mutation behavior through `terrain_state_load_failed`.
- True irregular/polygonal preserve zones remain future scope. MTA-04 supports rectangle preserve zones, and final live tests showed stepped preserve footprints can be approximated with multiple rectangles.
