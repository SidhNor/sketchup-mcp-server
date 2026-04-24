# Size: MTA-02 Build Terrain State And Storage Foundation

**Task ID**: `MTA-02`  
**Title**: Build Terrain State And Storage Foundation  
**Status**: `seeded`  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-24  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: platform
- **Primary Scope Area**: managed terrain state, repository, and storage boundary
- **Likely Systems Touched**:
  - terrain domain model
  - terrain repository
  - SketchUp attribute storage adapter
  - serialization and stale-state validation
- **Validation Class**: regression-heavy
- **Likely Analog Class**: metadata-backed domain state foundation

### Identity Notes
- Foundation task for storing managed terrain state without leaking storage details into public MCP contracts.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Establishes managed terrain state behavior but does not yet author terrain geometry. |
| Technical Change Surface | 3 | Likely touches domain objects, repository, adapters, serialization, and tests. |
| Hidden Complexity Suspicion | 3 | Heightmap ownership, identity, stale detection, and attribute namespace choices are sensitive. |
| Validation Burden Suspicion | 3 | Needs isolated state tests plus adapter and compatibility coverage. |
| Dependency / Coordination Suspicion | 2 | Depends on domain posture and constrains adoption/edit tasks. |
| Scope Volatility Suspicion | 2 | Storage shape may resize when adoption and regeneration needs are made concrete. |
| Confidence | 2 | The direction is clear, but implementation details are not planned yet. |

### Early Signals
- The heightmap should not live in the existing `su_mcp` metadata dictionary.
- Runtime-facing outputs must stay JSON-serializable.
- Recovery and stale-state behavior should be accepted inside this foundation slice.

### Early Estimate Notes
- Seed reflects a medium platform slice with meaningful state and compatibility risk.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

Not filled yet.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

Not filled yet.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

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
- `scope:terrain-state-storage`
- `validation:regression-heavy`
- `systems:domain-repository-adapter-serialization`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
