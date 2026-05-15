# Size: MTA-39 Add Feature-Aware Tolerance And Density Fields

**Task ID**: MTA-39  
**Title**: Add Feature-Aware Tolerance And Density Fields  
**Status**: seeded  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-15  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-state`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:regression`
- **Likely Analog Class**: MTA-36 adaptive lifecycle plus MTA-20 feature intent and MTA-23 adaptive prototype context

### Identity Notes
- Seeded as the first behavior-changing feature-aware adaptive output task. It should keep current PatchLifecycle and dirty-window semantics.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | First visible feature-aware adaptive output behavior across feature families. |
| Technical Change Surface | 3 | Likely spans feature context, output planning, adaptive traversal/policy, diagnostics, and validation. |
| Hidden Complexity Suspicion | 2 | Main risk is policy-field integration, not topology ownership changes. |
| Validation Burden Suspicion | 3 | Requires hosted before/after timing, face count, dirty-window, and feature-locality evidence. |
| Dependency / Coordination Suspicion | 2 | Hard dependency on MTA-38; relies on existing feature-intent and MTA-36 lifecycle behavior. |
| Scope Volatility Suspicion | 2 | Tolerance and density are coupled, but exact policy boundaries may need planning refinement. |
| Confidence | 2 | Direction is clear; implementation surface and acceptable face-count tradeoffs need planning. |

### Early Signals
- Merges Slice 2 and Slice 3 because both feed adaptive subdivision policy.
- Must explain any face-count growth as local feature pressure, not global drift.
- No hard topology claim belongs in this task.

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

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-state`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:validation-service`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:regression`
- `host:routine-matrix`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `volatility:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
