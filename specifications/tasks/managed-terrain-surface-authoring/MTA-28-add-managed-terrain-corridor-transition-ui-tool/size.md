# Size: MTA-28 Add Managed Terrain Corridor Transition UI Tool

**Task ID**: `MTA-28`  
**Title**: `Add Managed Terrain Corridor Transition UI Tool`  
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
- **Likely Analog Class**: non-brush SketchUp terrain UI tool over existing corridor edit command

### Identity Notes
- This task adds the first distinct visual cue family after round brushes. Corridor transition UI should reuse the shared panel foundation while keeping corridor geometry separate from survey and planar point-list UX.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new user-facing tool with multi-point corridor controls and a corridor-specific overlay. |
| Technical Change Surface | 3 | Likely touches tool registry, panel inputs, point capture, corridor request construction, overlay drawing, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Start/end capture, elevation entry, corridor width/shoulder visualization, transforms, and invalid corridor state are likely friction points. |
| Validation Burden Suspicion | 3 | Existing corridor math lowers kernel risk, but live SketchUp proof is needed for point capture, overlay, apply, and undo posture. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-27 and MTA-05; no public contract or terrain kernel change is expected. |
| Scope Volatility Suspicion | 2 | Scope is distinct and demonstrable, but could expand if point-list or hardscape-reference behavior is pulled in prematurely. |
| Confidence | 2 | Requirements are concrete, but no corridor UI analog exists yet in the repo. |

### Early Signals
- MTA-05 calibrated corridor math and hosted validation, but this task owns UI capture and overlay rather than solver behavior.
- Corridor cue geometry is not a round-brush variant and should be planned as its own visual family.
- The accepted boundary excludes survey and planar point-list UX.
- Hosted verification should focus on real control capture, visual cue behavior, command handoff, and undo posture.

### Early Estimate Notes
- Strong analogs are MTA-18 for SketchUp UI lifecycle and MTA-05 for corridor request semantics. Use MTA-05 as a contract/intent analog, not as evidence of new kernel scope.
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
- `risk:undo-semantics`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
