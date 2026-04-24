# Size: SVR-04 Add Terrain-Aware Measurement Evidence

**Task ID**: SVR-04  
**Title**: Add Terrain-Aware Measurement Evidence  
**Status**: calibrated  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-24  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: validation-heavy feature
- **Primary Scope Area**: scene validation and review measurement evidence
- **Likely Systems Touched**:
  - `measure_scene` command and measurement helpers
  - terrain profile or section sampling evidence
  - runtime-facing JSON-safe measurement serialization
- **Validation Class**: mixed
- **Likely Analog Class**: bounded measurement evidence follow-on

### Identity Notes
- Task-level evidence points to a bounded terrain-aware measurement slice that follows `SVR-03` and consumes `STI-03` evidence without becoming validation diagnostics.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds a moderate public measurement evidence extension while staying below terrain diagnostics or authoring. |
| Technical Change Surface | 2 | Likely touches measurement command/helper seams, profile evidence consumption, and result serialization. |
| Hidden Complexity Suspicion | 2 | Terrain evidence may expose unit, derivation, and upstream sampling-contract details not visible from `task.md` alone. |
| Validation Burden Suspicion | 2 | Evidence outputs need checks for quantities, units, derivation evidence, and the no-verdict boundary. |
| Dependency / Coordination Suspicion | 2 | Explicitly depends on settled `SVR-03` and `STI-03` contracts. |
| Scope Volatility Suspicion | 2 | Exact mode and kind names are intentionally deferred until upstream evidence contracts are settled. |
| Confidence | 2 | The task is well framed, but this seed intentionally uses only `task.md` evidence. |

### Early Signals
- The task extends a public measurement surface but constrains it to compact evidence rather than pass/fail verdicts.
- Dependencies on `SVR-03` and `STI-03` are first-class and shape the eventual enum and evidence contract.
- Technical constraints emphasize Ruby-owned execution and JSON-safe outputs.

### Early Estimate Notes
- Initial shape is moderate and bounded, with uncertainty concentrated in terrain evidence semantics and validation coverage.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Retroactive simulated prediction. Evidence is limited to `task.md` and `plan.md`; implementation `summary.md` was not used.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | One new bounded `measure_scene` mode/kind adds terrain elevation evidence while explicitly excluding diagnostics, verdicts, comparison, and editing. |
| Technical Change Surface | 3 | Plan calls for request validation, runtime command routing, measurement reduction, schema/contract updates, docs, fixtures, and reuse of scene-query sampling internals. |
| Implementation Friction Risk | 3 | Internal seam must consume `SampleSurfaceEvidence::Sample` rows directly, preserve public envelopes, avoid public JSON parsing, and enforce legal field combinations at runtime. |
| Validation Burden Risk | 3 | Plan requires request tests, command/service tests, reducer/helper coverage, native schema/contract tests, docs updates, and hosted/manual verification notes. |
| Dependency / Coordination Risk | 2 | Delivery depends on settled `SVR-03` measurement posture and `STI-03` profile sampling evidence, but both are described as implemented. |
| Discovery / Ambiguity Risk | 2 | Plan resolves the MVP branch as `terrain_profile/elevation_summary`, though visibility, occlusion, partial-hit, and compact evidence semantics remain validation-sensitive. |
| Scope Volatility Risk | 2 | External review already narrowed scope, but estimate breakers remain around terrain semantics, evidence size, and pressure to add slope/comparison behavior. |
| Rework Risk | 2 | Moderate risk from public contract and sampling-boundary mistakes, mitigated by explicit non-goals and internal seam requirements. |
| Confidence | 3 | `task.md` and `plan.md` provide strong planning evidence, but this prediction is retroactive and intentionally excludes implementation results. |

### Top Assumptions
- `SVR-03` and `STI-03` are stable enough to reuse without redesigning their public contracts.
- One public branch, `terrain_profile/elevation_summary`, remains the whole functional slice.
- Internal profile evidence can be exposed as `SampleSurfaceEvidence::Sample` rows without parsing public `sample_surface_z` JSON.
- Hosted validation can confirm visibility, occlusion, partial-hit, and evidence-capping behavior without requiring a broader terrain diagnostics task.

### Estimate Breakers
- If terrain evidence expands into slope, grade, comparison, drainage, fairness, or validation verdicts, functional scope and validation burden increase materially.
- If `STI-03` internals cannot return reusable profile evidence cleanly, implementation friction and technical surface increase.
- If provider schema constraints force a substantially different request shape, contract and test work grows.
- If visibility or ignore-target semantics need new SketchUp traversal behavior, discovery and validation risk increase.

### Predicted Signals
- The planned public API adds `mode`, `kind`, `sampling`, `samplingPolicy`, optional evidence, and a new unavailable reason while preserving the existing `measure_scene` envelope.
- The plan explicitly calls for runtime validation instead of root schema composition, which concentrates correctness in request parsing and refusal behavior.
- Evidence output must stay compact, chainable, unit-bearing, and measurement-only.
- The premortem already identified risks around too many flat siblings, partial response chainability, internal evidence seams, and evidence caps.

### Predicted Estimate Notes
- Predicted size is moderate-to-high technically despite a bounded functional slice because the work crosses public contract, runtime request validation, sampling internals, serialization, and hosted verification. This section is a simulation from planning evidence, not an originally recorded pre-implementation estimate.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CONSENSUS:START -->
## Challenge Review

