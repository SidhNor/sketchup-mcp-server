# Summary: MTA-37 Implement CDT Patch Residual Frontier Batching

**Task ID**: `MTA-37`
**Status**: `closed; failed-performance-gates; implementation-reverted; not-production-path`
**Date**: `2026-05-14`

## Final Decision

MTA-37 Slice 1 was implemented mechanically after the third implementation pass, but it still failed
the representative hosted performance gates. The attempted implementation has been reverted. MTA-37
is closed as evidence, not as production code and not as a production output path.

The third implementation pass proved the required private residual frontier mechanics were possible:
broad patch-local frontier population, retained multi-batch heap use, full-current-point XY spacing,
dirty-block incremental rescore, final full quality scan, recovery after spaced insertion stalls,
and unchanged PatchLifecycle/seam ownership. That proof did not translate into sufficient runtime
improvement, so the code was removed to avoid legitimizing this Ruby residual-loop direction.

Hosted public command evidence still shows too many patch backend calls and full patch Ruby rebuilds.
The corrected Slice 1 evidence therefore supports moving next to native/incremental backend work
and/or seam policy work rather than another Ruby scoring-only pass. The supported production/default
terrain output remains the existing adaptive path; CDT remains private and must not be
default-enabled from this task.

## Retained Behavior

- The MTA-37 residual-frontier implementation code was reverted.
- The pre-existing private CDT path remains gated exactly as a non-default path.
- Public MCP request/response contracts and default production terrain output remain unchanged.
- The production/default terrain output remains the existing adaptive path.
- Retained only an explicit default-stack regression asserting that
  `TerrainOutputStackFactory.new(env: {})` keeps CDT disabled, so production/default output cannot
  accidentally inherit the private path.
- The task artifacts retain the hosted timings, failure classification, and next-direction evidence.

## Historical Validation Before Revert

- `bundle exec ruby -Itest test/terrain/output/cdt_height_error_meter_test.rb`
  - `4 runs, 15 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/cdt_residual_candidate_frontier_test.rb`
  - `6 runs, 15 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Itest test/terrain/output/residual_cdt_engine_test.rb`
  - `20 runs, 127 assertions, 0 failures, 0 errors, 0 skips`
- Focused CDT/output and command/contract regression checks passed.
- `bundle exec rake ruby:lint`
  - `336 files inspected, no offenses detected`
- `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.7.0.rbz`
- `bundle exec rake ruby:test`
  - `1373 runs, 15273 assertions, 0 failures, 0 errors, 37 skips`

## Final Post-Revert Validation

- Focused default-path guard:
  `bundle exec ruby -Itest test/terrain/output/terrain_output_stack_factory_test.rb`
  - `4 runs, 7 assertions, 0 failures, 0 errors, 0 skips`
- Full Ruby suite:
  `bundle exec rake ruby:test`
  - `1362 runs, 15227 assertions, 0 failures, 0 errors, 37 skips`
- Full Ruby lint:
  `RUBOCOP_CACHE_ROOT=/tmp/rubocop_cache bundle exec rake ruby:lint`
  - `334 files inspected, no offenses detected`
- Package verification:
  `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.7.0.rbz`

## Review Disposition

The normal Step 10 external `grok-4.3` review was intentionally skipped by explicit user instruction
after the failed implementation was reverted. No retained production CDT implementation remains for
that review. The remaining code change is the default-stack regression guard.

## Post-Revert Installed Extension Check

After restoring the installed SketchUp extension tree, hosted Ruby verification reported:

- `TerrainOutputStackFactory.new(env: {}).mesh_generator.cdt_enabled? == false`
- installed plugin file
  `su_mcp/terrain/output/cdt/patches/residual_candidate_frontier.rb` is absent

## Historical Hosted Verification Before Final Revert

Changed CDT files were staged into the installed SketchUp extension tree and reloaded through
`mcp__su_ruby__`.

Final hosted public command-path row:

