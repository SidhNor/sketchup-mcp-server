# MTA-08 Interim Implementation Summary

**Status**: implementation complete locally; not closed  
**Task**: `MTA-08 Adopt Bulk Full-Grid Terrain Output In Production`  
**Captured**: 2026-04-26

## Implemented Locally

- Promoted the builder-backed full-grid terrain emitter into production `TerrainMeshGenerator#generate`.
- Kept `TerrainMeshGenerator#regenerate` on the existing refusal/cleanup flow, now rebuilding through the production builder-backed path after unsupported-child checks pass.
- Retained `generate_bulk_candidate` as a validation-only diagnostic entrypoint.
- Kept the per-face compatibility path only for host entity collections that do not respond to `build`.
- Preserved no automatic fallback after a builder failure; builder exceptions propagate through the existing command operation boundary.
- Removed command-level `output.regeneration.strategy` leakage so public output remains centered on `output.derivedMesh`.

## Test Coverage Added

- Production `generate` uses `entities.build` and returns only the expected generated result shape.
- Production output does not leak `validationOnly`, `bulk`, `candidate`, `strategy`, `regeneration`, sample-window, chunk, tile, face ID, or vertex ID internals.
- Generated faces and edges receive derived-output markers using a narrow `Sketchup::Edge`-shaped test support seam.
- Counts, digest linkage, deterministic diagonals, positive-Z normals, and public meter to internal unit conversion remain covered.
- `regenerate` erases prior derived output and rebuilds through the builder path.
- Unsupported child entities still refuse before old derived output is erased.
- Builder-unavailable compatibility is covered separately from builder-failure propagation.
- Contract stability coverage verifies public terrain output vocabulary does not expose bulk/candidate/internal fields.
- The hosted validation placeholder now describes MTA-08 production create/edit/regenerate validation rather than MTA-07 candidate comparison.

## Local Validation

- Focused terrain integration:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| load path }' test/terrain/terrain_mesh_generator_test.rb test/terrain/terrain_contract_stability_test.rb test/terrain/terrain_surface_commands_test.rb test/terrain/terrain_output_live_validation_test.rb`
  - Result: 29 runs, 197 assertions, 0 failures, 0 errors, 1 skip.
- Full Ruby test suite:
  - `bundle exec rake ruby:test`
  - Result: 688 runs, 3195 assertions, 0 failures, 0 errors, 35 skips.
- Ruby lint:
  - `bundle exec rake ruby:lint`
  - Result: 185 files inspected, no offenses.
- Package verification:
  - `bundle exec rake package:verify`
  - Result: passed; produced `dist/su_mcp-0.22.0.rbz`.
- `mcp__pal__.codereview` with `grok-4.20` completed. Follow-up test/contract findings were addressed before rerunning focused checks, full tests, lint, and package verification.

## Live Validation Status

Live MCP validation has **not** been completed for MTA-08.

An initial `ping` confirmed the hosted MCP endpoint was reachable, and one unmanaged sentinel was created in the live SketchUp model. Validation was then stopped because the live MCP process did not yet contain the local MTA-08 changes. Any live evidence from that session is therefore not valid for production bulk-output acceptance.

Required live validation remains:

- confirm the updated extension/package is loaded in SketchUp
- exercise production `create_terrain_surface` on small, non-square, near-cap, and high-variation cases
- exercise production `edit_terrain_surface` regeneration
- record timings, mesh counts, digest linkage, response shape, derived face/edge markers, positive-Z normals, undo behavior, responsiveness/ping, and unmanaged sentinel preservation
- verify unsupported-child refusal still happens before derived output deletion in the live host

## Remaining Gaps

- MTA-08 is not closed until hosted SketchUp validation runs against the updated extension.
- `size.md` actual calibration has not been performed yet because Step 11 is intentionally blocked until live validation is complete.
- `task.md` status remains unchanged until the live validation result is known.