> Not produced. No challenge estimate was recorded before implementation.

### Agreed Drivers
- Not recorded.

### Contested Drivers
- Not recorded.

### Missing Evidence
- Not recorded.

### Recommendation
- Not recorded.

### Challenge Notes
- Not recorded.
<!-- SIZE:CONSENSUS:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|
| n/a | n/a | n/a | n/a | n/a | n/a | No in-flight drift log existed before retroactive calibration. |

### Drift Notes
- No material drift entries were recorded during implementation.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Shipped one bounded `measure_scene` branch, `terrain_profile/elevation_summary`, without diagnostics, verdicts, or editing. |
| Technical Change Surface | 3 | Touched request validation, measurement command/service paths, internal profile evidence, schema/contract fixtures, docs, and performance-sensitive sampling internals. |
| Actual Implementation Friction | 3 | Hosted verification exposed follow-up fixes for blocker reuse, all-ambiguous zero-hit semantics, and two TDD optimization slices. |
| Actual Validation Burden | 3 | Required focused unit/contract suites, full Ruby validation, package verification, runtime ping, hosted smoke, edge checks, and performance timing. |
| Actual Dependency Drag | 2 | The task relied on settled `SVR-03` and `STI-03` seams but reused them without recorded external blockage. |
| Actual Discovery Encountered | 3 | Live and performance checks revealed visible-only sampling cost, all-ambiguous no-hit behavior, and corridor-pruning edge cases. |
| Actual Scope Volatility | 2 | Public scope stayed stable, but implementation expanded into bounded post-verification fixes and performance hardening. |
| Actual Rework | 2 | Rework was contained to sampling performance and ambiguity handling after verification, not a broad redesign. |
| Final Confidence in Completeness | 4 | Completion is backed by automated tests, lint, package verification, runtime ping, hosted smoke, and performance/edge validation. |

### Actual Signals
- `summary.md` records the shipped terrain profile mode/kind, profile-only request validation, and internal `SampleSurfaceQuery#profile_evidence` seam.
- Post-verification fixes changed observable unavailable semantics for all-ambiguous zero-hit profiles and optimized visible blocker handling.
- Hosted checks covered complete, partial, zero-hit, ambiguous, evidence-included, occluder, hidden-target, and refusal paths.
- Performance timing drove request-local prepared face entries and conservative profile-corridor blocker pruning.

### Actual Notes
- Actual size was driven less by the single public branch and more by proving terrain profile evidence stayed compact, measurement-only, visibility-aware, and performant enough for hosted use.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Targeted Ruby test load covering terrain profile reducer, request validation, measurement service/commands, sample surface query commands, native runtime loader, and native contract tests passed.
- `bundle exec rake ruby:test`, `bundle exec rake ruby:lint`, and `bundle exec rake package:verify` passed.

### Manual Validation
- SketchUp MCP runtime ping returned `pong`.
- Hosted smoke passed for `sampleCount` and `intervalMeters`, complete/partial/zero-hit profiles, evidence inclusion, occluder ignore behavior, hidden target behavior, refusals, and measurement-only contract checks.

### Performance Validation
- Hosted timing identified visibility-aware sampling as the expensive path.
- Request-local prepared face entries and profile-corridor blocker pruning materially improved the recorded scaling fixtures, and edge smoke found no observed blocker false negatives in the tested cases.

### Migration / Compatibility Validation
- Native MCP schema and contract fixtures were updated for the new mode/kind and validated by native contract tests.

### Operational / Rollout Validation
- Package verification passed; no separate rollout exercise was recorded.

### Validation Notes
- Validation burden was substantial because correctness depended on runtime contract shape, hosted SketchUp sampling behavior, visibility semantics, compact evidence, and performance characteristics.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Validation burden and discovery. The seed suspected moderate terrain-evidence validation, but hosted checks and performance timing exposed multiple edge and scaling concerns.
- **Most Overestimated Dimension**: None identified from a true predicted profile; no planning-stage prediction existed, and the seed-level functional/dependency suspicions remained broadly accurate.
- **Signal Present Early But Underweighted**: The `visibleOnly` / `ignoreTargets` sampling policy implied blocker and visibility behavior would need heavier hosted and performance validation.
- **Genuinely Unknowable Factor**: The exact visible-only performance cost and all-ambiguous no-hit behavior required implementation and hosted SketchUp evidence to measure precisely.
- **Future Similar Tasks Should Assume**: Terrain-profile measurement additions are likely moderate in functional scope but high enough in hosted validation and performance evidence needs to budget explicit edge and scaling checks.

### Calibration Notes
- Because `size.md` was created retroactively, there is no true predicted profile to compare against. Delta review compares actual behavior to the task-only seed where useful and avoids reconstructing pre-implementation certainty.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:validation-heavy-feature`
- `scope:scene-validation-review-measurement`
- `validation:mixed`
- `systems:measure-scene`
- `systems:terrain-profile-evidence`
- `systems:json-serialization`
- `volatility:medium`
- `friction:medium`
- `rework:unknown`
- `confidence:medium`
<!-- SIZE:TAGS:END -->

---

## Scoring Reference

Use the shared size playbook for all scoring.

- **0** = none / negligible
- **1** = low
- **2** = moderate
- **3** = high
- **4** = very high

Do not score from intuition alone. Every non-trivial score should be supported by concrete signals or evidence.
