# MTA-08 Implementation Summary

**Status**: completed  
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

Live MCP validation was completed against the updated deployed extension.

### Loaded-Code Check

- Hosted `eval_ruby` confirmed `TerrainMeshGenerator#generate` was loaded from the deployed SketchUp plugin path and contains the production builder emitter call.
- Hosted `eval_ruby` confirmed `TerrainSurfaceCommands` no longer contains the `output.fetch(:summary).merge(regeneration: ...)` output-strategy merge.
- Hosted `ping` returned `pong` before and after terrain operations.

### Production Create Cases

| Case | MCP call timing | Mesh | State | Result |
| --- | ---: | ---: | --- | --- |
| Small 4x3 | 0.097s | 12 vertices / 12 faces | `heightmap_grid` v1 revision 1 | PASS |
| Non-square 17x9 | 0.775s | 153 vertices / 256 faces | `heightmap_grid` v1 revision 1 | PASS |
| Near-cap 100x100 | 0.622s | 10,000 vertices / 19,602 faces | `heightmap_grid` v1 revision 1 | PASS |

Create response checks passed:

- `output.derivedMesh.derivedFromStateDigest` matched the saved terrain-state digest.
- Public output stayed on the `derivedMesh` shape without `validationOnly`, `bulk`, `candidate`, `strategy`, `chunks`, `tiles`, `faceId`, or `vertexId`.
- Persisted terrain payload stayed `payloadKind: "heightmap_grid"` and `schemaVersion: 1`.

Hosted geometry inspection after create passed:

| Case | Faces | Edges | Derived faces | Derived edges | Non-positive normals | Minimum normal Z |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Small 4x3 | 12 | 23 | 12 | 23 | 0 | 1.0 |
| Non-square 17x9 | 256 | 408 | 256 | 408 | 0 | 1.0 |
| Near-cap 100x100 | 19,602 | 29,601 | 19,602 | 29,601 | 0 | 1.0 |

### Production Edit / Regenerate

- Edited `mta08-live-nonsquare-20260426` through public `edit_terrain_surface`.
- MCP call timing: 1.833s.
- Revision changed from 1 to 2.
- Digest changed from `a1fbb02dad3cdb4d9381ea4ca5e678c341ca1e265863738bba6c27e1b0f1059f` to `972d9a3ecd6fd571793ac17488d590e219d7edd6a2a4e69dae003adeb370d36e`.
- `output.derivedMesh.derivedFromStateDigest` matched the after-state digest.
- Regenerated output contained 256 faces and 408 edges.
- All 256 faces and all 408 edges retained derived-output markers.
- Normals remained positive: 0 non-positive normals, minimum normal Z about `0.1741`.
- Elevations changed from flat 0.0m to a 0.0m-4.0m high-variation range.
- Post-edit `ping` returned `pong`.

### Undo

- Hosted `Sketchup.undo` after edit restored:
  - terrain revision 1
  - original digest `a1fbb02dad3cdb4d9381ea4ca5e678c341ca1e265863738bba6c27e1b0f1059f`
  - flat elevation range 0.0m-0.0m
  - 256 derived faces and 408 derived edges
  - 0 non-positive normals

### Unsupported-Child Refusal

- Added an unmanaged child group under `mta08-live-sentinel-check-20260426`.
- Public `edit_terrain_surface` refused with `terrain_output_contains_unsupported_entities`.
- Refusal details reported `unsupportedChildTypes: ["group"]`.
- Existing derived output was not erased: 12 faces remained, with all 12 still marked derived.
- Terrain state stayed revision 1.

### Unmanaged Scene Safety

- A solid unmanaged sentinel group was created in the live scene with its own child face.
- The solid sentinel survived subsequent create/edit/refusal checks.
- Existing prior scene geometry remained present during the terrain operations.

## Remaining Gaps

- No remaining MTA-08 implementation or validation gaps are known.
- The internal per-face diagnostic/compatibility path remains available by design until a later task removes or demotes it.
