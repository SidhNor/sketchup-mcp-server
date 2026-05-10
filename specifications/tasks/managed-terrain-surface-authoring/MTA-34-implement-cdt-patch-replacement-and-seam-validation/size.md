# Size: MTA-34 Implement CDT Patch Replacement And Seam Validation

**Task ID**: `MTA-34`  
**Title**: `Implement CDT Patch Replacement And Seam Validation`  
**Status**: `seeded`  
**Created**: `2026-05-09`  
**Last Updated**: `2026-05-09`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:integration`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:scene-mutation`
  - `systems:public-contract`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:undo`
  - `validation:performance`
  - `validation:contract`
- **Likely Analog Class**: hosted partial derived-output replacement with CDT patch seams

### Identity Notes
- Seeded from MTA-10 partial output regeneration, MTA-31 CDT scaffold evidence, and the external review requirement to replace only affected patches while validating seams.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds local CDT patch replacement behavior while keeping public terrain workflows and default backend stable. |
| Technical Change Surface | 4 | Likely touches terrain mesh generation, derived-output ownership, scene mutation, seam checks, fallback/no-leak behavior, and hosted validation seams. |
| Hidden Complexity Suspicion | 4 | Patch ownership, seam compatibility, old-output preservation, undo semantics, and host entity behavior are all high-risk surfaces. |
| Validation Burden Suspicion | 4 | Requires hosted mutation, seam, fallback, no-leak, and undo evidence; local tests cannot prove the main acceptance criteria. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-32 patch result shape, MTA-33 patch feature constraints, MTA-10 ownership lessons, and hosted SketchUp access. |
| Scope Volatility Suspicion | 3 | Scope is bounded by reuse of MTA-10 concepts, but may grow if CDT patch ownership does not map cleanly to existing partial output metadata. |
| Confidence | 2 | The target behavior is clear, but host mutation and seam proof remain evidence-dependent. |

### Early Signals
- MTA-10 is a useful analog for partial replacement, but CDT patches add seam and topology risks beyond regular grid ownership.
- MTA-31 showed default CDT enablement is premature; this task must stay internally gated.
- Hosted SketchUp evidence is essential because undo, visible seams, and entity ownership cannot be proven by local doubles alone.
- Public no-leak behavior remains a mandatory constraint.

### Early Estimate Notes
- Use MTA-10 as the closest mutation/ownership analog and MTA-31 as the closest CDT/fallback/no-leak analog. Validation burden should stay high because this is a host-sensitive output mutation task.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | Not filled yet. | Not filled yet. |
| Technical Change Surface | Not filled yet. | Not filled yet. |
| Implementation Friction Risk | Not filled yet. | Not filled yet. |
| Validation Burden Risk | Not filled yet. | Not filled yet. |
| Dependency / Coordination Risk | Not filled yet. | Not filled yet. |
| Discovery / Ambiguity Risk | Not filled yet. | Not filled yet. |
| Scope Volatility Risk | Not filled yet. | Not filled yet. |
| Rework Risk | Not filled yet. | Not filled yet. |
| Confidence | Not filled yet. | Not filled yet. |

### Top Assumptions
- Not filled yet.

### Estimate Breakers
- Not filled yet.

### Predicted Signals
- Not filled yet.

### Predicted Estimate Notes
- Not filled yet.
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

- `archetype:integration`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:scene-mutation`
- `validation:hosted-matrix`
- `validation:undo`
- `validation:performance`
- `contract:no-public-shape-change`
- `host:special-scene`
- `host:undo`
- `risk:undo-semantics`
- `risk:performance-scaling`
- `confidence:low`
<!-- SIZE:TAGS:END -->
