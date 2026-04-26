# Size: MTA-06 Implement Local Terrain Fairing Kernel

**Task ID**: `MTA-06`  
**Title**: Implement Local Terrain Fairing Kernel  
**Status**: `challenged`  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-26  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: local terrain fairing kernel
- **Likely Systems Touched**:
  - public terrain edit contract
  - heightmap neighborhood math
  - edit result evidence
  - request validation and runtime dispatch
  - loader schema and native contract fixtures
  - terrain output dirty-window handoff
- **Validation Class**: regression-heavy
- **Likely Analog Class**: public terrain edit mode extension

### Identity Notes
- Adds local fairing behavior as a narrow `edit_terrain_surface` operation mode with a SketchUp-free terrain kernel, measurable evidence, and no broad public smoothing tool.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a targeted public terrain edit mode with explicit fairing controls and evidence, while still avoiding a separate broad smoothing tool. |
| Technical Change Surface | 4 | Likely touches request validation, loader schema, dispatch, kernel math, neighborhood selection, fixtures, evidence, docs, and dirty-window handoff. |
| Hidden Complexity Suspicion | 4 | Fairing can blur constraints, cause edge artifacts, or conflict with bounded edit intent. |
| Validation Burden Suspicion | 4 | Needs before/after numerical checks, public contract coverage, dirty-window integration checks, and hosted terrain evidence. |
| Dependency / Coordination Suspicion | 3 | Depends on managed edit contracts, shared constraint behavior, and MTA-08 through MTA-10 output behavior being usable. |
| Scope Volatility Suspicion | 3 | Public naming, iteration caps, no-effect behavior, and evidence shape were refined during planning; remaining volatility is bounded. |
| Confidence | 3 | Step 05 resolved the public surface, field names, metric, algorithm, and output handoff, but hosted validation risk remains. |

### Early Signals
- Fairing is now planned as `operation.mode: "local_fairing"` on the existing `edit_terrain_surface` tool, not as a separate public MCP tool.
- Public operation controls are planned as `strength`, `neighborhoodRadiusSamples`, and optional bounded `iterations`.
- The kernel must avoid treating hardscape paths and pads as terrain.
- Regression coverage should prove local changes do not corrupt unrelated terrain cells or leak internal partial-output planning details.
- MTA-10 partial output support changes the output risk from full-regeneration cost to changed-region correctness and fallback safety.

