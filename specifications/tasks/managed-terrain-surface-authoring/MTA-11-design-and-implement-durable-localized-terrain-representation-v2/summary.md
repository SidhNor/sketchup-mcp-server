# Summary: MTA-11 Migrate To Tiled Heightmap V2 With Adaptive Output

**Task ID**: `MTA-11`
**Status**: `implemented`
**Completed**: `2026-05-01`

## Shipped Behavior

- Added `TiledHeightmapState` as schema v2 terrain source state with deterministic tile payloads, v2 summaries, `with_elevations`, tile summaries, and dirty-tile lookup helpers.
- Updated `TerrainStateSerializer` so persisted terrain state serializes as `heightmap_grid` v2 and supported v1 `heightmap_grid` payloads migrate one way into v2 after original digest validation.
- Updated create/adopt state building so the public `heightmap_grid` request shape remains stable while runtime state is created as tiled heightmap v2, including optional public row-major `definition.grid.elevations`.
- Added `RasterEditWindow` with bounded sample-window reads/writes, `MAX_SAMPLES` refusal, dirty sample bounds, dirty tile IDs, and commit back to v2 state.
- Updated terrain edit kernels to preserve the incoming state class through `with_elevations`, keeping kernel math tile-agnostic while allowing v2 state to remain authoritative after edits.
- Added first-slice adaptive output planning and generation for v2 state using deterministic corner-fit error subdivision and full adaptive regeneration.
- Kept regular-grid output planning and partial regeneration behavior for legacy `HeightmapState` test coverage while avoiding grid-cell ownership metadata on v2 adaptive output.
- Updated native contract fixtures and user-facing docs so response summaries expose `heightmap_grid` and `adaptive_tin` without introducing a new public payload kind.
- Removed the introduced alternate payload/class vocabulary in favor of `heightmap_grid` payloads and internal `TiledHeightmapState` naming.

## Validation Evidence

- `bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |path| load path }'`
  - Passed: `844 runs`, `4338 assertions`, `0 failures`, `0 errors`, `37 skips`.
- `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop Gemfile Rakefile rakelib test src/su_mcp`
  - Passed: `215 files inspected`, `no offenses detected`.
- `bundle exec rake package:verify`
  - Passed and produced `dist/su_mcp-1.1.1.rbz`.
- `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rake ci`
  - Passed full local CI equivalent: version assertion, RuboCop, Ruby tests, and package verification.
- Focused post-review regression:
  - `bundle exec ruby -Itest -e 'load "test/terrain/terrain_mesh_generator_test.rb"'`
  - Passed after adding v2 adaptive no-data refusal coverage.

## Code Review

- Step 05 PAL review challenged the implementation queue and led to three explicit controls:
  - use `with_elevations` as the narrow kernel preservation seam,
  - prove create/adopt build v2 from the stable `heightmap_grid` request shape,
  - keep v2 adaptive output on full regeneration to avoid misleading regular-grid ownership metadata.
- Step 10 PAL review found one real implementation issue:
  - adaptive v2 no-data output could build an adaptive plan before structured refusal.
  - Fixed by refusing no-data v2 adaptive generation/regeneration before output planning and adding regression coverage.
- Final PAL review found no remaining blocking defects.
- Final local `$task-review` pass after live-verification updates found no blocking defects:
  - bugbot: `0` L1 findings, `16` L2 findings, all reviewed as non-blocking complexity/test-helper noise,
  - `tldr secure`: `0` findings,
  - `tldr dead src/su_mcp/terrain/tiled_heightmap_state.rb`: `0` dead functions,
  - changed terrain complexity remains concentrated in `TerrainMeshGenerator`,
    `TerrainOutputPlan`, and `CreateTerrainSurfaceRequest`, with coverage from automated tests
    and live MCP verification.

## Contract And Docs

- Public tool names and core create/edit request sections remain stable.
- Public create schema now exposes optional `definition.grid.elevations`; malformed counts or non-finite values are refused instead of ignored.
- Public response summaries now reflect:
  - `terrainState.payloadKind: "heightmap_grid"`
  - `terrainState.schemaVersion: 2`
  - `output.derivedMesh.meshType: "adaptive_tin"`
  - source spacing, simplification tolerance, max simplification error, and seam check summary.
- Updated:
  - `docs/mcp-tool-reference.md`
  - `README.md`
  - `specifications/tasks/managed-terrain-surface-authoring/README.md`
  - `test/support/native_runtime_contract_cases.json`

## Live SketchUp Verification

Live SketchUp MCP verification was completed on a reset scene after the final payload-kind and
public-elevation corrections.

Verified:

- Tool discovery exposes `create_terrain_surface.definition.grid.elevations` as
  `Array<number|null>`.
- Flat `61x41` create and minimum `2x2` create both return
  `terrainState.payloadKind: "heightmap_grid"` and adaptive `4 vertices / 2 faces` output.
- Irregular create through public row-major `grid.elevations` affects created terrain; a `5x5`
  irregular grid produced non-flat output and center sample `z = 1.6`.
- Malformed elevation counts refuse with `invalid_grid_definition` at
  `definition.grid.elevations` and leave no named output group behind.
- No-data create through `null` elevation refuses before output creation with
  `adaptive_output_generation_failed`, `category: no_data_samples`, and leaves no named output
  group behind.
- Sloped/irregular adoption replaces the unmanaged source, keeps
  `terrainState.payloadKind: "heightmap_grid"`, and produced representative adaptive output.
- Live contract scan found no alternate payload kind, `tileSize`, `tileCount`, Ruby class dumps,
  or SketchUp object dumps in observed responses/schema/docs.
- Non-coplanar planar-fit refusal evidence reports violating rows as
  `status: "violating"`.
- Target-height bump, flattening regeneration, irregular adopt plus flatten/fair/corridor, face
  normals, non-mutation on refusal, pure planar crossfall, irregular crossfall, crossfall planar
  fit, and crossfall non-coplanar refusal smoke checks passed.

Remaining manual verification:

- save/reopen loads v2 directly without duplicate migration.

## Remaining Gaps And Follow-Ups

- First adaptive output is intentionally bounded and not Delaunay, breakline-preserving, or globally optimized.
- V2 adaptive regeneration is full-output regeneration for the first slice; partial adaptive regeneration remains follow-on work.
- Cross-tile kernel behavior is covered through v2 class preservation and target-height dirty-tile tests, but broader hosted cross-tile equivalence across every edit mode remains a manual/next-slice validation target.
- Save/reopen evidence remains open.
- The public no-data create refusal is structured and non-mutating, but currently uses
  `adaptive_output_generation_failed` with `category: no_data_samples`; changing it to a more
  direct `terrain_no_data_unsupported` code should be handled as a follow-up contract change if
  desired.
