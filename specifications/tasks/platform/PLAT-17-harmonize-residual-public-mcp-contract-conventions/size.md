# Size: PLAT-17 Harmonize Residual Public MCP Contract Conventions

**Task ID**: PLAT-17  
**Title**: Harmonize Residual Public MCP Contract Conventions  
**Status**: calibrated  
**Created**: 2026-04-28  
**Last Updated**: 2026-04-28  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:platform
- **Primary Scope Area**: scope:platform
- **Likely Systems Touched**:
  - systems:loader-schema
  - systems:public-contract
  - systems:runtime-dispatch
  - systems:scene-query
  - systems:scene-mutation
  - systems:target-resolution
  - systems:serialization
  - systems:tool-response
  - systems:docs
  - systems:native-contract-fixtures
- **Validation Modes**: validation:contract, validation:docs-check, validation:regression, validation:public-client-smoke
- **Likely Analog Class**: cross-family-public-contract-convergence

### Identity Notes
- This task follows PLAT-14/15/16 and is shaped as a bounded public contract convergence pass rather than a net-new capability build.
- Planning rebaseline adds complete deletion of legacy `boolean_operation`, a full first-class shape/vocabulary sweep, and explicit meter-unit convergence at the MCP boundary.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Behavior remains contract convergence rather than new capability, but it removes a public tool and changes selector, response, and unit semantics across first-class surfaces. |
| Technical Change Surface | 4 | Likely spans runtime schema, public routing, command validation paths, target resolution, serializers, docs, README, native fixtures, and owning tests. |
| Hidden Complexity Suspicion | 3 | Existing mixed legacy selector, response, error, and unit semantics may hide coupling across command families and reused serializers. |
| Validation Burden Suspicion | 4 | Requires cross-family contract inventory, schema/runtime/docs/fixture parity, unit proof, and likely hosted smoke for target/transform/unit semantics. |
| Dependency / Coordination Suspicion | 2 | Platform-owned work with moderate coupling to existing capability seams and prior PLAT conventions. |
| Scope Volatility Suspicion | 3 | Bounded by convergence goals, but the required full public sweep may surface additional equivalent-concept drift that must be included or explicitly split. |
| Confidence | 2 | Good source context exists, but exact breadth of residual inconsistencies needs implementation-time confirmation. |

### Early Signals
- Prior tasks explicitly scoped out full cross-family harmonization, leaving a plausible residual convergence slice.
- Known public-surface seams include mixed selector contracts, mixed response casing, mixed invalid-input handling posture, and scene-query unit ambiguity.
- The refined plan deletes legacy `boolean_operation` rather than modernizing it with one-off `toolReference` vocabulary.
- Discoverability synchronization requires touching docs, README, runtime catalog, dispatch, and contract fixtures in lockstep with runtime behavior.

### Early Estimate Notes
- Seed suggests high technical and validation shape with moderate-high volatility; confidence remains medium-low until the full first-class sweep confirms affected seams.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Converges and removes existing public MCP contract behavior, but does not add a new product workflow or modeling capability. |
| Technical Change Surface | 3 | Spans loader schema, public routing/facade/server exposure, command assembly, command validation, scene-query serialization, unit conversion, docs, README, and native fixtures, but changes are concentrated in established contract seams. |
| Implementation Friction Risk | 2 | Work is mostly mechanical contract convergence and public removal, using existing command, response, resolver, and contract-test patterns. |
| Validation Burden Risk | 3 | Needs a full public sweep, cross-family contract tests, docs/schema/runtime/fixture parity, and meter-unit proof, but existing contract tests and fixtures reduce the proof cost. |
| Dependency / Coordination Risk | 1 | Platform-owned work with no expected external dependency or product replacement requirement. |
| Discovery / Ambiguity Risk | 2 | Canonical direction is clear; the sweep can still uncover additional equivalent-concept drift, but the plan defines split criteria for product redesign. |
| Scope Volatility Risk | 2 | "No residuals" can add equivalent-concept fixes, but the task explicitly excludes new capability design and replacement solid-modeling behavior. |
| Rework Risk | 2 | Rework pressure is moderate because inventory-first tests should catch stale docs, fixtures, legacy selectors, and unit leaks before broad edits settle. |
| Confidence | 3 | The refined plan, existing contract-test posture, and explicit non-goals support a more stable estimate. |

