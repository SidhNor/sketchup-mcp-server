# Summary: MTA-35 Implement CDT Replacement Provider On PatchLifecycle For Windowed Terrain Edits

**Task ID**: `MTA-35`
**Status**: `implementation-complete`
**Date**: `2026-05-14`

## Current State

- The corrected local MTA-35 implementation queue is complete through Step 10 local validation,
  refreshed `grok-4.3` review follow-up, live strict-CDT public-command verification, final
  `$task-review`, final `grok-4.3` review, and Step 11 estimation calibration.
- MTA-35 remains internally gated and disabled on the default production path. Default enablement is
  out of scope and remains blocked on a follow-up performance/native-backend decision.
- Public MCP terrain request/response contracts remain unchanged and continue to hide CDT patch IDs,
  registry details, feature-planning internals, seam/topology diagnostics, fallback enums, timing
  buckets, and raw mesh internals.

## Shipped Local Behavior

- Added an internally gated stable-domain CDT replacement path over MTA-36 `PatchLifecycle`.
- Added a private grey-box output switch, `SKETCHUP_MCP_TERRAIN_SIMPLIFIER=cdt_patch`, that routes
  public terrain commands through DI to the stable-domain CDT provider with CDT fallback disabled.
- `PatchLifecycle` remains the owner of CDT patch identity, dirty-window resolution, face ownership,
  registry persistence, mutation sequencing support, timing, and readback data.
- CDT create/bootstrap and full CDT rebuild now emit lifecycle-owned `cdtPatchId` face metadata and
  write registry records through `PatchLifecycle`.
- Dirty replacement now consumes bootstrap or prior-replacement metadata instead of proof-window
  digests or handcrafted fixture-only ownership.
- `CdtPatchBatchPlan` is invocation-scoped and carries lifecycle resolution, retained-boundary
  spans, terrain summary, and feature plan without owning registry state or patch identity.
- Retained-boundary spans are captured before provider invocation and the same snapshot feeds
  provider input and seam validation.
- `TerrainFeaturePlanner` now returns a structured CDT patch feature plan with shared
  `selectedFeaturePool`, per-patch `patchFeatureBundles`, inclusion reasons, counts, derived feature
  geometry, and `featureSelectionDigest`.
- Feature bundle role tags now cover affected, replacement, conformance, retained-boundary, and
  safety-margin domains when those domains are present.
- Provider acceptance now rejects missing production mesh, invalid topology, duplicate triangles,
  duplicate boundary edges, bad winding, out-of-domain geometry using terrain origin/spacing,
  stale retained-boundary evidence, and solver-reported seam Z mismatch.
- Dirty replacement accepts only after provider acceptance, registry-backed ownership lookup,
  ordered multi-span seam validation, mutation, registry writeback, and orphan-edge cleanup.
- Default adaptive mode keeps the safe fallback behavior. The private `cdt_patch` switch refuses
  selected-output failures instead of rendering adaptive fallback geometry.
- Internal timing now covers command prep, feature selection, CDT input build,
  retained-boundary snapshot, solve, topology validation, ownership lookup, seam validation,
  mutation, registry write, audit, fallback route, and total runtime.
- Live verification found and corrected drift where public direct terrain command construction could
  bypass the strict output stack. `TerrainSurfaceCommands` now defaults through
  `TerrainOutputStackFactory`, while `RuntimeCommandFactory` still injects explicitly.
- Live A/B verification found and corrected a second strict-mode gap: CDT-ineligible paths could
  still render adaptive output, and patch-local preserve rectangles spanning a replacement patch
  could be misclassified as hard domain violations. Strict CDT now refuses instead of falling back
  when CDT is genuinely ineligible, and valid hard preserve regions are clipped to the local patch
  domain for CDT seed/segment planning instead of rejecting valid public edits.
- Live remaining-mode verification found and corrected retained-boundary and per-patch feature
  filtering gaps:
  - retained CDT neighbor spans now merge face fragments and include lifecycle side endpoints from
    the terrain state so valid retained boundaries do not falsely fail with `open_gap`;
  - stable-domain CDT patch solves now receive patch-local feature geometry, using state origin and
    spacing for patch domain checks, so survey anchors outside the current patch do not falsely
    trigger hard geometry failure.
