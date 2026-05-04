# Summary: MTA-21 Make Adaptive Terrain Output Conforming

**Task ID**: `MTA-21`
**Status**: `implemented`
**Completed**: `2026-05-04`

## Shipped Behavior

- Repaired adaptive terrain output planning by deriving side-specific boundary vertices for
  adaptive cells that share mixed-resolution edges.
- Kept the existing adaptive-cell planner and public `derivedMesh` response shape while computing
  final conforming vertex and face counts from a single internal emission-triangle plan.
- Updated adaptive mesh generation to emit planned boundary triangles, removing unsplit axis edges
  where another emitted terrain vertex lies on the edge interior.
- Preserved source heightmap authority: boundary vertices, center-fan vertices, generated
  triangles, and adaptive-cell internals remain runtime-derived output facts and are not persisted
  or exposed in public MCP responses.
- Marked generated terrain edges as derived output and hidden SketchUp geometry when the host edge
  supports `hidden=`.
- Hardened adaptive regeneration so nil elevation state refuses before erasing derived output, even
  though the public regeneration path already performs that precondition check.
- After hosted validation showed representative edits were blocked before output generation, updated
  feature pre-save planning so affected-window pointification projections remain diagnostic-only
  unless a feature carries an explicit expansion `sampleEstimate`.
- After redeployed hosted validation showed representative corridors and adopted irregular terrain
  were still nearly dense, replaced global adaptive boundary-line split grids with side-specific
  boundary vertices and center-fan triangulation for only the cells that need extra boundary
  vertices.
- Coherence cleanup moved emission-triangle ownership into `AdaptiveOutputConformity` so plan
  counts and generator emission use the same derived triangle list.
- Final coherence cleanup removed stale `split_columns` / `split_rows` production cell keys, added
  explicit test coverage for ordered simple boundary cycles, and left only the runtime topology facts
  consumed by output counting and mesh emission.

## Validation Evidence

- `bundle exec ruby -Itest test/terrain/terrain_output_plan_test.rb`
  - `10 runs, 218 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/terrain_mesh_generator_test.rb`
  - `35 runs, 1031 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`
  - `7 runs, 389 assertions, 0 failures, 0 errors, 0 skips`
- Final broader validation:
  - `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
  - `288 runs, 3336 assertions, 0 failures, 0 errors, 3 skips`
  - `bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |path| load path }'`
  - `888 runs, 5686 assertions, 0 failures, 0 errors, 37 skips`
  - `bundle exec rubocop --cache false Gemfile Rakefile rakelib test src/su_mcp`
  - `224 files inspected, no offenses detected`
- Post-review focused checks:
  - focused output plan, mesh generator, and contract stability tests all passed with the run counts
    listed above.
  - focused RuboCop: `5 files inspected, no offenses detected`
- Feature-cap mask follow-up checks:
  - `bundle exec ruby -Itest test/terrain/terrain_feature_planner_test.rb`
    - `9 runs, 58 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_surface_commands_test.rb`
    - `28 runs, 169 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`
    - `7 runs, 349 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
    - `287 runs, 3187 assertions, 0 failures, 0 errors, 3 skips`
  - scoped RuboCop on terrain runtime/tests:
    - `71 files inspected, no offenses detected`
  - `bundle exec rake package:verify`
    - produced `dist/su_mcp-1.1.2.rbz`
- Boundary-fan compactness follow-up checks:
  - `bundle exec ruby -Itest test/terrain/terrain_output_plan_test.rb`
    - `10 runs, 218 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_mesh_generator_test.rb`
    - `35 runs, 1031 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/terrain_contract_stability_test.rb`
    - `7 runs, 389 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
  - `288 runs, 3336 assertions, 0 failures, 0 errors, 3 skips`
  - `bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |path| load path }'`
  - `888 runs, 5686 assertions, 0 failures, 0 errors, 37 skips`
  - scoped RuboCop on terrain runtime/tests:
    - `72 files inspected, no offenses detected`
  - full RuboCop:
    - `224 files inspected, no offenses detected`
  - `bundle exec rake package:verify`
    - produced `dist/su_mcp-1.1.2.rbz`
- Final `git diff --check`
  - passed
- Final `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.1.2.rbz`

## Codereview Disposition

- Required PAL codereview with `model: "grok-4.3"` completed for the initial skeleton sequence.
  Follow-up added compactness-ratio coverage, regeneration cleanup coverage, public no-leak terms,
  real fake-edge hidden-state support, and a hosted validation checklist.
