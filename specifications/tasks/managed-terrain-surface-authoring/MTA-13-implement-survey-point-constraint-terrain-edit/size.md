# Size: MTA-13 Implement Survey Point Constraint Terrain Edit

**Task ID**: `MTA-13`  
**Title**: Implement Survey Point Constraint Terrain Edit  
**Status**: `completed`  
**Created**: 2026-04-26  
**Last Updated**: 2026-04-27  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: managed terrain survey correction fields
- **Likely Systems Touched**:
  - public `edit_terrain_surface` contract
  - terrain command layer
  - terrain edit kernels
  - terrain state and storage
  - fixed-control and preserve-zone handling
  - terrain evidence
  - terrain output planning
  - native loader schema and contract fixtures
  - README terrain examples
- **Validation Modes**: contract, hosted-matrix, performance, persistence, undo, regression
- **Likely Analog Class**: constraint-heavy terrain edit kernel

### Identity Notes
- This is a new public terrain edit mode with numerical constraint behavior and an explicit local/regional correction-field distinction. The closest analogs are `MTA-04`, `MTA-05`, `MTA-10`, `MTA-12`, and completed `MTA-14`, with additional split pressure from possible localized-detail needs captured in deferred `MTA-11`.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Adds survey-driven terrain authoring for both isolated local point correction and bounded regional grade-field adjustment. |
| Technical Change Surface | 4 | Likely touches public contract, command dispatch, numerical correction-field behavior, MTA-14 solver promotion, fairing-style smoothing, evidence, output planning, docs, fixtures, and hosted validation. |
| Hidden Complexity Suspicion | 4 | Constraint solving, local/regional support semantics, tolerances, grid-resolution limits, preserve conflicts, detail recomposition, and smoothing without survey drift are all sensitive. |
| Validation Burden Suspicion | 4 | Needs numerical, contract, regression, hosted-origin, undo/output, performance, repeated-edit, and representational-limit validation. |
| Dependency / Coordination Suspicion | 4 | Depends on MTA-06, MTA-12, and completed MTA-14; may feed MTA-11 if v1 grid fidelity or regional correction-field behavior is insufficient. |
| Scope Volatility Suspicion | 4 | Scope can expand if regional correction requires broader optimization, if contract vocabulary drifts, or if v1 heightmap detail preservation proves insufficient. |
| Confidence | 2 | Product need is clear, but exact solver and refusal boundary are not planned yet. |

### Early Signals
- User clarified that points are survey constraints with small tolerances, not loose hints.
- User clarified that MTA-13 must distinguish isolated local correction from bounded regional/global survey adjustment, including cross-fall and multi-plane grade-field workflows.
- Current `FixedControlEvaluator` already proves bilinear point evaluation exists, but it only preserves points rather than solving toward target survey elevations.
- MTA-06 provides local fairing and neighborhood smoothing behavior that can inform correction-field regularization, but it is not itself a survey constraint solver.
- MTA-14 completed base/detail evaluation and provides reusable solver ingredients, metrics, and refusal cases, but it did not implement broad regional support scopes.
- Localized survey/detail zones are explicitly deferred unless v1 heightmap evidence proves insufficient.
- Step 05 refinement selected an additive contract shape: `operation.mode: "survey_point_constraint"`, `operation.correctionScope: "local" | "regional"`, and `constraints.surveyPoints`, with existing `region` reused as correction support geometry.

