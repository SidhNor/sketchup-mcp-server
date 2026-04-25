# Size: SAR-01 Curate And Discover Approved Asset Exemplars

**Task ID**: `SAR-01`  
**Title**: `Curate And Discover Approved Asset Exemplars`  
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
- **Primary Scope Area**: staged asset reuse curation and discovery
- **Likely Systems Touched**:
  - Asset Exemplar metadata and approval policy
  - staged asset library organization
  - target resolution for in-model assets
  - `list_staged_assets` MCP command and runtime registration
  - JSON-safe asset summary serialization
  - initial exemplar-protection predicate
  - task-level tests and user-facing docs for the new tool surface
- **Validation Class**: mixed
- **Likely Analog Class**: metadata-backed domain discovery vertical slice

### Identity Notes
- First staged-asset slice combines curation metadata, approval policy, discovery, and initial guardrail posture because discovery needs a supported way to create approved exemplars.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Creates the first product-visible staged-asset workflow: register an in-model asset and discover it as approved. |
| Technical Change Surface | 3 | Likely touches metadata policy, target resolution, staging organization, command registration, serialization, tests, and docs. |
| Hidden Complexity Suspicion | 3 | Resolution by name or target, staging movement, approval semantics, and exemplar/instance distinction can hide edge cases. |
| Validation Burden Suspicion | 3 | Needs positive discovery, excluded unapproved assets, refusal cases, JSON-safe output, and likely hosted SketchUp checks. |
| Dependency / Coordination Suspicion | 2 | Depends on existing targeting and serialization foundations but introduces a new product namespace and public tool surface. |
| Scope Volatility Suspicion | 3 | Pressure may appear to absorb rich curation, Warehouse import, versioning, or deeper guardrails unless boundaries stay explicit. |
| Confidence | 2 | Direction is source-backed, but no asset implementation exists and final metadata shape is not technically planned yet. |

### Early Signals
- The task starts from a zero staged-asset implementation baseline.
- User-curated 3D Warehouse assets are in scope only after they are already present in the model.
- PAL/Grok review pushed curation, discovery, and initial protection into one demonstrable first slice.
- Prior metadata-backed and hosted-behavior analogs suggest validation burden can exceed apparent command count.

### Early Estimate Notes
- Seed reflects a moderate-to-large first feature slice because it establishes the asset metadata contract and proves it through a public discovery tool.
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
- `scope:asset-curation-discovery`
- `validation:mixed`
- `systems:metadata-policy`
- `systems:mcp-tool-registration`
- `systems:scene-query-serialization`
- `systems:target-resolution`
- `volatility:high`
- `friction:medium`
- `rework:medium`
- `confidence:low`
<!-- SIZE:TAGS:END -->
