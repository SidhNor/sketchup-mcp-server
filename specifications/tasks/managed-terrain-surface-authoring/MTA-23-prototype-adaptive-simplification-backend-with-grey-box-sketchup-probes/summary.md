# MTA-23 Summary: Prototype Intent-Constrained Adaptive Output Backend

**Status**: `implemented`
**Recommendation**: `keep_adaptive_grid_as_promising_upgrade_candidate_and_prototype_cdt_next`

## Outcome

MTA-23 implemented a validation-only intent-aware adaptive-grid candidate backend and the
backend-neutral feature-geometry layer it consumes. The candidate is not production-wired and did not
change public MCP tool contracts, dispatcher routes, request schemas, response shapes, or production
terrain output behavior.

The final direction is not to blindly production-swap the adaptive-grid candidate, but the live
scene evidence supports keeping it as a serious upgrade candidate. Keep the feature-geometry layer
and use it as the constraint substrate for a constrained Delaunay/CDT follow-up, then compare current,
adaptive-grid, and CDT before selecting the production default.

## Delivered

- Added `TerrainFeatureGeometry`, a JSON-safe backend-neutral primitive payload for:
  - `outputAnchorCandidates`
  - `protectedRegions`
  - `pressureRegions`
  - `referenceSegments`
  - `affectedWindows`
  - `tolerances`
  - stable `featureGeometryDigest` and `referenceGeometryDigest`
- Added `TerrainFeatureGeometryBuilder` for MTA-20 intent derivation:
  - hard preserve regions
  - hard fixed controls
  - firm corridor pressure and corridor reference segments
  - firm survey and planar pressure
  - soft target, fairing, and inferred-heightfield pressure
- Added `IntentAwareAdaptiveGridPolicy` for split priority, local tolerance, pressure coverage, hard
  anchor checks, and protected-crossing metrics.
- Added `IntentAwareEnhancedAdaptiveGridPrototype`, a validation-only adaptive-grid candidate that
  emits real vertices/triangles/cells/metrics without production wiring.
- Added MTA-22 fixture comparison support for replayable and provenance-only rows.
- Added failure-capture and hosted sidecar probe support.
- Expanded public no-leak contract coverage so candidate internals do not leak into public terrain
  responses.

## Evidence Summary

Feature geometry is validated for the MTA-23 scope in both focused Ruby tests and live SketchUp audit
evidence. Preserve, fixed-control, corridor, survey, planar, target, fairing, and inferred-heightfield
intents all produce the expected backend-neutral primitive collections, roles, strengths, reference
segments, anchors, affected windows, and stable digests.

The adaptive-grid candidate emits real geometry and responds to feature intent, but it does not
satisfy hard preserve regions or fixed-control anchors. Planar/survey and soft target/fairing
pressure host cleanly. Corridor pressure drives a large face-count and budget increase on the
single-terrain matrix.

The hard preserve/fixed-anchor failures are not unique to MTA-23. A live shared-state bakeoff against
the deployed current simplifier shows the current simplifier also fails those hard-intent checks, and
does so without any feature-aware diagnostic category.

The old global 30-degree max-normal-break production gate was rejected as too blunt. Normal-break is
kept as role-aware diagnostic evidence, not as a universal production gate for deliberate corridor
transitions, endpoint caps, protected boundaries, or other intended grade changes.

## MTA-22 Apples-To-Apples Fixture Comparison

The canonical MTA-22 regression tests were rerun:

- `bundle exec ruby -Itest test/terrain/adaptive_terrain_regression_fixture_test.rb`
  - `27 runs, 1768 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`
  - `8 runs, 601 assertions, 0 failures, 0 errors, 0 skips`

The MTA-23 simplifier was then run through `AdaptiveTerrainMta23CandidateComparison` against the
same MTA-22 fixture pack. Only the four created-corridor fixture rows are locally replayable today;
adopted/stress rows remain provenance-only and are explicitly `comparison_not_applicable`.

