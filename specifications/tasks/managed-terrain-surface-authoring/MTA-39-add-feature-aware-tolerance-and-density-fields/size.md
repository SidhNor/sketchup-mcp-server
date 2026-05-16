# Size: MTA-39 Add Feature-Aware Tolerance And Density Fields

**Task ID**: MTA-39  
**Title**: Add Feature-Aware Tolerance And Density Fields  
**Status**: challenged  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-16  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-state`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:regression`
- **Likely Analog Class**: MTA-36 adaptive lifecycle plus MTA-20 feature intent and MTA-23 adaptive prototype context

### Identity Notes
- Seeded as the first behavior-changing feature-aware adaptive output task. It should keep current PatchLifecycle and dirty-window semantics.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | First visible feature-aware adaptive output behavior across feature families. |
| Technical Change Surface | 3 | Likely spans feature context, output planning, adaptive traversal/policy, diagnostics, and validation. |
| Hidden Complexity Suspicion | 2 | Main risk is policy-field integration, not topology ownership changes. |
| Validation Burden Suspicion | 3 | Requires hosted before/after timing, face count, dirty-window, and feature-locality evidence. |
| Dependency / Coordination Suspicion | 2 | Hard dependency on MTA-38; relies on existing feature-intent and MTA-36 lifecycle behavior. |
| Scope Volatility Suspicion | 2 | Tolerance and density are coupled, but exact policy boundaries may need planning refinement. |
| Confidence | 2 | Direction is clear; implementation surface and acceptable face-count tradeoffs need planning. |

### Early Signals
- Merges Slice 2 and Slice 3 because both feed adaptive subdivision policy.
- Must explain any face-count growth as local feature pressure, not global drift.
- No hard topology claim belongs in this task.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

| Dimension | Predicted (0-4) | Rationale |
|---|---:|---|
| Functional Scope | 3 | Adds the first production behavior-changing feature-aware adaptive output policy across local tolerance and density pressure. Public contracts stay stable, but output allocation changes across feature families. |
| Technical Change Surface | 3 | Likely touches feature planner wiring, a new output policy object, `TerrainOutputPlan`, compact diagnostics/replay evidence, contract guards, and mesh/lifecycle validation. |
| Implementation Friction Risk | 3 | The core algorithm is bounded, but integration must preserve dirty-window planning, policy determinism, fallback behavior, and no accidental MTA-40/MTA-41 semantics. |
| Validation Burden Risk | 3 | Requires automated policy/output/command/contract/lifecycle coverage plus a full MTA-38 hosted replay result pack with timing, face-count, patch-scope, and verdict interpretation. This is more than routine smoke, but not assumed to be repeated blocker-heavy validation. |
| Dependency / Coordination Risk | 2 | Depends on MTA-20 feature geometry, MTA-36 PatchLifecycle, and the MTA-38 reusable harness, but all are in-repo baselines and the plan avoids public contract coordination. |
| Discovery / Ambiguity Risk | 2 | Major design choices are resolved; remaining uncertainty is tactical tuning, exact fixture shape, hard-point representation details, and hosted timing interpretation. |
| Scope Volatility Risk | 2 | Scope is explicitly bounded to local tolerance and density fields, but tuning pressure or accidental topology expectations could push toward MTA-40/MTA-41 if not guarded. |
| Rework Risk | 3 | Rework risk is concentrated in policy constants, density locality, command feature-geometry wiring, and replay diagnostics if early implementation overfits unit tests or bloats face counts. |
| Confidence | 3 | Confidence is supported by current code inspection, architecture revalidation, calibrated analogs, resolved ambiguity, and a matrix-shaped test plan; hosted evidence remains the main uncertainty. |

### Top Assumptions

- Existing `TerrainFeatureGeometryBuilder` output is sufficient for local tolerance and density
  pressure without durable feature-geometry persistence.
- `TerrainOutputPlan` can consume a pure policy object inside the current full/dirty patch-domain
  planning scope without changing PatchLifecycle mutation semantics.
