# Summary: MTA-36 Productize Windowed Adaptive Patch Output Lifecycle For Fast Local Terrain Edits

**Task ID**: `MTA-36`
**Status**: `completed`
**Completed Local Implementation**: `2026-05-11`
**Latest Validation Update**: `2026-05-12`

## Planning Amendment And Follow-Up Implementation

The first implementation pass used one SketchUp group per stable adaptive patch. Hosted validation
proved that lifecycle mechanics and numeric stitching work, including repeated and intersecting
edits on dense terrain. That geometry model is now classified as lifecycle proof, not final
acceptance.

MTA-36 is amended before closeout: accepted production output must be one derived terrain mesh
container with logical patch ownership on faces and registry entries. Local replacement must become
single-mesh face-cavity replacement, with temporary staging allowed only for no-delete validation.
This prevents MTA-35/CDT from inheriting separate patch groups as the topology substrate.

The follow-up implementation is now complete locally. `TerrainMeshGenerator` emits one derived
adaptive mesh group for policy-backed adaptive output. Dirty adaptive replacement resolves logical
patch IDs, selects affected faces inside the single mesh group, deletes only affected face sets,
emits replacement faces into the same mesh context, cleans orphan derived edges, updates the mesh
metadata, and updates only affected registry records.

## Shipped Behavior

- Added internal adaptive patch lifecycle seams under `src/su_mcp/terrain/output/adaptive_patches/`:
  - `AdaptivePatchPolicy`
  - `AdaptivePatchResolver`
  - `AdaptivePatchRegistryStore`
  - `AdaptivePatchTraversal`
  - `AdaptivePatchTiming`
  - `AdaptivePatchPlan`
- Added stable owner-local adaptive patch IDs based on fixed output-cell lattice coordinates.
- Added deterministic adaptive output-policy fingerprints covering patch size, hard-boundary policy, conformance ring, and adaptive metadata schema version.
- Added dirty output-cell window to affected patch and conformance-ring resolution.
- Added hard patch-boundary adaptive planning in `TerrainOutputPlan` when an internal adaptive patch policy is supplied.
- Added dirty-window patch-local adaptive planning/conformance: dirty edits now subdivide only
  replacement patches plus local planning context instead of replanning the full adaptive terrain.
- Added adaptive patch containers and per-new-face ownership metadata in `TerrainMeshGenerator`
  for the first lifecycle-proof implementation pass.
- Added owner-level compact adaptive patch registry storage as a JSON string under `su_mcp_terrain/adaptivePatchRegistry` for reload-safe attribute persistence.
- Added dirty-window adaptive patch replacement that targets resolved replacement patch containers
  and preserves unaffected patch containers and face metadata. This must be replaced by
  single-mesh logical patch cavity mutation before final acceptance.
- Added repeated-edit metadata reuse coverage for same-patch edits.
- Added internal hosted evidence shell `Mta36HostedPatchLifecycleProbe` with timing, undo, reload/readback, visual, fallback, and performance rows.
- Replaced first-pass patch-container accepted output with single-mesh logical patch output:
  - `outputKind: adaptive_patch_mesh` on the one derived mesh group;
  - `outputKind: adaptive_patch_face` plus `adaptivePatchId` and face index on generated faces;
  - dirty edits replace face sets by logical patch ID inside that mesh group.
- Optimized adaptive planning by replacing allocation-heavy `flat_map/map/max` error scans with
  loop-based scanning and threshold short-circuiting for non-leaf split decisions, while preserving
  exact max-error reporting for accepted/leaf cells.
- Optimized adaptive patch face emission by marking unique emitted edges once per adaptive patch
  replacement batch instead of repeatedly marking shared edges once per emitted face.
- Optimized planned adaptive patch batch construction by caching projected adaptive vertices per
  batch and reusing batch/fingerprint values across face plans.
- Extracted the patch lifecycle substrate into generic `PatchLifecycle` classes:
  - `PatchGridPolicy`
  - `PatchWindowResolver`
  - `PatchRegistryStore`
  - `PatchPlan`
  - `PatchTiming`
  - `PatchTraversal`