### Early Estimate Notes
- Seed was refreshed during planning because Step 05 expanded the task from a point constraint edit into a local plus bounded regional correction-field task. Seed uses MTA-04, MTA-05, MTA-10, MTA-12, and MTA-14 as analogs, with high suspicion because this task combines public contract expansion, numerical constraint satisfaction, detail-preserving correction, regional support semantics, and hosted proof.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Adds a new public survey edit workflow with both isolated local correction and bounded regional grade-field adjustment. |
| Technical Change Surface | 4 | Touches public contract, native schema, dispatcher, terrain-domain solver, evidence, state save, output planning/regeneration, docs, fixtures, and hosted validation. |
| Implementation Friction Risk | 4 | Regional fair/project correction, survey projection after smoothing, MTA-14 primitive promotion, and protection constraints create substantial implementation resistance. |
| Validation Burden Risk | 4 | Requires contract, terrain-domain, command/evidence, hosted public MCP, undo, persistence, and performance-sensitive regional validation. |
| Dependency / Coordination Risk | 3 | Depends on MTA-06, MTA-12, MTA-14, hosted SketchUp MCP access, and MTA-10 output/performance assumptions, but remains within owned terrain runtime. |
| Discovery / Ambiguity Risk | 3 | The public contract is settled, but regional correction thresholds, coherent-field criteria, and fair/project parameter defaults still need proof in fixtures. |
| Scope Volatility Risk | 3 | Regional support could narrow, split, or escalate to MTA-11 if v1 heightmap behavior cannot satisfy representative fixtures safely. |
| Rework Risk | 3 | High chance of revisiting solver/evidence thresholds after regional fixtures or hosted validation, but phased contract-first work contains rollback cost. |
| Confidence | 3 | Plan is detailed, premortem-tested, externally reviewed, and contract/solver boundaries are now explicit; regional production and hosted evidence remain unproven. |

### Top Assumptions
- The MTA-14 interpolation, minimum-norm projection, base/detail, mask, metric, and refusal ideas can be promoted into production terrain-domain code without relying on `test/support`.
- Local-fairing-style neighborhood averaging is sufficient regularization for the first bounded regional correction-field implementation.
- Existing rectangle/circle `region` plus `blend` can express local and bounded regional support without adding a new top-level support object.
- Hosted output regeneration, undo, and target resolution behave like the MTA-10-corrected terrain edit path for larger regional changed regions.
- The first implementation can refuse unsafe regional cases rather than solving them through a full constrained optimization model.

### Estimate Breakers
- Regional fixtures show fair/project correction still behaves like isolated point pockets or creates unacceptable humps, trenches, rings, or slope breaks.
- Final residuals cannot stay within tolerance after smoothing and residual-detail recomposition without a stronger optimization solver.
- Preserve-zone or fixed-control projection interactions require a more complex constrained solve than planned.
- Hosted validation exposes output, undo, or performance behavior worse than MTA-10 analogs for regional edits.
- Public contract review rejects `constraints.surveyPoints` or `operation.correctionScope`, forcing a schema redesign after implementation starts.

### Predicted Signals
- Public contract expands in a high-risk tool surface with finite mode, schema, docs, fixtures, dispatcher, and response-shape updates.
- The task includes two user-visible correction scopes under one operation mode.
- Regional correction depends on numerical behavior not yet implemented in production, despite strong MTA-14 local/base-detail evidence.
- Prior terrain tasks found live-host issues after local tests passed, especially output regeneration, undo, coordinate semantics, and performance.
- The plan intentionally keeps solver knobs internal, increasing implementation responsibility for defaults and refusal thresholds.

### Predicted Estimate Notes
- This predicted profile is the current planning baseline after Step 05 expanded the task from survey point constraints into local plus bounded regional correction fields. `MTA-04`, `MTA-10`, and `MTA-14` are the strongest outside-view analogs: they lower uncertainty around existing terrain flow and MTA-14 primitives, but they raise validation and rework expectations for hosted output, regional performance, and solver correctness.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Public contract scope is materially broad: existing `edit_terrain_surface` gains `survey_point_constraint`, `operation.correctionScope`, `constraints.surveyPoints`, schema updates, fixtures, dispatcher routing, docs, and response evidence.
- Regional success requires coherent correction-field proof on cross-fall and multi-plane fixtures, not only per-point residual satisfaction.
- Validation burden remains very high because correctness spans contract tests, terrain-domain numerical tests, command/evidence tests, no-leak tests, hosted MCP validation, undo, persistence, output regeneration, and performance-sensitive regional behavior.
- MTA-14 reduces algorithm discovery risk by proving interpolation/stencils, minimum-norm projection, base/detail split, detail masks, metrics, refusals, and repeated workflow concepts, but it does not remove production integration or hosted validation risk.
- Premortem found no unresolved Tiger-class blockers after fixing public evidence naming to `evidence.survey` and tightening the no-`global` scope guardrail.