- Grok 4.3 reviewed the revised strategy after hosted validation showed global adaptive boundary-line
  splitting was conforming but too dense. The plan and implementation moved to side-specific
  boundary vertices and center-fan emission.
- Final Grok 4.3 coherence review confirmed the architecture is coherent for MTA-21 and suggested
  hardening the boundary ordering assumption, documenting `:max_error`, and removing a redundant
  private no-data guard. Those follow-ups were applied.
- A final narrow Grok 4.3 pass after those changes found no medium-or-higher blocker in the final
  MTA-21 state.
- Post-review focused tests and RuboCop passed after the follow-up changes.

## Public Contract And Docs

- No public MCP tool names, request fields, response fields, loader schema entries, dispatcher
  routes, setup paths, or user-facing workflows changed.
- Public response changes are limited to natural `derivedMesh.vertexCount` and
  `derivedMesh.faceCount` deltas from conforming derived output.
- Contract stability tests now explicitly reject split-grid, adaptive-boundary, raw-vertex,
  raw-triangle, densification, and stitch vocabulary in public output.
- User-facing docs were reviewed for contract impact; no README/tool documentation update was
  required because the repair is internal derived-output topology.

## Hosted Verification Status

- Live SketchUp-hosted verification was run through multiple fix/deploy loops on 2026-05-04. The
  initial representative matrix was blocked; the final matrix is accepted for seam conformance.
- Fresh created 41x41 and 71x31 terrains still create successfully and initially simplify to
  `4` vertices / `2` faces.
- Representative whole-terrain planar fits, large/medium created corridors, large rectangle/circle
  target-height edits, and representative adopted-terrain corridors refused before output
  generation with `terrain_feature_pointification_limit_exceeded`.
- Follow-up code prevents affected-window-only projections from causing that refusal. Redeployed
  hosted validation confirmed representative large edits now run.
- The same hosted pass showed global boundary-line splitting was too conservative: flat/crossfall/
  steep 41x41 corridors emitted `3042-3200 / 3200` faces, adopted irregular terrain emitted
  `19404 / 19602` before edit, and the aggressive simple stack emitted `4640 / 4800`.
- Boundary-fan follow-up code now avoids propagating boundary splits through full cell interiors;
  redeployed hosted validation showed materially better face counts and no reproduced T-rip/folded
  seam artifacts in the representative cases.
- Small created and adopted corridor sanity checks succeeded, sampled requested public profiles
  correctly, and showed no down-facing faces or non-manifold edges.
- Successful aggressive stacked edits still showed severe sharp-normal discontinuity diagnostics,
  including `149` sharp breaks with worst `94.12 deg` on the final stacked simple fixture.
- Sophisticated adopted terrains completed adoption in about `3-4s`, but simplified output was
  effectively dense: `19404` faces vs dense equivalent `19602`, worse than the earlier reverted
  pass's roughly `8248`-face result on similar terrain.
- Representative adopted corridors now run, but off-grid adopted corridor endpoint correctness is
  still wrong: requested end `1.85`, sampled end `1.43`, endpoint delta `0.4165`.
- Final hosted representative corridors emitted `1378-1750` faces versus dense equivalents of
  `3200-4200`, adopted irregular terrain improved to `11044 / 19602` before corridor and
  `6824-7765 / 19602` after corridors, aggressive stacked output was `3578 / 4800`, and high-relief
  seam-stress output was `6667 / 9600`.
- Final hosted pass found no down-facing faces, no non-manifold edges, seam check passed where
  recorded, and no obvious T-type rips or folded seam artifacts were observed.
- Full details are recorded in [hosted-validation-checklist.md](./hosted-validation-checklist.md).

## Remaining Gaps

- Face counts are materially higher than the pre-conformance simplifier in some representative
  cases. The final hosted pass is acceptable for seam correctness, but not an ideal simplification
  quality endpoint.
- Off-grid adopted corridor endpoint correctness remains a separate failure from mesh conformance.
- Real SketchUp hidden-edge behavior remains unverified as a dedicated acceptance check.
- Full active-model save/reopen persistence was not checked.
- The implementation intentionally remains a repair of the current adaptive-cell output path, not a
  new RTIN, Delaunay, DELATIN, or feature-aware meshing backend.
- Further face-count reduction should be handled as a separate simplifier-quality task with captured
  hosted heightfields, not by continuing to tune the MTA-21 conformance repair.
