# Size: MTA-31 Enable CDT Terrain Output After Disabled Scaffold

**Task ID**: MTA-31
**Title**: Enable CDT Terrain Output After Disabled Scaffold
**Status**: calibrated
**Created**: 2026-05-08
**Last Updated**: 2026-05-09
**Related Task**: [task.md](./task.md)
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-state`
  - `systems:terrain-kernel`
  - `systems:scene-mutation`
- **Validation Modes**:
  - `validation:performance`
  - `validation:hosted-matrix`
  - `validation:undo`
- **Likely Analog Class**: production-enablement-after-disabled-performance-scaffold

### Identity Notes
- Seeded from the MTA-31 task, the managed terrain HLD, MTA-25 closeout findings, and Step 06 refinement. The dominant shape is CDT enablement gated by performance, containment, materialized feature-intent state, internal schema migration, undo/branch safety, and hosted SketchUp evidence while preserving current backend defaults.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Enables consideration of a new production terrain output path across create/edit flows, though public MCP responses and defaults stay stable until evidence passes. |
| Technical Change Surface | 4 | Likely spans CDT structural cleanup, internal feature-intent schema migration, materialized effective-state/index maintenance, CDT input planning, triangulation adapter posture, profiling, fallback, and SketchUp mutation safety. |
| Hidden Complexity Suspicion | 4 | MTA-25 live validation already exposed minute-scale hangs, accumulated intent semantics, boundary containment, undo/branch sensitivity, and Ruby-versus-native uncertainty. |
| Validation Burden Suspicion | 4 | Requires performance budgets, representative large-history fixtures, topology/residual/containment checks, stale-index/migration checks, fallback checks, undo/save-copy evidence, and hosted SketchUp acceptance. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-20 feature constraints, MTA-24 CDT prototype evidence, MTA-25 scaffold behavior, MTA-26 target-height path settling, and a native/C++ adapter decision path. |
| Scope Volatility Suspicion | 4 | The task may need to split if Ruby CDT cannot approach the responsiveness target, native adapter packaging becomes required, dirty-region CDT becomes mandatory, or feature-history semantics exceed the enablement slice. |
| Confidence | 3 | Step 06 research and consensus clarified the implementation shape, but production performance, hosted undo behavior, and native/dirty-region split evidence remain unproven. |

### Early Signals
- MTA-25 closed with CDT disabled by default after live validation found unacceptable edit latency on representative terrain histories.
- The task intentionally preserves current backend defaults and public contract stability while enablement evidence is gathered.
- Feature-intent override, deprecation, replacement, merge, relevance, undo/branch behavior, and boundary containment semantics are all listed as enablement gates.
- Step 06 refinement resolved the feature-intent direction as an internal materialized effective layer with a minimal derived index, plus no normal-path full-history replay.
- The work is explicitly split into a behavior-preserving CDT structural queue followed by semantic/performance enablement.
- Native triangulation is an explicit decision path, not a preselected implementation.

### Early Estimate Notes
- This is a high-risk enablement task rather than a routine backend toggle. Seed scores now reflect Step 06 research, but predicted sizing should still wait for the finalized technical plan, premortem, fixture strategy, and native/dirty-region evidence gates.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Internally enables a new terrain output path across create/edit flows and must prove undo, fallback, performance, and native posture, though public contract and default backend stay stable. |
| Technical Change Surface | 4 | Plan spans CDT structural ownership, feature-intent schema/migration, merge lifecycle, effective index validation, geometry selection, primitive containment, residual CDT instrumentation, fallback/no-leak, and hosted validation seams. |
| Implementation Friction Risk | 4 | Merge-time lifecycle/index semantics, no-full-history runtime path, conservative containment, rollback safety, and Ruby budget checkpoints all create meaningful engineering resistance. |
| Validation Burden Risk | 4 | Requires two test queues, migration/index/digest tests, large-history performance fixtures, containment matrix, no-leak/contract checks, rollback/undo evidence, and hosted SketchUp validation. |
| Dependency / Coordination Risk | 3 | Depends on MTA-20/MTA-24/MTA-25 behavior, MTA-26 target-height path settling for fixture refresh, and SketchUp hosted runtime evidence. Native binaries are not required. |
| Discovery / Ambiguity Risk | 3 | Step 06 resolved core architecture, but actual bottleneck attribution, hosted rollback semantics, and Ruby-vs-native decision remain evidence-gated. |
| Scope Volatility Risk | 4 | Task may split if profiling proves dirty-region CDT, native triangulation, residual redesign, or SketchUp mutation work is required before useful CDT enablement. |
| Rework Risk | 4 | Closest analogs had high rework from hosted evidence and production-readiness gaps; dual-authority index drift, supersession overreach, and containment mistakes could force cross-module corrections. |
| Confidence | 3 | Plan and consensus provide a stable implementation shape, but performance, hosted rollback, and fixture evidence remain unproven until execution. |

### Top Assumptions
- Queue A structural cleanup can be kept behavior-preserving and verified before semantic changes.
- Minimal hybrid lifecycle plus derived `effectiveIndex` is sufficient to avoid normal-path full-history replay without needing dirty-region CDT in the first pass.
- Legacy feature-intent payloads can be migrated internally without public MCP contract changes.
- Hosted SketchUp operation semantics will allow serialized state and visible output rollback to be proven or corrected within MTA-31.
- A deterministic large-history fixture/generator can substitute for the original MTA-25 live scene if that scene is unavailable or stale after MTA-26.

### Estimate Breakers
- Profiling shows residual scans, triangulation, or SketchUp mutation still cause minute-scale hangs after effective filtering and containment.
- Hosted rollback proves attribute state and derived geometry do not undo together under current save/output ordering.
- Effective-index validation still causes fallback storms despite `effectiveRevision` and query-driving digest narrowing.
- Pre-triangulation cardinality gates still allow expensive residual/triangulation/SketchUp work to start on representative large-history inputs.
- Target-height/MTA-26 changes alter fixture shape enough to require broader edit-kernel or UI integration work.
- Native/C++ packaging becomes required to produce any useful CDT evidence rather than a follow-up decision.

### Predicted Signals
- MTA-25 actuals showed high technical surface, friction, validation, discovery, volatility, and rework for the disabled scaffold.
- MTA-24 hosted evidence required repeated fix/reload/redeploy/rerun loops before CDT conclusions were credible.
- Current implementation derives geometry from every persisted feature and lacks active/effective filtering.
- Current runtime budget reports elapsed time after work rather than preempting expensive phases.
- Step 06 consensus resolved architecture but intentionally carried performance/native and hosted rollback gates.

### Predicted Estimate Notes
- Predicted profile is based on the finalized plan after Step 12 premortem. The estimate treats sub-3 seconds as a target and decision signal, not a hard pass/fail gate.
- Functional scope remains `3` because public behavior/defaults do not change, but the internal enablement surface is broad and user-impacting.
- Validation and rework are `4` by outside-view evidence from MTA-24/MTA-25 plus the hosted rollback, undo, performance, and no-leak matrix required here.
- Confidence is medium: core design choices are now explicit, but the decisive runtime and hosted evidence cannot be known until implementation.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- MTA-25 remains the closest analog and supports high technical surface, friction, validation, discovery, volatility, and rework risk.
- The plan touches multiple hard seams: structural CDT ownership, internal state schema/migration, feature lifecycle/index semantics, CDT primitive containment, residual CDT instrumentation, fallback/no-leak behavior, and hosted SketchUp validation.
- Validation burden is legitimately `4`, not from routine hosted breadth alone, but from performance profiling, undo/rollback, migration/index integrity, containment, no-leak, and representative large-history evidence.
- Scope volatility remains `4` because profiling may force dirty-region CDT, native triangulation, residual-scan redesign, or a decision to keep CDT disabled.

### Contested Drivers
- Hybrid lifecycle plus `effectiveIndex` could be seen as over-engineered, but consensus and premortem favored a minimal index because inline-only risks a later query-layer rewrite for large histories.
- `Confidence` could be argued down to `2` because runtime and hosted evidence remain unproven; kept at `3` because Step 06 consensus and Step 12 premortem now define concrete mitigations and gates.
- Dependency risk could be argued as `4` if MTA-26 changes fixture semantics materially or hosted rollback breaks operation ordering; kept at `3` because native binaries and public contract changes are explicitly out of scope.

### Missing Evidence
- Hosted proof that attribute dictionary state and derived output rollback together after refusal/fallback/exception.
- Representative large-history fixture/generator evidence with documented terrain size, feature distribution, hard/firm/soft mix, relevance windows, and cardinality pressure.
- Profiling evidence after effective filtering, containment, and pre-triangulation cardinality gates.
- Evidence that `effectiveRevision` and query-driving digest inputs avoid stale-index fallback storms.
- Ruby-vs-native decision evidence from phase timings and cardinalities.

### Recommendation
- Confirm the predicted profile with no score changes. Treat the task as high-risk but bounded for implementation because the final plan now contains specific guardrails for the two premortem Tigers: pre-triangulation cardinality fallback and digest validation that excludes audit-only revision churn.
- Do not split before implementation. Split only if profiling proves dirty-region CDT, native triangulation, residual redesign, or SketchUp mutation work is required to produce useful CDT evidence.

### Challenge Notes
- Controlled Step 06 consensus used `grok-4.3`, `gpt-5.4`, and `grok-4.20` with different stances. The main disagreement was inline-only versus hybrid state/index; final mediation kept a minimal hybrid index with authoritative inline lifecycle fields.
- Step 12 premortem identified two Tigers: residual/triangulation work could still dominate after effective filtering, and digest validation could cause fallback storms. The finalized plan mitigates these with pre-triangulation cardinality gates and `effectiveRevision` plus narrowed digest inputs.
- No predicted score changed after challenge. The challenge increased plan precision but confirmed the original high-risk shape.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|

### Drift Notes
- No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Internal CDT enablement foundation changed materially, but public behavior and default backend stayed stable. |
| Technical Change Surface | 4 | Touched CDT output structure, feature-intent schema/indexing, merge lifecycle, planner/view selection, command edit windows, backend containment/budgets, residual probes, storage/serializer tests, and hosted validation seams. |
| Actual Implementation Friction | 4 | Work was dominated by hidden coupling between feature history, edit windows, CDT primitive budgets, residual policy, and hosted runtime behavior. The `SampleWindow` selection bug and residual bottleneck attribution required extra implementation and probe loops. |
| Actual Validation Burden | 4 | Validation required full terrain regression, lint/package checks, required `grok-4.3` review, deployed SketchUp hosted matrix, special side-copy harness setup, live patch verification, and performance probes that exposed a nonviable runtime path. |
| Actual Dependency Drag | 3 | Flow depended on MTA-24/MTA-25 architecture history, deployed SketchUp access, representative hosted scene state, side-copy repository saves, and external research review, but no native binary or public contract dependency blocked closeout. |
| Actual Discovery Encountered | 4 | The task became evidence-heavy: effective selection was wired but initially ineffective for `SampleWindow`, Ruby residual refinement dominated runtime, feature constraints multiplied cost, and the external review shifted the follow-up direction toward dirty/local residual strategy. |
| Actual Scope Volatility | 4 | The task closed as an evidence/recalibration milestone rather than default enablement. Performance evidence forced follow-up rearchitecture instead of continuing a mechanical enablement pass. |
| Actual Rework | 3 | Review follow-up and hosted findings caused targeted rework in effective-index validation, lifecycle defaults, native-unavailable regression, command window handling, residual probes, and builder fallback. The main architecture was not rewritten inside MTA-31. |
| Final Confidence in Completeness | 3 | Strong confidence that MTA-31 evidence and internal foundations are complete; moderate confidence only for production enablement because undo/save-reopen acceptance and sub-3-second CDT edits remain follow-up work. |

### Actual Signals
- Full terrain suite stayed green after the final builder fallback hardening:
  `585 runs, 9277 assertions, 0 failures, 3 skips`.
- Hosted real CDT P1 completed visually but took roughly 9 minutes on the
  representative terrain with `204` feature intents.
- Hosted small-terrain probes isolated the bottleneck to residual refinement and
  repeated Ruby retriangulation, not effective feature selection or SketchUp
  face emission.
- Effective view selection had a real host-shape defect: `SampleWindow` failed
  open until fixed, selecting all `204` active features instead of `123`.
- External review supported keeping CDT as a topology primitive but changing the
  residual strategy before any default enablement attempt.

### Actual Notes
- The predicted high-risk profile was directionally correct. The biggest actual
  lesson is that bounded feature selection is necessary but insufficient: the
  current global residual/retriangulation policy can still miss interactive
  budgets by orders of magnitude.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused affected regression: `123 runs, 671 assertions, 0 failures, 0 errors,
  0 skips`.
- Full terrain suite: `585 runs, 9277 assertions, 0 failures, 0 errors, 3 skips`.
- Package-support smoke: `14 runs, 85 assertions, 0 failures, 0 errors, 0 skips`.
- Targeted RuboCop: `31 files inspected, no offenses detected`.
- `git diff --check`: clean.

### Hosted / Manual Validation
- Hosted matrix ran on deployed SketchUp scene `TestGround` against
  `option-terrain-north-terrace-west-threshold-amendment-semantic-edit-v1`.
- P1 real CDT target-height path completed and emitted `5,379` derived CDT faces,
  but took roughly 9 minutes.
- P2 fast accepted corridor seam, N1 native-unavailable fallback, N2 unsupported
  option refusal, and E1-E4 hard/firm/soft/budget edge probes passed.
- Hosted visual confirmation exists for P1 topology, but repeated undo/new-edit
  branch behavior and save/reopen acceptance remain follow-up gaps.

### Performance Validation
- Representative P1 hosted edit missed the intended responsiveness target by a
  large margin: roughly 9 minutes.
- Small 31x31 hosted probe with 10 seeded edits: real CDT command about
  `4085ms`; planner/effective view/geometry build `5.49ms`; backend `3969ms`;
  residual refinement `3521ms`.
- Residual disabled path ran about `136ms` but produced unacceptable quality
  with max height error `1.1256`.
- Detailed residual probes showed scan time around `0.33s-0.46s`, while repeated
  late Ruby retriangulations dominated total runtime.

### Migration / Compatibility Validation
- Feature-intent normalization, serializer, and tiled-state tests cover legacy
  active lifecycle defaults, new field round-tripping, effective index digest
  stability under audit-only churn, and digest changes for query-driving
  lifecycle changes.
- Public MCP response shape and default backend remained unchanged.

### Operational / Rollout Validation
- CDT remains internal/test gated and disabled by default.
- No public backend selector, public CDT diagnostics, setup path, or user-facing
  workflow changed; no user-facing doc update was required.
- Native/C++ packaging was not introduced; adapter posture and native-unavailable
  fallback behavior were preserved.

### Validation Notes
- Hosted validation was high burden because it required special side-copy setup,
  repository-save correction after integrity refusal, transform-signature
  handling, performance probes, live patch verification, and interpretation of a
  nonviable runtime path. This was not a routine clean hosted matrix.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Discovery/ambiguity. The plan expected
  profiling uncertainty, but not the degree to which the task would become a
  residual-policy investigation and external-review recalibration.
- **Most Overestimated Dimension**: Native dependency. The native adapter path
  remained important, but closeout did not require native binaries or packaging;
  the immediate blocker is residual strategy and locality, not only raw
  triangulation implementation language.
- **Signal Present Early But Underweighted**: MTA-25 minute-scale hang and global
  residual refinement should have been treated as a conceptual-risk signal, not
  merely a Ruby performance-risk signal.
- **Genuinely Unknowable Factor**: The `SampleWindow` versus hash-window mismatch
  in live command selection and the exact residual/retriangulation timing split
  required hosted execution and instrumentation.
- **Future Similar Tasks Should Assume**: A disabled performance scaffold is not
  ready to default-enable until hosted probes prove locality, residual policy,
  mutation cost, and quality budgets together. Effective filtering alone does not
  prove interactive behavior.

### Calibration Notes
- Dominant actual failure mode: performance-scaling from global residual
  refinement and repeated full Ruby retriangulation on growing point sets.
- Future analog retrieval should prioritize performance-sensitive managed
  terrain output tasks with hosted special-scene matrices, residual/triangulation
  bottleneck attribution, no public contract change, and high scope volatility.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Keep this as a compact analog-search index, not coverage. Target 8-14 tags.

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-state`
- `validation:performance`
- `validation:hosted-matrix`
- `validation:undo`
- `host:special-scene`
- `host:repeated-fix-loop`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `volatility:high`
- `friction:high`
<!-- SIZE:TAGS:END -->