### Top Assumptions
- The task remains a public contract convergence pass and does not expand into new solid-modeling or semantic capability design.
- `boolean_operation` can be deleted from public catalog/routing/docs, command assembly, and implementation code without a hidden public dependency requiring replacement in the same task.
- A first-class public sweep can distinguish equivalent-concept drift from genuine role-specific vocabulary without product redesign.
- Runtime catalog, docs, fixtures, command validation, and meter conversion can be kept in lockstep within one implementation sequence.
- Shared selector work stays limited to direct-reference normalization, lookup strategy selection, and refusal mapping; it does not become a new targeting subsystem.

### Estimate Breakers
- Deleting `boolean_operation` exposes current product or test expectations that require a replacement public solid-modeling capability.
- The full shape/vocabulary sweep finds broad mixed conventions that cannot be harmonized without redesigning semantic or hierarchy tool boundaries.
- Unit semantics correction reveals deeper internal-unit leakage across shared serializers or stored data than scene-query bounds/origin changes.
- Public routing removal proves more coupled to runtime command assembly than expected, forcing larger factory/server changes.
- Selector reuse expands beyond direct-reference lookup into a broader targeting/query redesign.
- Hosted SketchUp smoke finds target-resolution, persistent-id, or transform-unit behavior that contradicts plain Ruby tests.

### Predicted Signals
- Existing catalog/schema shows mixed selector patterns and a legacy public `boolean_operation` entry.
- Scene-query serializer exposes snake_case fields while other first-class surfaces are camelCase oriented.
- Scene-query `bounds_to_h` returns SketchUp numeric lengths while public docs and HLDs require meter semantics at the MCP boundary.
- Public docs inventory currently advertises `boolean_operation` and legacy selector acceptance.
- Prior PLAT tasks intentionally deferred full cross-family harmonization, suggesting known residual complexity.

### Predicted Estimate Notes
- Predicted profile is moderate-high on technical surface and validation burden because the task intentionally removes residual public-contract drift rather than preserving compatibility aliases. Functional scope is moderate rather than high because this is contract convergence and public removal, not new capability work.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Validation burden remains a primary driver because the finalized plan requires a checked-in full first-class public sweep plus schema/runtime/docs/native-fixture parity for every included seam.
- Technical change surface is meaningful because the task touches public catalog removal, runtime dispatch/facade/server exposure, command assembly, command validation, serialization, docs, README, and native fixtures.
- Implementation friction is bounded by existing command, response, resolver, and contract-test patterns; the task is mostly contract convergence rather than new runtime architecture.
- Functional scope is moderate because the task removes and converges public contracts rather than adding new product workflows or modeling capabilities.

### Contested Drivers
- Whether the full first-class sweep will reveal additional direct-reference or response-vocabulary drift broad enough to force a follow-on split.
- Whether hosted SketchUp validation is needed for confidence, given that this task changes MCP contracts and serialization rather than core SketchUp behavior.
- Whether retaining any role-specific vocabulary after the sweep will be viewed as deliberate clarity or as residual mixed selector convention.

### Missing Evidence
- Implementation of the finalized plan's checked-in sweep table or fixture, confirming the exact included and ruled-out public tools, reference fields, response families, and geometry-bearing surfaces.
- Implementation evidence that complete `boolean_operation` deletion leaves no hidden public routing, command assembly, implementation code, stale docs, stale fixtures, or product expectation requiring replacement in this task.
- Implementation meter-conversion evidence for scene-query bounds/origin and public serializers that reuse `SceneQuerySerializer#bounds_to_h`.
- Native transport evidence that current-schema nuanced invalid requests still reach runtime validation where full structured refusal details are required.
- Hosted/runtime validation evidence for target references, persistent IDs, transforms, and scene-query geometry units.

### Recommendation
- confirm tightened revised profile

