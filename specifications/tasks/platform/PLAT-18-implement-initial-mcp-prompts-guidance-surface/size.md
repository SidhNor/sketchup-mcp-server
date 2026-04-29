# Size: PLAT-18 Implement Initial MCP Prompts Guidance Surface

**Task ID**: `PLAT-18`  
**Title**: Implement Initial MCP Prompts Guidance Surface  
**Status**: seeded  
**Created**: 2026-04-28  
**Last Updated**: 2026-04-29  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:platform
- **Primary Scope Area**: scope:platform
- **Likely Systems Touched**:
  - systems:runtime-dispatch
  - systems:public-contract
  - systems:docs
  - systems:test-support
- **Validation Modes**: validation:contract, validation:docs-check, validation:public-client-smoke
- **Likely Analog Class**: native-mcp-public-guidance-surface-implementation

### Identity Notes
- This is a platform implementation task for an initial MCP prompts surface. It must preserve `tools/list` baseline safety semantics and avoid moving core tool rules into prompts.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds a complementary prompt catalog surface without changing modeling tool behavior. |
| Technical Change Surface | 2 | Likely touches native runtime prompt registration, protocol tests, docs, and package/client smoke; tool schemas should remain stable. |
| Hidden Complexity Suspicion | 1 | Staged MCP SDK support for prompts/list and prompts/get was confirmed; remaining complexity is catalog wiring and prompt content control. |
| Validation Burden Suspicion | 2 | Requires contract/docs proof and likely a client smoke; no SketchUp geometry proof expected. |
| Dependency / Coordination Suspicion | 2 | Depends on prior platform contract hardening and MTA-15 guidance needs. |
| Scope Volatility Suspicion | 1 | Initial catalog is fixed to two static no-argument prompts; resources and third prompts are deferred. |
| Confidence | 3 | SDK/runtime prompt support was confirmed in the staged package; implementation should remain small if scope stays fixed. |

### Early Signals
- User feedback and staged SDK inspection suggest prompts are likely small; the initial catalog is fixed to managed_terrain_edit_workflow and terrain_profile_qa_workflow.
- The task explicitly preserves tool descriptions/schema as the baseline-safe surface.
- Analog PLAT-14/16/17 shows public MCP contract work must keep runtime, docs, and tests aligned.
- Current runtime has tool descriptions and schemas but no project-owned prompt catalog yet; the staged MCP SDK already supports prompt methods.

### Early Estimate Notes
- Seed was refreshed during planning after PLAT-18 changed from evaluation to initial prompt-surface implementation.
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

- `archetype:platform`
- `scope:platform`
- `scope:runtime-transport`
- `systems:runtime-dispatch`
- `systems:public-contract`
- `systems:docs`
- `systems:test-support`
- `validation:contract`
- `validation:docs-check`
- `validation:public-client-smoke`
- `host:not-needed`
- `contract:runtime-dispatch`
- `contract:docs-examples`
- `contract:no-public-shape-change`
- `risk:contract-drift`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
