# Size: MTA-26 Add Managed Terrain Brush Overlay Feedback

**Task ID**: `MTA-26`  
**Title**: `Add Managed Terrain Brush Overlay Feedback`  
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
- **Validation Modes**: `validation:hosted-smoke`, `validation:undo`
- **Likely Analog Class**: SketchUp terrain tool overlay refinement over existing managed edit command

### Identity Notes
- This task extends the MTA-18 toolbar/dialog/tool loop with transient viewport feedback for the existing target-height brush. It should not add terrain math, public contract changes, or new edit modes.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds visible brush feedback to one existing UI tool without changing supported edit modes. |
| Technical Change Surface | 3 | Likely touches SketchUp tool draw/hover lifecycle, UI state, coordinate conversion, status feedback, and tests. |
| Hidden Complexity Suspicion | 3 | Host draw timing, view invalidation, transform semantics, and valid/invalid hover targeting can hide live-only issues. |
| Validation Burden Suspicion | 3 | Local seams can check state, but real overlay behavior needs SketchUp-hosted smoke and undo/non-mutation checks. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-18 and existing target-height command behavior; no new public contract or solver dependency is planned. |
| Scope Volatility Suspicion | 2 | Scope is narrow, but overlay foundation may attract future-tool abstraction pressure if not held to target height. |
| Confidence | 2 | Requirements are clear, but MTA-18 showed host UI behavior can require live fix loops. |

### Early Signals
- MTA-18 actuals showed toolbar/dialog/tool lifecycle risks and repeated live patching around SketchUp host behavior.
- The task deliberately keeps mutation behavior unchanged and adds only transient feedback.
- The overlay must prove the brush radius and falloff cue without creating persistent model geometry.
- Transform and selected-terrain semantics remain likely validation pressure points.

### Early Estimate Notes
- Strongest analog is calibrated MTA-18. Use it for host UI lifecycle and validation shape, not for terrain math or public contract risk.
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
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
