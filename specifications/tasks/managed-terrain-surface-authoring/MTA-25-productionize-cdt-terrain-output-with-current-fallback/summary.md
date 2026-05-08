# Summary: MTA-25 Productionize CDT Terrain Output With Current Backend Fallback

**Task ID**: `MTA-25`
**Status**: `closed-disabled-by-default-enablement-deferred`
**Updated**: `2026-05-08`

## Closeout Position

MTA-25 is closed as a controlled production-scaffolding task, not as active CDT
production enablement.

The current terrain output path remains the production default. CDT is wired only behind an internal
disabled-by-default backend path because live validation found unacceptable edit latency on
representative terrain, including a single target-height edit on a terrain with hundreds of
historical feature intents hanging for minutes.

## Shipped Behavior

- Added production-owned CDT scaffolding under `src/su_mcp/terrain/output/`:
  - `ResidualCdtEngine`
  - `TerrainProductionCdtResult`
  - `TerrainCdtPrimitiveRequest`
  - `TerrainTriangulationAdapter`
  - `TerrainProductionCdtBackend`
- Refactored `CdtTerrainCandidateBackend` into a validation wrapper over the production residual
  engine while preserving MTA-24 candidate-row output for comparison tests.
- Wired `TerrainMeshGenerator` so an explicitly injected/enabled CDT backend can compute and emit
  CDT output before falling back to the current backend.
- Set default runtime behavior to keep CDT disabled:
  - `TerrainMeshGenerator` uses no default CDT backend while `DEFAULT_CDT_ENABLED` is `false`.
  - `TerrainSurfaceCommands` only builds CDT feature geometry and passes CDT feature context when
    the injected mesh generator reports CDT enabled.
  - Existing regular/adaptive terrain output remains active for normal create/edit flows.
  - Tests can still inject an accepted/fallback CDT backend to exercise mutation, fallback, and
    no-leak paths.
- Added an internal `strict_quality_gates` switch on `TerrainProductionCdtBackend` so residual,
  runtime, and firm-feature residual failures can be restored as fallback gates in guarded builds
  without rewriting call sites.
- Preserved public MCP request/response contracts. Internal CDT fallback reasons and solver details
  remain below the public terrain response boundary.

## Validation

- `bundle exec ruby -Itest test/terrain/features/terrain_feature_planner_test.rb`
  - `10 runs, 67 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/commands/terrain_surface_commands_test.rb`
  - `30 runs, 175 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/contracts/terrain_contract_stability_test.rb`
  - `12 runs, 3055 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/release_support/runtime_package_tasks_test.rb`
  - `5 runs, 27 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/cdt_terrain_point_planner_test.rb`
  - `5 runs, 40 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/residual_cdt_engine_test.rb`
  - `6 runs, 38 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/cdt_terrain_candidate_backend_test.rb`
  - `16 runs, 132 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/terrain_production_cdt_backend_test.rb`
  - `15 runs, 105 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/terrain_production_cdt_result_test.rb`
  - `4 runs, 67 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/terrain_cdt_primitive_request_test.rb`
  - `3 runs, 15 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/terrain_triangulation_adapter_test.rb`
  - `3 runs, 13 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/terrain_mesh_generator_test.rb`
  - `44 runs, 1068 assertions, 0 failures, 0 errors, 0 skips`
- `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop ...`
  - Targeted changed command, feature, CDT/output, package, contract, and test files inspected, no
    offenses.
- `mcp__pal__codereview` with `model: "grok-4.3"`
  - Found one low-severity dead-assignment cleanup in `TerrainMeshGenerator#regenerate`.
  - Cleanup was applied and revalidated with `terrain_mesh_generator_test.rb` plus targeted
    RuboCop.

Full test suite, full lint, package verification, and hosted closeout were not rerun after the
disabled-default cleanup.

## Live Findings