### Early Estimate Notes
- Seed refreshed during task planning Step 05 after confirming a public `edit_terrain_surface` mode addition rather than an internal-only kernel.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Predicted (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Adds a public terrain edit mode with new user-visible controls, measurable evidence, and refusal behavior, while avoiding a separate tool or broad sculpting workflow. |
| Technical Change Surface | 4 | Touches public request validation, loader schema, dispatcher wiring, command orchestration, a new terrain kernel, shared constraint evaluation, evidence shaping, output-plan handoff, fixtures, docs, and hosted validation. |
| Implementation Friction Risk | 3 | The implementation path is clear, but neighborhood math, bounded iterations, changed-sample diagnostics, fixed controls, preserve masks, and no-effect handling can interact in subtle ways. |
| Validation Burden Risk | 4 | Requires kernel math tests, public contract parity, no-leak tests, dirty-window integration, hosted output/undo/normal/marker checks, coordinate edge cases, and near-cap performance evidence. Prior terrain edit/output analogs found live-only issues. |
| Dependency / Coordination Risk | 3 | Depends on MTA-04/MTA-05 edit contracts and MTA-08 through MTA-10 output behavior. SketchUp-hosted validation and deployed runtime correctness materially affect closeout. |
| Discovery / Ambiguity Risk | 2 | Step 05 resolved public naming, request fields, metric, iteration semantics, no-effect behavior, and output handoff. Remaining ambiguity is mostly tactical metric/sample-set implementation detail. |
| Scope Volatility Risk | 2 | The task already shifted from internal-only to public edit mode, but the current plan deliberately excludes brush UI, detail-preserving smoothing, and representation v2. |
| Rework Risk | 3 | MTA-04, MTA-05, and MTA-10 all exposed late hosted or review-driven corrections. MTA-06 has similar numeric and host-output surfaces even with a tighter plan. |
| Confidence | 3 | The plan is detailed and analog-backed, and Grok 4.20 challenged the main interface decisions. Confidence is capped by hosted SketchUp and performance behavior that cannot be fully proven from local tests. |

### Top Assumptions

- `heightmap_grid` v1 provides enough sample density and neighborhood access for representative local fairing without pulling in MTA-11 representation work.
- Rectangle bounds plus existing `region.blend` are sufficient for the first supported fairing slice.
- `mean_absolute_neighborhood_residual` is an acceptable review metric and can be implemented without flattening steady slopes.
- MTA-10 partial/fallback output behavior remains correct when fairing emits accurate actual changed-region diagnostics.
- Hosted validation can use the existing public MCP path and targeted grey-box checks where partial/fallback distinction needs proof.

### Estimate Breakers

- Fairing requires polygon/circle/brush regions to satisfy the representative workflow.
- The residual metric proves misleading on sloped terrain and needs a different continuity or curvature metric.
- Fixed controls require constrained smoothing rather than post-candidate conflict refusal.
- MTA-10 partial output cannot safely consume fairing changed regions without output-layer changes.
- Hosted near-cap validation shows radius/iteration behavior is too slow even with bounded inputs and early convergence.

### Predicted Signals

- Public contract change requires schema, dispatcher, fixtures, README, and no-leak coverage.
- Analog `MTA-05` had a live adopted-coordinate endpoint bug despite focused local tests.
- Analog `MTA-04` had hosted face-normal and coordinate-semantics surprises.
- Analog `MTA-10` had repeated hosted partial-output fix loops and performance diagnosis.
- Step 05 external challenge confirmed the core direction but added exact strength semantics, `actualIterations`, and early-convergence evidence.

### Predicted Estimate Notes

- Seed sections were refreshed before prediction because Step 05 changed task shape from internal-only kernel to public `edit_terrain_surface` operation mode.
- Validation risk is intentionally scored high because the closeout must prove both numerical behavior and SketchUp output coherence. Routine hosted matrix breadth alone would not justify this score, but the terrain analogs show live-only defects are plausible.
- Discovery risk is lower than the seed suspicion because the public API, algorithm, metric, refusal behavior, and output ownership decisions are now explicit.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- Public contract breadth is real: validator, loader schema, dispatcher, native fixtures, docs, examples, response evidence, and no-leak coverage must move together.
- Validation burden remains the dominant size driver because correctness must be proven across both numerical terrain behavior and SketchUp-hosted output lifecycle behavior.
- Prior analogs support the validation/rework posture:
  - `MTA-04` found hosted coordinate and face-normal issues.
  - `MTA-05` found a live adopted-coordinate endpoint tolerance bug.
  - `MTA-10` required repeated hosted partial-output fix loops and performance diagnosis.
- Step 11 premortem strengthened, rather than weakened, the predicted profile by adding guardrails for material-delta tolerance and neighborhood-context behavior.

### Contested Drivers

- Validation Burden Risk `4` could prove high if hosted fairing validation runs cleanly on the first pass. The score is retained because the plan requires output/undo/marker/normal/coordinate/performance proof and the closest terrain analogs had live-only defects.
- Rework Risk `3` could fall to `2` if `LocalFairingEdit` stays purely SketchUp-free and output handoff behaves exactly like prior kernels. The score is retained because the public contract plus numeric/kernel evidence plus MTA-10 dirty-window path creates several plausible revisit points.
- Dependency / Coordination Risk `3` depends on live SketchUp deployment and MTA-10 output behavior. If hosted partial/fallback evidence is unnecessary during implementation, this may be lower in actuals.

### Missing Evidence

- No implementation has yet proven that `mean_absolute_neighborhood_residual` behaves well on representative sloped-but-rough terrain.
- No hosted evidence yet proves fairing changed regions are safe inputs to partial output regeneration.
- No near-cap hosted timing exists for radius and iteration combinations.
- No public MCP example has yet confirmed that the final schema wording is understandable to callers.

### Recommendation

- Keep the predicted scores unchanged.
- Do not split the task before implementation; the plan already excludes brush/circle/polygon/detail-preserving/representation-v2 scope.
- Treat hosted validation, no-leak contract coverage, and residual metric tests as mandatory implementation closeout gates.
- Revisit actual validation burden and rework during closeout; these are the most likely dimensions to diverge from prediction.

### Challenge Notes

- The challenge confirms that high validation risk is evidence-backed by terrain analogs and required host-sensitive checks, not by routine hosted matrix breadth alone.
- The premortem did not surface unresolved Tigers, so finalization remains appropriate.
- No predicted score revisions are justified before implementation.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:public-contract`
- `systems:loader-schema`
- `systems:runtime-dispatch`
- `systems:command-layer`
- `validation:regression`
- `validation:contract`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:undo`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:native-fixture`
- `contract:response-shape`
- `contract:finite-options`
- `contract:docs-examples`
- `risk:performance-scaling`
- `risk:contract-drift`
- `risk:schema-requiredness`
- `risk:partial-state`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
