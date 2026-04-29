# Summary: MTA-15 Harden Terrain Edit Contract Discoverability

**Task ID**: `MTA-15`
**Status**: `completed`
**Date**: `2026-04-29`

## Shipped Contract Behavior

- Updated `edit_terrain_surface` MCP descriptions to teach terrain intent for `target_height`, `corridor_transition`, `local_fairing`, and `survey_point_constraint`.
- Clarified that regional `survey_point_constraint` applies a bounded smooth correction field, not implicit planar fitting or best-fit replacement.
- Described `constraints.preserveZones` as the primary protection mechanism for known-good terrain during local and regional edits.
- Added post-edit review guidance for changed region, max sample delta, survey residuals, preserve-zone drift, slope/curvature proxy changes, and regional coherence where available.
- Updated `sample_surface_z` and `measure_scene terrain_profile/elevation_summary` guidance so point sampling reads controls and profile sampling reviews terrain shape between controls.
- Updated `docs/mcp-tool-reference.md` with operation intent, a compact safe terrain edit loop, grid-spacing limits, evidence review, and point/profile QA guidance.

## Contract Boundary

- No public tool names changed.
- No request shape, response shape, enum set, dispatcher route, refusal payload, solver behavior, storage behavior, generated geometry, or undo behavior changed.
- No MCP prompts or resources were added.
- No prose-locking tests were added; wording quality is governed by semantic review as planned.

## Validation Evidence

- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
  - 46 runs, 396 assertions, 0 failures, 0 errors, 6 skips.
- `bundle exec ruby -Itest test/runtime/public_mcp_contract_posture_test.rb`
  - 5 runs, 36 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb`
  - 25 runs, 2 assertions, 0 failures, 0 errors, 24 skips.
- `bundle exec rubocop --cache false src/su_mcp/runtime/native/mcp_runtime_loader.rb`
  - 1 file inspected, no offenses detected.
- `git diff --check -- src/su_mcp/runtime/native/mcp_runtime_loader.rb docs/mcp-tool-reference.md specifications/tasks/managed-terrain-surface-authoring/MTA-15-harden-terrain-edit-contract-discoverability/{task.md,size.md,summary.md}`
  - clean for MTA-15 changed paths.
- Full-worktree `git diff --check`
  - blocked by unrelated trailing whitespace in `specifications/tasks/platform/PLAT-18-implement-initial-mcp-prompts-guidance-surface/size.md`.

## Code Review

- Final Step 10 `mcp__pal__codereview` completed with `model: "grok-4.20"`.
- No critical, high, medium, or low findings were reported.
- Review confirmed the change is description/docs-only, keeps security and performance surfaces unchanged, and preserves architecture boundaries.

## Live SketchUp Verification Status

Live or hosted SketchUp validation was not run and is not required for this task.

Reason: MTA-15 changes static runtime tool descriptions and documentation only. It does not change command execution, SketchUp API usage, terrain solvers, geometry output, persistence, undo behavior, transport routing, or public response data.

## Contract And Documentation Review

- Runtime loader and MCP reference docs were reviewed against the semantic obligations in `task.md` and `plan.md`.
- The changed text does not imply planar fitting, best-fit replacement, monotonic correction, boundary-preserving patch behavior, preview/dry-run, visual acceptance, grading acceptance, or validation pass/fail policy.
- README was searched for terrain tool guidance; it contains only broad terrain lifecycle bullets and did not require an update.

## Remaining Gaps

- Wording quality is intentionally review-governed rather than enforced by brittle prose assertions.
- Future richer terrain recipes still belong in docs or MCP prompts/resources once that surface exists.
- Actionable refusal UX remains deferred behavior work and was not changed by this task.