- CDT residual refinement now scans broad error candidates but inserts a spatially thinned subset
  first, with a conservative broad recovery path when thinning cannot satisfy the hard height-error
  gate.
- Stable-domain CDT solves now synchronize actual internal replacement-boundary vertices across
  adjacent patches before acceptance, so patch-local feature or support vertices on one side are
  mirrored into the neighboring patch solve instead of leaving T-junction seam risk.
- Final review cleanup removed stale test-helper `patch_domain_digest` compatibility aliases so
  executable tests no longer keep proof-window identity as an accepted input shape.
- Latest local optimization keeps solved replacement patch meshes during internal boundary
  synchronization and re-solves only patches whose synchronized boundary anchors changed; the
  height-error meter also avoids per-sample feature-array concatenation and uses flat array buckets
  for triangle lookup.

## Validation

- Full available Ruby test glob:
  `bundle exec ruby -Itest -e 'ARGV.each { |path| require_relative path }' test/**/*_test.rb`
  - Result: 482 runs, 1788 assertions, 0 failures, 0 errors, 2 skips.
- Focused post-live regression suite:
  - `stable_domain_cdt_solver_test.rb`, `stable_domain_cdt_provider_test.rb`,
    `terrain_mesh_generator_test.rb`, `terrain_output_stack_factory_test.rb`,
    `runtime_command_factory_test.rb`, and `mcp_runtime_config_test.rb`
  - Result: 94 runs, 1740 assertions, 0 failures, 0 errors, 0 skips.
- Terrain command/default-DI regression suite:
  - `terrain_surface_commands_test.rb`, `runtime_command_factory_test.rb`, and
    `terrain_output_stack_factory_test.rb`
  - Result: 49 runs, 340 assertions, 0 failures, 0 errors, 0 skips.
- Post-A/B focused strict-CDT regression:
  - `terrain_feature_planner_test.rb`, `terrain_mesh_generator_test.rb`,
    `cdt_terrain_point_planner_test.rb`, and `residual_cdt_engine_test.rb`
  - Result: focused suites green, including the new no-fallback strict mode and
    patch-local protected-region clipping cases.
- Post-remaining-check focused regressions:
  - `stable_domain_cdt_solver_test.rb` and `terrain_mesh_generator_test.rb`
  - Result: focused suites green, including retained-boundary endpoint enrichment and patch-local
    feature geometry filtering with non-zero state origin/spacing coverage.
- Post-density-reduction focused regressions:
  - `residual_cdt_engine_test.rb`, `terrain_cdt_backend_test.rb`,
    `stable_domain_cdt_solver_test.rb`, `stable_domain_cdt_provider_test.rb`, and
    `terrain_mesh_generator_test.rb`
  - Result: focused suites green, including spatial residual thinning, conservative recovery,
    synchronized internal replacement-boundary anchors, and a reduced-face-count case that stays
    under the 0.05 height-error gate.
- Post-review focused seam/density regressions:
  - `residual_cdt_engine_test.rb`, `stable_domain_cdt_solver_test.rb`,
    `stable_domain_cdt_provider_test.rb`, and `terrain_mesh_generator_test.rb`
  - Result: 103 runs, 1844 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop:
  - `bundle exec rubocop --cache false ...`
  - Result: focused changed files inspected, no offenses detected.
- `git diff --check`: clean.
- Final `$task-review` dead-code sweep:
  - `tldr dead src/su_mcp/terrain/output/cdt --format json --quiet`: 0 dead, 0 possibly dead.
  - `tldr dead src/su_mcp/terrain/output --format json --quiet`: 0 dead, 0 possibly dead.
  - `tldr dead src/su_mcp/terrain --format json --quiet`: 0 dead, 0 possibly dead across 1945
    functions.
