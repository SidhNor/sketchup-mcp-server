# Summary: MTA-14 Evaluate Base Detail Preserving Survey Correction

**Task ID**: `MTA-14`
**Status**: `completed`
**Date**: `2026-04-27`

## Shipped Evaluation Behavior

- Added a private, test-owned `SU_MCP::Terrain::SurveyCorrectionEvaluation` harness in `test/support`.
- Added deterministic terrain-domain tests for the minimum-change baseline and the base/detail candidate.
- Kept the evaluation outside runtime command registration, public MCP schemas, persisted terrain state, and README examples.
- Implemented JSON-safe evaluation reports with serialized `HeightmapState` payloads for test inspection.
- Implemented survey residual, max sample delta, changed-region, slope proxy, curvature proxy, detail-retention, detail-suppression, fixed-control drift, preserve-zone drift, and cumulative-drift evidence.
- Implemented refusal cases for survey points outside bounds, survey points over no-data samples, contradictory survey points, preserve-zone conflicts, fixed-control conflicts, and required sample deltas above threshold.
- Preserve-zone conflicts include both survey points inside preserve zones and post-correction preserve-zone drift from overlapping survey influence.
- Implemented repeated single, batch, and corrected single-point workflow evaluation.
- Added recommendation logic that selects a base/detail tuple only when it satisfies residuals and is not a threshold-only posture.

## Solver Recommendation Package

Recommendation for `MTA-13`: use the base/detail-preserving strategy as the default solver candidate for supported `heightmap_grid` v1 survey edits, with minimum-change retained as a control baseline and safe-case fallback only when fixture evidence shows detail preservation is unnecessary.

Selected default tuple from the current parameter matrix:

- `radiusSamples`: `1`
- `passes`: `1`
- `coreRadiusM`: `0.5`
- `blendRadiusM`: `1.5`
- `falloff`: `smoothstep`
- `surveyTolerance`: `0.01`

Baseline and candidate fixture results on the flat/local-detail fixture:

| Strategy | Parameters | Residual | Max Sample Delta | Changed Samples | Detail Retention Outside Influence | Core Suppression | Blend Suppression | Slope Increase | Curvature Increase | Status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `minimum_change` | default comparison tuple | `0.0` | `1.0` | `1` | `1.0` | `0.0` | `0.0` | `1.0000` | `2.0000` | `satisfied`, not detail-preserving |
| `base_detail` | `radius=1`, `passes=1`, `core=0.5`, `blend=1.5`, `smoothstep` | `0.0` | `1.0` | `9` | `1.0` | `0.9000` | `0.9669` | `0.7695` | `1.5391` | `satisfied`, detail-preserving |
| `base_detail` | `radius=2`, `passes=2`, `core=1.0`, `blend=2.0`, `smoothstep` | `0.0` | `1.0` | `25` | `1.0` | `2.0906` | `0.8448` | `0.7018` | `1.4036` | `satisfied`, detail-preserving |

Repeated edit workflow results on the sloped/noisy fixture:

| Step | Scenario | Residuals | Max Sample Delta | Status |
|---|---|---:|---:|---|
| 1 | single survey edit | `[0.0]` | `0.8000` | `satisfied` |
| 2 | batch survey edit | `[0.0, 0.0]` | `0.8000` | `satisfied` |
| 3 | corrected single-point edit | `[0.0]` | `0.4116` | `satisfied` |

Cumulative drift outside the current correction influence after the repeated workflow:

- max: `0.4451`
- mean: `0.1413`

## Algorithm Sketch

Minimum-change baseline:

```ruby
current_z = interpolate(H, survey_xy)
residual = target_z - current_z
weights = bilinear_stencil_weights(survey_xy)
delta = minimum_norm_solution(weights, residual)
H_prime[stencil] += delta
```

Base/detail candidate:

```ruby
B = cropped_square_low_pass(H, radius_samples, passes)
D = H - B
M = detail_retention_mask(core_radius_m, blend_radius_m, smoothstep)
D_retained = D * M
base_target = survey_target_z - interpolate(D_retained, survey_xy)
B_prime = minimum_norm_bilinear_correction(B, base_target)
H_prime = B_prime + D_retained
```

Cumulative drift rule:

```ruby
excluded = samples_inside_current_core_plus_blend_radius
drift = current_samples.excluding(excluded) - first_acceptable_samples.excluding(excluded)
```

