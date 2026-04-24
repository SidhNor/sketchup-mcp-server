# Size: MTA-03 Adopt Supported Surface As Managed Terrain

**Task ID**: `MTA-03`  
**Title**: Adopt Supported Surface As Managed Terrain  
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
- **Primary Scope Area**: adopted managed terrain vertical slice
- **Likely Systems Touched**:
  - supported surface detection
  - heightmap derivation
  - terrain repository
  - derived output regeneration
  - command result evidence
- **Validation Class**: mixed
- **Likely Analog Class**: adoption command with geometry-derived state

### Identity Notes
- Converts an existing supported SketchUp surface into managed terrain state, then regenerates a managed derived output instead of mutating the original TIN.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds the first user-visible managed terrain workflow. |
| Technical Change Surface | 3 | Likely spans detection, sampling, storage, geometry output, command behavior, and evidence. |
| Hidden Complexity Suspicion | 4 | Existing geometry can be irregular; adoption must avoid eval-style in-place mesh edits. |
| Validation Burden Suspicion | 4 | Needs deterministic fixtures plus SketchUp-hosted evidence for real geometry behavior. |
| Dependency / Coordination Suspicion | 3 | Depends on terrain state foundation and existing scene targeting/sampling behavior. |
| Scope Volatility Suspicion | 3 | Supported input limits and output evidence may need tightening during planning. |
| Confidence | 2 | The vertical slice is clear, but geometry cases are not fully enumerated yet. |

### Early Signals
- The adopted heightmap must be recreated from existing surface geometry.
- The source surface should remain distinct from managed derived terrain output.
- Existing path and pad hardscape semantics are not part of terrain adoption.

### Early Estimate Notes
- Seed reflects a high-risk first runtime slice because it crosses state, sampling, and SketchUp geometry output.
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
- `scope:terrain-adoption`
- `validation:mixed`
- `systems:detection-heightmap-repository-geometry-command`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