| MTA-22 case | Mode | Candidate category | Candidate faces | MTA-21 baseline faces | Candidate dense ratio | MTA-21 dense ratio | Hard failures |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| `created_flat_corridor_mta21` | `local_backend_capture` | `none` | 462 | 1750 | 0.1444 | 0.5469 | none |
| `created_crossfall_corridor_mta21` | `local_backend_capture` | `none` | 462 | 1546 | 0.1444 | 0.4831 | none |
| `created_steep_corridor_mta21` | `local_backend_capture` | `none` | 462 | 1653 | 0.1444 | 0.5166 | none |
| `created_non_square_corridor_mta21` | `local_backend_capture` | `none` | 522 | 1378 | 0.1243 | 0.3281 | none |
| `adopted_irregular_before_corridor_mta21` | `provenance_capture` | `comparison_not_applicable` | n/a | 11044 | n/a | 0.5634 | not locally replayable |
| `adopted_irregular_grid_aligned_corridor_mta21` | `provenance_capture` | `comparison_not_applicable` | n/a | 6824 | n/a | 0.3481 | not locally replayable |
| `adopted_irregular_off_grid_corridor_mta21` | `provenance_capture` | `comparison_not_applicable` | n/a | 7765 | n/a | 0.3961 | not locally replayable |
| `aggressive_stacked_created_terrain_mta21` | `provenance_capture` | `comparison_not_applicable` | n/a | 3578 | n/a | 0.7454 | not locally replayable |
| `high_relief_seam_stress_mta21` | `provenance_capture` | `comparison_not_applicable` | n/a | 6667 | n/a | 0.6945 | not locally replayable |

This apples-to-apples run shows the adaptive-grid candidate is promising on the locally replayable
created-corridor MTA-22 rows. It does not change the final recommendation, because the broader live
matrix and expanded hard-constraint probes show the same candidate still fails hard preserve/fixed
requirements. The static fixture harness still cannot replay adopted/stress rows locally, so those
rows were compared through the live scene-level sampling pass below.

## Scene-Level MTA-22 Fixture Inspection

The actual in-scene group `MTA-22 fixture eval 20260506-094548` was inspected through the MCP wrapper.

- Group persistent id: `7981047`
- Child terrain groups: `9`
- Aggregate child faces: `46744`
- Aggregate child edges: `70619`
- Aggregate down faces: `0`
- Aggregate non-manifold edges: `0`
- Aggregate max normal break: `124.6631`

Scene-level comparison for the four locally replayable created-corridor rows:

| Case | MTA-22 scene faces | MTA-22 scene vertices | MTA-23 scene faces | MTA-23 scene vertices | Down faces | Non-manifold edges |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `created_flat_corridor_mta21` | 462 | 242 | 462 | 242 | 0 / 0 | 0 / 0 |
| `created_crossfall_corridor_mta21` | 462 | 242 | 462 | 242 | 0 / 0 | 0 / 0 |
| `created_steep_corridor_mta21` | 462 | 242 | 462 | 242 | 0 / 0 | 0 / 0 |
| `created_non_square_corridor_mta21` | 522 | 272 | 522 | 272 | 0 / 0 | 0 / 0 |

The MTA-23 corrected sidecars are outside the MTA-22 fixture group bounds, carry
`su_mcp_mta23_candidate.validationOnly = true`, and remain inspectable in `TestGround`.

### Scene-Level Adopted/Stress Prototype Comparison

The live group `MTA23-STRESS-SCENE-COMPARE-20260506-234023` was created through MCP `eval_ruby`
from the actual `MTA-22 fixture eval 20260506-094548` child meshes. Each adopted/stress MTA-22 child
was sampled into a tiled heightmap state, run through the MTA-23 prototype simplifier, and emitted as
a validation-only sidecar for direct scene inspection.

- Comparison group persistent id: `8541424`
- Source group persistent id: `7981047`
- Generated sidecars: `5`
- Source sampling fallback count: `0` for every row
- Candidate scene topology: `0` down faces and `0` non-manifold edges for every row
- Candidate row category: `performance_limit_exceeded` for every row under the initial
  `8.0` second runtime budget and `1024` cell budget

