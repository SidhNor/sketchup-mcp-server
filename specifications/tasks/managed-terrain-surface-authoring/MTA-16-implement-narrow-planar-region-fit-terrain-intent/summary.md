# Summary: MTA-16 Implement Narrow Planar Region Fit Terrain Intent

**Task ID**: `MTA-16`  
**Status**: `implemented`  
**Completed**: `2026-04-29`

## Shipped Behavior

- Added explicit `edit_terrain_surface` operation mode `planar_region_fit`.
- Added request validation and native schema exposure for `constraints.planarControls`.
- Implemented a SketchUp-free `PlanarRegionFitEdit` terrain editor for `heightmap_grid` v1:
  - fits one least-squares plane `z = ax + by + c`
  - supports rectangle and circle support regions
  - applies full-weight planar replacement and blend-shoulder interpolation
  - excludes preserve-zone samples from mutation
  - refuses grid/representation cases where accepted controls would not be sampled back from
    the edited discrete heightmap within tolerance
  - checks fixed controls before save/output mutation
  - returns structured residual, plane, changed-region, preserve-zone, fixed-control, sample, grid-warning, and max-delta evidence
- Added refusals for non-coplanar controls, same-XY contradictory controls,
  degenerate/collinear controls, controls outside terrain bounds/support, controls inside
  preserve zones, no-data terrain, no mutable samples, fixed-control conflicts, and
  off-grid boundary controls that the discrete edited heightmap cannot satisfy.
- Added close-control grid warnings for controls closer than the max grid spacing.
- Routed `planar_region_fit` through `TerrainSurfaceCommands` and exposed `evidence.planarFit` through the edit evidence builder.
- Updated native schema tests, public contract posture tests, native runtime fixture cases, and `docs/mcp-tool-reference.md`.
- Preserved `survey_point_constraint` as a separate smooth correction-field behavior and kept its `evidence.survey` namespace unchanged.

## Validation Evidence

- Focused skeleton suite:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/terrain/edit_terrain_surface_request_test.rb test/terrain/planar_region_fit_edit_test.rb test/terrain/terrain_edit_evidence_builder_test.rb test/terrain/terrain_surface_commands_test.rb test/runtime/native/mcp_runtime_loader_test.rb test/runtime/public_mcp_contract_posture_test.rb test/runtime/native/mcp_runtime_native_contract_test.rb`
  - Passed after off-grid follow-up: 154 runs, 948 assertions, 0 failures, 0 errors, 32 skips.
- Broader terrain/runtime suite:
  - `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }; Dir["test/runtime/**/*_test.rb"].sort.each { |path| load path }'`
  - Passed after off-grid follow-up: 383 runs, 2593 assertions, 0 failures, 0 errors, 35 skips.
- Full Ruby test suite:
  - `bundle exec rake ruby:test`
  - Passed after off-grid follow-up: 826 runs, 4253 assertions, 0 failures, 0 errors, 37 skips.
- Ruby lint:
  - `bundle exec rake ruby:lint`
  - Passed: 206 files inspected, no offenses detected.
- Package verification:
  - `bundle exec rake package:verify`
  - Passed and produced `dist/su_mcp-1.0.0.rbz`.
- Diff whitespace:
  - `git diff --check`
  - Passed.

## Code Review Disposition

- Required PAL code review workflow was invoked with `model: "grok-4.20"`.
- Local PAL review step completed and led to one follow-up fix: the top-level native `edit_terrain_surface` tool description now explicitly mentions `planar_region_fit`.
- The final external expert validation call failed with a provider 429 credits/spend-limit error:
  - `Your team ... has either used all available credits or reached its monthly spending limit.`
- Because the external expert model call could not complete, final expert code-review validation remains a closeout gap.

## Hosted Verification

- Live SketchUp validation was run from a separate agent terminal through public MCP wrapper calls.
- Passed live checks:
  - wrapper schema refresh, `planar_region_fit` exposure, and `constraints.planarControls` exposure
  - rectangle and circle positive planar fits
  - smooth blend behavior
  - near-coplanar controls within tolerance
  - preserve-zone protection
  - compatible and conflicting fixed controls
  - non-zero origin and transformed-owner coordinate evidence
  - non-uniform/fractional spacing
  - sample evidence caps
  - `survey_point_constraint` regression with `evidence.survey` and no `evidence.planarFit`
  - refusal paths for missing controls, contradictory controls, degenerate controls,
    non-coplanar controls, outside-bounds controls, outside-support controls, no affected
    samples, and no-data terrain
  - close-control warnings, default tolerance floor/cap, undo, mesh sanity, no public leak
    strings, and 100x100 terrain performance around 2.07 seconds
  - 40m x 70m crossfall correction cases, including 3-point, 6-point, alternate fall
    direction, interior rectangle, smooth blend, preserve strip, and fixed-control conflict
  - varying-grid aligned cases and mesh sanity across inspected terrain outputs
  - additional pre-fix crossfall coverage:
    - full-rectangle 3-point, 4-corner, 5-point with center, 6-point with north/south
      midpoints, and alternate opposite crossfall all passed
    - interior rectangle, smooth blend, preserve strip, and fixed-control conflict all passed
  - additional pre-fix coplanarity coverage:
    - whole-terrain and interior stretched-plane cases passed for 3 controls, small center
      residuals, and small edge residuals
    - whole-terrain and interior large center/edge outliers refused with
      `non_coplanar_controls` before mutation
  - additional pre-fix region-shape coverage:
    - circular crossfall, steeper circular crossfall, and circular smooth blend passed
    - capsule-style rounded rectangle composed from left circle, rectangle, and right circle
      passed with a continuous plane across the composed footprint
    - visual guide bounds confirmed rectangle and circle/capsule footprints
- Live validation found one material issue:
  - off-grid boundary controls on hard edit boundaries were reported as satisfied against the
    mathematical plane, but exact public surface sampling could disagree because unchanged
    neighboring grid samples influenced interpolation.
  - reproduced before the fix in VG-02 and OG-01 through OG-04 across coarse, medium, dense,
    and non-uniform grids.
- Follow-up fix:
  - added a `planar_fit_unsafe` refusal when the edited discrete heightmap surface cannot
    sample accepted planar controls back within tolerance.
  - documented the off-grid boundary limitation and remediation options in
    `docs/mcp-tool-reference.md`.
- Post-fix live validation:
  - off-grid boundary cases were rerun and validated after the `planar_fit_unsafe` follow-up.
  - the hosted matrix is now considered complete.

## Contract Alignment

- Runtime validation, native schema, dispatcher, evidence shaping, native fixture cases, tests, and docs now describe `planar_region_fit`.
- Finite option discoverability exists before a bad call through schema/tool descriptions and docs.
- Finite option discoverability exists after a bad call through structured refusals with fields and allowed values for operation/region/preserve-zone option errors.
- `README.md` does not mirror the terrain operation matrix, so no README update was required.
- The prompt catalog already mentions `planar_region_fit`; it was left unchanged.

## Remaining Gaps

- External PAL expert code review did not complete because of provider quota.
- Hosted SketchUp validation passed after one validation-driven fix loop for off-grid boundary
  control representation.
- Native transport fixture cases are checked in, but the staged native runtime contract test skips locally when staged vendor runtime is unavailable.
