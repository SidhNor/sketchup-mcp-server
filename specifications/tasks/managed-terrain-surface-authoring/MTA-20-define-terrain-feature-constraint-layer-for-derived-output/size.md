# Size: MTA-20 Define Terrain Feature Constraint Layer For Derived Output

**Task ID**: `MTA-20`
**Title**: Define Terrain Feature Constraint Layer For Derived Output
**Status**: `seeded`
**Created**: 2026-05-02
**Last Updated**: 2026-05-02

**Related Task**: [task.md](./task.md)
**Related Plan**: none yet
**Related Summary**: none yet

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-state`
  - `systems:surface-sampling`
  - `systems:tool-response`
- **Validation Modes**: `validation:contract`, `validation:hosted-matrix`, `validation:regression`
- **Likely Analog Class**: terrain-output feature metadata foundation after failed simplifier replacement

### Identity Notes
- This task is an internal foundation for feature-aware terrain output and diagnostics. It should
  not change the public `heightmap_grid` source-of-truth contract or introduce a new public spline
  authoring tool.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Behavior-visible purpose is meaningful because it should unblock better derived terrain output and diagnostics, but it is an internal foundation rather than a new public edit mode. |
| Technical Change Surface | 3 | Likely touches edit-kernel diagnostics, output planning, terrain state adjunct data, sampling/coordinate normalization, and response no-leak tests. |
| Hidden Complexity Suspicion | 4 | MTA-19 showed that feature boundaries, off-grid adopted controls, corridor endpoints, and visual topology do not fall out of elevation samples alone. |
| Validation Burden Suspicion | 4 | Needs deterministic tests plus hosted evidence against corridor, rectangle, circle, planar-fit, preserve-zone, adopted irregular, non-square, and off-grid cases. |
| Dependency / Coordination Suspicion | 2 | Depends on existing terrain edit kernels and MTA-19 failure evidence, but remains in the owned Ruby terrain runtime. |
| Scope Volatility Suspicion | 3 | The task is intentionally backend-agnostic, but planning may resize around how much explicit edit history versus inferred heightfield feature detection belongs in the first slice. |
| Confidence | 2 | The need is clear from MTA-19, but no technical plan exists yet and the exact feature vocabulary is still unproven. |

### Early Signals
- MTA-19 failed because correct heightfield samples could still produce unreliable derived
  triangulation, especially around corridors and adopted irregular terrain.
- UE Landscape research suggests explicit spline/feature concepts are important, but UE remains
  non-normative and cannot be copied directly into SketchUp MCP architecture.
- The task explicitly avoids a new triangulation backend and public response expansion, which
  keeps scope bounded but increases pressure on internal abstraction quality.
- Off-grid adopted controls and endpoint caps are early risk signals for coordinate normalization
  and feature evidence.

### Early Estimate Notes
- Seed treats MTA-20 as a validation-heavy internal feature foundation. The likely difficulty is
  not public contract breadth; it is finding a generic feature vocabulary that works across edit
  families and can support future simplifiers without becoming corridor-specific patch logic.
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

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-state`
- `systems:surface-sampling`
- `validation:contract`
- `validation:hosted-matrix`
- `validation:regression`
- `host:special-scene`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:regression-breadth`
- `unclassified:feature-constraint-model`
- `volatility:medium`
- `friction:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