- Kept `AdaptivePatches` as compatibility adapters over the generic lifecycle layer so existing
  adaptive metadata keys and hosted output remain unchanged while MTA-35/CDT can consume the
  generic policy/resolver/registry/timing seams without inheriting adaptive names.
- Kept public terrain MCP contracts unchanged. Public responses do not expose patch IDs, registry internals, adaptive patch lifecycle fields, fallback categories, dirty windows, timing buckets, adaptive cells, or raw triangles.

## Validation Evidence

- `bundle exec rake ruby:test`
  - `1335 runs, 15314 assertions, 0 failures, 0 errors, 37 skips`
- `bundle exec rake ruby:lint`
  - `334 files inspected, no offenses detected`
- `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.7.0.rbz`
- Post-performance-tuning validation:
  - `bundle exec rake ruby:lint`
    - `334 files inspected, no offenses detected`
  - `bundle exec rake ruby:test`
    - `1339 runs, 15323 assertions, 0 failures, 0 errors, 37 skips`
  - `bundle exec rake package:verify`
    - produced `dist/su_mcp-1.7.0.rbz`
- Post-generic-lifecycle-extraction validation:
  - generic patch lifecycle tests:
    - `4 runs, 10 assertions, 0 failures, 0 errors`
  - adaptive compatibility wrapper tests:
    - `14 runs, 61 assertions, 0 failures, 0 errors`
  - `bundle exec ruby -Itest test/terrain/output/terrain_output_plan_test.rb`
    - `18 runs, 242 assertions, 0 failures, 0 errors`
  - `bundle exec ruby -Itest test/terrain/output/terrain_mesh_generator_test.rb`
    - `63 runs, 1581 assertions, 0 failures, 0 errors`
  - `bundle exec ruby -Itest test/terrain/commands/terrain_surface_commands_test.rb`
    - `39 runs, 296 assertions, 0 failures, 0 errors`
  - `bundle exec rake ruby:lint`
    - `343 files inspected, no offenses detected`
  - `bundle exec rake ruby:test`
    - `1343 runs, 15335 assertions, 0 failures, 0 errors, 37 skips`
  - `bundle exec rake package:verify`
    - produced `dist/su_mcp-1.7.0.rbz`
- Final Step 10 validation after restart/live verification:
  - `bundle exec rake ruby:lint`
    - `343 files inspected, no offenses detected`
  - `bundle exec rake ruby:test`
    - `1343 runs, 15335 assertions, 0 failures, 0 errors, 37 skips`
  - `bundle exec rake package:verify`
    - produced `dist/su_mcp-1.7.0.rbz`

## Code Review

- PAL review with `grok-4.3` completed after local validation.
- Initial review reported no critical findings and identified hosted-only residual risks.
- Local Step 10 review then found and fixed two hosted-risk issues:
  - registry storage now writes JSON strings instead of raw nested hashes so SketchUp attribute persistence and reload/readback are safer;
  - adaptive patch container and registry revision metadata now records the current terrain state revision instead of the previous revision.
- Follow-up PAL review with `grok-4.3` found no critical, high, or medium issues after those fixes.
- Follow-up low-severity review suggestions were addressed:
  - dirty adaptive patch plans now have explicit test coverage for invalid internal patch IDs;
  - dirty/global replacement-cell equivalence tests no longer reach through private state;
  - dirty adaptive patch tests assert that an `adaptive_patch_plan` is present.
- Final PAL code review with `grok-4.3` after the single-mesh ownership hardening found no
  critical, high, medium, or low actionable findings.
- Final Step 10 PAL code review with `grok-4.3` after generic lifecycle extraction, fresh
  restart/live verification, full tests, lint, and package verification found no critical, high,
  medium, or low actionable findings.

## Contract And Docs

- Public MCP tool names, request schemas, dispatcher routes, and response shapes were not changed.
- User-facing docs were not updated because no public usage, setup, schema, or workflow contract changed.
- Contract guardrails were expanded in `test/terrain/contracts/terrain_contract_stability_test.rb` for adaptive patch lifecycle, registry, fallback, and timing vocabulary.

