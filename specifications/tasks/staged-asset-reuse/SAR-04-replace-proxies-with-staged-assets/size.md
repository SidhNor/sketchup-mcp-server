# Size: SAR-04 Replace Proxies With Staged Assets

**Task ID**: `SAR-04`  
**Title**: `Replace Proxies With Staged Assets`  
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
- **Primary Scope Area**: staged asset reuse replacement
- **Likely Systems Touched**:
  - `replace_with_staged_asset` MCP command and runtime registration
  - proxy target resolution
  - approved exemplar resolution
  - Asset Instance creation reuse
  - workflow identity and semantic role preservation
  - previous representation removal or handoff policy
  - lineage serialization and replacement tests
- **Validation Class**: mixed
- **Likely Analog Class**: identity-preserving scene replacement

### Identity Notes
- Replacement depends on earlier curation, instantiation, and guardrail behavior and should not be treated as a generic semantic replacement clone.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new proxy-to-asset upgrade workflow with identity preservation and source lineage. |
| Technical Change Surface | 3 | Likely touches new command registration, target resolution, instantiation reuse, metadata handoff, and mutation operation behavior. |
| Hidden Complexity Suspicion | 4 | Identity handoff, semantic role preservation, previous representation policy, and no-partial-state behavior are high-risk seams. |
| Validation Burden Suspicion | 4 | Needs success, refusal, lineage, exemplar immutability, identity preservation, and live or hosted SketchUp checks. |
| Dependency / Coordination Suspicion | 3 | Depends on `SAR-01`, `SAR-02`, and `SAR-03`; downstream behavior inherits their contracts. |
| Scope Volatility Suspicion | 3 | Pressure may expand into broad replacement policy, archival behavior, or more target families. |
| Confidence | 2 | Product outcome is clear, but replacement policy and supported target breadth are intentionally unplanned at seed time. |

### Early Signals
- The HLD says replacement preserves business identity while changing representation.
- Existing semantic `replace_preserve_identity` is adjacent but not sufficient for staged asset replacement.
- Prior replacement and hosted-behavior analogs suggest validation and no-partial-state checks are likely significant.

### Early Estimate Notes
- Seed reflects a high-risk dependent feature slice that should remain after instantiation and guardrails.
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
- `systems:target-resolution`
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
