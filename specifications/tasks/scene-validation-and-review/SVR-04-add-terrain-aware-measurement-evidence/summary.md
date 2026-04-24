# SVR-04 Implementation Summary
**Task ID**: `SVR-04`
**Status**: `completed`
**Date**: `2026-04-24`

## Shipped

- Added `measure_scene` mode/kind `terrain_profile/elevation_summary`.
- Added terrain-profile request validation for explicit `target`, profile-only `sampling`, nested `samplingPolicy.visibleOnly`, and nested `samplingPolicy.ignoreTargets`.
- Added an internal `SampleSurfaceQuery#profile_evidence` seam that returns `SampleSurfaceEvidence::Sample` rows without public `sample_surface_z` serialization.
- Added `TerrainProfileElevationSummary` to reduce profile rows into elevation summary values, `no_profile_hits` unavailable results, omitted-quantity evidence, and capped compact sample evidence.
- Updated native MCP schema, native contract fixtures, README, task index, HLD, and PRD language for the shipped branch and deferred slope/grade/diagnostic behavior.

## Validated

- `bundle exec ruby -Itest -e 'load "test/scene_validation/terrain_profile_elevation_summary_test.rb"; load "test/scene_validation/measure_scene_request_test.rb"; load "test/scene_validation/measurement_service_test.rb"; load "test/scene_validation/measure_scene_commands_test.rb"; load "test/scene_query/sample_surface_z_scene_query_commands_test.rb"; load "test/runtime/native/mcp_runtime_loader_test.rb"; load "test/runtime/native/mcp_runtime_native_contract_test.rb"'`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`
- SketchUp MCP runtime ping returned `pong`.

## Live SketchUp Verification

- Hosted smoke passed for full profile measurement with both `sampleCount` and `intervalMeters`.
- Complete profile responses retained the expected stable value fields: min/max elevation, elevation range, sampled length, sample counts, endpoint elevations, net elevation delta, `totalRise`, and `totalFall`.
- Partial profiles with misses returned `outcome: "measured"` with stable keys retained. When endpoints were missing, endpoint fields and delta were `null` and omitted-quantity reasons were present.
- Zero-hit profiles returned `outcome: "unavailable"` with reason `no_profile_hits`.
- `includeEvidence: true` returned compact summary, capped sample evidence, and omitted-quantity reasons. An 80-sample profile returned capped evidence with `samplesTruncated: true`. `includeEvidence: false` emitted no evidence.
- Ignoring a visible occluder caused a combined profile to return terrain elevations rather than occluder elevations.
- Direct hidden targets behaved as expected: `visibleOnly: false` measured the hidden occluder and `visibleOnly: true` returned structured refusal `target_not_sampleable`.
- The measurement-only contract was preserved: no slope/grade verdicts, terrain diagnostics, validation result, or edit output were observed.
- Refusal paths passed for missing `sampling`, missing `sampling.path`, mutually exclusive `sampleCount`/`intervalMeters`, `sampleCount: 201` cap overflow, and missing/bad target resolution.
- Edge semantics observed:
  - A terrain target under a visible sibling occluder returned a partial profile with misses where occluded, consistent with visibility/blocking semantics.
  - A combined target with a visible occluder measured occluder elevations where that was the sampled surface.
  - A combined target with a hidden occluder and `visibleOnly: false` produced one all-ambiguous no-hit case, while direct hidden target measurement worked and ignoring the hidden occluder restored measured output.
  - Ambiguous samples in a partial profile were tracked through `ambiguousCount`, with unsupported endpoint/rise/fall quantities set to `null`.

## Post-Verification Fixes

- Profile and point sampling now build the visible blocker face set once per request instead of once per sample. Regression coverage pins that profile evidence calls `blocking_faces_for` once for visible-only profiles and zero times when `visibleOnly: false`.
- All-ambiguous zero-hit terrain profiles now return unavailable reason `no_unambiguous_profile_hits` instead of the generic `no_profile_hits`, and retain compact evidence internally so `includeEvidence: true` can expose the ambiguous count and capped samples.
- The raw `sample_surface_z` ambiguity contract remains stable: overlapping host surfaces with multiple surviving z-clusters still return `ambiguous` rather than inventing an elevation.
- First TDD optimization slice added request-local prepared face entries for target and blocker faces. Runtime face plane and XY bounds are now prepared once per request/profile, and samples outside prepared XY bounds skip intersection/classification. Regression tests pin one runtime face `vertices` call per profile and zero classification calls for profile samples outside the face XY bounds.
- Second TDD optimization slice added conservative profile-corridor pruning for visible blockers. Visible blocker collection now receives the profile/point XY envelope and skips top-level blocker entities whose bounds cannot overlap the sampled corridor. Regression coverage pins that off-corridor blockers are not traversed while an on-corridor blocker still blocks the profile.

## Performance Notes

- Initial hosted timing showed the expensive path was visibility-aware sampling, not source-ID resolution, evidence serialization, or summary reduction.
- After request-local prepared face entries and XY bounds prefiltering, the same scaling fixtures showed a real improvement:
  - Small terrain, `visibleOnly: true`: 9 samples improved from about 3.61s to 1.60s; 20 samples from 3.71s to 1.52s; 50 samples from 7.35s to 2.18s; 100 samples from 13.03s to 3.47s.
  - Small terrain, `visibleOnly: false`: 50 samples stayed about 0.66s to 0.62s; 100 samples about 0.69s to 0.60s.
  - 20 samples, `visibleOnly: true`: small 64-face terrain improved from about 3.71s to 1.52s; medium 1024-face terrain from 3.36s to 1.87s; large 6400-face terrain from 3.30s to 1.48s.
  - Large 6400-face terrain, 100 samples: `visibleOnly: true` improved from about 14.11s to 3.52s; `visibleOnly: false` from 6.11s to 1.78s.
- Hosted edge smoke for the XY envelope filter passed with blockers inside the corridor, overlapping the corridor end, just before or touching the start boundary, hidden inside blockers, and combined target terrain+blocker cases.
- The edge smoke found no observed false negatives for visible blockers that overlap or touch the profile corridor, no hidden-blocker leakage under `visibleOnly: true`, no loss of combined-target ambiguity, and no false ambiguity for paths outside blocker bounds.
- Performance work is closed for SVR-04. The remaining visible-only fixed overhead is acknowledged but no further optimization is planned in this task.
