# Size: PLAT-17 Harmonize Residual Public MCP Contract Conventions

**Task ID**: PLAT-17  
**Title**: Harmonize Residual Public MCP Contract Conventions  
**Status**: challenged  
**Created**: 2026-04-28  
**Last Updated**: 2026-04-28  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:platform
- **Primary Scope Area**: scope:platform
- **Likely Systems Touched**:
  - systems:loader-schema
  - systems:public-contract
  - systems:scene-query
  - systems:scene-mutation
  - systems:serialization
  - systems:docs
  - systems:native-contract-fixtures
- **Validation Modes**: validation:contract, validation:docs-check, validation:regression
- **Likely Analog Class**: cross-family-public-contract-convergence

### Identity Notes
- This task follows PLAT-14/15/16 and is shaped as a bounded public contract convergence pass rather than a net-new capability build.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Behavior is mostly contract convergence and discoverability hardening rather than a new capability family. |
| Technical Change Surface | 3 | Likely spans runtime schema, command validation paths, serializers, docs, and native contract fixtures. |
| Hidden Complexity Suspicion | 3 | Existing mixed legacy selector and error semantics may hide coupling across multiple command families. |
| Validation Burden Suspicion | 3 | Requires cross-family contract verification and docs/runtime/schema/fixture sync checks. |
| Dependency / Coordination Suspicion | 2 | Platform-owned work with moderate coupling to existing capability seams and prior PLAT conventions. |
| Scope Volatility Suspicion | 2 | Bounded by convergence goals but could expand if additional residual drift is discovered. |
| Confidence | 2 | Good source context exists, but exact breadth of residual inconsistencies needs implementation-time confirmation. |

### Early Signals
- Prior tasks explicitly scoped out full cross-family harmonization, leaving a plausible residual convergence slice.
- Known public-surface seams include mixed selector contracts, mixed response casing, and mixed invalid-input handling posture.
- Discoverability synchronization requires touching docs and contract fixtures in lockstep with runtime behavior.

### Early Estimate Notes
- Seed suggests medium-high technical and validation shape with moderate volatility; confidence remains medium-low until full implementation inventory confirms affected seams.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Converges existing public MCP contract behavior and discoverability rather than adding a new tool family. |
| Technical Change Surface | 3 | Likely spans loader schema, scene-query serialization, mutation selectors, refusal pathways, docs, and native contract fixtures. |
| Implementation Friction Risk | 3 | Removing mixed legacy shapes across commands requires coordinated breaking-change updates and careful sequencing. |
| Validation Burden Risk | 3 | Needs cross-family contract tests plus docs/schema/runtime parity checks to avoid partial convergence drift. |
| Dependency / Coordination Risk | 2 | Platform-owned but coupled to scene-query, editing, modeling, and native runtime boundaries. |
| Discovery / Ambiguity Risk | 2 | Canonical contract direction is clear, but exact touched seam inventory still needs disciplined implementation-time confirmation. |
| Scope Volatility Risk | 2 | Task is bounded, but discovery may reveal additional residual inconsistencies that pressure scope growth. |
| Rework Risk | 3 | Inconsistent client-facing contracts can trigger iterative revisions if deltas are not harmonized end-to-end. |
| Confidence | 2 | Strong problem framing exists, but full breadth of residual drift still requires implementation-time inventorying. |

### Top Assumptions
- The task remains a bounded convergence pass and does not expand into semantic capability redesign.
- A canonical selector and response vocabulary can be adopted without introducing a second runtime path.
- First-class caller-recoverable invalid input paths can be normalized to structured refusals on touched surfaces.
- Runtime catalog, docs, and fixtures can be kept in lockstep within one implementation sequence.

### Estimate Breakers
- Breaking-change removal of legacy selectors (`id`, `target_id`, `tool_id`) exposes additional undocumented dependencies outside currently scoped tools.
- Cross-family response vocabulary convergence exposes deeper serializer coupling than expected.
- Error-path harmonization reveals transport-boundary assumptions that require larger refactors.
- Unit semantics correction uncovers hidden dependency on existing client assumptions or stale fixtures.

### Predicted Signals
- Existing catalog/schema already shows mixed selector and naming patterns across tool families.
- Scene-query serializer currently exposes snake_case fields while other first-class surfaces are camelCase oriented.
- Public docs inventory and unit semantics are currently susceptible to runtime drift.
- Prior PLAT tasks intentionally deferred full cross-family harmonization, suggesting known residual complexity.

### Predicted Estimate Notes
- Predicted profile is moderate-to-high due to cross-family contract coupling and validation burden, while functional expansion remains intentionally limited.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Validation burden is a primary driver because schema, runtime behavior, docs, and fixtures must ship together for every touched public seam.
- Implementation friction is likely moderate-high because selector, response, and refusal conventions are uneven across command families.
- Functional scope should stay moderate because the task converges existing behavior rather than introducing new capability surfaces.

### Contested Drivers
- Whether any additional public tools beyond the current touched set must be included immediately to avoid partial selector convergence.
- Whether response-vocabulary convergence should be full immediate normalization or staged normalization across touched seams.

### Missing Evidence
- Focused implementation inventory confirming exact touched commands and serializers.
- Finalized removed-field refusal codes/messages for touched mutation and modeling tools.
- Hosted/runtime validation evidence if any touched behavior depends on real SketchUp lifecycle semantics.
- Implementation-time confirmation that staged response-vocabulary normalization does not leak mixed casing into untouched public paths.

### Recommendation
- confirm estimate

### Challenge Notes
- Independent review and premortem both indicate no blocking Tigers when convergence is phased through explicit contract artifact synchronization and strict breaking-change guardrails.
- Challenge pass tested three contested drivers (selector removal scope, normalization sequencing, and parity gate strictness) and retained the predicted profile.
- No predicted-score revision is justified yet; contested items remain sequencing and evidence-gathering controls rather than signs of wider functional scope.
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
- Not applicable (intentional breaking change; no compatibility window).

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
- <short note>
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Prefer compact atomic tags over compound tags; include only facets that help retrieve useful analogs.

- `archetype:platform`
- `scope:platform`
- `systems:loader-schema`
- `systems:public-contract`
- `systems:scene-query`
- `systems:scene-mutation`
- `systems:serialization`
- `systems:native-contract-fixtures`
- `systems:docs`
- `validation:contract`
- `validation:docs-check`
- `validation:regression`
- `host:not-needed`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:response-shape`
- `contract:docs-examples`
- `risk:contract-drift`
- `risk:schema-requiredness`
- `risk:regression-breadth`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
