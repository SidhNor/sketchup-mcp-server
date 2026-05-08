# Summary: MTA-31 Enable CDT Terrain Output After Disabled Scaffold

**Task ID**: `MTA-31`
**Status**: `closed-disabled-by-default-follow-up-required`
**Updated**: `2026-05-09`

MTA-31 closed as an enablement and evidence milestone, not as a default-enable
change. CDT remains disabled by default. Public MCP responses and the default
terrain output backend remain unchanged.

## Shipped Behavior

- CDT output ownership was cleaned into the `terrain/output/cdt` runtime slice,
  with `TerrainTriangulationAdapter` kept as the low-level Ruby/native seam.
- `FeatureIntentSet` now normalizes and round-trips `semanticScope`,
  `strengthClass`, `relevanceWindow`, `lifecycle`, `effectiveRevision`, and
  `effectiveIndex`.
- Legacy feature-intent records normalize to `lifecycle.status = active`.
- `FeatureIntentMerger` materializes lifecycle state instead of deleting retired
  records, supports same-ID active replacement, marks exact retires, supersedes
  same-kind/same-scope active records, and materializes `effectiveIndex` before
  `state.with_feature_intent`.
- Added `EffectiveFeatureView`, which validates the full stored effective index,
  exposes active features, applies relevance-bounded selection, and owns stale
  index errors.
- Normal CDT planning uses `EffectiveFeatureView`; command edit windows are
  propagated into planner selection, including `SampleWindow` instances.
- `TerrainFeatureGeometryBuilder` accepts selected features and now defaults to
  `EffectiveFeatureView` when no selected feature list is supplied, so retired
  persisted history is not replayed through the fallback path.
- CDT point planning and backend gates now contain hard/firm/soft primitives to
  the terrain domain and provide pre-triangulation hard/firm primitive budget
  fallback before residual refinement starts.
- `ResidualCdtEngine` now reports residual refinement probes: pass count, scan
  count/time, sample count, point insertion time, retriangulation count/time, and
  point counts by pass.

## Code Review Disposition

Required `grok-4.3` code review ran in Step 10.

- Finding: effective index validation was digest-only. Fixed by validating the
  full stored index, including active buckets, counts, digest, and revision.
- Finding: lifecycle revision normalization could let audit-only revision churn
  affect lifecycle state. Fixed so lifecycle defaults come from feature-intent
  revision, not provenance churn.
- Finding: native-unavailable might be swallowed. Current code already preserved
  it, but a real residual-engine regression was added.
- Finding: planner/builder could still consume raw feature history. Planner was
  already on `EffectiveFeatureView`; builder fallback was hardened after review
  and covered with a retired-history regression.
- Later review comments claiming new fields were dropped or retirees were still
  deleted were stale against the current diff and were dispositioned with local
  code inspection.

## Validation Evidence

Automated validation after final review follow-up:

```sh
bundle exec ruby -Itest -e 'paths = %w[test/terrain/features/terrain_feature_geometry_builder_test.rb test/terrain/features/effective_feature_view_test.rb test/terrain/features/terrain_feature_planner_test.rb test/terrain/features/feature_intent_set_test.rb test/terrain/features/feature_intent_merger_test.rb test/terrain/commands/terrain_surface_commands_test.rb test/terrain/output/residual_cdt_engine_test.rb test/terrain/output/terrain_cdt_backend_test.rb test/terrain/output/cdt_terrain_point_planner_test.rb test/terrain/output/terrain_triangulation_adapter_test.rb]; paths.each { |path| load path }'
# 123 runs, 671 assertions, 0 failures, 0 errors, 0 skips

bundle exec ruby -Itest -e 'paths = Dir["test/terrain/**/*_test.rb"]; paths.sort.each { |path| load path }'
# 585 runs, 9277 assertions, 0 failures, 0 errors, 3 skips

bundle exec ruby -Itest -e 'paths = %w[test/release_support/runtime_package_tasks_test.rb test/release_support/runtime_package_manifest_test.rb test/release_support/runtime_package_verifier_test.rb test/release_support/runtime_package_stage_builder_test.rb]; paths.each { |path| load path }'
# 14 runs, 85 assertions, 0 failures, 0 errors, 0 skips

bundle exec rubocop --cache false src/su_mcp/terrain/features src/su_mcp/terrain/commands/terrain_surface_commands.rb src/su_mcp/terrain/output/cdt test/terrain/features test/terrain/commands/terrain_surface_commands_test.rb test/terrain/contracts/terrain_contract_stability_test.rb test/terrain/output/cdt_terrain_point_planner_test.rb test/terrain/output/terrain_cdt_backend_test.rb test/terrain/output/residual_cdt_engine_test.rb test/terrain/output/terrain_triangulation_adapter_test.rb test/terrain/state/tiled_heightmap_state_test.rb test/terrain/storage/terrain_state_serializer_test.rb
# 31 files inspected, no offenses detected

git diff --check
# clean
```

