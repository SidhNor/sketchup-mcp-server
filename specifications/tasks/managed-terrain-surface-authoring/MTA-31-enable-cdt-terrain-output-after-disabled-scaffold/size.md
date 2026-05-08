# Size: MTA-31 Enable CDT Terrain Output After Disabled Scaffold

**Task ID**: MTA-31  
**Title**: Enable CDT Terrain Output After Disabled Scaffold  
**Status**: challenged  
**Created**: 2026-05-08  
**Last Updated**: 2026-05-08  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

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
| Functional Scope | Not filled yet. | Not filled yet. |
| Technical Change Surface | Not filled yet. | Not filled yet. |
| Actual Implementation Friction | Not filled yet. | Not filled yet. |
| Actual Validation Burden | Not filled yet. | Not filled yet. |
| Actual Dependency Drag | Not filled yet. | Not filled yet. |
| Actual Discovery Encountered | Not filled yet. | Not filled yet. |
| Actual Scope Volatility | Not filled yet. | Not filled yet. |
| Actual Rework | Not filled yet. | Not filled yet. |
| Final Confidence in Completeness | Not filled yet. | Not filled yet. |

### Actual Signals
- Not filled yet.

### Actual Notes
- Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Not filled yet.

### Hosted / Manual Validation
- Not filled yet.

### Performance Validation
- Not filled yet.

### Migration / Compatibility Validation
- Not filled yet.

### Operational / Rollout Validation
- Not filled yet.

### Validation Notes
- Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Not filled yet.
- **Most Overestimated Dimension**: Not filled yet.
- **Signal Present Early But Underweighted**: Not filled yet.
- **Genuinely Unknowable Factor**: Not filled yet.
- **Future Similar Tasks Should Assume**: Not filled yet.

### Calibration Notes
- Not filled yet.
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
- `systems:serialization`
- `validation:performance`
- `validation:hosted-matrix`
- `validation:undo`
- `validation:migration`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:undo-semantics`
<!-- SIZE:TAGS:END -->
