# Size: SAR-02 Instantiate Editable Asset Instances

**Task ID**: `SAR-02`  
**Title**: `Instantiate Editable Asset Instances`  
**Status**: `seeded`  
**Created**: `2026-04-25`  
**Last Updated**: `2026-04-25`  

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: staged asset reuse instantiation
- **Likely Systems Touched**:
  - `instantiate_staged_asset` MCP command and runtime registration
  - Asset Exemplar resolver and approval checks
  - Asset Instance creation behavior
  - placement and scale handling
  - source asset lineage metadata
  - Managed Scene Object metadata integration
  - asset result serialization and tests
- **Validation Class**: mixed
- **Likely Analog Class**: hosted scene creation with metadata lineage

### Identity Notes
- Instantiation is the first mutating asset-reuse slice and must prove that Asset Instances are separate editable scene objects rather than mutated exemplars.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new mutating reuse workflow from approved exemplar to editable scene instance. |
| Technical Change Surface | 3 | Likely touches resolver, mutation operation, metadata, placement, serialization, runtime schema, tests, and docs. |
| Hidden Complexity Suspicion | 3 | Copy versus component-instance policy, origin/scale behavior, lineage, and exemplar immutability can hide complexity. |
| Validation Burden Suspicion | 4 | Needs no-exemplar-mutation proof, lineage checks, placement evidence, refusal paths, and likely live SketchUp verification. |
| Dependency / Coordination Suspicion | 2 | Depends on `SAR-01` metadata and approval semantics plus existing managed-object and targeting foundations. |
| Scope Volatility Suspicion | 3 | Pressure may expand into replacement, richer placement policy, or broad component instancing behavior. |
| Confidence | 2 | Outcome is clear, but implementation policy and host behavior are not technically planned yet. |

### Early Signals
- The PRD requires Asset Instances to retain source lineage and stop being treated as exemplars.
- Prior hosted semantic behavior analogs show live SketchUp proof is important for placement and no-partial-state confidence.
- Replacement is explicitly excluded to keep this slice focused.

### Early Estimate Notes
- Seed reflects a high-validation mutating feature slice with meaningful lineage and host-behavior risk.
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

- `archetype:feature`
- `scope:staged-asset-reuse`
- `validation:hosted-smoke`
- `systems:managed-object-metadata`
- `systems:asset-metadata`
- `systems:scene-mutation`
- `host:routine-smoke`
- `risk:partial-state`
- `volatility:high`
- `friction:medium`
- `rework:medium`
- `confidence:low`
<!-- SIZE:TAGS:END -->