| Case | MTA-22 scene faces | MTA-23 candidate faces | Face ratio vs MTA-22 | Candidate dense ratio | MTA-22 max normal break | MTA-23 scene max normal break |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `adopted_irregular_before_corridor_mta21` | 12020 | 1326 | 0.1103 | 0.0676 | 3.4775 | 9.4337 |
| `adopted_irregular_grid_aligned_corridor_mta21` | 12072 | 921 | 0.0763 | 0.0470 | 61.9768 | 52.6528 |
| `adopted_irregular_off_grid_corridor_mta21` | 12048 | 901 | 0.0748 | 0.0460 | 61.4814 | 51.3919 |
| `aggressive_stacked_created_terrain_mta21` | 2466 | 936 | 0.3796 | 0.1950 | 70.8334 | 68.2970 |
| `high_relief_seam_stress_mta21` | 6230 | 1120 | 0.1798 | 0.1167 | 124.6631 | 128.7649 |

The same five rows were rerun in live SketchUp with a higher `20.0` second runtime budget and
`4096` cell budget in group `MTA23-STRESS-SCENE-COMPARE-HIGHBUDGET-20260506-234613`
(`persistentId: 8557345`). Cells are quadtree planning cells, not faces; the emitted mesh generally
uses roughly two triangles per final cell after conformity processing.

| Case | Initial faces | High-budget faces | High-budget face ratio vs MTA-22 | High-budget max height error | High-budget status |
| --- | ---: | ---: | ---: | ---: | --- |
| `adopted_irregular_before_corridor_mta21` | 1326 | 2006 | 0.1669 | 0.0668 | `max_runtime_budget_exceeded` |
| `adopted_irregular_grid_aligned_corridor_mta21` | 921 | 1445 | 0.1197 | 0.7226 | `max_runtime_budget_exceeded` |
| `adopted_irregular_off_grid_corridor_mta21` | 901 | 1389 | 0.1153 | 0.7327 | `max_runtime_budget_exceeded` |
| `aggressive_stacked_created_terrain_mta21` | 936 | 1490 | 0.6042 | 1.0313 | `max_runtime_budget_exceeded` |
| `high_relief_seam_stress_mta21` | 1120 | 1594 | 0.2559 | 8.8474 | `max_runtime_budget_exceeded` |

### Current Backend Versus MTA-23 Shared-State Bakeoff

The live group `MTA23-CURRENT-VS-MTA23-BAKEOFF-20260507-091137` (`persistentId: 8581540`) was then
created from the same sampled state per adopted/stress case. Each row emitted two validation-only
sidecars: the deployed current simplifier through `TerrainOutputPlan` and the MTA-23 adaptive-grid
prototype. This is the direct scene-level bakeoff against the current simplifier.

- Source group persistent id: `7981047`
- Generated sidecars: `10`
- Shared source sampling fallback count: `0` for every row
- Current simplifier tolerance: `0.01`
- MTA-23 base tolerance: `0.05`
- MTA-23 runtime/cell budget: `20.0` seconds, `4096` cells
- Both backends emitted `0` down faces and `0` non-manifold edges for every row

| Case | Source faces | Current faces | MTA-23 faces | MTA-23 faces vs current | Current max normal break | MTA-23 max normal break |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `adopted_irregular_before_corridor_mta21` | 12020 | 13288 | 1762 | 0.1326 | 3.6959 | 7.5336 |
| `adopted_irregular_grid_aligned_corridor_mta21` | 12072 | 13286 | 1283 | 0.0966 | 61.9768 | 52.6528 |
| `adopted_irregular_off_grid_corridor_mta21` | 12048 | 13260 | 1261 | 0.0951 | 61.4814 | 51.3919 |
| `aggressive_stacked_created_terrain_mta21` | 2466 | 2466 | 1450 | 0.5880 | 70.8334 | 68.2970 |
| `high_relief_seam_stress_mta21` | 6230 | 7923 | 1328 | 0.1676 | 124.6631 | 128.7649 |

