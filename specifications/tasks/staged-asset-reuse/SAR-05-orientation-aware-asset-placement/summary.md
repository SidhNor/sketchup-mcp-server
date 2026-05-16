# SAR-05 Implementation Summary

**Status**: `completed`
**Task**: `SAR-05 Orientation-Aware Asset Placement`
**Captured**: `2026-05-16`

## Delivered

- Added optional `placement.orientation` support to `instantiate_staged_asset`.
- Added strict staged-assets request normalization for `upright` and `surface_aligned` modes, optional finite `yawDegrees`, required `surfaceReference` for `surface_aligned`, and misplaced top-level `orientation` refusal.
- Added orientation-aware transform construction:
  - omitted orientation preserves SAR-02 source transform compatibility
  - explicit `upright` normalizes up to model vertical and applies yaw around model vertical
  - `surface_aligned` derives local up from the resolved surface frame
  - omitted yaw preserves source heading
  - source axis scale is retained for orientation transforms
- Added staged-assets surface-frame resolution from an explicit `placement.orientation.surfaceReference` and request `placement.position` XY.
- Added pre-mutation refusals for invalid orientation shape, missing surface reference, unresolved/ambiguous/unsupported surfaces, surface misses, and degenerate frames.
- Updated compact response evidence under `placement.orientation` with `mode`, `yawDegrees`, `sourceHeadingPreserved`, and surface `hitPoint`/`slopeDegrees` when applicable.
- Updated native tool schema, native contract fixtures, public contract posture, and `docs/mcp-tool-reference.md`.

## Contract Notes

- The public request shape stays under the existing top-level sections: `targetReference`, `placement`, `metadata`, and `outputOptions`.
- `placement.orientation` is optional. Omitting it keeps SAR-02-compatible source transform behavior.
- Explicit `placement.orientation.mode = "upright"` keeps the applied up axis model-vertical; yaw, when present, is around model vertical.
- Explicit `placement.orientation.mode = "surface_aligned"` requires `placement.orientation.surfaceReference`; the command samples that referenced surface at request `placement.position` XY and uses the hit Z as the applied position.
- Surface-aligned response evidence is compact and JSON-safe; raw SketchUp geometry is not exposed.
- Staged asset metadata remains a JSON-safe property bag for discoverability and cannot veto explicit SAR-05 placement intent.

## Tests Added

- Orientation request normalizer tests for defaults, explicit upright yaw, invalid mode, non-finite yaw, missing surface reference, and accepted direct surface references.
- Orientation transform builder tests for SAR-02-compatible omitted orientation, explicit upright yaw, explicit upright model-vertical normalization, surface-aligned local up, source-heading preservation without yaw, and source axis scale preservation.
- Surface frame resolver tests for fake surfaces, transformed fake surfaces, miss, ambiguity, and runtime face-plane sampling.
- Command tests for upright yaw evidence, omitted orientation evidence, misplaced top-level orientation refusal, missing surface reference refusal, surface-aligned success evidence, and surface refusal without mutation.
- Serializer tests for compact orientation evidence.
- Native runtime/schema/contract tests and fixtures for orientation success and refusal cases.

## Validation

- Focused post-review validation:
  - Staged assets suite: `64 runs, 211 assertions, 0 failures, 0 errors, 0 skips`.
  - Runtime suite: `167 runs, 750 assertions, 0 failures, 0 errors, 36 skips`.
  - Scene query plus staged assets suite: `162 runs, 523 assertions, 0 failures, 0 errors, 1 skip`.
- Full CI after final review follow-up:
  - RuboCop inspected 360 files with no offenses.
  - Ruby tests: `1444 runs, 17386 assertions, 0 failures, 41 skips`.
  - Package verification passed and produced `dist/su_mcp-1.8.0.rbz`.
- Post hosted-transform-fix focused validation:
  - Transform builder test: `7 runs, 30 assertions, 0 failures, 0 errors, 0 skips`.
  - Staged assets suite: `65 runs, 214 assertions, 0 failures, 0 errors, 0 skips`.
  - Runtime suite: `167 runs, 750 assertions, 0 failures, 0 errors, 36 skips`.
- Post-fix full CI:
  - RuboCop inspected 360 files with no offenses.
  - Ruby tests: `1445 runs, 17389 assertions, 0 failures, 0 errors, 41 skips`.
  - Package verification passed and produced `dist/su_mcp-1.8.0.rbz`.

## Review

- Ran the task-review workflow locally. Subagents were not launched because this environment only permits spawned agents when the user explicitly asks for delegation; deterministic local review commands were used instead.
- Ran PAL code review with `model: "gpt-5.4"` per user instruction.
- Review follow-up changes applied:
  - implemented runtime face-plane sampling instead of leaving the live-face path as a placeholder
  - fixed surface-aligned omitted yaw so source heading is preserved
  - fixed surface-aligned transforms so source axis scale is preserved
  - fixed explicit upright transforms so the up axis is model-vertical rather than preserving source tilt
  - updated tool description and neutralized reused missing-target refusal wording
  - simplified serializer input to consume explicit compact surface evidence
- Hosted visual follow-up found one additional issue: `surface_aligned` replaced the source asset basis with a generic surface frame, which could stand asset `13` groundcover on edge. Fixed the transform builder to rotate the existing source transform from model up to surface up, preserving definition-axis correction and source scale.

## Live SketchUp Verification

- Initial live smoke through first-class `su-ruby` staged-asset tools exposed two invalid probe assumptions:
  - an initial terrain placement used a broad/flat-enough surface target and did not provide useful visual proof
  - clipped hedge probes were placed with explicit `z: 1.0`, so they appeared to fly and were not valid visual evidence
- After the transform fix was deployed and reloaded into SketchUp, a focused live surface-aligned smoke passed:
  - created `sar05-live-steep-surface-001`, a visible temporary managed terrain surface with center hit `z = 0.6` at `[33.0, 57.0]`
  - sampled the surface at `[33.0, 57.0]`, `[33.0, 56.25]`, and `[33.0, 57.75]`, confirming a clear slope from `z = 0.15` to `z = 1.05`
  - instantiated asset `13` as `sar05-live-surface-aligned-fixed-001` with `surface_aligned` placement against that explicit surface
  - response evidence reported `placement.position = [33.0, 57.0, 0.6]` and `slopeDegrees = 30.963756532`
  - `validate_scene_update` passed for the test surface, created instance, and instance metadata
  - missing `surfaceReference` refusal returned `missing_surface_reference`, and `find_entities` confirmed no `sar05-live-surface-refusal-fixed-001` was created
- Explicit upright visual behavior was reviewed live and accepted.
- Undo does not need a SAR-05-specific hosted check because the command remains wrapped in the shared SketchUp operation path.
- Temporary failed probes were deleted. The fixed steep-surface probe and fixed groundcover instance were left in the scene for visual inspection.

## Remaining Follow-Up

- Consider a separate refinement for explicit near-vertical surface-frame refusals if hosted validation shows miss-style evidence is too ambiguous for callers.

## Task Metadata Updates

- Updated [task.md](./task.md) status to `completed`.
- Updated [plan.md](./plan.md) status to `implemented`.
- Updated [size.md](./size.md) status to `calibrated` with actual profile, validation evidence, and estimation delta.
