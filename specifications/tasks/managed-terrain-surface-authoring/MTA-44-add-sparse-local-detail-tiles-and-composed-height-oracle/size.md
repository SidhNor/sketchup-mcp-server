# Size: MTA-44 Add Sparse Local Detail Tiles And Composed Height Oracle

**Task ID**: MTA-44  
**Title**: Add Sparse Local Detail Tiles And Composed Height Oracle  
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
  - `systems:terrain-storage`
  - `systems:terrain-kernel`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:persistence`
  - `validation:compatibility`
- **Likely Analog Class**: new terrain state/output layer on top of MTA-36 lifecycle and MTA-43 component planning

### Identity Notes
- Seeded as the strategic local-resolution task. It changes state/oracle shape more than earlier output-only tasks.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 4 | Adds true local high-detail capability without global source-grid refinement. |
| Technical Change Surface | 4 | Likely touches terrain state, storage, height queries, output planning, validation, and hosted evidence. |
| Hidden Complexity Suspicion | 4 | Composed height precedence, local-detail boundaries, and readback can hide significant complexity. |
| Validation Burden Suspicion | 4 | Needs hosted performance, face count, persistence, boundary, component, and comparison evidence. |
| Dependency / Coordination Suspicion | 3 | Depends on seam contracts and component planning before local detail can cross patch boundaries safely. |
| Scope Volatility Suspicion | 3 | Local detail representation and oracle precedence may need split-pressure during planning. |
| Confidence | 2 | Architecture need is clear, but representation and migration details are not planned yet. |

### Early Signals
- State/oracle change, not just output policy.
- Needs evidence against equivalent global refinement pressure.
- Depends on MTA-42 and MTA-43; optional diagonal work is not required.

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
- `systems:terrain-storage`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `validation:compatibility`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `volatility:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