This pass materially increases confidence in the geometry-producing path: the prototype can emit
scene-valid sidecars for the MTA-22 adopted and stress shapes, not only the simple created-corridor
cases, and it is substantially more compact than the current simplifier on the shared live states.
The timeout should be treated as an optimization risk rather than a geometry-quality proof: more
budget produced more granular meshes while retaining clean topology and still far fewer faces than
the source MTA-22 scene meshes and the current simplifier output. The candidate is still not ready
for an unconditional production swap because hard preserve/fixed-anchor cases fail and the
unoptimized prototype does not converge within the tested runtime budgets on adopted/stress terrain.

### Current Backend Versus MTA-23 Hard-Intent Enforcement

The live group `MTA23-CURRENT-VS-MTA23-HARD-INTENT-BAKEOFF-20260507-095411`
(`persistentId: 8754894`) compared the deployed current simplifier and MTA-23 on the same hard-intent
states. Both backends emitted topology-clean SketchUp sidecars. The scoring applied the MTA-23
protected-crossing and hard-anchor metrics to both meshes.

| Case | Current faces | Current hard result | MTA-23 faces | MTA-23 hard result |
| --- | ---: | --- | ---: | --- |
| `hard_preserve_rectangle_flat` | 2 | `8` protected crossings, severity `67.8823` | 480 | `256` protected crossings, severity `2.8284` |
| `hard_fixed_off_grid_anchor_flat` | 2 | fixed anchor missing, nearest vertex `27.7010` | 1941 | fixed anchor missing, nearest vertex `0.4950` |
| `hard_preserve_and_fixed_combined_flat` | 2 | `8` protected crossings, fixed anchor missing at `28.9917` | 1607 | `136` protected crossings, fixed anchor missing at `0.7211` |

This confirms the hard-intent gap is not a regression relative to the current simplifier. The current
backend is blind to these feature intents and crosses preserve regions with large triangles; MTA-23
still fails the hard checks, but it localizes the error much more closely around the intended geometry
and reports the violation explicitly.

### Aggressive Varied Scene Bakeoff

The live group `MTA23-CURRENT-VS-MTA23-AGGRESSIVE-VARIED-20260507-100018`
(`persistentId: 8767254`) added harsher synthetic scene-level cases than the MTA-22 fixture shapes:
rippled ridge/valley, stepped cliff/trench, high-relief off-grid corridor, preserve island on rough
terrain, and a fixed-anchor cluster on rough terrain. Each case emitted current and MTA-23 sidecars
from the same generated state.

- Generated sidecars: `10`
- Current simplifier tolerance: `0.01`
- MTA-23 base tolerance: `0.05`
- MTA-23 runtime/cell budget: `12.0` seconds, `4096` cells
- Both backends emitted `0` down faces and `0` non-manifold edges for every row
- MTA-23 hit `max_runtime_budget_exceeded` for every row

| Case | Dense faces | Current faces | MTA-23 faces | Current max error | MTA-23 max error | Hard-intent result |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `aggressive_rippled_ridge_valley_65` | 8192 | 8192 | 1461 | 0.0000 | 1.4608 | no hard intents |
| `aggressive_stepped_cliff_trench_65` | 8192 | 8072 | 1424 | 0.0071 | 7.3904 | no hard intents |
| `aggressive_offgrid_corridor_high_relief_73` | 8064 | 7982 | 1448 | 0.0097 | 2.6732 | corridor pressure only |
| `aggressive_preserve_island_rough_65` | 8192 | 8192 | 1251 | 0.0000 | 3.8503 | current: `544` crossings; MTA-23: `204` crossings |
| `aggressive_fixed_anchor_cluster_rough_65` | 8192 | 8192 | 1191 | 0.0000 | 3.8503 | both miss `3` fixed anchors |

This set makes the tradeoff explicit. The current simplifier mostly falls back to dense output on
aggressive terrain, while MTA-23 keeps clean topology with roughly `14.5%` to `17.8%` of dense faces
on four of the five rows. That is strong simplification evidence. It is not a production-quality
accuracy result yet: the unoptimized MTA-23 pass times out, accepts larger height error under the
tested tolerance/budget, and the rough fixed-anchor cluster shows MTA-23 can be farther from anchors
than the dense current output.

