# Summary: MTA-13 Implement Survey Point Constraint Terrain Edit

**Task ID**: `MTA-13`
**Status**: `completed`
**Date**: `2026-04-28`

## Shipped Runtime Behavior

- Added public `edit_terrain_surface` mode `survey_point_constraint`.
- Added required `operation.correctionScope` with finite values `local` and `regional`.
- Added required non-empty `constraints.surveyPoints` for survey edits, with finite public-meter `point.x`, `point.y`, `point.z`, optional JSON-safe `id`, and optional non-negative `tolerance`.
- Reused rectangle and circle terrain edit regions as explicit correction support geometry.
- Reused existing fixed controls and rectangle/circle preserve zones for survey edits.
- Added local survey correction using promoted MTA-14 base/detail solver behavior under `src/su_mcp/terrain/`.
- Added bounded regional survey correction using explicit support-region correction fields plus minimum-norm projection.
- Added structured refusals for out-of-bounds points, no-data states, points outside support, contradictory points, preserve-zone conflicts, fixed-control conflicts, unsafe sample delta, unsafe regional distortion, and empty affected support.
- Added compact `evidence.survey` output with per-point requested/before/after/residual/tolerance/status rows and correction summary evidence.

## MTA-14 Promotion

The proven MTA-14 base/detail solver was promoted into production terrain-domain code as `SurveyCorrectionSolver`.

The production implementation imports no `test/support` solver code. `test/support/terrain_survey_correction_evaluation.rb` remains an oracle harness, and the MTA-13 test suite compares production local correction with the MTA-14 base/detail oracle for residual, changed sample count, detail retention, and detail suppression.

Regional correction remains intentionally separate because MTA-14 did not model explicit bounded regional support. The regional path is guarded by explicit `correctionScope: "regional"`, request support geometry, and distortion/coherence evidence.

Post-verification regional fixes added:

- affine residual correction for survey points that exactly define a planar correction field;
- complete survey-grid residual correction for piecewise bilinear or breakline-style correction fields;
- inverse-distance residual correction remains the fallback for under-specified or non-grid regional survey inputs.
- normalized regional residual-range safety, so large absolute survey residual ranges are judged
  relative to the mutable support footprint and resulting grade/curvature rather than by a
  footprint-blind meter threshold.

## Contract And Docs

- Updated native MCP schema for `operation.correctionScope` and `constraints.surveyPoints`.
- Updated native runtime contract fixtures for local success, regional success, invalid correction scope, missing survey points, invalid survey point shape, and unsupported corridor region.
- Updated command routing so survey edits use `SurveyPointConstraintEdit`.
- Updated evidence shaping so `diagnostics[:survey]` is returned as public `evidence.survey`.
- Updated README mode matrix, request example, and terrain edit response description.
- Updated `docs/mcp-tool-reference.md` to document regional coherence evidence fields
  `supportFootprintLength` and `normalizedSurveyResidualRange`.
- Added no-leak coverage preventing solver internals, generated face/vertex IDs, matrices, stencils, and MTA-14 harness names from public response evidence.

## Production Shape

- `SurveyPointConstraintEdit`: orchestration only.
- `SurveyPointConstraintContext`: shared request/state geometry helpers.
- `SurveyPointInputRefusals`: pre-solve refusal checks.
- `SurveyBilinearStencil`: bilinear survey interpolation weights.
- `SurveyCorrectionSolver`: promoted local base/detail correction solver.
- `RegionalSurveyCorrectionSolver`: bounded regional correction field selection and projection.
- `SurveyGridResidualField`: complete survey-grid residual interpolation for piecewise bilinear and breakline-style regional fields.
- `SurveyCorrectionMetrics`: max delta, slope, curvature, normalized residual-range regional coherence, detail evidence, and preserve drift metrics.
- `SurveyCorrectionEvidence`: public diagnostics and post-correction refusals.

## Validation Evidence

- Focused public MCP/terrain suite:
  - 132 runs, 936 assertions, 0 failures, 0 errors, 31 skips.
- Focused survey point edit regression suite after normalized regional safety:
  - 11 runs, 65 assertions, 0 failures, 0 errors, 0 skips.
