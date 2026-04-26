# Summary: MTA-05 Implement Corridor Transition Terrain Kernel

**Task ID**: `MTA-05`  
**Implementation State**: completed after automated validation, final Grok-4.20 review, live SketchUp MCP retest, and size calibration  
**Last Updated**: `2026-04-26`

## Shipped Automated Surface

- Added `operation.mode: "corridor_transition"` for `edit_terrain_surface`.
- Added `region.type: "corridor"` with endpoint controls, full-weight corridor `width`, and optional meter-based `sideBlend`.
- Added SketchUp-free `CorridorFrame` for oriented corridor math, conservative bounds, longitudinal/lateral sampling, and side-blend weights.
- Added SketchUp-free `CorridorTransitionEdit` for heightmap mutation, no-data refusal, preserve-zone hard masks, fixed-control conflicts, changed-region diagnostics, and compact transition evidence.
- Reused the existing repository save and full derived-output regeneration flow through `TerrainSurfaceCommands`.
- Updated native MCP schema, request validation, command dispatch, evidence shaping, contract fixtures, and README documentation.
- Extracted shared fixed-control evaluation/interpolation used by both bounded grade and corridor transition kernels.

## Contract Alignment

- Schema-level `operation.required` is now only `mode`; runtime validation owns mode-specific fields.
- `target_height` is compatible only with `rectangle`.
- `corridor_transition` is compatible only with `corridor`.
- Finite options are discoverable through schema constants and refusal payloads:
  - `operation.mode`: `target_height`, `corridor_transition`
  - `region.type`: `rectangle`, `corridor`
  - rectangle `region.blend.falloff`: `none`, `linear`, `smooth`
  - corridor `region.sideBlend.falloff`: `none`, `cosine`
  - `constraints.preserveZones[].type`: `rectangle`

## Validation

- `bundle exec rake ci`
  - RuboCop: 175 files, no offenses
  - Ruby tests: 654 runs, 3013 assertions, 0 failures, 0 errors, 32 skips
  - Package verification: `dist/su_mcp-0.22.0.rbz`
- Focused regression after live testing:
  - `bundle exec ruby -Itest -e 'load "test/terrain/corridor_transition_edit_test.rb"; load "test/terrain/corridor_frame_test.rb"'`
  - 12 runs, 244 assertions, 0 failures, 0 errors, 0 skips
- Final Grok-4.20 Step 10 code review completed after the live endpoint fix.
- Review findings addressed:
  - updated stale `edit_terrain_surface` tool description
  - extracted shared fixed-control evaluator
  - rejected negative corridor bounds expansion values
  - strengthened preserve-zone behavior coverage
  - added explicit non-uniform diagonal corridor bounds coverage
  - strengthened schema assertions that `operation.required` is only `mode` and corridor fields are exposed
  - documented the endpoint-tolerance purpose inline

## Live SketchUp MCP Verification

- Public MCP client smoke coverage passed for baseline terrain creation, preserve-zone hard masks, fixed-control conflicts, invalid mode/region pairs, invalid corridor geometry, supported and unsupported side-blend refusals, diagonal corridor output normals, and unmanaged-content preservation through edit, undo, and refusals.
- The live pass found one adopted-coordinate endpoint bug: for a terrain adopted at non-zero origin `(2100,1000)` with approximately `0.1m` spacing, the exact end-control sample at `(2108,1008)` remained unchanged while nearby samples and interpolated diagnostics moved correctly.
- Root cause: floating-point drift could classify the exact end sample as just past the corridor length.
- Fix: `CorridorFrame` now uses a small longitudinal parameter tolerance when testing whether a sample is outside the corridor length.
- Regression coverage now includes the non-zero-origin, fractional-spacing exact endpoint case and verifies both the stored end-grid sample and endpoint delta evidence.
- Focused live retest after the fix passed:
  - adopted-coordinate exact endpoint: fresh terrain origin `(2500,1000)`, exact end sample `(2508,1008)` returned `4.0`, stored state at column `80` / row `80` was `3.9999999999999996`, and `endpointDeltas.end` was approximately `7.8e-13`
  - adopted-coordinate nearby samples: start `(2502,1002)` was `1.0`, midpoint `(2505,1005)` was `2.5`, just-before-end `(2507.9,1007.9)` was `3.95`, and outside-after-end `(2508.1,1008.1)` stayed near original terrain
  - coincident endpoint corridor still refused with `invalid_corridor_geometry`
  - diagonal corridor output had `19,602` up-facing faces, `0` down, `0` flat, and minimum normal Z `0.024`
  - unmanaged sentinel survived edit, refusal, and undo
  - successful corridor edit remained one undo step, with revision `2 -> 1` and endpoint sample reverting from `4.0` to original `-0.1`

## Remaining Follow-Ups

- Production output regeneration still uses the existing full SketchUp entity mutation path. The internal `generate_bulk_candidate` path is validation-only in this task; production adoption belongs to the follow-on bulk-update/performance task.
- Broader release or merge packaging remains outside this task closeout.
