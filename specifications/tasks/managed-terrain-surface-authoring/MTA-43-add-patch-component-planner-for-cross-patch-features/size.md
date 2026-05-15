# Size: MTA-43 Add Patch Component Planner For Cross-Patch Features

**Task ID**: MTA-43  
**Title**: Add Patch Component Planner For Cross-Patch Features  
**Status**: seeded  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-15  

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
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
  - `systems:managed-object-metadata`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:regression`
- **Likely Analog Class**: MTA-36 dirty-window patch lifecycle with stronger cross-patch planning pressure

### Identity Notes
- Seeded as the bounded-promotion task. The core risk is preserving local edit economics while allowing required cross-patch correctness.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds cross-patch feature correctness while preserving bounded edits. |
| Technical Change Surface | 3 | Likely spans planning graph, patch roles, promotion/refusal, diagnostics, and validation. |
| Hidden Complexity Suspicion | 4 | Component promotion can accidentally broaden edits or undermine no-delete behavior. |
| Validation Burden Suspicion | 4 | Needs hosted matrices for local, adjacent, cross-patch, over-budget, timing, face count, and readback cases. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-42 seam contracts and MTA-36 lifecycle semantics. |
| Scope Volatility Suspicion | 3 | Planning may need to narrow patch roles or promotion policies. |
| Confidence | 2 | Direction is clear, but component budgets and row design need technical planning. |

### Early Signals
- Directly threatens dirty-window/local-edit performance if poorly scoped.
- Must record component size and patch roles in evidence.
- Blocks sparse local detail.

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

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:managed-object-metadata`
- `systems:validation-service`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `host:routine-matrix`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:partial-state`
- `volatility:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