- Full Ruby test suite:
  - 791 runs, 4000 assertions, 0 failures, 0 errors, 35 skips.
- Ruby lint:
  - 202 files inspected, no offenses detected.
- Package verification:
  - produced `dist/su_mcp-0.25.0.rbz`.

## Code Review

- Final Step 10 PAL/Grok-4.20 review completed after implementation.
- A self-review finding identified duplicate identical survey points as a possible singular-solve edge; production solvers now dedupe duplicate solve equations while preserving every public evidence row.
- A user review finding identified excessive production lint disables on `SurveyPointConstraintEdit`; the editor was split into focused collaborators and the broad disable block was removed.
- Fresh Step 10 PAL/Grok-4.20 review after the split found no critical, high, or required medium findings.
- Remaining review notes are non-blocking maintainability/documentation suggestions only.
- Hosted validation later exposed two regional interpolation defects; both were fixed and covered by regression tests.
- Follow-up Step 10 PAL/Grok-4.20 review for normalized regional residual-range safety found no findings.

## Live SketchUp Verification Status

Hosted public MCP validation completed.

Core public MCP scenarios passed:

- Local one-point survey edit: corrected center point from `1.0` to `2.5`, residual `0.0`, `correctionScope: "local"`, and `evidence.survey.points[]` present.
- Local repeated corrected point: second edit used current terrain state, with before `2.5`, after `2.8`, revision `2 -> 3`, and no stale replay.
- Regional multi-point edit: three survey points satisfied with residual `0.0`, changed `49` samples, with regional coherence and distortion evidence present.
- Invalid `correctionScope: "global"` refused with `unsupported_option` and `allowedValues: ["local", "regional"]`.
- Missing `constraints.surveyPoints` refused with `missing_required_field`.
- Points outside terrain bounds refused with `survey_point_outside_bounds`.
- Points outside explicit support refused with `survey_point_outside_support_region`.
- Contradictory same-XY points refused with `contradictory_survey_points`.
- Duplicate identical points succeeded and both duplicate IDs appeared in `evidence.survey.points[]`.
- Preserve-zone conflicts refused with `survey_point_preserve_zone_conflict`.
- Fixed-control conflicts refused with `fixed_control_conflict` before mutation, with predicted delta evidence.
- Unsafe regional distortion refused with `regional_correction_unsafe`.
- Excessive correction magnitude refused with `required_sample_delta_exceeds_threshold`.
- Public evidence exposed survey points, residuals, correction summaries, and distortion/coherence summaries without raw face IDs, vertex IDs, solver matrices, or internal stencils.

Additional hosted public MCP scenarios passed:

- Targeting by `persistentId` selected the correct terrain and edited it, with residual `0.0` and revision `3 -> 4`.
- Missing target refused `terrain_target_not_found`; non-terrain target refused `unsupported_target_type`; existing terrain revisions remained unchanged.
- Transformed owner placement behaved correctly: terrain placed at `(5080, 3000)`, survey XY `(5, 5)` corrected the world sample `(5085, 3005)` to `2.1`.
- Circle local support succeeded for a point inside the circle and refused the same point outside a hard circle with `survey_point_outside_support_region`.
- Circle regional support satisfied three survey points with `supportRegionType: "circle"` and `changedSampleCount: 45`.
- Blend shoulder support accepted a point outside the core but inside positive blend support, with evidence weight `0.5` and residual `0.0`.
- Off-grid bilinear point `(5.5, 5.5)` satisfied target `2.25` with residual `0.0`.
- Boundary min/max points `(0, 0)` and `(10, 10)` succeeded with residual `0.0`, including zero/tiny tolerance coverage.
- Tiny-tolerance fractional point `(5.25, 5.25)` with tolerance `1e-9` satisfied residual `0.0`.
- Regional edit with fixed controls inside support refused `fixed_control_conflict` before mutation.
- Preserve-zone-near-influence case succeeded with protected zone drift `0.0`.
- Region-fully-protected setup refused `survey_point_preserve_zone_conflict` because the survey point itself was inside the preserve zone; this is the expected precedence before `edit_region_has_no_affected_samples`.
- Sample evidence enabled returned survey evidence plus bounded samples without internal IDs or solver internals.