- Ruby CDT can generate terrain output, including accepted meshes on small and medium fixtures.
- Representative edited terrain exposed unacceptable runtime:
  - a terrain with hundreds of accumulated feature intents can hang for minutes on a single small
    target-height edit.
  - feature-intent accumulation, override/deprecation semantics, merge behavior, and effective
    feature-geometry selection were not pressure tested enough for production enablement.
- Earlier live probing also showed CDT input can be sensitive to corridor/reference feature geometry
  near terrain boundaries. That issue is recorded as follow-up scope, not patched into this closeout.

## Rework And Iteration Notes

This task had material implementation drift after the first local implementation pass. Calibration
should count this as significant rework rather than a straight execution of the original plan.

- The first implementation drifted toward a one-shot production CDT wrapper. We repivoted after
  rereading MTA-24 and clarified that MTA-25 needed the residual-driven stack:
  `CdtTerrainPointPlanner`, `CdtHeightErrorMeter`, `CdtTriangulator`, and the residual refinement
  loop.
- `CdtTerrainCandidateBackend` was reduced into a validation wrapper over a new production
  `ResidualCdtEngine`. This preserved candidate-row tests as an oracle but changed ownership and
  required row-shape compatibility tests.
- Live SketchUp probing showed CDT was attempted but fell back on intersecting/protected-crossing
  diagnostics. We changed Ruby CDT semantics so intersecting constraints and conservative crossing
  diagnostics are limitations/metrics, not automatic fallback reasons.
- We temporarily explored residual/runtime gate relaxations during live validation. That churn ended
  in an internal `strict_quality_gates` switch:
  - default behavior treats residual/runtime/firm residual as diagnostics;
  - strict mode can restore those fallback reasons for guarded builds/tests.
- We overcorrected a boundary-shape issue by adding full source-perimeter seeding/constraints. That
  increased seed counts and was removed during cleanup. The planner is back to four domain corner
  seeds.
- We also prototyped CDT input clipping to stop corridor/reference geometry from expanding the
  terrain hull. The live experiment confirmed the issue, but the clipping patch was removed from
  this closeout because CDT is disabled by default and geometry containment needs a properly planned
  enablement task.
- Multiple live monkey patches were used in SketchUp to inspect backend status, residual metrics,
  constraint coverage, runtime status, and scene geometry bounds. Those probes informed the
  disabled-default decision but are not part of the repository change.
- The final cleanup deliberately preserves current terrain output by default and leaves CDT as
  scaffold only. This is a narrower outcome than the original “productionize active CDT” goal.
- After closeout review, CDT feature-geometry preparation was also gated behind the same internal
  CDT-enabled check so disabled-default create/edit flows do not pay CDT preparation cost.

## Deferred Enablement Work

CDT must remain disabled by default until
[MTA-31 Enable CDT Terrain Output After Disabled Scaffold](../MTA-31-enable-cdt-terrain-output-after-disabled-scaffold/task.md)
plans and validates:

- effective feature-intent compaction for terrains with hundreds of historical edits;
- override/deprecation/merge semantics for feature geometry consumed by CDT;
- bounded CDT input selection for a single edit against a large feature history;
- profiling split across feature geometry build, point planning, residual metering, triangulation,
  and SketchUp mutation;
- explicit performance budgets on representative fixtures;
- safe timeout/fallback behavior that cannot block editing for minutes;
- geometry containment around terrain boundaries and corridor side/cap references;
- hosted SketchUp validation after the above work is complete.

## Public Contract And Docs

- No public MCP tool name, request schema, dispatcher behavior, or user-facing response contract was
  changed.
- No public backend selector or CDT user control was added.
- README and public examples were not updated because default user-visible behavior remains the
  current terrain output path.
- Public no-leak contract tests cover accepted CDT and every internal fallback reason.

## Remaining Risk

The repository now contains a disabled CDT production scaffold. It should not be enabled by default
or treated as productized terrain output until the deferred enablement work is planned and
validated.