## Refusal, Warning, And Escalation Guidance

Implemented refusal reason codes:

- `survey_point_outside_bounds`
- `survey_point_over_no_data`
- `contradictory_survey_points`
- `survey_point_preserve_zone_conflict`
- `fixed_control_conflict`
- `required_sample_delta_exceeds_threshold`

Recommendation behavior:

- `satisfied`: survey residuals and detail/distortion evidence are within configured limits.
- `warn`: residuals are satisfied but slope or curvature increases approach configured limits.
- `refuse`: required inputs or computed correction violate current v1 constraints.
- `escalate_mta11`: no detail-preserving strategy is available and a constrained penalty solver remains undefined.

Thresholds are not a substitute for detail preservation. A threshold-only minimum-change result must not be labeled detail-preserving just because residual and max-delta checks pass.

The constrained detail-penalty solver is explicitly deferred unless a later task defines it with comparable pseudocode, parameters, fixtures, and tests.

## Validation Evidence

- `bundle exec ruby -Itest test/terrain/survey_correction_evaluation_test.rb`
  - 12 runs, 66 assertions, 0 failures, 0 errors, 0 skips.
- Neighboring terrain/contract suite:
  - 45 runs, 258 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec rake ruby:test`
  - 768 runs, 3714 assertions, 0 failures, 0 errors, 36 skips.
- `bundle exec rake ruby:lint`
  - 195 files inspected, no offenses detected.

Package verification was not run because this task does not change extension runtime, packaging, loader metadata, vendored files, or public command registration.

## Code Review

- Pre-skeleton PAL/Grok-4.20 review completed.
- Pre-skeleton findings addressed before implementation:
  - clarified cumulative-drift exclusion rule;
  - added concrete report shape and metric pseudocode to `plan.md`;
  - added parameter-matrix recommendation coverage.
- Final Step 10 PAL/Grok-4.20 review completed.
- Findings addressed:
  - added post-correction preserve-zone drift refusal for overlap cases where the survey point is outside a preserve zone but affected samples would move;
  - replaced the `git diff` shell-out contract test with a pure Ruby source-location check;
  - documented the minimum-norm dual solve used by the evaluation harness.
- Self-review follow-up before final review:
  - added `required_sample_delta_exceeds_threshold` refusal output and focused test coverage.

## Live SketchUp Verification Status

SketchUp-hosted Ruby evaluation smoke ran and passed.

Host context:

- SketchUp version: `26.1.189`
- Ruby version: `3.2.2`
- Harness loaded from the WSL UNC path into the SketchUp Ruby process.

Smoke evidence:

- The flat/local-detail comparison selected `base_detail`.
- Selected tuple: `radiusSamples=1`, `passes=1`, `coreRadiusM=0.5`, `blendRadiusM=1.5`, `falloff=smoothstep`.
- Minimum-change satisfied residual `0.0` but remained `detailPreserving=false`, with slope increase `1.0000` and curvature increase `2.0000`.
- Selected base/detail tuple satisfied residual `0.0`, reported `detailPreserving=true`, changed `9` samples, and had lower slope/curvature increases (`0.7695` / `1.5391`) than the minimum-change baseline.
- Repeated single, batch, and corrected single-point workflow satisfied all residuals and reported cumulative drift max `0.4451`, mean `0.1413`.
- Preserve-zone overlap smoke refused with `survey_point_preserve_zone_conflict`.

Visual geometry proof:

- Created undoable SketchUp group `MTA-14 visual proof 2026-04-27 20:06:35`.
- Entity ID: `404444`; persistent ID: `1284529`.
- The group contains side-by-side generated terrain meshes for original local-detail terrain, minimum-change correction, and base/detail correction.
- Minimum-change visual: residual `0.0`, changed samples `1`, slope/curvature increase `1.0000` / `2.0000`, `detailPreserving=false`.
- Base/detail visual: residual `0.0`, changed samples `9`, slope/curvature increase `0.7695` / `1.5391`, `detailPreserving=true`.
- The group also includes survey markers, labels, and a preserve-zone refusal proof marker.
- Created richer large-surface visual group `MTA-14 large terrain visual proof 350m east 2026-04-27 20:11:49`.
- Large visual group entity ID: `474703`; persistent ID: `1293742`.
- Large visual bounds: approximately X `350m..420m`, Y `-3m..24m`.
- The large visual proof uses a 21x21 synthetic terrain with slope, ridge, basin, mound, ripples, fine detail, and four survey points.
- Large minimum-change result: residuals `[0.0, 0.0, ~0.0, 0.0]`, changed samples `16`, max sample delta `0.9229`, slope/curvature increase `0.5657` / `1.1699`, `detailPreserving=false`.
- Large base/detail result: residuals `[~0.0, 0.0, 0.0, 0.0]`, changed samples `51`, max sample delta `0.9556`, slope/curvature increase `0.5735` / `1.3149`, `detailPreserving=true`, outside detail retention `1.0`.
- Created standalone original large terrain group `MTA-14 standalone original large terrain 2026-04-27 20:14:22`.
- Standalone original entity ID: `523838`; persistent ID: `1302392`; bounds approximately X `350m..370m`, Y `40m..60m`.

Proof boundary: this is hosted Ruby-domain execution plus standalone visual proof geometry. It confirms the evaluation harness and solver math run inside SketchUp Ruby and can generate explanatory meshes, but it still does not validate the public MCP survey edit workflow, managed terrain persistence, runtime command dispatch, stored terrain transforms, production regenerated mesh output, or public undo behavior.

`MTA-13` still requires hosted/public MCP validation for the implemented survey edit mode, including request validation, persistence, output regeneration, undo behavior, and visual/runtime behavior.

## Contract And Documentation Review

- Public MCP contract: unchanged.
- Runtime dispatcher and native loader schema: unchanged.
- Persisted terrain payload kind/schema version: unchanged.
- README examples and user-facing tool docs: unchanged because no public tool, setup path, schema, or workflow changed.
- MTA-14 task status was updated to `completed`.
- MTA-14 plan was refined to include exact report shape, metric pseudocode, cumulative-drift rule, and parameter-matrix coverage.

## Conclusion And MTA-13 Handoff

MTA-14 proves that the base/detail-preserving strategy is practical enough to carry into `MTA-13` as the primary implementation candidate for supported `heightmap_grid` v1 survey edits.

The conclusion is not that base/detail always dominates every metric. On the small local-detail fixture it both preserved detail and reduced slope/curvature disturbance compared with minimum-change. On the richer 21x21 multi-point fixture it preserved detail and satisfied all survey points, but minimum-change produced lower slope/curvature proxy values because it changed only local stencils. That difference is useful: it confirms `MTA-13` should report both detail-preservation and distortion metrics, and should not treat a single threshold family as the whole safety story.

`MTA-13` should reuse as much of the MTA-14 implementation as possible, but by promoting the logic into production terrain-domain code rather than depending on `test/support` directly. The reusable pieces are:

- bilinear survey interpolation and stencil weighting;
- minimum-norm correction over one or more survey stencils;
- cropped-square low-pass base extraction;
- core/blend detail-retention mask with smoothstep falloff;
- retained-detail target adjustment before base correction;
- recomposition into a new `HeightmapState`;
- survey residual, changed-region, max-delta, slope, curvature, fixed-control drift, preserve-zone drift, detail-retention, and detail-suppression metrics;
- refusal codes and refusal ordering for out-of-bounds, no-data, contradictory points, fixed controls, preserve zones, and sample-delta threshold breaches;
- repeated-edit drift logic and fixture coverage.

Recommended production shape for `MTA-13`:

- move the solver into a SketchUp-free terrain-domain service under `src/su_mcp/terrain/`;
- keep the public command layer responsible for request validation, target resolution, storage, output regeneration, undo wrapping, and response shaping;
- port the MTA-14 fixtures into production tests instead of leaving them as spike-only evidence;
- keep the baseline minimum-change strategy available for comparison, diagnostics, or explicitly safe fallback cases;
- keep the base/detail strategy as the default recommendation where detail preservation matters;
- preserve the explicit proof boundary: `MTA-13` must still add hosted/public MCP validation for persistence, regenerated mesh output, undo behavior, and visual/runtime behavior.

## Remaining Gaps

- This is terrain-domain solver evidence only; it is not public SketchUp-hosted proof.
- Fixture thresholds are implementation-guiding defaults for `MTA-13`, not universal civil grading safety constants.
- Broader constrained optimization remains deferred to `MTA-11` or a follow-up research task unless it is specified and tested at the same level.
