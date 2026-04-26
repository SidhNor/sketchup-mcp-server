# Size: MTA-09 Define Region-Aware Terrain Output Planning Foundation

**Task ID**: `MTA-09`
**Title**: Define Region-Aware Terrain Output Planning Foundation
**Status**: `seeded`
**Created**: 2026-04-26
**Last Updated**: 2026-04-26

**Related Task**: [task.md](./task.md)
**Related Plan**: none yet
**Related Summary**: none yet

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform
- **Primary Scope Area**: terrain output planning and dirty-window handoff
- **Likely Systems Touched**:
  - terrain output planning
  - `SampleWindow` integration
  - terrain edit diagnostics
  - output contract stability tests
  - terrain mesh generation fallback behavior
- **Validation Class**: regression-heavy / contract-sensitive
- **Likely Analog Class**: terrain output seam foundation

### Identity Notes
- Foundation task that makes dirty-window intent explicit without implementing partial SketchUp mesh replacement or persisted schema changes.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Mostly internal platform behavior, but it shapes how future edit kernels and output regeneration interact. |
| Technical Change Surface | 3 | Likely touches output planning, edit diagnostics, tests, and mesh generation boundaries. |
| Hidden Complexity Suspicion | 3 | Risk is creating fake partial regeneration or leaking internal windows into public evidence/persistence. |
| Validation Burden Suspicion | 3 | Needs contract/no-drift tests plus regression coverage for full-output fallback and kernel handoff behavior. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-07 primitives, benefits from MTA-08 output baseline, and informs MTA-05/MTA-06/MTA-10. |
| Scope Volatility Suspicion | 3 | Can expand if it starts owning partial output, chunk ownership, or public evidence evolution. |
| Confidence | 3 | The boundary is clear after MTA-07 and Grok review, but exact output-plan shape remains planning-time work. |

### Early Signals
- `SampleWindow` exists and is already integrated into bounded-grade changed-region diagnostics.
- MTA-05 planning expects `CorridorFrame` to compose with `SampleWindow`, not replace it.
- Public evidence vocabulary and persisted `heightmap_grid` v1 must remain stable.
- Grok review warned not to merge this foundation with partial regeneration.

### Early Estimate Notes
- Seed treats this as a deliberate output-planning seam task with moderate functional scope and high split-pressure risk if partial regeneration is pulled in.
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

- `archetype:platform`
- `scope:terrain-output-planning`
- `scope:sample-window-output-region-handoff`
- `validation:regression-heavy`
- `systems:sample-window-terrain-output-plan-edit-diagnostics`
- `contract:public-vocabulary-stability`
- `volatility:high`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
