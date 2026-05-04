# Hosted Validation Checklist: MTA-21

**Task ID**: `MTA-21`
**Status**: `completed`
**Last Updated**: `2026-05-04`

## Scope

Validate the adaptive terrain conformance repair in live SketchUp after deploy, with emphasis on
mixed-resolution corridor seams, representative created terrains, adopted irregular terrains, and
aggressive stacked edits.

## Final Hosted Pass

| Case | Result | Output Faces |
|---|---|---:|
| Flat 41x41 representative corridor | edited | 1750 / 3200 |
| Crossfall 41x41 representative corridor | edited | 1546 / 3200 |
| Steep 41x41 representative corridor | edited | 1653 / 3200 |
| Non-square 71x31 representative corridor | edited | 1378 / 4200 |
| Adopted irregular terrain before corridor | adopted | 11044 / 19602 |
| Adopted off-grid corridor | edited | 7765 / 19602 |
| Adopted grid-aligned corridor | edited | 6824 / 19602 |
| Aggressive stacked created terrain | edited | 3578 / 4800 |
| High-relief seam-stress terrain | edited | 6667 / 9600 |

## Checks

- Representative created corridors accepted without `terrain_feature_pointification_limit_exceeded`.
- Adopted irregular terrain accepted before and after representative corridor edits.
- No down-facing faces were found in successful outputs.
- No non-manifold edges were found in successful outputs.
- No obvious T-type rips or folded seam artifacts were reproduced visually.
- High-relief seam-stress terrain reported a passing seam check.
- Grid-aligned adopted corridor sampled the requested profile correctly: `0.75 -> 1.90`.
- Aggressive stacked corridor profile matched the requested profile: `2.4 -> 0.6`.
- High-relief corridor profile matched the requested profile: `12.0 -> -3.0`.

## Earlier Hosted Findings Addressed

- Initial post-fix hosted pass was blocked by `terrain_feature_pointification_limit_exceeded` on
  representative planar, large corridor, large rectangle, circle, and adopted-corridor edits.
- Feature planner cap enforcement was narrowed to explicit `payload.sampleEstimate`; affected-window
  projections remain diagnostic-only.
- Follow-up hosted pass confirmed representative large edits then ran, but global boundary-line
  conformity was nearly dense in several cases.
- Boundary-fan conformity reduced face counts materially and removed the reproduced seam/fold class in
  the final hosted matrix.

## Residuals

- Face counts are still materially higher than the pre-conformance simplifier in some representative
  cases. This is accepted for MTA-21 seam correctness and should become a separate simplifier-quality
  task if pursued.
- Off-grid adopted corridor endpoint correctness remains wrong: requested end `1.85`, sampled end
  `1.43`, endpoint delta `0.4165`.
- Sharp-normal diagnostics are treated as stress indicators only in this pass because intentional steep
  grade changes can create high normal discontinuities without indicating a seam failure.
- Dedicated hidden-edge state verification in live SketchUp was not separately recorded.
- Save/reopen persistence was not checked in this hosted pass.
