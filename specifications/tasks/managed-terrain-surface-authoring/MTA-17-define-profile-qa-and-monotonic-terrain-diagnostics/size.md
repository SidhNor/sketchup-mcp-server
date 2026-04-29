# Size: MTA-17 Define Profile QA And Monotonic Terrain Diagnostics

**Task ID**: `MTA-17`  
**Title**: Define Profile QA And Monotonic Terrain Diagnostics  
**Status**: deferred-seeded  
**Created**: 2026-04-28  
**Last Updated**: 2026-04-29  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:docs-specs
- **Primary Scope Area**: scope:managed-terrain
- **Likely Systems Touched**:
  - systems:surface-sampling
  - systems:measurement-service
  - systems:validation-service
  - systems:terrain-kernel
  - systems:docs
- **Validation Modes**: validation:docs-check, validation:contract
- **Likely Analog Class**: cross-capability diagnostics ownership definition

### Identity Notes
- This deferred task defines ownership and contract posture for profile QA concepts after planar fit and initial prompt guidance settle. It should not implement validation findings, sampling changes, or monotonic edit constraints.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Clarifies future QA and diagnostic semantics across existing evidence surfaces without shipping new behavior. |
| Technical Change Surface | 2 | Likely touches docs/specs and possibly task planning across terrain, sampling, measurement, and validation seams. |
| Hidden Complexity Suspicion | 3 | Ownership boundaries are subtle: diagnostics can drift into terrain mutation, measurement, or validation policy. |
| Validation Burden Suspicion | 2 | Proof is mainly review and docs consistency now; later implementation tasks will carry deeper validation. |
| Dependency / Coordination Suspicion | 3 | Requires coordination across MTA, STI, SVR, and should follow MTA-16/PLAT-18 so ownership reflects the new planar and prompt baseline. |
| Scope Volatility Suspicion | 2 | Scope can be contained if it remains ownership definition, but monotonic constraints could pull toward solver work if not guarded. |
| Confidence | 2 | The signal clearly motivates profile QA, but exact diagnostic ownership and later task splits remain unsettled. |

### Early Signals
- The task is deferred/late iteration work and explicitly separates profile diagnostics from monotonic edit constraints.
- Existing `sample_surface_z` and `measure_scene` profile evidence should remain the sampling path.
- Acceptance depends on clear ownership mapping rather than runtime behavior changes.
- Analog STI-03/SVR-04 suggests profile evidence can pull toward diagnostics if non-goals are not enforced.

### Early Estimate Notes
- Seed treats this as deferred cross-capability specification work with moderate coordination risk and low immediate implementation friction.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

Not filled yet.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

Not filled yet.
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

Not filled yet.
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

Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:docs-specs`
- `scope:managed-terrain`
- `scope:scene-targeting-interrogation`
- `scope:scene-validation-review`
- `systems:surface-sampling`
- `systems:measurement-service`
- `systems:validation-service`
- `systems:terrain-kernel`
- `systems:docs`
- `validation:docs-check`
- `validation:contract`
- `host:not-needed`
- `contract:no-public-shape-change`
- `risk:contract-drift`
- `risk:review-rework`
- `volatility:medium`
- `friction:low`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