### Challenge Notes
- Premortem initially exposed a Tiger around an under-specified sweep: generic direct-reference fields such as `sample_surface_z.target` could survive as residual mixed vocabulary. The finalized plan mitigates this by requiring a checked-in sweep table and naming known candidates.
- User challenge surfaced concrete downward evidence: there is no new functional capability, `boolean_operation` removal avoids a one-off modernization path, and existing contract tests/fixtures already cover much of the intended proof style.
- Predicted scores were revised downward for functional scope, technical change surface, implementation friction, validation burden, dependency, discovery, volatility, and rework. Confidence increased because the refined plan is bounded and explicitly excludes compatibility, replacement capability design, and residual mixed-unit behavior.
- Follow-up selector investigation keeps the estimate stable: the plan now asks for a small reusable direct-reference facility that preserves native lookup fast paths, not a broad selector framework.
- Plan tightening after the complete boolean-deletion decision keeps the score profile stable. The plan is shorter and less ambiguous, but the touched runtime/docs/test surfaces are materially the same; complete deletion replaces the previous public-removal-plus-possible-internal-residual posture without adding a new capability.
- Validation burden remains `3` because proof still depends on full-catalog public contract inventory, unit semantics, docs/schema/runtime parity, and representative native transport cases. It is no longer `4` because the repository already has contract-test scaffolding and this is not expected to require broad hosted retest loops.
- Recommendation is to implement with the inventory-first phase and split only if the sweep reveals product-boundary redesign rather than equivalent-concept contract drift.
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
| Functional Scope | 2 | Moderate behavior-visible contract convergence: removed one public tool, tightened direct-reference inputs, normalized response identity/casing, and clarified meter-unit semantics without adding a new workflow. |
| Technical Change Surface | 3 | Touched loader schema, dispatcher/facade expectations, command factory assembly, scene-query commands/serialization, editing mutation payloads, target resolution, docs, native fixtures, and contract posture tests. |
| Actual Implementation Friction | 2 | Mostly followed established contract-test and command patterns; friction came from resolver hardening, compatibility-safe persistent ID access, and response identity cleanup rather than new architecture. |
| Actual Validation Burden | 3 | Required focused contract suites, full CI, package verification, JSON fixture checks, PAL code review, and an external MCP-client matrix with one follow-up cleanup loop. |
| Actual Dependency Drag | 1 | No upstream dependency or replacement capability was needed; only coordination was user/external-client feedback during final contract verification. |
| Actual Discovery Encountered | 2 | Found schema/RPC required-field behavior, response `id` remnants, a stale mutation resolver comment, source-absence guard needs, and SketchUp compatibility lint for direct `persistent_id` dispatch. |
| Actual Scope Volatility | 2 | Scope expanded within the planned contract-convergence boundary to remove response `id` aliases after hosted validation feedback; no product-boundary redesign or new tool family was added. |
| Actual Rework | 2 | Review and external validation caused bounded follow-up edits to docs, comments, source absence tests, identity payloads, fixtures, and tests; one CI lint fix was required. |
| Final Confidence in Completeness | 3 | Full CI and contract checks are green and external MCP validation covered the main matrix; confidence is high for code, with a remaining optional live re-run to confirm the final no-`id` payload after cleanup. |

### Actual Signals
- `boolean_operation` deletion remained a removal task rather than turning into a replacement solid-modeling capability.
- Canonical `targetReference` changes propagated through schema, command validation, dispatcher/facade tests, docs, and native fixtures.
- Public scene-query and mutation response identity cleanup was needed after external MCP validation surfaced remaining `id` echoes.
- Meter conversion was contained to scene-query serialization plus semantic double-conversion protection.
- External MCP matrix found schema/RPC invalid-params behavior for exact missing required fields; this matched the planned canonical-schema posture and did not require code changes.

### Actual Notes
- The original prediction was directionally accurate: high technical surface and validation burden, moderate implementation friction, and low dependency drag. The one material late adjustment was not hidden architecture; it was a public-contract purity decision to remove response `id` aliases after seeing how an external client would interpret them.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- Focused PLAT-17 subset passed before final review: 165 runs, 688 assertions, 0 failures, 31 skips.
- Full pre-review validation passed: `bundle exec rake ruby:test`, `bundle exec rake ruby:lint`, `bundle exec rake package:verify`, `bundle exec rake ci`, and JSON fixture parse checks.
- Post-review focused validation passed after code-review fixes: 31 runs, 140 assertions, 0 failures, 0 skips; focused RuboCop with cache disabled inspected 3 files with no offenses.
- After response identity cleanup, focused affected suite passed: 139 runs, 661 assertions, 0 failures, 30 skips.
- Final `bundle exec rake ci` passed: 202 files inspected with no RuboCop offenses; 790 runs, 3990 assertions, 0 failures, 35 skips; package verification produced `dist/su_mcp-0.26.0.rbz`.
- `git diff --check` passed.

