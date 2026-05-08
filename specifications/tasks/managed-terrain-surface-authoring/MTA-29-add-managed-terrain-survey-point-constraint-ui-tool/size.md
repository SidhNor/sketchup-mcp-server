# Size: MTA-29 Add Managed Terrain Survey Point Constraint UI Tool

**Task ID**: `MTA-29`  
**Title**: `Add Managed Terrain Survey Point Constraint UI Tool`  
**Status**: `seeded`  
**Created**: `2026-05-08`  
**Last Updated**: `2026-05-08`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:feature`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `unclassified:sketchup-ui`
  - `systems:command-layer`
  - `systems:target-resolution`
  - `systems:scene-mutation`
  - `systems:terrain-state`
  - `systems:terrain-output`
  - `systems:test-support`
  - `systems:docs`
- **Validation Modes**: `validation:hosted-smoke`, `validation:undo`
- **Likely Analog Class**: control-point SketchUp terrain UI tool over existing survey edit command

### Identity Notes
- This task introduces the first point-list/support-region UI for managed terrain, scoped to survey point constraint only. It should preserve the semantic boundary between survey correction and explicit planar fitting.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new user-facing control-point edit tool with point management, support-region cueing, and survey-specific parameters. |
| Technical Change Surface | 3 | Likely touches shared panel state, point-list management, support-region request construction, overlay markers, command handoff, docs, and tests. |
| Hidden Complexity Suspicion | 4 | Point capture/list state, support-region validity, tolerance semantics, and avoiding implicit planar behavior are likely subtle. |
| Validation Burden Suspicion | 3 | Existing survey math reduces kernel risk, but UI state, invalid points, hosted interaction, command refusal, and undo need proof. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-27 and MTA-13, and it intentionally blocks planar UI reuse in MTA-30. |
| Scope Volatility Suspicion | 3 | Split pressure is real because survey and planar share primitives but must remain semantically separate. |
| Confidence | 2 | Task boundary is explicit after refinement, but no point-list UI analog exists yet in the repo. |

### Early Signals
- MTA-13 calibrated survey correction as validation-heavy, but this task should reuse that behavior rather than re-open solver scope.
- The iteration was explicitly split so survey point UI can prove the point-list foundation before planar UI.
- Product risk centers on not implying survey correction is planar fitting.
- Hosted smoke should cover real point capture, point removal, invalid/out-of-region feedback, and command handoff.

### Early Estimate Notes
- Strong analogs are MTA-18 for SketchUp UI lifecycle and MTA-13 for survey semantics. Use MTA-13 as a semantic/validation warning, not as evidence that this task owns new solver complexity.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Not filled yet. Produce during task planning.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Not filled yet.
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

> Not filled yet.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Not filled yet.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:command-layer`
- `systems:target-resolution`
- `systems:scene-mutation`
- `validation:hosted-smoke`
- `host:routine-smoke`
- `contract:no-public-shape-change`
- `risk:host-api-mismatch`
- `risk:transform-semantics`
- `risk:contract-drift`
- `volatility:medium`
- `friction:high`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
