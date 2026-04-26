# Summary: MTA-06 Implement Local Terrain Fairing Kernel

**Task ID**: `MTA-06`
**Title**: `Implement Local Terrain Fairing Kernel`
**Status**: `implemented`
**Completed**: `2026-04-26`

## Shipped Behavior

- Added `operation.mode: "local_fairing"` to the existing public `edit_terrain_surface` command.
- Kept fairing rectangle-only for this slice and preserved the existing provider-compatible schema shape with `operation.required == ["mode"]`.
- Added mode-specific runtime validation:
  - `operation.strength`: required finite number, `> 0`, `<= 1`
  - `operation.neighborhoodRadiusSamples`: required integer, `1..31`
  - `operation.iterations`: optional integer, `1..8`, default `1`
- Implemented `SU_MCP::Terrain::LocalFairingEdit` as a SketchUp-free kernel over materialized `HeightmapState` elevations.
- Fairing uses deterministic cropped-square neighborhood averaging with prior-pass snapshots, strength interpolation, rectangle/blend weights, preserve-zone hard masking, fixed-control conflict checks, no-data refusal, no-affected-sample refusal, and no-material-change `fairing_no_effect` refusal.
- Added `evidence.fairing` with:
  - `metric: "mean_absolute_neighborhood_residual"`
  - before/after residuals
  - `improved`
  - request controls
  - `actualIterations`
  - `changedSampleCount`
  - warnings
- Reused the existing command save/regenerate flow and dirty-window handoff through `TerrainOutputPlan`.
- Updated native loader schema, runtime fixtures, no-leak contract coverage, and README examples/matrix.

## Validation Evidence

- `bundle exec ruby -Itest test/terrain/edit_terrain_surface_request_test.rb`
  - Passed during implementation after request validation changes.
- `bundle exec ruby -Itest test/terrain/local_fairing_edit_test.rb`
  - Passed after final code review follow-up: 11 runs, 57 assertions, 0 failures, 0 errors.
- Focused terrain/evidence/contract suite:
  - `bundle exec ruby -Itest -e 'load "test/terrain/edit_terrain_surface_request_test.rb"; load "test/terrain/local_fairing_edit_test.rb"; load "test/terrain/terrain_surface_commands_test.rb"; load "test/terrain/terrain_edit_evidence_builder_test.rb"; load "test/terrain/terrain_contract_stability_test.rb"'`
  - Passed before final code review follow-up: 50 runs, 399 assertions, 0 failures, 0 errors.
- `bundle exec rake ruby:test`
  - Passed after final code review follow-up: 738 runs, 3569 assertions, 0 failures, 0 errors, 36 skips.
- `bundle exec rake ruby:lint`
  - Passed after final code review follow-up: 191 files inspected, no offenses.
- `bundle exec rake package:verify`
  - Passed after final code review follow-up and built `dist/su_mcp-0.23.0.rbz`.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb`
  - Local native transport contract execution was subsequently verified successfully.

## Code Review

- Final Step 10 PAL code review used `model: "grok-4.20"`.
- Review found no critical, high, or medium issues.
- Low follow-ups addressed:
  - `actualIterations` now counts the pass that converged instead of undercounting a final converged pass.
  - The non-improving-residual test subclass now documents that it forces the acceptance path where changed terrain succeeds with a warning.
- Focused kernel tests, lint, full Ruby tests, and package verification were rerun after the follow-up changes.

## Hosted Verification

- Live MCP smoke verification was completed by the user after the local Step 10 implementation/code-review pass.
- Setup used public MCP create/edit paths for most cases:
  - `lf-main`: 11x11 managed terrain, seeded with a center spike using `target_height`
  - `lf-flat`: 11x11 flat managed terrain
  - `lf-nodata`: 6x6 managed terrain with one nil/no-data sample injected for refusal testing
  - `lf-large-noisy`: 31x31 deterministic varied terrain with slope, waves, and local noise
  - `lf-large-preserve`: same 31x31 varied terrain with preserve-zone test
- Smoke matrix result:
  - `LF-01` happy path fairing improves noisy patch: PASS
  - `LF-02` default iterations: PASS
  - `LF-03` preserve zone unchanged: PASS
  - `LF-04` fixed control conflict: PASS
  - `LF-05` flat/no-effect terrain: PASS
  - `LF-06` region outside terrain: PASS
  - `LF-07` no-data terrain: PASS
  - `LF-08` invalid strength: PASS
  - `LF-09` missing strength: PASS
  - `LF-10` invalid radius: PASS
  - `LF-11` invalid iterations: PASS
  - `LF-12` incompatible region type: PASS
  - `LF-13` unsupported mode discoverability: PASS
  - `LF-14` public evidence no-leak: PASS by response inspection
  - `LF-15` undo coherence: PASS
- Key hosted evidence:
  - 11x11 noisy patch revised `2 -> 3`; residual improved `0.1567 -> 0.0589`; `improved: true`; changed region columns `2..8`, rows `2..8`; output digest matched updated state digest.
  - Default iterations omitted `operation.iterations`; response returned `iterations: 1`, `actualIterations: 1`; residual improved `0.0589 -> 0.0410`.
  - Preserve zone protected one center sample; protected sample stayed `1.37`; neighboring samples changed from about `0.10` to `0.11`; changed samples did not include the protected sample.
  - Fixed-control conflict refused with `fixed_control_conflict`, `controlId: lf-fixed-tight`, `effectiveTolerance: 1e-6`, `predictedDelta: 0.0218`.
  - Refusals matched expected codes and fields for flat terrain, outside rectangle, no-data sample `{ column: 2, row: 2 }`, invalid/missing strength, invalid radius, invalid iterations, local_fairing with corridor, and unsupported mode `smooth`.
- Larger terrain addendum:
  - 31x31 varied terrain had 961 vertices and 1800 faces, height range about `-0.66m` to `3.07m`.
  - Fairing rectangle `7..23 x 7..23`, blend distance `2m`, radius `3`, strength `0.35`, iterations `3`.
  - Changed 361 samples; residual improved `0.2464 -> 0.1283`; revision `2 -> 3`; output digest matched updated state digest; faces `1800`, down faces `0`, flat faces `0`.
  - Preserve-zone variant used preserve zone `14..16 x 14..16`; protected 9 samples; changed 352 samples; residual improved `0.2386 -> 0.1378`; protected center sample stayed `2.33`; nearby samples changed; faces `1800`, down faces `0`, flat faces `0`.

## Follow-up Status

- `LF-15` undo coherence was subsequently verified.
- Local native transport contract execution was subsequently verified successfully.
- Step 11 task-estimation calibration was completed in `size.md`.