### Contested Drivers
- Implementation Friction Risk: `4` is conservative. External `grok-4.20` review argued `3` because MTA-14 and local-fairing analogs reduce raw numerical risk; the score remains `4` because production integration still combines correction-field construction, preserve/fixed constraints, refusal ordering, detail recomposition, and post-save prevention.
- Discovery / Ambiguity Risk: external review argued `2` because the public contract and solver family are now fixed. The score remains `3` because exact coherent-field metrics, threshold constants, and hosted regional performance behavior are still unproven.
- Confidence: raised from `2` to `3` after premortem plus `grok-4.20` review found no blockers and confirmed the plan is implementation-ready, while still preserving explicit missing evidence.

### Missing Evidence
- Kernel fixture results for regional cross-fall and multi-plane cases showing a measurable coherent-field proxy, not only satisfied survey residuals.
- Threshold evidence for acceptable max sample delta, slope/curvature proxy increase, residual detail retention/suppression, and unsafe-regional refusal.
- Hosted MCP timing, changed-sample counts, output regeneration behavior, undo behavior, and persistence proof for a realistic regional support case at target resolution.
- Confirmation during implementation that promoted MTA-14 primitives live under `src/su_mcp/terrain/` and do not import `test/support` code.
- No-leak response tests proving `evidence.survey`, `evidence.survey.points`, and `evidence.survey.correction` do not expose solver internals, MTA-14 strategy names, output-plan internals, generated face IDs, or generated vertex IDs.

### Recommendation
- Proceed with the current implementation plan and keep the predicted risk profile unchanged except for Confidence `2 -> 3`.
- Do not split the task before implementation; instead, treat regional coherent-field fixtures and hosted performance as the first material drift gates.
- If regional fixtures require a stronger optimizer, more than fixed bounded passes, public solver knobs, or localized detail zones, record size drift and revise or escalate to `MTA-11`.

### Challenge Notes
- External `grok-4.20` review on 2026-04-27 found no blocking findings and considered the plan implementation-ready.
- The review introduced one implementation-facing refinement: define deterministic coherent-field metrics for regional tests, such as correction-field gradient/curvature or equivalent support-region smoothness checks.
- Hosted validation burden remains high for reasons beyond routine matrix breadth: performance sensitivity, undo, persistence, output regeneration, and interpretation of regional numerical evidence.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

- 2026-04-27: Implementation split `SurveyPointConstraintEdit` into focused production collaborators after review of excessive RuboCop disables. This improved maintainability without changing public contract or solver behavior.
- 2026-04-27: Hosted public MCP validation expanded from routine contract checks to larger regional performance fixtures. The broader validation increased evidence quality but did not require implementation changes.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Actual scope matched the challenged forecast: public local survey correction and bounded regional survey correction shipped under one existing MCP tool. |
| Technical Change Surface | 4 | Touched request validation, native schema, dispatcher, terrain-domain solvers, evidence, docs, fixtures, RuboCop config, and task metadata. |
| Implementation Friction | 3 | Solver promotion and regional support were substantial, but MTA-14 evidence and existing terrain edit flows kept the implementation controlled. |
| Validation Burden | 4 | Required automated contract/kernel/evidence coverage plus hosted public MCP validation for targeting, transforms, regions, constraints, output sanity, and performance. |
| Dependency / Coordination | 3 | Depended on MTA-06, MTA-12, MTA-14, and hosted MCP access, but no cross-repo or external service dependency was introduced. |
| Discovery / Ambiguity | 2 | Contract and behavior clarified during planning; hosted validation added precedence/safety-gate clarifications but no redesign. |
| Scope Volatility | 2 | The implementation stayed within the planned local/regional contract and did not escalate to localized detail zones or public solver knobs. |
| Rework | 1 | Post-implementation review changed code organization for lint/maintainability, but hosted deployment and verification required no implementation changes. |
| Confidence | 4 | Automated tests, final code review, and broad hosted public MCP checks all passed, including complex `100x100` regional validation. |

