# Size: MTA-11 Design And Implement Durable Localized Terrain Representation v2

**Task ID**: `MTA-11`
**Title**: Design And Implement Durable Localized Terrain Representation v2
**Status**: `seeded`
**Created**: 2026-04-26
**Last Updated**: 2026-04-26

**Related Task**: [task.md](./task.md)
**Related Plan**: none yet
**Related Summary**: none yet

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform / migration
- **Primary Scope Area**: durable localized terrain state representation
- **Likely Systems Touched**:
  - terrain state model
  - terrain serializer and repository dispatch
  - migration and refusal behavior
  - compatibility tests
  - possible evidence schema evolution
- **Validation Class**: migration-sensitive / regression-heavy
- **Likely Analog Class**: terrain state storage and migration foundation

### Identity Notes
- Deferred representation task that changes persisted terrain state shape while preserving v1 `heightmap_grid` compatibility.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Enables localized terrain detail and larger extents, but may remain mostly internal unless evidence schemas evolve. |
| Technical Change Surface | 4 | Likely touches state model, serializer, repository, migration, tests, and possibly public evidence compatibility. |
| Hidden Complexity Suspicion | 4 | Storage versioning, v1 compatibility, localized units, migration/refusal behavior, and edit-kernel abstraction are sensitive. |
| Validation Burden Suspicion | 4 | Requires round-trip, migration, corrupt/unsupported payload, compatibility, and likely hosted persistence validation. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-07 direction and MTA-09 planning vocabulary, and may be pulled forward by MTA-10. |
| Scope Volatility Suspicion | 4 | Candidate representation shapes could split into design, migration, and implementation if planning uncovers broad storage risk. |
| Confidence | 2 | The need is clear, but the exact representation format and migration path are intentionally undecided. |

### Early Signals
- MTA-02 showed terrain storage foundation has high validation and rework sensitivity.
- MTA-07 intentionally did not introduce persisted v2 and kept contract/no-drift tests first.
- Any durable representation change must preserve exact v1 `heightmap_grid` round-trip behavior.
- Partial output regeneration may reveal whether durable output-region metadata is needed earlier.

### Early Estimate Notes
- Seed treats this as a high-risk migration/platform task with low-medium confidence until representation choices are planned and challenged.
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
- `archetype:migration`
- `scope:managed-terrain`
- `validation:migration`
- `systems:terrain-state`
- `systems:terrain-repository`
- `systems:serialization`
- `contract:response-shape`
- `risk:contract-drift`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