## Hosted Verification Status

- Live SketchUp checks were run through deployed files and `su-ruby`/`eval_ruby`.
- Runtime fixes found during live testing were patched, deployed, and reloaded in SketchUp:
  - normal command create/edit now wires `AdaptivePatchPolicy`;
  - SketchUp `Entities` face enumeration no longer assumes a non-hosted `faces` helper;
  - dirty adaptive planning now runs patch-local planning/conformance instead of global planning.
- Follow-up hosted testing found that single-mesh dirty replacement needed stricter ownership
  integrity gates before mutation. The generator now refuses corrupted affected patch ownership
  before deleting old output.
- Single-mesh hosted correctness, performance, user-observed visual inspection, true `.skp`
  save/reopen verification, fresh reinstall/restart verification, final review, and Step 11 size
  calibration have passed.

Completed hosted rows for the patch-container lifecycle proof:

- command-path bootstrap at `x >= 130m`: `33x33`, 4 adaptive patch containers, registry JSON parsed, no public leaks;
- medium command-like fixture at `x >= 170m`: `69x69`, 25 containers, 7097 faces, registry parsed;
- interior, boundary, corner, repeated same-patch, and adjacent-patch edits preserved far patches and replaced bounded patch sets;
- fallback/no-delete refused unsupported output safely without deleting old patch output;
- undo restored prior patch output and registry state after SketchUp action processing settled;
- in-process registry/face readback parsed JSON and supported a follow-up local edit;
- numeric seam audit checked 40 seams with 0 unmatched segments;
- dense `50m x 70m @ 20cm` fixture after patch-local planning: 352 patches, edit subtotal `1111.68ms`, output planning `97.24ms`, mesh regeneration `210.04ms`, replaced 16 and preserved 336 patches.
- intersecting multi-edit stitch stress on the same dense fixture
  `MTA36-20CM-localplan-default-1778571462`:
  - initial seam audit: 2642 internal seam segments, 0 unmatched, 0 duplicate, 0 Z mismatches;
  - accepted target-height circle edit: 36 patches replaced, 316 preserved, seam audit passed;
  - accepted local-fairing rectangle edit intersecting prior edit: 36 replaced, 316 preserved, seam audit passed;
  - accepted planar-region-fit rectangle edit intersecting prior edits: 42 replaced, 310 preserved, seam audit passed;
  - accepted survey-point local correction inside the overlap: 42 replaced, 310 preserved, seam audit passed;
  - accepted corridor-transition edit crossing the same patch cluster: 56 replaced, 296 preserved, seam audit passed;
  - final seam audit: 2762 internal seam segments, 0 unmatched, 0 duplicate, 0 Z mismatches;
  - final registry remained a JSON string with 352 patches and state revision 7.

Completed hosted rows for the single-mesh implementation:

- small command-path single-mesh smoke `MTA36-SINGLE-MESH-SMOKE-1778584387`:
  - create emitted one `adaptive_patch_mesh` group, 0 patch-container groups, 4 logical patch IDs,
    registry JSON string with 4 patches;
  - target-height edit kept the same mesh persistent ID, advanced mesh revision 1 -> 2, and kept 0
    patch-container groups;
  - topology audit passed before and after, with 0 bad internal seam edges and 0 orphan edges;
  - public responses had no internal patch/registry leak tokens.
- medium intersecting single-mesh smoke `MTA36-SINGLE-MESH-INTERSECT-1778584528`:
  - create emitted one `adaptive_patch_mesh` group, 0 patch-container groups, 16 logical patch IDs,
    registry JSON string with 16 patches;
  - accepted intersecting edits: `target_height`, `local_fairing`, `planar_region_fit`, and
    `survey_point_constraint`;
  - mesh persistent ID stayed stable across all four edits;
  - each row kept one owner child group, 0 patch-container groups, 16 registry patches, and matching
    mesh face-count metadata;
  - topology audit passed after every edit with 0 bad internal seam edges and 0 orphan edges;
  - public responses had no internal patch/registry leak tokens.