### Hosted / Manual Validation
- External MCP-client scenario matrix ran after code review and confirmed tool inventory, removed `boolean_operation`, canonical `targetReference` schemas, sourceElementId/persistentId/entityId resolution, camelCase scene summary fields, meter-unit geometry, transform by `+1 m`, material application, delete by `targetReference.entityId`, predicate `targetSelector` behavior, and raw JSON-RPC `structuredContent`.
- The external matrix found two contract interpretation points: exact missing required fields are rejected by MCP schema/RPC validation before command-level structured refusals, and public responses still exposed `id` aliases. The schema/RPC behavior was accepted as aligned with the canonical-schema posture; the response `id` aliases were removed in follow-up code.
- The final no-`id` response payloads have not been re-run through the external MCP matrix after the cleanup; automated contract and full CI coverage are green.

### Performance Validation
- No separate performance benchmark was needed.
- Resolver tests assert native `entityId` and `persistentId` fast lookup paths avoid recursive traversal; metadata-backed `sourceElementId` remains traversal-backed by design.

### Migration / Compatibility Validation
- Not applicable (intentional breaking change; no compatibility window).

### Operational / Rollout Validation
- Package verification ran through `bundle exec rake ci` and produced `dist/su_mcp-0.26.0.rbz`.
- Public contract break is documented in `docs/mcp-tool-reference.md` and guarded by loader/schema, command, fixture, and posture tests.

### Validation Notes
- Validation burden was high because proof had to align runtime schema, runtime behavior, docs, fixtures, response vocabulary, unit semantics, and external MCP-client behavior. It did not reach very high because the host/client validation produced one bounded cleanup loop rather than repeated redeploy/restart/rerun debugging.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

- **Most Underestimated Dimension**: Rework. The prediction expected moderate rework, but the external MCP matrix made the response `id` aliases more clearly problematic and forced an additional contract cleanup after the main review.
- **Most Overestimated Dimension**: None materially; predicted implementation friction and validation burden were close. Dependency drag stayed low as expected because no replacement capability or external upstream change was required.
- **Signal Present Early But Underweighted**: The plan focused on request selector aliases and snake_case response keys, but equivalent identity aliases in response payloads (`id` beside `entityId`) deserved the same contract-sweep scrutiny from the start.
- **Genuinely Unknowable Factor**: External MCP schema validation behavior for exact missing required fields was only fully visible during client-matrix verification, but it aligned with the planned canonical-schema posture.
- **Future Similar Tasks Should Assume**: Public-contract convergence should inventory both input aliases and response aliases, and should include an external-client smoke before final summary wording is treated as stable.

### Calibration Notes
- Dominant actual failure mode: residual public-contract aliases surviving outside the most obvious schema fields. Future analog retrieval should use `contract:public-tool`, `contract:response-shape`, `risk:contract-drift`, `risk:schema-requiredness`, `validation:contract`, and `validation:public-client-smoke`.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

Use canonical values from the repo task-estimation taxonomy when present. Prefer compact atomic tags over compound tags; include only facets that help retrieve useful analogs.

- `archetype:platform`
- `scope:platform`
- `systems:loader-schema`
- `systems:public-contract`
- `systems:runtime-dispatch`
- `systems:scene-query`
- `systems:scene-mutation`
- `systems:target-resolution`
- `systems:serialization`
- `systems:tool-response`
- `systems:native-contract-fixtures`
- `systems:docs`
- `validation:contract`
- `validation:docs-check`
- `validation:public-client-smoke`
- `validation:regression`
- `host:single-fix-loop`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:runtime-dispatch`
- `contract:response-shape`
- `contract:docs-examples`
- `risk:contract-drift`
- `risk:schema-requiredness`
- `risk:unit-conversion`
- `risk:regression-breadth`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
