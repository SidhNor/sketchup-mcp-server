# Size: SVR-03 Establish measure_scene MVP With Structured Measurement Modes

**Task ID**: SVR-03  
**Title**: Establish measure_scene MVP With Structured Measurement Modes  
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
- **Primary Scope Area**: scene validation and review measurement surface
- **Likely Systems Touched**:
  - public MCP tool registration and schema
  - measurement request normalization and execution
  - target resolution and JSON-safe measurement serialization
- **Validation Class**: regression-heavy
- **Likely Analog Class**: new bounded public MCP tool surface

### Identity Notes
- Task-only evidence frames this as the first public `measure_scene` contract, distinct from validation verdicts and arbitrary Ruby fallback.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Establishes a new first-class public workflow surface with multiple initial measurement modes. |
| Technical Change Surface | 3 | Likely touches tool registration, schemas, targeting, measurement execution, serialization, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Geometry measurement, units, target references, and unsupported mode combinations can hide contract edge cases. |
| Validation Burden Suspicion | 3 | New public MCP tool requires mode coverage, response-shape checks, refusal behavior, and geometry-sensitive validation notes. |
| Dependency / Coordination Suspicion | 2 | Depends on `STI-02` and must align with adjacent targeting/interrogation and validation capability boundaries. |
| Scope Volatility Suspicion | 2 | The task has bounded modes, but the line between measurement, validation, and arbitrary interrogation may attract expansion. |
| Confidence | 2 | `task.md` provides strong intent, but this seed intentionally excludes technical planning evidence. |

### Early Signals
- The task introduces `measure_scene` as a new public MCP workflow surface rather than a local behavior tweak.
- Acceptance criteria require distance, area, height, bounds, explicit units, target-reference posture, refusals, docs, and focused verification.
- Non-goals repeatedly constrain validation verdicts, raw metadata, arbitrary properties, and additional modes.

### Early Estimate Notes
- Task-only shape suggests a bounded but sizable public contract task, with risk concentrated in geometry semantics, public schema clarity, and validation breadth.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new public read-only MCP tool with five legal mode/kind combinations across bounds, height, distance, and area. |
| Technical Change Surface | 3 | Plan spans runtime loader, dispatcher, factory, command path, measurement service, target resolver reuse, schemas, docs, fixtures, and tests. |
| Implementation Friction Risk | 3 | Geometry semantics require unit conversion, transforms, finite mode/kind enforcement, structured refusals, and separation from validation behavior. |
| Validation Burden Risk | 4 | Plan requires loader, dispatcher/facade, command, helper, native contract, docs, hosted SketchUp smoke, and MCP client smoke coverage. |
| Dependency / Coordination Risk | 2 | Depends on prior validation, surface sampling, runtime, target resolver, serializer, and hosted SketchUp runtime, but all are identified and mostly existing. |
| Discovery / Ambiguity Risk | 3 | Premortem calls out schema discoverability, semantic ambiguity, host-sensitive geometry, unit conversion, and public MCP drift risks. |
| Scope Volatility Risk | 2 | Bounded MVP modes and explicit non-goals limit growth, though pressure toward clearance, slope, validation verdicts, or arbitrary interrogation remains. |
| Rework Risk | 3 | Public contract, unit conversion, transformed geometry, and tool discoverability mistakes could force revisiting completed implementation and docs. |
| Confidence | 3 | Planning evidence is detailed and includes premortem controls, but hosted geometry behavior remains a meaningful uncertainty. |

### Top Assumptions
- Compact references for `target`, `from`, and `to` are enough for the MVP; selector-shaped measurements stay deferred.
- The existing runtime loader, dispatcher, factory, target resolver, and serializer can be extended without architectural redesign.
- Geometry behavior for bounds, height, distance, and area can be normalized into public meters or square meters with focused helper coverage.
- Hosted smoke coverage is available or can be explicitly recorded for transformed/nested geometry and client-facing discoverability.

### Estimate Breakers
- If selector-based aggregation or arbitrary target types become required, scope and contract surface increase materially.
- If transformed or nested SketchUp geometry cannot be isolated in tests, validation burden and rework risk increase.
- If provider-compatible schema constraints make legal branch discoverability weak, tool description and refusal design need more iteration.
- If measurement starts returning validation-style pass/fail outcomes, boundary and documentation work must be revisited.

### Predicted Signals
- The public contract adds a new top-level tool and five finite mode/kind combinations, each with distinct reference and response semantics.
- Runtime validation must enforce legal field combinations because the schema avoids root composition keywords.
- Measurement outputs must avoid SketchUp internal units and must not leak raw objects or dictionaries.
- The test plan explicitly includes native contract snapshots, hosted SketchUp smoke checks, and MCP client smoke checks.

### Predicted Estimate Notes
- Predicted size is high for validation and moderate-high for implementation because this is a first public measurement surface crossing public schema, runtime routing, geometry semantics, docs, and hosted verification.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Public contract and runtime discoverability are major size drivers: the plan requires schema exposure, runtime refusals, native contract coverage, and MCP client smoke review.
- Geometry correctness is a major validation driver because bounds, transformed face area, nesting, scaling, and unit conversion must be trustworthy in real SketchUp models.
- Boundary control is essential: `measure_scene` must remain direct measurement and must not absorb validation verdicts, terrain diagnostics, or arbitrary interrogation.

### Contested Drivers
- Schema expressiveness is constrained by provider-compatible top-level parameters; legal combinations must be communicated through descriptions and runtime refusals rather than root schema branches.
- Hosted SketchUp validation is necessary for confidence, but the plan leaves availability and final host-sensitive gaps to implementation-time reporting.
- Area and distance semantics may still be misused by clients unless contrastive descriptions and examples are strong enough.

