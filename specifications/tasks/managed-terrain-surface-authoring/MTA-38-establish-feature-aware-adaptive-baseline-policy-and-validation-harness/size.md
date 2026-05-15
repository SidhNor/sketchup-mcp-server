# Size: MTA-38 Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness

**Task ID**: MTA-38  
**Title**: Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness  
**Status**: seeded  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-15  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:test-infrastructure`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
  - `systems:test-support`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:undo`
- **Likely Analog Class**: MTA-36 hosted adaptive patch lifecycle evidence, MTA-22 regression fixture capture

### Identity Notes
- Seeded from the feature-aware adaptive architecture note and confirmed iteration-planning sequence. MTA-36 is the strongest positive analog; CDT tasks are intentionally not implementation analogs.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Establishes harness and metadata expectations, but should not materially change terrain geometry. |
| Technical Change Surface | 2 | Likely touches output planning diagnostics, test/probe support, and validation scaffolding. |
| Hidden Complexity Suspicion | 2 | Baseline rows and policy metadata can expose gaps, but no topology change is intended. |
| Validation Burden Suspicion | 3 | The task is primarily hosted replay, timing, persistence, undo, and evidence-format work. |
| Dependency / Coordination Suspicion | 2 | Depends on existing adaptive lifecycle and feature-intent context from prior MTA work. |
| Scope Volatility Suspicion | 2 | Replay corpus selection may need refinement before implementation planning. |
| Confidence | 2 | Source direction is clear, but exact corpus rows and instrumentation details are not planned yet. |

### Early Signals
- Harness-first task with no intended geometry change.
- Live hosted public command path is required.
- Baseline evidence must be reusable by MTA-39 through MTA-44.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

Not filled yet.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

Not filled yet.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

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

- `archetype:test-infrastructure`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:validation-service`
- `systems:test-support`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `validation:undo`
- `host:routine-matrix`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