Performance and complex regional hosted validation passed:

- `mta13-perf-regional-80`: `80x80` terrain, `6400` vertices, `12482` faces, circular regional support radius `25` plus blend `5`, four survey points, edit wall time `0.666s`, `2809` changed samples, returned sample evidence capped at `20`, all residuals `0.0`, revision `1 -> 2`, output digest matched updated state digest, and runtime ping passed immediately after.
- `100x100` complex varied terrain: `10000` vertices, `19602` faces, waves/slope/local variation/ridge/basin seeded field, create time `0.57s`, seed plus regeneration `0.97s`, regional edit wall time `1.48s`, eight survey points, circular support radius `38` plus blend `8`, circular preserve zone radius `4`, `6552` changed samples, sample evidence capped at `25`, all residuals `0.0`, revision `2 -> 3`, protected samples `69`, preserve drift `0.0`, regional coherence `satisfied`, max sample delta `1.17564`, slope max increase `0.3000`, curvature max increase `0.4237`, and runtime ping passed immediately after.

Output sanity across hosted checks:

- Derived face and edge markers were complete for checked outputs.
- `downFaces: 0` and `flatOrDownFaces: 0` across checked fixtures.
- Large `80x80` support fixture: all `12482` faces and `18881` edges marked derived.
- Complex `100x100` fixture: all `19602` faces and `29601` edges marked derived, `minNormalZ: 0.6896`.

Behavior clarifications from hosted validation:

- Preserve-zone point overlap takes precedence over no-mutable-samples refusal.
- Unsafe regional requests can fail through either `required_sample_delta_exceeds_threshold` for very large corrections or `regional_correction_unsafe` for smaller steep/distorting corrections.

Post-fix hosted verification on redeployed extension:

- Full-region planar crossfall redirection now matches the target plane at edge and midline samples.
- Full-region crowned/breakline correction with a complete `3x3` survey grid now matches the expected piecewise planar crowned surface without ringing or edge bowing.
- Planar matrix verification passed `19/20` scenarios:
  - rotate crossfall 90 degrees;
  - reverse same-axis crossfall;
  - flatten crossfall;
  - uniform lift preserving plane;
  - steepen existing crossfall;
  - diagonal NE-high and NW-high planes;
  - non-zero base plane;
  - partial planar patch;
  - flat core with blend shoulder;
  - non-square terrain;
  - non-uniform spacing;
  - non-zero state origin;
  - fractional off-grid constraints;
  - repeated planar edits chain;
  - undo planar edit;
  - fixed controls satisfied;
  - fixed-control conflict;
  - preserve zone inside planar region.
- Most planar cases landed at numerical precision, typically around max error `4.44e-16`.
- P20, complex terrain to planar replacement from four corner points, was reclassified as an explicit product-boundary case rather than an MTA-13 defect. Current `survey_point_constraint` satisfies survey constraints while preserving existing terrain detail; forcing complete interior replacement with an implied plane needs a future explicit plane/replacement mode or policy.

Post-calibration regional safety follow-up:

- A hosted repro showed that the absolute `surveyResidualRange` threshold rejected a valid planar
  regional edit: `8.0m` correction range over a `~12.89m` footprint, slope increase about `0.62`,
  and effectively zero curvature.
- Regional coherence now reports `supportFootprintLength` and
  `normalizedSurveyResidualRange`, and safety uses normalized residual range plus slope and
  curvature rather than an absolute meter range alone.
- Regression coverage accepts the reported non-zero-origin, non-uniform-spacing `5x5` planar site
  grade and still refuses a concentrated `10m` spike/trench correction with
  `normalizedSurveyResidualRange > 2.0`.
- The live SketchUp runtime was monkey patched with the same normalized safety logic via
  `eval_ruby`. Exact hosted MCP rerun of the repro remains pending user-side verification.

## Conclusion

MTA-13 is implemented through the public MCP terrain edit surface with contract, runtime, terrain-domain, evidence, docs, and validation in sync.

The MTA-14 base/detail solver was meaningfully promoted into production for local survey correction, while regional survey adjustment remains bounded and explicit instead of inferring destructive terrain replacement from sparse points.