- Source: `MTA37-HOSTED-FINALSCAN-1778844248`
- Placement: `x=4250m`, `y=20m`
- Grid: `100x100`, `1m` spacing
- Output verification: corrected row emitted `9986` faces, all tagged `cdt_patch_face`.
- Public leak scan: zero rows leaked CDT patch IDs, frontier diagnostics, fallback reasons, raw
  vertices, or raw triangles.

| Row | Outcome | Wall | Backend calls | Builds | Scan | Retriangulation | Max error |
|---|---|---:|---:|---:|---:|---:|---:|
| create | created | `21.18s` | 49 | 199 | `3.53s` | `11.14s` | `0.04998m` |
| target height | edited | `6.41s` | 16 | 56 | `1.27s` | `3.04s` | `0.04964m` |
| local fairing | edited | `12.66s` | 25 | 104 | `2.11s` | `6.48s` | `0.04997m` |
| planar region fit | edited | `9.39s` | 25 | 86 | `1.99s` | `4.32s` | `0.04997m` |
| survey constraint | edited | `10.26s` | 25 | 94 | `2.07s` | `4.84s` | `0.04997m` |

Corrected-row aggregate:

- wall time: `59.89s`
- backend calls: `140`, all accepted
- engine builds: `539`
- residual scan: `10.98s`
- retriangulation: `29.82s`
- candidates inserted/scored: `12487 / 28792`
- max error: `0.04998m`

The mechanics are now proven, but the performance gate still fails: the representative public path
remains dominated by many patch-local backend calls and full Ruby retriangulation.

Follow-up hosted baseline without the frontier/runtime changes:

- The CDT runtime/test changes were manually stashed under `/tmp/mta37-frontier-stash` after
  `git stash push` returned exit 1 without producing a stash entry.
- Reverted only `src/su_mcp/terrain/output/cdt/cdt_height_error_meter.rb`,
  `src/su_mcp/terrain/output/cdt/residual_cdt_engine.rb`, and their focused tests; the new frontier
  class/test were moved out of the worktree.
- Deployed the baseline CDT files into the installed SketchUp extension tree and reloaded them.
- Source: `MTA37-HOSTED-BASELINE-ELEV-1778845439`
- Placement: `x=4520m`
- Grid: `100x100`, `1m` spacing
- Elevations: non-flat values recovered from the prior final hosted terrain state
  `MTA37-HOSTED-FINALSCAN-1778844248`; this makes the row CDT-representative but not a perfect
  replay of the original initial fixture.
- Output verification: `10250` faces, all tagged `cdt_patch_face`.

| Baseline Row | Outcome | Wall | Backend calls | Builds* | Scan | Retriangulation | Max error |
|---|---|---:|---:|---:|---:|---:|---:|
| create | created | `13.32s` | 49 | 169 | `2.27s` | `7.37s` | `0.04997m` |
| target height | edited | `16.41s` | 36 | 150 | `2.51s` | `9.52s` | `0.04999m` |
| local fairing | edited | `19.32s` | 36 | 167 | `2.66s` | `11.29s` | `0.04995m` |
| planar region fit | edited | `18.46s` | 36 | 164 | `2.75s` | `10.89s` | `0.04995m` |
| survey constraint | edited | `20.87s` | 36 | 172 | `2.95s` | `12.45s` | `0.04998m` |

Baseline aggregate:

- wall time: `88.38s`
- backend calls: `193`, all accepted
- computed engine builds: `822`
- residual scan: `13.13s`
- retriangulation: `51.52s`
- max error: `0.04999m`

`*` The baseline runtime did not emit `engineBuildCount`, so builds are computed as
`backend calls + retriangulationCount`, equivalent to the recorded residual scan count for that
runtime.

## Remaining Gaps

- Build count did not approach the indicative `30 -> <= 6` direction.
- The hosted row is public command path and representative broad-overlap style, but it is still one
  run and not a statistical benchmark.
- Exact seam synchronization remains unchanged and may still inflate patch count/solve repetition.
- Pure Ruby full-patch retriangulation remains the dominant implementation bottleneck after the
  corrected frontier mechanics were tested.
- The failed residual-frontier code is not retained, so future CDT work must start from the reverted
  baseline and the recorded evidence rather than treating MTA-37 as a usable backend layer.
