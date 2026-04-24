# Size: MTA-04 Implement Bounded Grade Edit MVP

**Task ID**: `MTA-04`  
**Title**: Implement Bounded Grade Edit MVP  
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
- **Primary Scope Area**: bounded terrain grade edits and regeneration
- **Likely Systems Touched**:
  - terrain edit command
  - heightmap mutation model
  - bounded edit kernel
  - derived output regeneration
  - validation and evidence reporting
- **Validation Class**: mixed
- **Likely Analog Class**: stateful geometry edit with regenerated output

### Identity Notes
- First managed terrain editing capability; edits state and regenerates output rather than modifying an existing TIN in place.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds visible grade-edit behavior for managed terrain. |
| Technical Change Surface | 3 | Likely touches command orchestration, terrain state, edit kernels, output regeneration, and evidence. |
| Hidden Complexity Suspicion | 4 | Boundaries, interpolation, units, and regeneration invariants can easily become messy. |
| Validation Burden Suspicion | 4 | Requires numerical assertions, geometry output checks, and hosted verification. |
| Dependency / Coordination Suspicion | 3 | Depends on adoption and storage foundations being stable enough to edit. |
| Scope Volatility Suspicion | 3 | MVP edit limits may need narrowing as kernel contracts become concrete. |
| Confidence | 2 | Desired behavior is clear, but exact kernel and proof strategy remain unplanned. |

### Early Signals
- `eval_ruby` geometry mutation is explicitly unsuitable for managed terrain edits.
- The public capability should remain coarse while flatten/smooth/ramp-like operations stay internal.
- SketchUp Undo can cover user-level reversal rather than a custom history flow.

### Early Estimate Notes
- Seed reflects a high-friction runtime feature centered on controlled state mutation and regeneration.
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
- `scope:terrain-grade-edit`
- `validation:mixed`
- `systems:command-heightmap-kernel-regeneration-evidence`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
