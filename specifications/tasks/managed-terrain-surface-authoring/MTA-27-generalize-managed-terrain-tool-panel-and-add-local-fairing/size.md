# Size: MTA-27 Generalize Managed Terrain Tool Panel And Add Local Fairing

**Task ID**: `MTA-27`  
**Title**: `Generalize Managed Terrain Tool Panel And Add Local Fairing`  
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
- **Likely Analog Class**: shared SketchUp terrain tool panel over existing command-backed edit modes

### Identity Notes
- This task proves the Managed Terrain toolbar/panel split with two round-brush tools: target height and local fairing. It should generalize only enough for those two existing command-backed modes.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a second user-facing terrain tool and converts the dialog into a shared active-tool panel. |
| Technical Change Surface | 3 | Likely touches toolbar command registry, panel protocol, tool activation, request construction, shared selection/status handling, assets, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Risks center on focus/tool reactivation, active button state, panel state synchronization, and avoiding overgeneralized abstractions. |
| Validation Burden Suspicion | 3 | Needs local tool/panel/request coverage plus hosted smoke for two toolbar buttons, panel switching, and local fairing apply. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-18, MTA-26, and MTA-06, but reuses existing command behavior and avoids public contract changes. |
| Scope Volatility Suspicion | 2 | Scope can expand if corridor/control-point abstractions leak into this task; the accepted boundary is two round-brush tools only. |
| Confidence | 2 | The product boundary is clear, but MTA-18 showed shared host UI state is live-sensitive. |

### Early Signals
- The task is the abstraction proof point: one toolbar, one shared panel, two concrete tools.
- Local fairing already exists as terrain command behavior, so terrain math should stay out of scope.
- User explicitly wanted toolbar wording and UI controls to distinguish the container from tool buttons.
- Hosted validation is likely needed for active-tool switching and dialog/tool focus behavior.

### Early Estimate Notes
- Strong analogs are MTA-18 for UI lifecycle and MTA-06 for existing local fairing behavior. Analog use should not imply new kernel risk.
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
- `systems:docs`
- `validation:hosted-smoke`
- `host:routine-smoke`
- `contract:no-public-shape-change`
- `risk:host-api-mismatch`
- `risk:visibility-semantics`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