### Actual Notes

- The public contract shape selected during planning held: `operation.mode: "survey_point_constraint"`, `operation.correctionScope`, and `constraints.surveyPoints`.
- The MTA-14 base/detail solver was promoted into production terrain-domain code and remained isolated from `test/support`.
- Regional correction stayed bounded and explicit, with no need for localized detail zones or a stronger optimizer in this slice.
- The first hosted deployment validation passed without requiring implementation changes.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Focused public MCP/terrain suite: 130 runs, 924 assertions, 0 failures, 31 skips.
- Full Ruby test suite: 783 runs, 3884 assertions, 0 failures, 36 skips.
- Ruby lint: 204 files inspected, no offenses.
- Package verification: produced `dist/su_mcp-0.25.0.rbz`.
- Final PAL/Grok-4.20 review after refactor: no critical, high, or required medium findings.
- Hosted public MCP validation passed for local edit, repeated corrected edit, regional multi-point edit, invalid/missing inputs, out-of-bounds, outside support, contradictory points, duplicate identical points, preserve-zone conflict, fixed-control conflict, unsafe regional distortion, excessive delta, no-leak evidence, `persistentId` targeting, invalid target handling, transformed owner placement, circle support, blend shoulder support, off-grid bilinear points, boundary points, tiny tolerance, fixed controls inside regional support, preserve-near-influence, sample evidence, and output sanity.
- Performance validation passed on `80x80` regional support: edit wall time `0.666s`, `2809` changed samples, all residuals `0.0`, evidence capped at `20`, digest matched state, runtime ping passed.
- Complex hosted regional validation passed on `100x100` varied terrain: edit wall time `1.48s`, `6552` changed samples, eight residuals `0.0`, preserve drift `0.0`, regional coherence satisfied, evidence capped at `25`, runtime ping passed, all faces/edges marked derived, and no normal issues.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Delta Summary

- Predicted risk was directionally correct: public contract breadth, regional validation, evidence no-leak behavior, and hosted performance were the main risks.
- Actual implementation friction was lower than predicted because MTA-14 was strong enough to promote directly for the local solver and existing terrain edit/storage/output flows handled the new mode cleanly.
- Actual validation burden remained high, but the extra hosted checks increased confidence rather than creating rework.
- No post-deploy implementation changes were needed after hosted public MCP validation.

### Calibration Takeaways

- MTA-14-style solver research materially reduced MTA-13 implementation risk and should be counted as a strong risk reducer when the spike includes reusable code shape, thresholds, refusal taxonomy, and oracle tests.
- A public MCP contract expansion can still be high-surface without high rework when validator, loader schema, command routing, evidence builder, fixture, and README updates are kept synchronized.
- Hosted performance risk was overestimated for clean scenes up to the tested `100x100` varied terrain case; full mesh regeneration plus bounded evidence stayed interactive.
- The maintainability issue was not algorithmic correctness but production code shape. Future estimates should include explicit refactor budget when a numerical kernel is promoted from an evaluation harness.

### Updated Estimate Bias

- For similar terrain-domain tasks with completed solver research and existing command/output plumbing, keep validation burden high but reduce implementation-friction and rework assumptions by one level unless new persisted schema or new geometry ownership rules are introduced.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:public-contract`
- `systems:command-layer`
- `systems:terrain-kernel`
- `systems:terrain-state`
- `systems:terrain-storage`
- `systems:terrain-output`
- `systems:native-contract-fixtures`
- `systems:docs`
- `validation:contract`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `validation:undo`
- `validation:regression`
- `host:routine-matrix`
- `host:undo`
- `host:performance`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:native-fixture`
- `contract:response-shape`
- `contract:docs-examples`
- `contract:finite-options`
- `risk:contract-drift`
- `risk:partial-state`
- `risk:performance-scaling`
- `risk:schema-requiredness`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:high`
<!-- SIZE:TAGS:END -->
