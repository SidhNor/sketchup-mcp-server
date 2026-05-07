# Summary: MTA-22 Capture Adaptive Simplification Benchmark Fixtures And Replay Framework

**Task ID**: `MTA-22`
**Status**: `implemented`
**Updated**: `2026-05-06`

## Shipped Behavior

- Added the canonical adaptive terrain fixture/result document at
  `test/terrain/fixtures/adaptive_terrain_regression_cases.json`.
- Captured 9 recipe-first fixture cases and 9 matching MTA-21 `baselineResults` rows.
- Added 4 structured `coverageLimitations` rows for currently uncaptured edit-family evidence.
- Kept fixture cases free of result evidence keys: `expectations`, `residuals`,
  `expectedResiduals`, and `capturedBaseline`.
- Added compact baseline result rows with version, backend, evidence mode, face counts/ranges,
  dense-equivalent counts, dense ratios, profile/topology/seam/diagnostic probes, known residuals,
  provenance, limitations, and timing.
- Preserved the adopted off-grid corridor endpoint mismatch as a structured known residual in the
  baseline result row.
- Added a test-owned loader/replay seam in `test/support/adaptive_terrain_regression_fixtures.rb`
  for validation, result lookup, coverage summaries, and deterministic local replay of replayable
  created corridor cases.
- Added fixture tests covering root schema, exact case/result coverage, backend/evidence enums,
  dense metrics, provenance, known residuals, forbidden source-truth keys, edit-family coverage or
  limitations, recipe-first cases, local replay, and production runtime dependency isolation.
- Updated `test/terrain/fixtures/README.md` to document the `cases`, `baselineResults`, and
  `coverageLimitations` roles and MTA-23 result-set reuse expectation.

## Validation Evidence

- `bundle exec ruby -Itest test/terrain/adaptive_terrain_regression_fixture_test.rb`
  - `27 runs, 1768 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`
  - `7 runs, 389 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
  - `315 runs, 5104 assertions, 0 failures, 0 errors, 3 skips`
- `bundle exec rubocop --cache false test/support test/terrain/adaptive_terrain_regression_fixture_test.rb`
  - `9 files inspected, no offenses detected`
- JSON shape check:
  - `9` cases, `9` baseline result rows, `4` coverage limitation rows, and no case-level result
    evidence keys.

## Codereview Disposition

- Required Step 10 PAL codereview with `model: "grok-4.3"` completed.
- First Grok pass found low-severity legacy cleanup issues:
  - removed case-level `expectations`/`residuals` validation paths;
  - refactored test helper cases so result evidence is built only as `baselineResults`;
  - removed dormant `capturedBaseline` comparison and test hooks.
- Follow-up Grok pass found low-severity validation consistency items:
  - updated `coverageLimitations` field validation to use the loader's `require_field` path;
  - added forbidden source-truth scanning for `coverageLimitations`.
- The remaining dense-equivalent-count duplication in the test helper is intentionally retained as a
  small independent test-data oracle rather than coupling the test builder to the loader method it
  validates.

## Public Contract And Docs

- No public MCP tool names, request fields, response fields, dispatcher routes, native catalog
  schemas, setup paths, persisted terrain state, or user workflows changed.
- README tool usage documentation was not changed because MTA-22 is test fixture infrastructure.
- The fixture README was updated because it is the user-facing documentation for this fixture pack.

## Hosted Verification Status

- Live SketchUp-hosted verification ran on 2026-05-06 after final codereview follow-up.
- The check created one top-level parent group named `MTA-22 fixture eval 20260506-094548`.
- The parent group was placed to the side of existing geometry; measured world bounds were
  `min=(64.4, -15.0, -13.538008)` meters and `max=(423.4, 324.0, 12.0)` meters.
- Original model preservation check: `32` original top-level entities were present before the
  operation and all `32` were still present after generation.
- The parent group contains 9 child fixture groups and stores compact verification JSON under
  `su_mcp_verification/results_json`.
- All 9 hosted generation checks used the production `TerrainMeshGenerator` adaptive output path
  and produced `adaptive_tin` output with derived face markers.
- All 9 cases reported `0` down faces and `0` non-manifold edges.
- Created replayable corridor cases:
  - flat: `462` generated faces, `242` generated vertices, `0.0` start/end profile deltas;
  - crossfall: `462` generated faces, `242` generated vertices, `0.0` start/end profile deltas;
  - steep: `462` generated faces, `242` generated vertices, `0.0` start/end profile deltas;
  - non-square: `522` generated faces, `272` generated vertices, `0.0` start/end profile deltas.
- Provenance-only shape smoke cases:
  - adopted irregular before corridor: `12020` generated faces;
  - adopted irregular grid-aligned corridor: `12072` generated faces, `0.0` start/end profile
    deltas;
  - adopted irregular off-grid corridor: `12048` generated faces with profile deltas
    `0.5381091385643806` and `0.46146567111959613`, preserving the hosted-sensitive residual
    character captured in the fixture row;
  - aggressive stacked terrain: `2466` generated faces with `0.0` and near-zero corridor profile
    deltas;
  - high-relief seam stress: `6230` generated faces with `0.0` start/end profile deltas.
- The hosted pass is sidecar verification that the fixture recipes can generate representative
  SketchUp geometry safely. It does not replace the MTA-21 baseline rows or convert
  provenance-backed rows into local proof.

## Remaining Gaps

- The fixture pack captures MTA-21 baseline evidence only; MTA-23 still owns candidate result
  generation and candidate-vs-baseline comparison.
- Some edit families remain represented by explicit coverage limitations rather than captured
  hosted baseline rows.
