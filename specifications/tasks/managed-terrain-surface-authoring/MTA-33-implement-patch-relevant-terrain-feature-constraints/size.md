# Size: MTA-33 Implement Patch-Relevant Terrain Feature Constraints

**Task ID**: `MTA-33`  
**Title**: `Implement Patch-Relevant Terrain Feature Constraints`  
**Status**: `seeded`  
**Created**: `2026-05-09`  
**Last Updated**: `2026-05-09`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-state`
  - `systems:terrain-kernel`
  - `systems:public-contract`
- **Validation Modes**:
  - `validation:performance`
  - `validation:contract`
  - `validation:regression`
- **Likely Analog Class**: patch-relevant feature selection for local CDT terrain output

### Identity Notes
- Seeded from MTA-31 effective feature view closeout and the external review finding that hard constraints should be spatially owned rather than globally included in every local solve.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Internally changes CDT input relevance for local patch solves without public tool or response changes. |
| Technical Change Surface | 3 | Likely touches effective feature selection, feature geometry preparation, CDT input diagnostics, and no-leak tests. |
| Hidden Complexity Suspicion | 4 | Hard-feature semantics are subtle: far hard features must be excluded without silently weakening touched or protecting constraints. |
| Validation Burden Suspicion | 3 | Needs cardinality, hard/protected behavior, stale-index, and public no-leak proof; hosted evidence may be needed for representative feature-heavy cases. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-31 feature lifecycle/effective state and MTA-32 patch-domain shape. |
| Scope Volatility Suspicion | 3 | May grow if patch relevance requires a durable spatial index or protected-region expansion policy broader than expected. |
| Confidence | 3 | The task boundary is narrower than MTA-31, but hard constraint relevance rules still need careful proof. |

### Early Signals
- MTA-31 fixed active/effective feature state but still showed hard-feature pressure can dominate local CDT inputs.
- External review explicitly recommends including hard constraints only when they intersect, protect, constrain, or neighbor the local patch.
- This task intentionally avoids rewriting feature lifecycle/indexing and focuses on CDT patch input selection.
- Public contract stability remains a hard constraint.

### Early Estimate Notes
- Use MTA-31 as the closest analog for feature-intent and no-leak behavior, but this task has a narrower scope and a sharper semantic risk around hard-feature exclusion.
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

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-state`
- `systems:terrain-kernel`
- `validation:performance`
- `validation:contract`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:contract-drift`
- `volatility:medium`
- `friction:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
