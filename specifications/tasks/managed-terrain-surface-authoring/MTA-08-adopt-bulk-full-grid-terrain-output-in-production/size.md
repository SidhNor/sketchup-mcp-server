# Size: MTA-08 Adopt Bulk Full-Grid Terrain Output In Production

**Task ID**: `MTA-08`
**Title**: Adopt Bulk Full-Grid Terrain Output In Production
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
- **Primary Scope Area**: managed terrain derived output generation
- **Likely Systems Touched**:
  - terrain mesh generation
  - terrain output summaries
  - derived-output markers and normals
  - public create/edit hosted validation
  - fallback output path
- **Validation Class**: mixed / performance-sensitive / manual-heavy
- **Likely Analog Class**: terrain output-path production adoption

### Identity Notes
- Follow-on from MTA-07 that promotes the validated bulk full-grid candidate into production without changing persisted terrain state or public MCP request vocabulary.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | User-visible performance and production behavior change, but the public tool shape and terrain state semantics should stay stable. |
| Technical Change Surface | 3 | Likely touches mesh generation, output summaries, tests, and hosted validation while avoiding repository or public schema changes. |
| Hidden Complexity Suspicion | 3 | Bulk output must preserve derived markers, normals, digest linkage, undo, cleanup, and fallback behavior exactly. |
| Validation Burden Suspicion | 4 | MTA-07 showed output-path work needs live timing, high-variation terrain, undo, responsiveness, markers, and normals checks. |
| Dependency / Coordination Suspicion | 2 | Depends on MTA-07 evidence and live SketchUp validation access, but not on schema v2 or partial regeneration. |
| Scope Volatility Suspicion | 2 | Scope is bounded if kept to full-grid output; volatility rises if partial output or public contract changes are pulled in. |
| Confidence | 3 | Direction is well supported by MTA-07, with confidence capped until production wiring is planned and hosted retested. |

### Early Signals
- MTA-07 proved equivalent full-grid bulk output in grey-box checks with a large near-cap performance delta.
- Production `generate` and `regenerate` still use the slower per-face path.
- Existing public evidence and persisted `heightmap_grid` v1 must remain stable.
- MTA-04 and MTA-07 both show live SketchUp validation is mandatory for terrain output changes.

### Early Estimate Notes
- Seed treats this as a focused production-output adoption task with high validation burden and controlled functional scope.
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
- `scope:managed-terrain-output-generation`
- `validation:mixed-performance-manual`
- `systems:terrain-mesh-generator-output-summary-hosted-validation`
- `host:sketchup-live-validation`
- `contract:public-vocabulary-stability`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