- Compact aggregate diagnostics are enough to explain hosted replay deltas without per-cell traces.
- The reusable MTA-38 harness can be reused for MTA-39 with a task-specific result pack rather than
  new hosted infrastructure.

### Estimate Breakers

- Feature geometry cannot be requested for adaptive output with CDT disabled without a larger command
  or runtime contract change.
- Density pressure causes unexplained global face growth or dirty-window expansion that requires a
  different locality model.
- PatchLifecycle registry/readback or no-delete behavior regresses under density-driven face-count
  changes.
- The MTA-38 harness cannot produce comparable MTA-39 full result packs without significant harness
  redesign.
- Hard/protected feature expectations leak into exact topology/refusal behavior, forcing MTA-40 scope
  into this task.

### Predicted Signals

- Positive: architecture mapping is narrow, Phase B/M1 slices 2 and 3 only.
- Positive: current code already has selected in-memory feature geometry, adaptive output planning,
  policy diagnostics, and hosted replay scaffolding.
- Caution: MTA-36 and MTA-38 analogs both showed high validation sensitivity and hosted evidence
  interpretation cost.
- Caution: MTA-23 prototype constants are useful but cannot be copied as production guarantees.
- Caution: no public contract delta is expected, so any diagnostic leak is a regression.

### Predicted Estimate Notes

- Planning refinement rebaselined the task around a separate pure policy object, no runtime gate,
  no separate `policyVersion`, compact diagnostics, and a full MTA-38 harness result pack.
- Validation burden is scored high because of required performance/locality/lifecycle interpretation,
  not because hosted SketchUp validation is unusual by itself.
- Rework risk is higher than discovery risk: the architecture is now clear, but implementation may
  need tuning if density pressure or diagnostics have broader effects than expected.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

### Challenge Evidence

- Step 12 premortem challenged the draft plan from failure-analysis, host-runtime, public-contract,
  and downstream-scope perspectives.
- External critique with `grok-4.3` identified three material risks: MTA-38 result-pack adequacy for
  deterministic policy evidence, partial feature-geometry availability, and public diagnostic leaks
  before hosted replay.
- The plan was revised before finalization to add compact feature-geometry coverage/fallback counts,
  repeated-input policy fingerprint stability, fallback row classification, and no-leak coverage
  before hosted capture.

### Contested Drivers

- **Validation Burden Risk** remains the most contested driver. The full MTA-38 hosted result pack is
  routine in the sense that the harness exists, but result interpretation is non-trivial because it
  must explain timing, face-count locality, fallback rows, dirty scope, and lifecycle outcomes.
- **Rework Risk** remains elevated because tuning and locality failures are more likely to require
  revisiting completed policy/output-plan slices than to require new discovery.
- **Dependency / Coordination Risk** stays moderate rather than high because the harness and upstream
  feature/PatchLifecycle substrates already exist in-repo.

### Missing Evidence

- No MTA-39 hosted result pack exists yet.
- Exact feature-geometry fixture shape and final policy test filenames will be chosen during
  implementation.
- Performance impact is still predicted from architecture and analogs, not measured for MTA-39.

### Score Review

- No predicted score changes after challenge.
- Functional Scope `3`, Technical Change Surface `3`, Implementation Friction Risk `3`,
  Validation Burden Risk `3`, and Rework Risk `3` remain justified by the finalized plan and analog
  evidence.
- Dependency / Coordination Risk `2`, Discovery / Ambiguity Risk `2`, Scope Volatility Risk `2`,
  and Confidence `3` remain justified because major design choices are resolved and the remaining
  uncertainty is validation/tuning rather than task-shape ambiguity.

### Recommendation

Proceed with implementation using the finalized plan. Treat any public response leak, unexplained
global face growth, dirty-scope expansion, missing full result pack, or inability to classify
fallback rows as estimate breakers that should trigger drift review during implementation.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

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
- `systems:terrain-state`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:validation-service`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:regression`
- `host:routine-matrix`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `volatility:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
