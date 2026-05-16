# Size: SAR-05 Orientation-Aware Asset Placement

**Task ID**: `SAR-05`  
**Title**: `Orientation-Aware Asset Placement`  
**Status**: `seeded`  
**Created**: `2026-05-15`  
**Last Updated**: `2026-05-16`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:staged-asset-reuse`
- **Likely Systems Touched**:
  - `systems:public-contract`
  - `systems:runtime-dispatch`
  - `systems:command-layer`
  - `systems:scene-mutation`
  - `systems:surface-sampling`
  - `systems:asset-metadata`
  - `systems:tool-response`
  - `systems:native-contract-fixtures`
  - `systems:docs`
- **Validation Modes**:
  - `validation:contract`
  - `validation:undo`
  - `validation:hosted-smoke`
  - `validation:compatibility`
- **Likely Analog Class**: orientation-aware staged asset instantiation

### Identity Notes
- This is a bounded follow-on to `SAR-02`: it extends staged asset instantiation with optional heading control and metadata-gated surface-derived alignment for one rigid instance rather than adding scatter, replacement, arbitrary transforms, or area coverage workflows.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds orientation behavior to an existing instantiation workflow, but keeps scatter, replacement, and automatic terrain inference out of scope. |
| Technical Change Surface | 3 | Likely touches public schema, staged asset command behavior, transform construction, specific surface-reference frame derivation, metadata policy, response evidence, contract fixtures, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Surface-derived transforms, slope validation, SketchUp axis conventions, and interaction with existing source-instance transforms can hide host-specific issues. |
| Validation Burden Suspicion | 3 | Needs contract coverage, refusal paths, transform evidence, undo safety, backward compatibility, and likely live SketchUp smoke for actual orientation behavior. |
| Dependency / Coordination Suspicion | 2 | Depends on `SAR-01` metadata, `SAR-02` instantiation behavior, and a supported surface-reference path, but keeps broad area coverage and tiling in `SAR-06`. |
| Scope Volatility Suspicion | 2 | Open questions around field naming, preferred defaults, surface offset, and replacement reuse could expand the task if not held to single-instance placement. |
| Confidence | 2 | Requirements are clear at task-definition level, but no technical plan exists yet and transform semantics are known to be host-sensitive from `SAR-02`. |

### Early Signals
- `SAR-02` live validation exposed transform and group-copy host sensitivity, making orientation math a real risk rather than a trivial schema addition.
- External engine precedent supports separate yaw, surface alignment, slope limits, and offset concepts; this task intentionally keeps random scatter, arbitrary transform contracts, and brush behavior out.
- Explicit normal-vector input is out of scope; surface alignment is derived from a specific referenced surface and placement point.
- Metadata gating is central because upright shrubs and surface-hugging carpet assets need different placement policies.
- Backward compatibility matters because existing position/scale-only `instantiate_staged_asset` calls must keep working unchanged.

### Early Estimate Notes
- Seed uses `SAR-02` as the closest analog but scores functional scope lower because this is an extension to instantiation rather than the first mutating staged-asset workflow.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Implementation Friction Risk | <0-4> | <short note> |
| Validation Burden Risk | <0-4> | <short note> |
| Dependency / Coordination Risk | <0-4> | <short note> |
| Discovery / Ambiguity Risk | <0-4> | <short note> |
| Scope Volatility Risk | <0-4> | <short note> |
| Rework Risk | <0-4> | <short note> |
| Confidence | <0-4> | <short note> |

### Top Assumptions
- <assumption>

### Estimate Breakers
- <breaker>

### Predicted Signals
- <signal>

### Predicted Estimate Notes
- <short rationale>
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Not filled yet.

### Contested Drivers
- Not filled yet.

### Missing Evidence
- Not filled yet.

### Recommendation
- Not filled yet.

### Challenge Notes
- Not filled yet.
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
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Actual Implementation Friction | <0-4> | <short note> |
| Actual Validation Burden | <0-4> | <short note> |
| Actual Dependency Drag | <0-4> | <short note> |
| Actual Discovery Encountered | <0-4> | <short note> |
| Actual Scope Volatility | <0-4> | <short note> |
| Actual Rework | <0-4> | <short note> |
| Final Confidence in Completeness | <0-4> | <short note> |

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

- **Most Underestimated Dimension**: <dimension + why>
- **Most Overestimated Dimension**: <dimension + why>
- **Signal Present Early But Underweighted**: <note>
- **Genuinely Unknowable Factor**: <note or `none identified`>
- **Future Similar Tasks Should Assume**: <note>

### Calibration Notes
- <short note>
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:staged-asset-reuse`
- `systems:public-contract`
- `systems:command-layer`
- `systems:scene-mutation`
- `systems:surface-sampling`
- `systems:asset-metadata`
- `validation:contract`
- `validation:hosted-smoke`
- `contract:public-tool`
- `contract:finite-options`
- `risk:transform-semantics`
- `volatility:medium`
- `confidence:low`
<!-- SIZE:TAGS:END -->