- Final post-review validation after removing stale test-helper aliases:
  - full available Ruby test glob: 482 runs, 1788 assertions, 0 failures, 0 errors, 2 skips;
  - focused affected tests: 40 runs, 327 assertions, 0 failures, 0 errors, 0 skips;
  - focused changed-file RuboCop: 35 files inspected, no offenses;
  - `git diff --check`: clean.

## Code Review

- Required Step 10 `mcp__pal__codereview` ran with `model: "grok-4.3"` using continuation
  `a5fcb79f-614c-4646-8308-7c06f27fce44`.
- Review found no critical, high, or medium blockers.
- Low-severity review findings were addressed:
  - added retained-boundary, conformance, and safety-margin feature bundle role tags;
  - added provider/result acceptance gates for duplicate boundary edges, stale retained evidence,
    and seam Z mismatch;
  - changed provider domain containment to use terrain origin/spacing instead of assuming sample
    coordinates equal output XY;
  - added bootstrap fallback timing coverage for `fallback_route` and `audit`.
- Refreshed Step 10 `mcp__pal__codereview` ran with `model: "grok-4.3"` using continuation
  `ccace091-bb8c-4673-aa02-8d40cfaf78a1` after the retained-boundary and patch-local feature
  filtering fixes.
- The refreshed review found no medium-or-higher issues.
- Post-density/seam `grok-4.3` review ran with continuation
  `521b4253-2bf4-4113-a15c-329412daf027`.
- Review follow-up added an explicit recovery final-scan regression and aligned patch feature-domain
  filtering to `sampleBounds`.
- Final `$task-review` ran over the full uncommitted change set, including broad unchanged CDT dead
  code checks. Local semantic follow-up removed two stale test-helper proof-identity aliases.
- Final required `grok-4.3` code review ran with continuation
  `2ddf1602-e6f2-489b-b583-8da8a499d797`.
- The final review found no critical, high, or medium issues. Its only low observations required no
  change: `DEFAULT_CDT_ENABLED` is intentionally false, `cdt_patch` is selected only by exact private
  switch match, and retained-neighbor identity checks are defensive.

## Hosted Verification

- Live strict public-command verification ran in SketchUp with
  `SKETCHUP_MCP_TERRAIN_SIMPLIFIER=cdt_patch`.
- Initial live attempts exposed three implementation/verification drifts and were corrected:
  - adaptive fallback was still visible under the selected CDT mode;
  - initial create used global CDT simplification instead of lifecycle-owned patch bootstrap;
  - full-grid edit reconciliation could still rebuild adaptive patch output.
- Corrected live public path:
  - created `mta35-cdt-strict-2800` at x=2800m using public `create_terrain_surface`;
  - ran public `planar_region_fit` edit through the strict CDT path;
  - inspected live output: 4101 direct `cdt_patch_face` faces, 25 CDT patch IDs, valid 25-patch
    registry, registry face total 4101, no nested adaptive output.
- Earlier corrected strict run on `mta35-cdt-strict-2600` also accepted target-height replacement
  with 3801 `cdt_patch_face` faces across 25 patch IDs and full timing buckets.
- Save/reopen/readback was live-validated after the corrected strict CDT output path.
- Repeated overlapping edit row ran on `mta35-cdt-overlap-2900` at x=2900m:
  - create bootstrap produced 50 direct `cdt_patch_face` faces, 25 patch IDs, valid registry;
  - a large dirty edit intentionally refused with internal `hard_geometry_gate_failed`, and
    no-delete behavior preserved the original 50 CDT faces and valid registry;
  - three accepted overlapping `target_height` edits advanced revisions 2, 3, and 4, all through
    dirty-window CDT replacement with retained-boundary snapshot, ownership lookup, seam
    validation, mutation, and registry write timing buckets;
  - final repeated-overlap state after revision 4: 2536 direct `cdt_patch_face` faces, 25 patch IDs,
    valid 25-patch registry, registry face total 2536, no adaptive output.
- Multi-span retained-boundary row ran on the same terrain at revision 5:
  - accepted public `target_height` edit over previously replaced terrain;
  - replacement batch covered 9 lifecycle patch IDs and retained-boundary snapshot contained
    6 fresh retained spans;
  - final state: 2712 direct `cdt_patch_face` faces, 25 patch IDs, valid 25-patch registry,
    registry face total 2712, no adaptive output.
