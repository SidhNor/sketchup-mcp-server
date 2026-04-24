# Size: MTA-05 Implement Corridor Transition Terrain Kernel

**Task ID**: `MTA-05`  
**Title**: Implement Corridor Transition Terrain Kernel  
**Status**: `seeded`  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-24  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: terrain transition kernel for corridor-style grade changes
- **Likely Systems Touched**:
  - internal terrain kernel contracts
  - heightmap edit math
  - transition evidence
  - grade-edit integration
  - numerical test fixtures
- **Validation Class**: regression-heavy
- **Likely Analog Class**: numerical terrain kernel extension

### Identity Notes
- Makes corridor/ramp-like transition behavior concrete as an internal kernel, not as a new public tool surface.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds a specific internal terrain shaping capability surfaced through existing public edit flow. |
| Technical Change Surface | 3 | Likely touches kernel contracts, math, validation fixtures, and edit integration. |
| Hidden Complexity Suspicion | 4 | Transition zones, constraints, slope continuity, and edge behavior are risk-heavy. |
| Validation Burden Suspicion | 4 | Requires deterministic numerical tests and visual/hosted evidence for terrain output. |
| Dependency / Coordination Suspicion | 3 | Depends on bounded grade edit contracts and managed regeneration. |
| Scope Volatility Suspicion | 3 | Kernel parameter boundaries may need refinement after first fixtures. |
| Confidence | 2 | Kernel category is clear, but exact math and acceptance tolerances need planning. |

### Early Signals
- Unreal references should inform internal approaches and split decisions only.
- Transition/fairing kernels are part of the planned delivery, not deferred documentation.
- Public tool shape should remain outside this task.

### Early Estimate Notes
- Seed reflects a narrow functional slice with high numerical and validation suspicion.
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

No material drift recorded yet.
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
- `scope:terrain-transition-kernel`
- `validation:regression-heavy`
- `systems:kernel-heightmap-math-grade-edit-fixtures`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
