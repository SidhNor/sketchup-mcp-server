# Size: MTA-13 Implement Survey Point Constraint Terrain Edit

**Task ID**: `MTA-13`  
**Title**: Implement Survey Point Constraint Terrain Edit  
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
- **Primary Scope Area**: managed terrain survey point constraints
- **Likely Systems Touched**:
  - public `edit_terrain_surface` contract
  - terrain command layer
  - terrain edit kernels
  - fixed-control and preserve-zone handling
  - terrain evidence
  - terrain output planning
  - native loader schema and contract fixtures
  - README terrain examples
- **Validation Modes**: contract, hosted-matrix, regression
- **Likely Analog Class**: constraint-heavy terrain edit kernel

### Identity Notes
- This is a new public terrain edit mode with numerical constraint behavior. The closest analogs are `MTA-04` and `MTA-05`, with additional split pressure from possible localized-detail needs captured in deferred `MTA-11`.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new survey-driven terrain authoring workflow with reviewable per-point evidence. |
| Technical Change Surface | 4 | Likely touches public contract, command dispatch, numerical kernel behavior, fairing integration, evidence, output planning, docs, fixtures, and hosted validation. |
| Hidden Complexity Suspicion | 4 | Constraint solving, tolerances, grid-resolution limits, preserve conflicts, and fairing-without-drift are all sensitive. |
| Validation Burden Suspicion | 4 | Needs numerical, contract, regression, hosted-origin, undo/output, and representational-limit validation. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-06 and MTA-12 and may feed MTA-11 if v1 grid fidelity is insufficient. |
| Scope Volatility Suspicion | 3 | Scope can expand if survey tolerances require localized detail or a broader solver than expected. |
| Confidence | 2 | Product need is clear, but exact solver and refusal boundary are not planned yet. |

### Early Signals
- User clarified that points are survey constraints with small tolerances, not loose hints.
- Current `FixedControlEvaluator` already proves bilinear point evaluation exists, but it only preserves points rather than solving toward target survey elevations.
- MTA-06 is expected to provide local fairing, and MTA-13 must preserve survey constraints while using that behavior.
- Localized survey/detail zones are explicitly deferred unless v1 heightmap evidence proves insufficient.

### Early Estimate Notes
- Seed uses MTA-04 and MTA-05 as public terrain edit analogs, with higher hidden-complexity suspicion because this task introduces constraint satisfaction and representational-limit evidence.
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
- `systems:command-layer`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:native-contract-fixtures`
- `systems:docs`
- `validation:contract`
- `validation:hosted-matrix`
- `validation:regression`
- `host:routine-matrix`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:response-shape`
- `contract:docs-examples`
- `risk:contract-drift`
- `risk:partial-state`
- `risk:performance-scaling`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:low`
<!-- SIZE:TAGS:END -->