- aggressive command-path row `MTA36-SINGLE-MESH-AGGRESSIVE-1778585439` at `x >= 2300m`:
  - created two comparable `100x100` public-cap terrains, one using normal dirty replacement and
    one using a hosted validation generator that forces full adaptive rebuild on edit;
  - local first edit `345.72ms`, forced-full first edit `387.8ms`, ratio `1.12x`;
  - overlapping target-height, local-fairing, planar-region-fit, survey-point, and corridor edits
    all returned `edited` on the same single-mesh terrain;
  - the mesh persistent ID stayed stable through all five overlapping edits;
  - final local audit: one owner child group, 0 patch-container groups, 49 registry patches, 3536
    faces, registry passed, face metadata missing `0`, orphan edges `0`, duplicate faces `0`,
    unmatched interior segments `0`, Z mismatches `0`;
  - corrupted affected face-index metadata refused with `terrain_output_ownership_invalid` and
    preserved mesh persistent ID, face count, and revision;
  - unsupported child under the mesh refused with `terrain_output_contains_unsupported_entities`
    and preserved mesh persistent ID, face count, and revision;
  - public responses had no internal patch/registry leak tokens.
- dense direct hosted performance row `MTA36-SINGLE-MESH-DENSE-PERF-FIXED-1778585720`:
  - `50m x 70m @ 20cm`, `251x351` samples, 352 logical patches, one mesh group, 0 patch
    containers;
  - broader local dirty edit `594.85ms` versus forced full rebuild `996.01ms`, ratio `1.67x`;
  - local and forced-full audits both passed registry and topology checks with 0 orphan edges, 0
    duplicate faces, 0 unmatched interior segments, and 0 Z mismatches.
- dense direct hosted performance row `MTA36-SINGLE-MESH-DENSE-SMALL-PERF-1778585781`:
  - same `50m x 70m @ 20cm` scale and 352 logical patches;
  - smaller localized dirty edit `251.13ms` versus forced full rebuild `683.8ms`, ratio `2.72x`;
  - local and forced-full audits both passed registry and topology checks with 0 orphan edges, 0
    duplicate faces, 0 unmatched interior segments, and 0 Z mismatches.
- latest valid multi-edit visual row `MTA36-SEQUENCE-RERUN-CORRIDOR-FAIR-TARGET-1778587170` on
  selected terrain `MTA36-SM-AGG-LOCAL-1778585439`:
  - `corridor_transition`: `1014.39ms`, revision 10, face count 5792, registry 49 patches;
  - `local_fairing` with `5m` smooth blend radius: `1544.68ms`, revision 11, face count 5520;
  - `target_height` with `5m` smoothing radius: `1028.74ms`, revision 12, face count 5564;
  - all three accepted edits passed registry/topology audit with face metadata missing `0`,
    orphan edges `0`, duplicate faces `0`, unmatched interior segments `0`, Z mismatches `0`,
    and no leak tokens.
- invalidated partial multi-edit row `MTA36-SEQUENCE-CORRIDOR-FAIR-TARGET-1778587054`:
  - first corridor row succeeded, but the local fairing row used unsupported falloff
    `smoothstep` and was refused with `unsupported_option`; the rerun above supersedes it.
- final user-observed visual and reload result:
  - latest multi-edit looked visually flawless in SketchUp;
  - true save/reopen passed;
  - visual note: output may be slightly more detailed than desired, which feeds the tuning pass but
    is not a correctness blocker.
- performance tuning and bottleneck matrix before any code-level tuning:
  - direct hosted matrix used `50m x 70m @ 20cm`, `251x351` samples, 88,101 samples, generator-level
    fixtures because public create caps prevent a command-path terrain at that density;
  - default viable policy `tol=0.01`, patch size `16`, conformance ring `1`: small edit
    `162.67ms`, broad edit `453.94ms`, forced-full comparison `656.38ms`, speedup `4.04x`,
    topology passed;
  - `tol=0.02`, patch size `16`, ring `1`: small `141.27ms`, broad `387.39ms`, topology passed;
  - `tol=0.03`, patch size `16`, ring `1`: small `133.72ms`, broad `376.04ms`,
    create plan `186.33ms`, create generate `65.37ms`, final face count 3622, topology passed;
  - `tol=0.04` and `tol=0.05` were slightly faster or comparable, but may reduce detail too
    aggressively and need visual judgment;
  - conformance ring `0` was fastest but invalid, producing unmatched interior segments, so it is
    not viable;
  - patch sizes `24` and `32` were slower than patch size `16` because replacement domains grew;
  - command-path tolerance check at `100x100` showed tolerance reduces latency and face count:
    `tol=0.01` edit `436.29ms` with 3206 faces, `tol=0.03` edit `264.54ms` with 1612 faces,
    `tol=0.04` edit `241.16ms` with 972 faces.
