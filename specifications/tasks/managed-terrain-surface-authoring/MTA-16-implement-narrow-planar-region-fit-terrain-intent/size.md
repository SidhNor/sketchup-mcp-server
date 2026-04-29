# Size: MTA-16 Implement Narrow Planar Region Fit Terrain Intent

**Task ID**: `MTA-16`  
**Title**: Implement Narrow Planar Region Fit Terrain Intent  
**Status**: seeded  
**Created**: 2026-04-28  
**Last Updated**: 2026-04-29  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:feature
- **Primary Scope Area**: scope:managed-terrain
- **Likely Systems Touched**:
  - systems:terrain-state
  - systems:terrain-kernel
  - systems:loader-schema
  - systems:public-contract
  - systems:native-contract-fixtures
  - systems:test-support
  - systems:docs
- **Validation Modes**: validation:regression, validation:contract, validation:docs-check, validation:public-client-smoke
- **Likely Analog Class**: narrow public terrain edit mode implementation

### Identity Notes
- This task implements a narrow explicit planar terrain edit intent. It is closer to MTA-13-style public edit-mode delivery than to an open-ended MTA-14-style evaluation.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Ships a new explicit terrain edit intent, but keeps the first slice narrow to bounded rectangle/circle regions and planar controls. |
| Technical Change Surface | 3 | Likely spans terrain-domain solver code, request validation, runtime schema, dispatcher path, native fixtures, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Coplanarity, least-squares residuals, preserve-zone interaction, and grid spacing can hide real solver/contract ambiguity. |
| Validation Burden Suspicion | 4 | Needs terrain-domain fixtures, request/contract tests, docs parity, and hosted/public MCP proof for the new edit intent. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-13/MTA-14 terrain solver precedent, MTA-15 discoverability, and may expose MTA-11 grid-detail limits. |
| Scope Volatility Suspicion | 2 | Scope is intentionally narrowed to one explicit planar intent, with planar_region_fit assumed as the operation name and exact control field shape left to task planning. |
| Confidence | 2 | User direction and prior solver work support implementation, but the exact narrow contract still needs planning. |

### Early Signals
- The task explicitly preserves current regional correction semantics and adds planar intent separately.
- Analog MTA-13 shows public terrain edit modes require runtime schema, dispatcher, docs, contract fixtures, and hosted MCP validation to move together.
- Analog MTA-14 provides reusable plane/residual-style evaluation expectations, but this task must ship production behavior rather than only a recommendation.
- Current `heightmap_grid` spacing may make some planar-control expectations unsafe or impossible without localized detail.
- Iteration planning assumes a new explicit planar_region_fit intent inside edit_terrain_surface; exact control field naming remains a task-planning detail.

### Early Estimate Notes
- Seed was refreshed during planning after user direction changed MTA-16 from evaluation-only to narrow implementation.
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

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|

### Drift Notes
- No material drift recorded yet.
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

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Not filled yet.

### Hosted / Manual Validation
- Not filled yet.

### Performance Validation
- Not filled yet.

### Migration / Compatibility Validation
- Not filled yet.

### Operational / Rollout Validation
- Not filled yet.

### Validation Notes
- Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-state`
- `systems:terrain-kernel`
- `systems:loader-schema`
- `systems:public-contract`
- `systems:native-contract-fixtures`
- `systems:test-support`
- `systems:docs`
- `validation:regression`
- `validation:contract`
- `validation:docs-check`
- `validation:public-client-smoke`
- `host:routine-matrix`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:native-fixture`
- `contract:docs-examples`
- `risk:review-rework`
- `risk:contract-drift`
- `risk:schema-requiredness`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
