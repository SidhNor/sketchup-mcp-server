# Size: MTA-40 Add Forced Subdivision Masks For Feature-Critical Geometry

**Task ID**: MTA-40  
**Title**: Add Forced Subdivision Masks For Feature-Critical Geometry  
**Status**: seeded  
**Created**: 2026-05-15  
**Last Updated**: 2026-05-15  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:validation-heavy`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-state`
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:validation-service`
- **Validation Modes**:
  - `validation:hosted-matrix`
  - `validation:performance`
  - `validation:regression`
  - `validation:contract`
- **Likely Analog Class**: MTA-36 lifecycle with stronger feature-topology validation; MTA-20 feature intent as source context

### Identity Notes
- Seeded as the first topology-affecting feature-aware adaptive task. It must refuse unsupported hard/protected cases before mutation.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Moves from feature-guided density to supported feature-critical topology pressure. |
| Technical Change Surface | 3 | Likely touches masks, adaptive split decisions, validation, diagnostics, and fallback routing. |
| Hidden Complexity Suspicion | 3 | Risk comes from feature geometry edge cases and distinguishing height correctness from topology correctness. |
| Validation Burden Suspicion | 3 | Requires hosted rows for supported masks, unsupported refusal, no-delete, timing, and face count. |
| Dependency / Coordination Suspicion | 2 | Hard dependency on MTA-39 and the MTA-38 harness. |
| Scope Volatility Suspicion | 3 | Supported feature geometry boundary may need narrowing during technical planning. |
| Confidence | 2 | Architecture direction is clear; exact mask policy and refusal limits remain to plan. |

### Early Signals
- First major topology-affecting slice.
- Unsupported hard/protected approximation must fail safely.
- Later seam work depends on this behavior being explicit.

### Early Estimate Notes
- Seed only. Do not treat this as the predicted implementation estimate.
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

- `archetype:validation-heavy`
- `scope:managed-terrain`
- `systems:terrain-state`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:validation-service`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:contract`
- `host:routine-matrix`
- `contract:no-public-shape-change`
- `risk:partial-state`
- `volatility:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