- code-level bottleneck candidates captured for the next pass:
  - `TerrainOutputPlan.max_cell_error` optimization was implemented and kept after same-session
    revert/reapply hosted A/B;
  - adaptive non-leaf split decisions now short-circuit when a cell already exceeds tolerance,
    while exact max is still computed for accepted/leaf cells;
  - adaptive patch replacement now batch-marks unique emitted edges instead of repeatedly calling
    `mark_derived_edges(face)` for shared edges on every face;
  - planned adaptive patch batch construction now caches projected adaptive vertices per batch;
  - consider face-winding and staged batch streaming optimizations only after lower-risk timing
    changes are measured.
- same-session planner optimization A/B on `70m x 100m @ 20cm`, `351x501`, 175,851 samples:
  - `tol=0.01` create plan `800.69ms -> 239.15ms`, small edit total
    `369.88ms -> 243.78ms`, broad edit total `1462.46ms -> 1100.48ms`;
  - `tol=0.03` create plan `397.08ms -> 98.32ms`, small edit total
    `273.62ms -> 192.58ms`, broad edit total `876.95ms -> 699.25ms`;
  - all hosted rows passed registry/topology audit with orphan edges `0`, duplicate faces `0`,
    unmatched interior segments `0`, and Z mismatches `0`.
- edge batch marking detailed measurement on `70m x 100m @ 20cm`, `tol=0.01`:
  - small edit repeated edge marking `14.02ms -> 0.48ms`, with one unique-edge pass `8.55ms`;
  - broad edit repeated edge marking `75.16ms -> 2.41ms`, with one unique-edge pass `46.40ms`;
  - `emit_faces` changed `50.45ms -> 45.15ms` small and `283.92ms -> 269.86ms` broad;
  - targeted sub-bucket improved, but end-to-end total gains were small/noisy relative to planner
    and planned-batch work.
- planned adaptive patch batch optimization varied-terrain matrix:
  - baseline case `MTA36-PLANNED-PATCH-BATCH-BASELINE-1778595622`; after case
    `MTA36-PLANNED-PATCH-BATCH-BASELINE-1778595925`;
  - fixtures: `gaussian_wave` `70m x 100m`/`351x501`, `ridge_plateau` `80m x 80m`/`401x401`,
    and `multi_peak_long` `60m x 120m`/`301x601`, all at `20cm`, with tolerances `0.01` and
    `0.03`;
  - small `planned_patch_batch` min/median/max improved from `17.00/31.59/117.78ms` to
    `5.58/8.22/11.30ms`;
  - broad `planned_patch_batch` min/median/max improved from `218.84/330.03/334.74ms` to
    `65.19/91.53/101.93ms`;
  - representative broad totals improved:
    `1171.67ms -> 982.77ms` (`gaussian_wave`, `0.01`),
    `918.65ms -> 720.29ms` (`gaussian_wave`, `0.03`),
    `1408.56ms -> 1226.20ms` (`ridge_plateau`, `0.01`),
    `1041.21ms -> 941.44ms` (`ridge_plateau`, `0.03`),
    `1204.60ms -> 1006.89ms` (`multi_peak_long`, `0.01`),
    `920.04ms -> 680.27ms` (`multi_peak_long`, `0.03`);
  - all hosted rows passed registry/topology audit with orphan edges `0`, duplicate faces `0`,
    unmatched interior segments `0`, and Z mismatches `0`.