### Missing Evidence
- Pre-implementation proof that transformed/nested group and component area behavior matches the intended meter and square-meter outputs.
- Rendered MCP tool-card review showing clients can discover legal branches without implementation docs.
- Wrapped MCP invocation evidence for each legal branch and for predictable bad-shape refusals.

### Recommendation
- confirm estimate

### Challenge Notes
- The premortem supports the predicted high validation burden and moderate-high implementation friction. No score revision is needed because the predicted profile already accounts for schema discoverability, geometry semantics, unit conversion, hosted smoke, and MCP-surface drift risks.
<!-- SIZE:CHALLENGE:END -->

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
| Functional Scope | 3 | Shipped `measure_scene` as a first-class read-only MCP tool with five supported mode/kind combinations. |
| Technical Change Surface | 3 | Summary records schema fields, runtime validation, command validation, target-reference resolution, reusable measurement service behavior, docs, guide, and native fixtures. |
| Actual Implementation Friction | 2 | Implementation largely followed the planned surfaces; live distance testing found and fixed a SketchUp vector API mismatch. |
| Actual Validation Burden | 3 | Validation covered schema, dispatcher/factory, command behavior, measurement service, native contracts, live SketchUp modes, resolver paths, evidence, and `tools/list`; live distance testing found one contained SketchUp vector API mismatch that required a fix and rerun. |
| Actual Dependency Drag | 1 | Prior runtime and resolver seams were reused; no external blocker or coordination drag is recorded. |
| Actual Discovery Encountered | 2 | Live testing exposed the absent vector `magnitude` API and accepted sub-micro-square-meter rounding behavior. |
| Actual Scope Volatility | 1 | The shipped feature stayed within the planned five generic modes and deferred terrain/clearance behavior. |
| Actual Rework | 1 | Rework appears limited to the distance vector API mismatch found during live smoke. |
| Final Confidence in Completeness | 4 | Completion is backed by broad automated coverage plus live SketchUp verification and client-visible tool-list smoke. |

### Actual Signals
- `summary.md` records shipped provider-compatible schema fields and runtime validation for all five planned mode/kind combinations.
- Live SketchUp smoke passed for bounds, height, distance, surface area, and horizontal bounds area after the vector API mismatch fix.
- Resolver live checks covered source, persistent, compatibility entity, hidden, nonexistent, deleted/stale, and structured refusal paths.
- `tools/list` live smoke confirmed finite modes/kinds, compact references, evidence option, descriptions, and read-only annotations.

### Actual Notes
- Actual delivery matched the planned public contract closely. The largest observed cost was validation breadth rather than uncontrolled implementation expansion.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Runtime loader/schema tests covered tool inventory, exact branch schema, compact references, and contrastive descriptions.
- Dispatcher and factory tests covered routing; command tests covered successes, unavailable outcomes, unsupported mode/kind, missing references, selector-shaped references, and target-resolution refusals.
- Measurement service tests covered bounds, height, bounds-center distance, horizontal bounds area, surface area, unit conversion, unavailable reasons, and the SketchUp vector API regression.
- Native contract fixtures covered measured, unavailable, and refused outcomes.

### Manual Validation
- Live SketchUp smoke passed for `bounds/world_bounds`, `height/bounds_z`, `distance/bounds_center_to_bounds_center`, `area/surface`, and `area/horizontal_bounds`.
- Live checks covered transformed/scaled component instance bounds, component instance height, distance to a component instance, terrain and mesh surface area, resolver paths, serializable evidence, and client-visible `tools/list` output.

### Performance Validation
- Not applicable; no performance-specific validation was recorded for this MVP measurement surface.

### Migration / Compatibility Validation
- Compatibility `entityId` target resolution was covered in live resolver checks.
- Native contract fixtures validated the MCP response families for measured, unavailable, and refused `measure_scene` outcomes.

### Operational / Rollout Validation
- `tools/list` live smoke confirmed the new top-level read-only tool was discoverable with finite `mode` and `kind` values and compact reference fields.

### Validation Notes
- Validation burden was high because the task introduced a public MCP surface whose correctness depends on schema clarity, runtime refusals, unit conversion, live SketchUp geometry, resolver behavior, evidence serialization, and client-visible discoverability.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: None materially. The predicted validation concern was directionally right because live SketchUp exposed a vector API mismatch.
- **Most Overestimated Dimension**: Validation burden and rework risk. Under the retest-loop scale, actual validation burden is `3` because the live issue required one contained fix/rerun rather than repeated loops. Recorded rework was limited to that vector API mismatch.
- **Signal Present Early But Underweighted**: Host-sensitive SketchUp API behavior was recognized in the plan, and the live vector API mismatch confirms it deserved explicit hosted smoke.
- **Genuinely Unknowable Factor**: The missing live SketchUp vector `magnitude` API behavior was only proven during live verification.
- **Future Similar Tasks Should Assume**: New public MCP tools with geometry semantics need broad contract and hosted validation even when the functional mode set is bounded.

### Calibration Notes
- Prediction and challenge were directionally accurate: scope and technical surface landed at 3, while validation landed at 3 under the retest-loop scale and implementation friction/rework landed lower than their risk scores.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:scene-validation-review`
- `validation:contract`
- `validation:hosted-matrix`
- `host:single-fix-loop`
- `systems:measurement-service`
- `systems:target-resolution`
- `risk:host-api-mismatch`
- `volatility:medium`
- `friction:medium`
- `rework:low`
- `confidence:high`
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