## Hosted Evidence

Live checks ran through the MCP wrapper `eval_ruby` against SketchUp `26.1.189`, model `TestGround`.
Existing top-level scene entities were preserved.
The canonical record is this task summary; generated validation sidecars remain inspectable in the
live SketchUp scene.

Representative findings:

- Corrected corridor sidecar pass:
  - all four locally replayable MTA-22 created-corridor rows emitted matching face/vertex counts
  - hosted down faces: `0`
  - hosted non-manifold edges: `0`
  - save-copy passed
  - separate sidecar undo smoke passed
- Expanded representative probes:
  - planar/survey pressure: `none`
  - soft target/fairing pressure: `none`
  - hard preserve rectangle: `hard_output_geometry_violation`, `256` protected crossings
  - fixed off-grid anchor: `hard_output_geometry_violation`, `fixed_anchor_missing: 1`
  - combined corridor/preserve/fixed: `hard_output_geometry_violation`, `86` protected crossings,
    `fixed_anchor_missing: 1`
- Single-terrain varied-intent matrix:
  - no intent baseline: `138` faces, clean
  - corridor only: `1416` faces, `performance_limit_exceeded`
  - hard preserve + fixed: `1469` faces, `226` protected crossings, fixed anchor missing
  - planar + survey: `711` faces, clean
  - soft target + fairing: `575` faces, clean
  - all constraints combined: `1320` faces, `148` protected crossings, fixed anchor missing
- Feature-geometry audit overlay:
  - result: `passed`
  - expected primitive counts matched
  - digests stable
  - hard/firm/soft roles matched expected intent semantics
  - rendered audit sidecar metadata matched derived primitive collections

## Validation

- Focused MTA-23 feature/candidate suite:
  `25 runs, 148 assertions, 0 failures, 0 errors, 0 skips`
- Terrain suite:
  `344 runs, 5495 assertions, 0 failures, 0 errors, 3 skips`
- Full Ruby test sweep before live-check expansion:
  `941 runs, 7812 assertions, 0 failures, 0 errors, 37 skips`
- RuboCop on affected MTA-23 files: no offenses
- Full RuboCop before live-check expansion:
  `241 files inspected, no offenses detected`
- Package verification before live-check expansion:
  `dist/su_mcp-1.2.0.rbz`
- `git diff --check`: passed after latest edits

## Verdict

Do not blindly production-swap the adaptive-grid candidate, but keep it as a serious upgrade
candidate. Relative to the current simplifier, MTA-23 is a clear improvement candidate on the tested
scene-level face-count, topology, and hard-intent diagnostic evidence.

The feature-geometry layer is validated and useful. The adaptive-grid candidate is feature-sensitive,
hosts clean SketchUp geometry, and materially outperforms the current simplifier on face count in the
shared live adopted/stress bakeoff. Its remaining blockers are hard preserve/fixed-anchor
enforcement, unoptimized runtime, and high-relief residual behavior, but the hard-intent blocker is
shared with the current simplifier rather than a unique MTA-23 regression.

The aggressive varied bakeoff reinforces the same conclusion with a sharper caveat: MTA-23 is much
more compact than the current simplifier on rough terrain, but productionization needs accuracy and
runtime tuning before it can replace dense fallback behavior.

Do not implement CDT inside MTA-23. The next implementation task should use the MTA-23
feature-geometry layer as input to a constrained Delaunay/CDT prototype, then compare current,
MTA-23 adaptive-grid, and CDT on the same scene-level cases before selecting the production backend.

The `mta23_*` source and test filenames are accepted as temporary prototype identifiers for this
validation slice. They should not become permanent production naming. When a backend is promoted,
the selected implementation should be renamed into backend-neutral terrain output classes/tests and
prototype-only MTA-23 wrappers or artifacts should be removed or archived with the task evidence.