- generic lifecycle hosted smoke:
  - deployed `PatchLifecycle` files, updated output plan, mesh generator, and command files to the
    SketchUp plugin tree;
  - in-process Ruby reload could not redefine already-loaded `AdaptivePatchPolicy` with a new
    superclass, which is expected until SketchUp restart;
  - direct generic smoke with `PatchLifecycle::PatchGridPolicy` configured for `adaptive-patch`
    IDs succeeded: `TerrainOutputPlan` used `PatchLifecycle::PatchPlan`, generated one
    `adaptive_patch_mesh`, wrote registry as a JSON string, and emitted 168 faces.
- fresh reinstall/restart live verification row `MTA36-RESTART-LIVE-1778598078`:
  - SketchUp was restarted after reinstall, and `AdaptivePatchPolicy` loaded cleanly as a wrapper
    over `PatchLifecycle::PatchGridPolicy`;
  - command-path terrain was created off to the side at `x=3200m`, with selected bounds
    `x=3200..3280m`, `y=0..80m`;
  - create emitted one `adaptive_patch_mesh`, 0 patch-container groups, 25 logical patches, registry
    as a JSON string, 11,947 faces, and no public leak tokens;
  - overlapping `corridor_transition`, `local_fairing`, `target_height`, `planar_region_fit`, and
    `survey_point_constraint` edits all returned `edited` on the same selected terrain;
  - the mesh persistent ID stayed stable through all five edits, revisions advanced `1 -> 6`, and
    each row kept one owner child mesh group, 0 patch-container groups, valid registry JSON,
    complete face metadata, registry face-count matches, orphan edges `0`, duplicate faces `0`,
    duplicate coincident XY edges `0`, Z-mismatch duplicate edges `0`, and no public leak tokens.
- invalidated dense setup row:
  - `MTA36-SINGLE-MESH-DENSE-PERF-1778585590` is discarded because the script accidentally changed
    the local terrain origin between before and after states, producing artificial unmatched
    interior segments. The corrected fixed-origin rows above supersede it.

Final closeout decisions:

- MTA-36 retains the existing production adaptive simplification tolerance of `0.01m`.
  Tolerances such as `0.03m` showed useful performance and lower face count in hosted rows, but
  changing the default is a visual-quality/product tuning decision and is not required to prove the
  patch lifecycle.
- No further MTA-36 code-level bottleneck work is required before closeout. Planner short-circuiting,
  unique-edge marking, and planned-batch vertex caching were implemented and hosted-validated.
- Step 10 final review and live SketchUp verification are complete.
- Step 11 size calibration is complete in `size.md`.

## MTA-35 Handoff

Lifecycle pieces now available for CDT reuse:

- stable patch policy and lattice IDs independent of adaptive cell splits;
- dirty-window to patch and conformance-ring resolver;
- compact registry store with reload-style JSON parsing;
- purpose-specific traversal and no-delete validation sequencing;
- logical patch registry and face ownership metadata conventions;
- internal timing and hosted evidence row shape;
- no-public-leak contract guardrails.
- generic `PatchLifecycle` policy/resolver/registry/plan/timing/traversal classes that MTA-35 can
  use with CDT-specific patch IDs, registry keys, output kinds, and replacement face providers.

Adaptive-only assumptions that MTA-35 must not inherit:

- adaptive mesh quality still comes from the current adaptive emitter, not the CDT mesh builder;
- adaptive patch face generation is not a CDT mesh builder; CDT must plug its own replacement
  provider into the generic patch lifecycle rather than reuse adaptive face planning;
- the first-pass one-group-per-patch output topology is not CDT-ready and must not become the CDT
  output substrate;
- true CDT topology, residual solving, constrained-edge seam validation, and feature-intent behavior remain out of scope.

## Remaining Gaps

- No MTA-36 closeout gaps remain.
- Adaptive simplification tolerance/product tuning is deliberately left as future work; MTA-36
  retained the current `0.01m` default after proving the patch lifecycle and performance path.
- CDT mesh provider integration, CDT topology, residual solving, constrained-edge seam validation,
  and feature-intent behavior remain MTA-35 scope.
