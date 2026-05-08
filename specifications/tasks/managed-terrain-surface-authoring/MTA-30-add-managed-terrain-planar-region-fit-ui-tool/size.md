# Size: MTA-30 Add Managed Terrain Planar Region Fit UI Tool

**Task ID**: `MTA-30`  
**Title**: `Add Managed Terrain Planar Region Fit UI Tool`  
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
- **Likely Analog Class**: control-point SketchUp terrain UI tool over existing planar edit command

### Identity Notes
- This task reuses the point-list/support-region UI foundation from MTA-29 for explicit planar region fit. It should preserve planar intent as distinct from survey correction and avoid changing planar terrain math.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new user-facing planar control tool with point management, support-region cueing, and planar-specific readiness/refusal feedback. |
| Technical Change Surface | 3 | Likely touches shared point-list UI reuse, planar-control state, request construction, overlay markers, command handoff, docs, and tests. |
| Hidden Complexity Suspicion | 3 | Three-control readiness, invalid control feedback, support-region validity, and planar-vs-survey semantics can hide edge cases. |
| Validation Burden Suspicion | 3 | Existing planar math reduces kernel risk, but UI control state and hosted command handoff still need focused proof. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-29 point-list foundation and MTA-16 planar command behavior. |
| Scope Volatility Suspicion | 2 | Scope is concrete if MTA-29 lands reusable point-list UX; volatility rises only if planar controls need a different interaction model. |
| Confidence | 2 | Boundaries are clear, but they depend on an unimplemented MTA-29 foundation. |

### Early Signals
- MTA-16 calibrated planar fit as representation-sensitive, but this UI task should reuse its refusals instead of changing terrain math.
- This task was split from survey UI to avoid mixing two semantic tool families in one implementation.
- The user-facing distinction between explicit planar fit and survey correction remains a core product constraint.
- Hosted smoke should cover point-list reuse, insufficient-control feedback, support-region cueing, command refusal, and undo posture.

### Early Estimate Notes
- Strong analogs are MTA-18 for SketchUp UI lifecycle, MTA-29 as planned immediate predecessor, and MTA-16 for planar semantics. Seed confidence stays moderate-low until MTA-29 exists.
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
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
