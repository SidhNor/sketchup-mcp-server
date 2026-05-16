# Size: SAR-03 Harden Exemplar Mutation Guardrails

**Task ID**: `SAR-03`  
**Title**: `Harden Exemplar Mutation Guardrails`  
**Status**: `cancelled`
**Created**: `2026-04-25`  
**Last Updated**: `2026-05-16`

**Related Task**: [task.md](./task.md)  
**Related Plan**: none yet  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: staged asset reuse protection
- **Likely Systems Touched**:
  - approved-exemplar predicate
  - delete mutation path
  - transform mutation path
  - material mutation path
  - metadata mutation path
  - refusal response shaping
  - mutation tests and docs
- **Validation Class**: regression-heavy
- **Likely Analog Class**: cancelled cross-command mutation guardrail

### Identity Notes
- Cancelled after SAR-02 established source-stability semantics and the product policy kept explicit generic mutation of targeted exemplars allowed.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 0 | Runtime guardrail work is cancelled; source-stability remains in reuse workflows. |
| Technical Change Surface | 0 | No code or public MCP contract changes are planned for SAR-03. |
| Hidden Complexity Suspicion | 1 | Remaining complexity is documentation and dependency cleanup. |
| Validation Burden Suspicion | 1 | Validation belongs to SAR-02 and SAR-04 source-stability checks, not this cancelled task. |
| Dependency / Coordination Suspicion | 1 | SAR-04 no longer depends on SAR-03. |
| Scope Volatility Suspicion | 1 | Cancellation avoids expanding into duplicate maintenance surfaces or broad asset locking. |
| Confidence | 3 | SAR-02 behavior and explicit target-reference mutation semantics make the runtime guardrail unnecessary under the chosen policy. |

### Early Signals
- SAR-02 creates separate Asset Instances and leaves source exemplars unchanged during instantiation.
- Generic mutation commands require explicit target references, so editing an exemplar is an intentional targeted operation rather than an implicit reuse side effect.
- Adding refusals to generic mutation paths would require a duplicate or override-based maintenance surface, which is not desired.

### Early Estimate Notes
- Seed is retired. Source-stability validation should stay attached to the reuse workflows that select exemplars as sources.
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

- 2026-05-16: Cancelled SAR-03 as a runtime mutation-refusal task. Product policy now allows explicit generic mutation of targeted Asset Exemplars while requiring instantiation and replacement workflows to preserve selected source exemplars.
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
- `status:cancelled`
- `validation:source-stability`
- `systems:asset-reuse-policy`
- `systems:task-dependency`
- `risk:duplicate-surface`
- `volatility:low`
- `friction:low`
- `rework:low`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
