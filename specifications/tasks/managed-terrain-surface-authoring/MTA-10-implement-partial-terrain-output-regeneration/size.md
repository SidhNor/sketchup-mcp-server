# Size: MTA-10 Implement Partial Terrain Output Regeneration

**Task ID**: `MTA-10`
**Title**: Implement Partial Terrain Output Regeneration
**Status**: `seeded`
**Created**: 2026-04-26
**Last Updated**: 2026-04-26

**Related Task**: [task.md](./task.md)
**Related Plan**: none yet
**Related Summary**: none yet

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform / performance-sensitive
- **Primary Scope Area**: partial terrain derived-output regeneration
- **Likely Systems Touched**:
  - terrain output ownership
  - mesh region replacement
  - seam and adjacency handling
  - derived markers and normals
  - undo/save/reopen hosted validation
  - fallback or refusal behavior
- **Validation Class**: mixed / manual-heavy / performance-sensitive
- **Likely Analog Class**: host-sensitive terrain output mutation

### Identity Notes
- Deferred output-layer task with high hidden complexity because it changes from full disposable output replacement to regional output replacement.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Substantial performance-visible behavior for localized edits, while public edit modes may remain unchanged. |
| Technical Change Surface | 4 | Likely touches output ownership, mesh generation, cleanup, seams, undo, tests, and hosted validation. |
| Hidden Complexity Suspicion | 4 | Seam coherence, derived markers, normals, fallback/refusal, and output-region ownership are all high-risk. |
| Validation Burden Suspicion | 4 | Needs live SketchUp validation for partial edits, adjacency, undo, save/reopen, markers, normals, and performance. |
| Dependency / Coordination Suspicion | 3 | Depends on bulk output and region-aware planning, and may force a minimal v2 metadata dependency. |
| Scope Volatility Suspicion | 4 | Scope may split if durable output-region metadata or schema work is required for safe partial replacement. |
| Confidence | 2 | Direction is clear, but implementation feasibility and storage coupling are intentionally unproven. |

### Early Signals
- MTA-07 proved faster full-grid bulk output, not partial regeneration.
- Grok review identified partial/v2 coupling as the main hidden dependency to watch.
- MTA-04 and MTA-07 show terrain output correctness depends on hosted checks for normals, markers, cleanup, undo, and responsiveness.
- Full bulk regeneration must remain the safe fallback if partial seams cannot be proven.

### Early Estimate Notes
- Seed treats this as a high-risk deferred platform task whose plan may need to split around durable output-region metadata.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

Not filled yet.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

Not filled yet.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

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

- `archetype:platform`
- `archetype:performance-sensitive`
- `scope:partial-terrain-output-regeneration`
- `validation:mixed-performance-manual`
- `systems:terrain-output-ownership-mesh-seams-derived-markers-undo`
- `host:sketchup-live-validation`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:low-medium`
<!-- SIZE:TAGS:END -->
