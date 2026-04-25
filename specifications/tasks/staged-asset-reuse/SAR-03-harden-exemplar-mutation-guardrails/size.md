# Size: SAR-03 Harden Exemplar Mutation Guardrails

**Task ID**: `SAR-03`  
**Title**: `Harden Exemplar Mutation Guardrails`  
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
- **Primary Scope Area**: staged asset reuse protection
- **Likely Systems Touched**:
  - exemplar-protection predicate
  - delete mutation path
  - transform mutation path
  - material mutation path
  - metadata mutation path
  - refusal response shaping
  - mutation tests and docs
- **Validation Class**: regression-heavy
- **Likely Analog Class**: cross-command mutation guardrail

### Identity Notes
- Guardrails are a protection-hardening slice across existing mutation surfaces, not a new asset creation flow.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds protection behavior across normal mutation tools but no new asset creation capability. |
| Technical Change Surface | 3 | Crosses several mutation paths and refusal/result conventions. |
| Hidden Complexity Suspicion | 3 | Must distinguish protected exemplars from editable Asset Instances without disrupting normal managed-object behavior. |
| Validation Burden Suspicion | 3 | Needs regression checks for protected refusals and non-exemplar mutation paths across multiple tools. |
| Dependency / Coordination Suspicion | 2 | Depends on `SAR-01` metadata contract and may interact with existing semantic/editing policy boundaries. |
| Scope Volatility Suspicion | 2 | Main risk is expanding into full integrity validation or unsupported manual UI protection. |
| Confidence | 2 | Guardrail need is clear, but exact mutation surfaces and centralization strategy are not technically planned yet. |

### Early Signals
- The PRD primary KPI requires zero accepted workflows that modify approved exemplars in place.
- PAL/Grok review warned that guardrails cannot wait until after replacement.
- Existing generic mutation tools know managed objects but not Asset Exemplars.

### Early Estimate Notes
- Seed reflects moderate functional scope with cross-cutting regression risk across mutation paths.
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
- `scope:mutation-guardrails`
- `validation:regression-heavy`
- `systems:editing-commands`
- `systems:metadata-mutation`
- `systems:tool-response`
- `systems:asset-protection`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:low`
<!-- SIZE:TAGS:END -->
