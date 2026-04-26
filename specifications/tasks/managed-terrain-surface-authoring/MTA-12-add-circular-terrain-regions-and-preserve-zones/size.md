# Size: MTA-12 Add Circular Terrain Regions And Preserve Zones

**Task ID**: `MTA-12`  
**Title**: Add Circular Terrain Regions And Preserve Zones  
**Status**: `seeded`  
**Created**: 2026-04-26  
**Last Updated**: 2026-04-26  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: managed terrain circular edit regions
- **Likely Systems Touched**:
  - public `edit_terrain_surface` contract
  - terrain request validation
  - terrain edit kernels
  - terrain evidence
  - native loader schema and contract fixtures
  - README terrain examples
- **Validation Modes**: contract, hosted-matrix
- **Likely Analog Class**: public terrain edit contract extension

### Identity Notes
- This is a bounded public contract and terrain-kernel extension. The closest analog is `MTA-04`, but scope is narrower because terrain edit orchestration, storage, output regeneration, and partial regeneration already exist.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds round local edit and preserve behavior across existing local-area terrain edit modes. |
| Technical Change Surface | 3 | Likely touches validation, schemas, fixtures, target-height kernel, local-fairing kernel, evidence, docs, and tests. |
| Hidden Complexity Suspicion | 2 | Circle weighting is simple, but mode-specific region and preserve-zone compatibility needs care. |
| Validation Burden Suspicion | 3 | Requires contract parity plus terrain-kernel and hosted edit checks across target-height and local-fairing modes. |
| Dependency / Coordination Suspicion | 2 | Depends on completed MTA-06 local fairing shape, but does not require representation or storage work. |
| Scope Volatility Suspicion | 2 | Scope is stable if corridor and polygon support stay explicitly out of bounds. |
| Confidence | 3 | The requested shape and analogs are clear, with remaining risk around MTA-06 integration details. |

### Early Signals
- User explicitly confirmed circle support should cover both target-height and local-fairing edit regions and preserve zones.
- MTA-04 proved the public terrain edit surface but also showed contract/docs/fixtures and hosted checks must move together.
- MTA-06 is actively planned as rectangle-only local fairing, making it the hard sequencing dependency for a coherent circular-region task.

### Early Estimate Notes
- Seed uses MTA-04 as an outside-view analog for public edit contract validation burden, adjusted downward because this task does not introduce the terrain edit command, repository flow, or output regeneration foundation.
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
- `scope:managed-terrain`
- `systems:public-contract`
- `systems:terrain-kernel`
- `systems:native-contract-fixtures`
- `systems:docs`
- `validation:contract`
- `validation:hosted-matrix`
- `host:routine-matrix`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:docs-examples`
- `risk:contract-drift`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
