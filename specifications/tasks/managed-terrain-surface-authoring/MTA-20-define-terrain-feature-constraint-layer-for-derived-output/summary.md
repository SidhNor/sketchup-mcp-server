# Summary: MTA-20 Define Terrain Feature Constraint Layer For Derived Output

**Task ID**: `MTA-20`
**Status**: `implemented`
**Completed**: `2026-05-03`

## Shipped Behavior

- Added `heightmap_grid` schema v3 with compact durable `featureIntent` state on
  `TiledHeightmapState`.
- Added sequential serializer migration from v1/v2 payloads to v3 with default empty
  `featureIntent`.
- Added digest-stable `FeatureIntentSet` normalization, finite internal feature kind/role
  validation, semantic feature IDs, canonical ordering, and JSON-safe payload checks.
- Added `FeatureIntentMerger` lifecycle policy for exact retirement and semantic upsert while
  retaining overlapping unrelated features.
- Added thin feature intent emission for corridor, target region, planar region, survey control,
  fairing region, preserve region, and fixed control inputs.
- Added `TerrainFeaturePlanner` pre-save feature validation/cap refusal, post-save runtime feature
  context preparation, runtime-only inferred heightfield candidates, and deterministic topology
  classification helpers.
- Strengthened planner foundation after plan cross-check with internal cap diagnostics, explicit
  fixed-control and preserve-region conflict diagnostics, conservative tight-corridor refusal, and
  public stripping of internal planner diagnostics on command refusals.
- Wired `TerrainSurfaceCommands` so successful edits emit and merge feature intent before
  repository save, run pre-save feature refusal before save/regeneration, prepare runtime context
  after save, and pass runtime-only context to mesh regeneration.
- Reconciled prepared feature affected windows into dirty output planning, with explicit full-grid
  fallback when requested by the feature planner.
- Hardened public edit evidence sanitization so nested private feature/output diagnostics inside
  compact evidence blocks are removed before response construction.
- Preserved compact public MCP response shape and added no-leak coverage for feature IDs, feature
  kinds, roles, payloads, affected windows, lanes, raw triangles, solver internals, and SketchUp
  object leakage.

## Validation Evidence

- `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
  - `274 runs, 2169 assertions, 0 failures, 0 errors, 3 skips`
- `bundle exec rake ci`
  - RuboCop: `223 files inspected, no offenses detected`
  - Ruby tests: `874 runs, 4519 assertions, 0 failures, 0 errors, 37 skips`
  - Package verification produced `dist/su_mcp-1.1.2.rbz`
- Focused post-review checks:
  - `60 runs, 563 assertions, 0 failures, 0 errors, 0 skips`
  - Focused RuboCop with cache disabled: `2 files inspected, no offenses detected`
- Hosted smoke entrypoints were executed locally and skipped by design:
  - `test/terrain/terrain_repository_hosted_smoke_test.rb`
  - `test/terrain/terrain_output_live_validation_test.rb`
  - `test/terrain/local_fairing_hosted_smoke_test.rb`
  - Result: `3 runs, 0 assertions, 0 failures, 0 errors, 3 skips`

## Codereview Disposition

- Required PAL codereview with `model: "grok-4.3"` completed.
- Review identified a material feature-window reconciliation gap. Follow-up implemented prepared
  feature window use in `TerrainSurfaceCommands#edit_output_plan`, retained explicit full-grid
  fallback, added command coverage, and reran CI successfully.
- Plan cross-check then found under-implemented foundation scope around planner diagnostics,
  fixed/preserve conflicts, tight corridor handling, semantic ID edge cases, and post-save
  output-preflight preservation. Follow-up implemented those items and reran focused tests, terrain
  suite, hosted-smoke entrypoints, PAL review, and CI.
- Review suggested defensive cap projection for malformed feature windows. Follow-up added guarded
  projection in `TerrainFeaturePlanner#projected_sample_count`.
- Review suggested documenting unused first-slice `feature_context` in mesh regeneration.
  Follow-up added an explicit comment.
- Final PAL follow-up found no blocking issues and two low-priority hardening suggestions. Nested
  public evidence sanitization was implemented and tested; moving feature-window reconciliation
  entirely into the planner was left as non-blocking architecture cleanup because the current
  command/planner split still matches the plan's command-owned output planning boundary.

## Public Contract And Docs

- No public MCP tool names, request fields, response fields, setup path, or user-facing workflow
  changed.
- User-facing README/tool docs were reviewed for relevance and did not need updates because
  `featureIntent`, feature constraints, and runtime context remain internal.
- Public contract coverage was expanded through terrain contract stability and command no-leak
  tests.

## Hosted Verification Status

- Live SketchUp verification was run on 2026-05-03 with off-side fixtures in `TestGround.skp`.
- Created terrain fixture `MTA20-LIVE-foundation-20260503` outside existing model bounds at roughly
  X `75.25..81.25`, Y `-44.6..-42.35`; verified schema v3 default `featureIntent`, non-square
  spacing, and compact public response shape.
- Edited the fixture with target-height, preserve-zone, fixed-control, and corridor-transition
  requests; verified durable feature kinds `fixed_control`, `preserve_region`, `target_region`, and
  `linear_corridor`, including corridor centerline/control/endpoint/side-transition roles.
- Verified transformed-owner behavior by moving the fixture owner: `edit_terrain_surface` refused
  with `owner_transform_unsupported` before terrain mutation. The fixture owner was moved back.
- Verified undo by applying a successful fixture edit, then `Sketchup.undo`; revision and digest
  returned from `4`/`35592f...` to `3`/`1024cb...`, with derived face count preserved at `24`.
- Verified post-save output-preflight refusal by adding an unmanaged child group under the fixture:
  edit refused with `terrain_output_contains_unsupported_entities`, revision/digest remained
  unchanged, existing `24` terrain faces remained, and the probe child was then removed.
- Created an off-side adoption source mesh and adopted it into
  `MTA20-LIVE-adopted-20260503`; verified the source was replaced, schema v3 persisted, dense
  off-grid spacing was stored, and an off-grid circular target edit emitted durable
  `target_region` feature intent.
- Non-disruptive save serialization was checked with
  `Sketchup.active_model.save_copy('/tmp/mta20_live_verification_20260503.skp')`, producing a
  `2,029,449` byte copy.
- Full active-model reopen was intentionally not run because it would replace/reload the user's
  currently open scene.

## Remaining Gaps

- Feature-aware output generation is not implemented; existing mesh generation remains the
  production baseline and accepts runtime context for future use.
- Inferred heightfield features are intentionally minimal and runtime-only.
- Planner pointification remains a cheap bounded projection. Tight corridor cases now refuse before
  mutation, but full lane expansion and self-intersection repair remain future output-planning
  work.
- Full save/reopen round-trip of the active model remains unverified; only non-disruptive
  `save_copy` serialization was checked.