- Residual CDT metrics were captured from a follow-up public edit on the same strict CDT path:
  - 9 accepted patch backend calls;
  - each call reported `residual_satisfied`;
  - residual refinement pass counts ranged from 2 to 4, retriangulations from 1 to 3;
  - residual point insertions were positive for every patch, with total residual count 1441 and
    max per-patch residual count 251;
  - selected point counts stayed below dense source counts, e.g. 93-255 selected points versus
    289 dense source points per patch, so this was not accepting the dense full-grid mesh as CDT.
- Adaptive-vs-CDT live A/B verification ran with identical heightmaps and identical public edits
  across target-height, corridor-transition, and planar-region-fit operations.
  - The CDT run stayed on lifecycle-owned `cdt_patch_face` output for all edits, kept registry
    readback valid, and did not fall back to adaptive output.
  - The run exposed and verified the patch-local protected-region clipping fix for valid preserve
    zones spanning replacement patches.
  - Detailed timing, face-count, residual, and sampled-elevation measurements were captured in the
    live verification notes rather than expanded in this closeout summary.
- Public output summary still reports the existing stable `adaptive_tin` mesh type string; CDT
  verification relies on internal live output metadata and registry inspection, not public contract
  expansion.
- Remaining feature-mode row ran on a fresh root-level terrain at x=6100m after closing an accidental
  active component edit context and removing the generated check groups that had landed inside that
  component definition.
  - Public create, target-height, corridor-transition, planar-region-fit, local-fairing, and
    survey-point-constraint all accepted through strict CDT.
  - The final state stayed root-level, had no nested output groups, contained only `cdt_patch_face`
    output, retained 25 lifecycle patch IDs, and had a valid 25-patch registry.
- Density-reduction verification ran on a fresh root-level strict-CDT terrain at x=6500m:
  - the same public feature-mode sequence accepted through CDT with valid registry and no adaptive
    output;
  - final CDT output dropped from the prior comparable feature row's 6192 faces to 2975 faces while
    readback max height error against the stored state remained within the 0.05m gate.
- Internal seam synchronization verification reran the same strict-CDT feature-mode sequence at
  x=7100m after adding actual boundary-vertex unioning across adjacent patch solves:
  - all 40 internal patch adjacency checks had matching boundary vertex sets;
  - final CDT output had 4090 faces and readback max height error remained within the 0.05m gate.
- Latest optimization live measurement after dirty-only boundary-sync re-solves and height-meter
  bucket cleanup showed a modest improvement on the broad overlap row: solve time moved from about
  8.03s to 7.60s, lifecycle total from about 8.29s to 7.85s, engine builds from 32 to 30, residual
  scan time from about 2.00s to 1.71s, and retriangulation from about 4.66s to 4.31s.
- Registry invalidation/no-delete row ran on a fresh root-level terrain at x=6220m:
  - after intentionally corrupting the patch registry, a valid public edit refused with
    `terrain_output_ownership_invalid`;
  - the original CDT faces and invalid registry remained in place, proving local CDT did not erase
    output before ownership/readback was trustworthy.
- Structural blocker variants for duplicate triangles, duplicate boundary edges, out-of-domain
  geometry, stale retained evidence, seam gaps, and protected-boundary crossings are covered by the
  local provider/seam acceptance suites. The live structural row exercised registry/readback
  invalidation and no-delete preservation through the public command path.

## Remaining Gaps

- Default-enable remains blocked and out of scope. Density materially improved on the live
  feature-mode rows, but seam-safe synchronization still leaves CDT solve time too high for a
  default-enable recommendation without a follow-up solver/backend optimization.
- A broader hosted structural-fault harness would still be useful, but it is follow-up evidence
  rather than a known correctness gap in the current strict public-command path.
- Native or incremental CDT backend research is the recommended next performance task; current Ruby
  CDT repeatedly rebuilds triangulations during residual refinement and remains the main runtime
  cost.