No user-facing docs were changed because no public tool contract, default
backend, response shape, setup path, or user workflow changed.

Hosted SketchUp was not rerun after the final builder fallback hardening. That
change is SketchUp-free and affects only callers that invoke
`TerrainFeatureGeometryBuilder` without a preselected feature list; the normal
hosted command path had already been verified through `TerrainFeaturePlanner`
and is covered by the focused regression plus full terrain suite above.

## Hosted SketchUp Evidence

Hosted validation ran against the deployed SketchUp scene `TestGround` and the
terrain `option-terrain-north-terrace-west-threshold-amendment-semantic-edit-v1`,
with CDT enabled through injected command/backend instances.

- P1 real CDT `target_height`: completed, emitted `5,379` derived CDT faces,
  feature count `204`, effective revision `97`, but took roughly 9 minutes.
- P2 gray-box `corridor_transition`: accepted through a fast CDT backend seam,
  no public leak, CDT seam called once.
- N1 native unavailable: public result stayed `edited`, internal fallback was
  `native_unavailable`, fallback grid emitted `10,591` faces, no public leak.
- N2 unsupported option: refused before CDT, with no backend call.
- E1-E4 edge probes covered hard out-of-domain fallback, firm clipping, soft
  pressure not exhausting hard/firm budget, and hard point budget exhaustion
  before adapter triangulation.

Hosted validation also found and fixed a real bug: the command path passed
`SampleWindow`, while `EffectiveFeatureView` initially only understood hash
windows. Before the fix, P1 selected all `204` active features. After the fix,
the same selection included `123` and excluded `81` by relevance.

## Performance Evidence

The decisive result is that Ruby CDT is not ready for default enablement.

Small hosted timing terrain `mta-31-cdt-timing-small-1778273068`:

- 31x31 samples, 10 seeded edits, 26 pre-existing features.
- Real CDT command: about `4085ms`; planner/effective view/geometry build
  `5.49ms`; backend `3969ms`; residual refinement `3521ms`; initial
  triangulation `25.88ms`; final mesh `511` vertices / `997` faces.
- Residual disabled: about `136ms`, but max height error rose to `1.1256`, so
  this is not acceptable output quality.
- Detailed residual probe default: command `4891ms`, scan time `462ms`,
  six triangulations, late triangulations about `1215ms` and `1243ms`, final
  max error `0.0469`.
- Bare no-feature mesh on the same 31x31 terrain: about `918ms`.
- Seeded features without a new edit: about `4963ms`.

Conclusion: effective feature view and geometry planning are not the bottleneck.
The bottleneck is the current residual policy repeatedly retriangulating a
growing point set in Ruby. Feature constraints and residual point growth are a
large multiplier, while scans are measurable but secondary.

## External Review Disposition

The external research note
`specifications/research/managed-terrain/cdt-terrain-output-external-review.md`
was added as an evidence artifact.

MTA-31 intentionally does not implement the research recommendations directly.
The useful closeout decision is architectural: keep CDT as a topology primitive,
but do not continue trying to reach interactive edits with the current global
residual loop. Follow-up work should focus on cached local patches, dirty-window
residual refinement, spatial hard-feature filtering, bounded residual policy,
and only then native/incremental triangulation if still needed.

## Remaining Gaps

- CDT remains disabled by default.
- Sub-3-second edit responsiveness was not achieved.
- Ruby CDT viability for default production enablement is negative under the
  current residual strategy.
- Repeated undo/new-edit branch behavior was not fully proven in hosted SketchUp.
- Save/reopen persistence beyond the hosted save-copy path still needs a focused
  acceptance pass.
- Native/C++ is not implemented; the adapter posture is preserved for a future
  task.

## Follow-Up Direction

The next task should be a recalibration/rearchitecture slice, not another
mechanical CDT enablement pass. It should define a local/dirty-region residual
strategy and budget model, decide what quality metric must be preserved, and
then measure against representative hosted edits before considering default CDT
enablement again.
