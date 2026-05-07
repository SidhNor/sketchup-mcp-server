# Size: MTA-25 Productionize CDT Terrain Output With Current Backend Fallback

**Task ID**: `MTA-25`
**Title**: Productionize CDT Terrain Output With Current Backend Fallback
**Status**: `seeded`
**Created**: 2026-05-07
**Last Updated**: 2026-05-07

**Related Task**: [task.md](./task.md)
**Related Plan**: none yet
**Related Summary**: none yet

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: `archetype:performance-sensitive`
- **Primary Scope Area**: `scope:managed-terrain`
- **Likely Systems Touched**:
  - `systems:terrain-output`
  - `systems:terrain-mesh-generator`
  - `systems:terrain-kernel`
  - `systems:public-contract`
  - `systems:scene-mutation`
- **Validation Modes**: `validation:performance`, `validation:hosted-matrix`, `validation:contract`, `validation:undo`, `validation:persistence`
- **Likely Analog Class**: production terrain backend promotion from comparison prototype with fallback gates

### Identity Notes
- MTA-25 turns the MTA-24 CDT direction into a production output path rather than another
  comparison-only bakeoff.
- Current production output remains a required fallback, so this is a gated productionization task,
  not a direct backend swap.
- MTA-24 calibration is the closest analog, especially its repeated hosted validation and
  evidence-harness cleanup lessons.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Makes CDT eligible for production terrain output while preserving current fallback and public contract stability. |
| Technical Change Surface | 4 | Likely spans production output routing, CDT backend hardening, fallback gates, harness cleanup, contract tests, hosted validation support, and packaging checks. |
| Hidden Complexity Suspicion | 4 | Runtime gates, topology validity, constraint recovery, fallback correctness, and separation of prototype harnesses from runtime ownership are high-risk. |
| Validation Burden Suspicion | 4 | Requires full local validation plus hosted production-path evidence, fallback cases, performance interpretation, undo, and save/reopen where practical. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-20 feature geometry, MTA-22 fixtures, MTA-24 CDT evidence, live SketchUp access, and user visual validation. |
| Scope Volatility Suspicion | 3 | The task is bounded by fallback-first productionization, but runtime or constraint failures may split native acceleration or contract work into separate tasks. |
| Confidence | 2 | MTA-24 gives strong direction, but production routing and fallback quality still need a technical plan and hosted proof. |

### Early Signals
- MTA-24 selected CDT directionally but explicitly did not claim production readiness.
- MTA-24 found that live validation and equivalence proof can dominate terrain backend work.
- Runtime pressure on high-relief and residual retriangulation cases is already known.
- Hard-geometry classifier precision and conservative protected-crossing metrics need production
  acceptance criteria before fallback can be narrowed.
- Task-specific MTA-24 bakeoff helpers must be isolated or removed before long-lived production
  wiring.

### Early Estimate Notes
- Seed scoring uses MTA-24 as a calibrated analog. The strongest risk is not whether CDT can emit
  candidate meshes; it is whether CDT can become a production path with deterministic fallback,
  stable contracts, and hosted acceptance.
- Native C++ remains a possible planning outcome but is not assumed in the seed.
- The technical plan should evaluate a native/C++ triangulation library adapter if pure Ruby CDT
  cannot satisfy production runtime gates, while avoiding premature native packaging scope in the
  task definition.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Implementation Friction Risk | <0-4> | <short note> |
| Validation Burden Risk | <0-4> | <short note> |
| Dependency / Coordination Risk | <0-4> | <short note> |
| Discovery / Ambiguity Risk | <0-4> | <short note> |
| Scope Volatility Risk | <0-4> | <short note> |
| Rework Risk | <0-4> | <short note> |
| Confidence | <0-4> | <short note> |

### Top Assumptions
- Not filled yet.

### Estimate Breakers
- Not filled yet.

### Predicted Signals
- Not filled yet.

### Predicted Estimate Notes
- Not filled yet.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Not filled yet.

### Contested Drivers
- Not filled yet.

### Missing Evidence
- Not filled yet.

### Recommendation
- Not filled yet.

### Challenge Notes
- Not filled yet.
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

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | <0-4> | <short note> |
| Technical Change Surface | <0-4> | <short note> |
| Actual Implementation Friction | <0-4> | <short note> |
| Actual Validation Burden | <0-4> | <short note> |
| Actual Dependency Drag | <0-4> | <short note> |
| Actual Discovery Encountered | <0-4> | <short note> |
| Actual Scope Volatility | <0-4> | <short note> |
| Actual Rework | <0-4> | <short note> |
| Final Confidence in Completeness | <0-4> | <short note> |

### Actual Signals
- Not filled yet.

### Actual Notes
- Not filled yet.
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

- **Most Underestimated Dimension**: <dimension + why>
- **Most Overestimated Dimension**: <dimension + why>
- **Signal Present Early But Underweighted**: <note>
- **Genuinely Unknowable Factor**: <note or `none identified`>
- **Future Similar Tasks Should Assume**: <note>

### Calibration Notes
- Not filled yet.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:performance-sensitive`
- `scope:managed-terrain`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:terrain-kernel`
- `validation:performance`
- `validation:hosted-matrix`
- `validation:contract`
- `validation:undo`
- `validation:persistence`
- `host:repeated-fix-loop`
- `contract:no-public-shape-change`
- `risk:performance-scaling`
- `risk:transform-semantics`
- `volatility:medium`
- `confidence:low`
<!-- SIZE:TAGS:END -->
