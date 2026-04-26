# Size: MTA-12 Add Circular Terrain Regions And Preserve Zones

**Task ID**: `MTA-12`  
**Title**: Add Circular Terrain Regions And Preserve Zones  
**Status**: `calibrated`
**Created**: 2026-04-26  
**Last Updated**: 2026-04-26  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: managed terrain circular edit regions
- **Likely Systems Touched**:
  - public `edit_terrain_surface` contract
  - terrain request validation
  - terrain edit kernels
  - terrain evidence
  - native loader schema and contract fixtures
  - README terrain examples
- **Validation Modes**: contract, hosted-matrix
- **Likely Analog Class**: public terrain edit contract extension

### Identity Notes
- This is a bounded public contract and terrain-kernel extension. The closest analog is `MTA-04`, but scope is narrower because terrain edit orchestration, storage, output regeneration, and partial regeneration already exist.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds round local edit and preserve behavior across existing local-area terrain edit modes. |
| Technical Change Surface | 3 | Likely touches validation, schemas, fixtures, target-height kernel, local-fairing kernel, evidence, docs, and tests. |
| Hidden Complexity Suspicion | 2 | Circle weighting is simple, but mode-specific region and preserve-zone compatibility needs care. |
| Validation Burden Suspicion | 3 | Requires contract parity plus terrain-kernel and hosted edit checks across target-height and local-fairing modes. |
| Dependency / Coordination Suspicion | 2 | Depends on completed MTA-06 local fairing shape, but does not require representation or storage work. |
| Scope Volatility Suspicion | 2 | Scope is stable if corridor and polygon support stay explicitly out of bounds. |
| Confidence | 3 | The requested shape and analogs are clear, with remaining risk around MTA-06 integration details. |

### Early Signals
- User explicitly confirmed circle support should cover both target-height and local-fairing edit regions and preserve zones.
- MTA-04 proved the public terrain edit surface but also showed contract/docs/fixtures and hosted checks must move together.
- MTA-06 is actively planned as rectangle-only local fairing, making it the hard sequencing dependency for a coherent circular-region task.

### Early Estimate Notes
- Seed uses MTA-04 as an outside-view analog for public edit contract validation burden, adjusted downward because this task does not introduce the terrain edit command, repository flow, or output regeneration foundation.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Predicted (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds circular edit regions and preserve zones to existing target-height and local-fairing flows. No new public tool, storage representation, corridor behavior, polygon support, or output strategy is added. |
| Technical Change Surface | 3 | Touches request validation, loader schema, native fixtures, README examples, shared terrain region math, target-height kernel, local-fairing kernel, contract stability, and hosted validation notes. Command dispatch and output regeneration should remain mostly unchanged. |
| Implementation Friction Risk | 2 | Circle math is straightforward, but extracting shared rectangle/circle influence without regressing existing rectangle behavior requires care. Preserve-zone half-spacing expansion and string/symbol coordinate normalization are the main implementation traps. |
| Validation Burden Risk | 3 | Contract parity plus kernel tests across two modes and two preserve-zone shapes is substantial. MTA-05 shows live numeric boundary behavior can require at least one focused fix/retest loop even when local math tests pass. |
| Dependency / Coordination Risk | 1 | MTA-06 is now landed in the working baseline and MTA-10 output behavior already exists. Remaining coordination is routine hosted SketchUp validation access, not a blocking upstream task. |
| Discovery / Ambiguity Risk | 2 | Public shape, formulas, and mode compatibility are settled. Residual ambiguity is mostly numeric: exact radius boundaries, outer blend boundaries, non-zero origin, fractional spacing, and preserve-zone sample footprint semantics. |
| Scope Volatility Risk | 1 | Scope is tightly bounded after refinement: no corridor circle regions, no corridor circle preserve zones, no polygon/freeform regions, no response-shape expansion, and no terrain representation changes. |
| Rework Risk | 2 | Likely rework is contained to helper parity, schema requiredness, or hosted numeric boundary fixes. Broad architecture rework is unlikely because existing command, state, and output seams remain intact. |
| Confidence | 3 | Confidence is strong enough for implementation planning because the public shape was challenged, formulas are explicit, and calibrated analogs exist. Confidence is not `4` because hosted circle-boundary behavior has not yet been proven. |

### Top Assumptions

- MTA-06 `local_fairing` remains available as a mode on `edit_terrain_surface` with rectangle baseline behavior and existing fairing evidence.
- Circle support can be implemented as request validation plus SketchUp-free terrain-domain math over current `HeightmapState`.
- The existing output path can consume circle edit `changedRegion` diagnostics without new public response fields.
- Runtime schema remains provider-compatible by exposing optional `bounds`, `center`, and `radius` fields while runtime validation enforces type-specific requiredness.
- Hosted validation can be completed with the existing MCP-wrapper/manual smoke pattern.

### Estimate Breakers

- Circle preserve-zone sample-footprint behavior requires broader geometry semantics than half-spacing expansion.
- Local fairing circle support reveals that the square neighborhood kernel must change shape, contradicting the MTA-06 baseline decision.
- Native schema/provider constraints reject the optional mixed field shape and force a larger schema redesign.
- Hosted validation finds output/undo or fractional-spacing boundary defects that require changes outside the helper and validator.
- Product scope expands to corridor circles, polygon/freeform regions, blended preserve zones, or public response-shape changes.

### Predicted Signals

- Calibrated MTA-04 actuals show public terrain edits carry high validation burden when output, undo, and evidence must be proven in SketchUp.
- Calibrated MTA-05 actuals show terrain edit-mode extensions can implement cleanly but still need live numeric edge validation.
- MTA-10 actuals show output-layer changes are expensive, but MTA-12 intentionally avoids output strategy changes and uses existing dirty-window handoff.
- Grok-4.20 contract challenge found no blockers and recommended refinements already incorporated into the draft plan.
- The main new abstraction, `RegionInfluence`, is small and testable without SketchUp.

### Predicted Estimate Notes

- This estimate is based on the Step 09 draft technical plan and the refined Step 05 decisions, including explicit circle formulas and mode-specific preserve-zone compatibility.
- MTA-04 and MTA-05 are the primary calibrated analogs. MTA-10 informs host/output risk but is not a direct size analog because MTA-12 should not change output mutation behavior.
- MTA-06 is used as current implementation context, not a calibrated estimate analog, because its size ledger is not yet actual/calibrated.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Public contract drift is the dominant coordination risk: validator constants, native loader schema, native fixtures, README examples, and contract tests must move together.
- The implementation should stay moderate-friction if `RegionInfluence` remains small, SketchUp-free, and covered by rectangle parity tests before kernel migration.
- Validation burden is higher than ordinary unit work because two edit modes and two preserve-zone shapes need contract, kernel, and hosted evidence.
- MTA-04 and MTA-05 remain the strongest calibrated analogs; MTA-10 informs output/host risk but is not a direct implementation-size analog.
- Premortem confirms the task does not need splitting if corridor circle behavior, polygon/freeform regions, response-shape expansion, and terrain-state changes remain out of scope.

### Contested Drivers
- Validation burden could land at `2` if all hosted checks pass cleanly, because hosted matrices are routine in this repository. It remains predicted `3` because MTA-05 showed exact-boundary terrain behavior can require a focused live fix/retest loop.
- Implementation friction could rise above `2` if circle preserve-zone footprint semantics are implemented inconsistently across target-height and local-fairing. The finalized plan mitigates this by making the half-diagonal footprint expansion formula explicit.
- Dependency risk is low only if the landed MTA-06 fairing baseline remains stable. Any late MTA-06 shape change would require rechecking the MTA-12 plan and estimate.
- Schema/provider compatibility is expected to hold with optional mixed fields and runtime requiredness, but it still needs loader/schema tests because stale preserve-zone `required: ["type", "bounds"]` would break valid circle requests.

### Missing Evidence
- No hosted public MCP circle edit has been run yet on non-zero-origin or fractional-spacing terrain.
- No implementation evidence yet proves rectangle behavior remains byte-for-byte or tolerance-equivalent after helper extraction.
- No provider/client evidence yet proves the updated preserve-zone schema is accepted with `type` as the only required field and optional `bounds`, `center`, and `radius`.
- MTA-06 does not yet have calibrated actual-size evidence, so it is useful implementation context but not a completed analog.

### Recommendation
- Confirm the predicted profile without score changes.
- Proceed to implementation using the finalized plan.
- Treat rectangle parity tests, schema requiredness tests, and hosted circle-boundary checks as acceptance gates rather than optional hardening.
- Reopen the estimate only if scope expands to corridor circles, polygon/freeform regions, blended preserve zones, response-shape changes, or terrain-state changes.

### Challenge Notes
- Grok-4.20 challenged the public shape and found no blockers. It recommended schema requiredness changes, mode-specific preserve-zone compatibility, helper-based shared math, and no response-shape expansion; these were incorporated into the finalized plan.
- The premortem found no unresolved Tigers. It produced one material plan correction: explicit circular preserve-zone footprint expansion using `sqrt((spacing.x / 2.0)^2 + (spacing.y / 2.0)^2)`.
- No predicted scores were changed because the challenge evidence clarified mitigations and validation gates rather than revealing a materially larger or smaller task.
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

| Dimension | Actual (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Delivered the planned circular local-area edit vocabulary for target-height and local-fairing modes, plus circular preserve zones. No new public tool, corridor circle support, storage representation, or response section was added. |
| Technical Change Surface | 3 | Touched request validation, terrain kernel math, a new shared helper, loader schema, native fixtures, README examples, and task metadata. Dispatch, repository, output planning, mesh generation, and state serialization remained unchanged. |
| Actual Implementation Friction | 2 | Implementation followed the planned helper extraction. Friction was contained to settling rectangle outer-boundary parity, validation test expectations, and code-review test hardening. |
| Actual Validation Burden | 2 | Automated contract/kernel/lint/package validation passed, and the public MCP hosted matrix plus edge-boundary suite passed cleanly without a fix loop. Case count was broad, but execution was routine. |
| Actual Dependency Drag | 1 | Required deployed SketchUp/MCP client validation supplied by the user, but no upstream task or runtime dependency blocked completion. |
| Actual Discovery Encountered | 1 | No material surprises. The expected boundary, preserve-zone, schema requiredness, and refusal risks were covered by tests and live checks. |
| Actual Scope Volatility | 1 | Scope stayed stable: no corridor circles, polygon/freeform regions, blended preserve zones, response expansion, or state changes were added. |
| Actual Rework | 1 | Rework was limited to small test expectation corrections and final code-review hardening; no production redesign or live fix loop was needed. |
| Final Confidence in Completeness | 4 | Full local validation, package verification, code review, deployed public MCP smoke, undo, output sanity, refusal, preserve, and edge-boundary checks all passed. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Automated local validation:
  - `bundle exec rake ruby:test`: 756 runs, 3648 assertions, 0 failures, 0 errors, 36 skips.
  - `bundle exec rake ruby:lint`: 193 files inspected, no offenses detected.
  - `bundle exec rake package:verify`: built and verified `dist/su_mcp-0.23.0.rbz`.
  - Focused terrain suite: 173 runs, 1478 assertions, 0 failures, 0 errors, 3 skips.
  - Focused schema/contract suite: 118 runs, 705 assertions, 0 failures, 0 errors, 31 skips.
  - Native contract fixture JSON parsed successfully.
- Code review:
  - Final PAL/Grok-4.20 review completed.
  - Follow-up covered explicit circle-vs-rectangle positive blend default parity and documented rectangle outer-boundary zero-weight parity.
- Public MCP hosted matrix:
  - Created and edited non-zero-placement/fractional-spacing terrain fixtures.
  - Target-height circle edit passed with correct revision, digest, full-weight, blend, and outside-sample evidence.
  - Local-fairing circle edit passed with residual improvement `0.2483 -> 0.1170`.
  - Circular preserve zones passed for target-height and local-fairing, with protected samples unchanged and unprotected samples still editable.
  - Unsupported corridor circle region and corridor circular preserve-zone requests refused with finite mode-specific `allowedValues`.
  - Invalid circle shapes refused on exact field paths without revision/digest mutation.
  - Undo restored revision, digest, and samples after a circular target-height edit.
  - Output coherence checks found derived face/edge markers intact, no down or flat faces, and no public raw face/vertex ID leaks.
- Circular edge-boundary matrix:
  - Max corner, partial outside overlap, fully outside circle, sub-spacing on-sample, sub-spacing between samples, partly outside preserve, full-preserve coverage, and edge blend clipping all passed.
  - Refusal cases did not mutate revision or digest.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

- Prediction accuracy:
  - Functional scope, technical change surface, implementation friction, dependency drag, scope volatility, and rework were predicted accurately.
  - Validation burden landed lower than the conservative prediction: predicted `3`, actual `2`. The hosted matrix and edge-boundary suite were broad but clean and did not require fix/redeploy/retest loops.
  - Confidence increased from predicted `3` to actual `4` after public MCP hosted validation closed the main boundary and output risks.
- Underestimated:
  - No material implementation or validation driver was underestimated.
- Overestimated:
  - Hosted numeric boundary risk was overestimated. The planned half-diagonal preserve semantics, exact outer-boundary tests, and public MCP checks all passed without live fixes.
- Early-visible signals:
  - The `RegionInfluence` helper was the right abstraction boundary and kept implementation friction contained.
  - Schema requiredness and finite refusal alignment were correctly identified as contract-drift risks.
  - MTA-05's live boundary concerns were useful as validation guidance, but MTA-12 did not repeat the live fix-loop pattern.
- Dominant actual failure mode:
  - No production failure mode materialized. The only actual rework was test hardening and expectation alignment around circle defaulting and rectangle boundary parity.
- Retrieval lessons:
  - Future public terrain edit vocabulary extensions should retrieve by `scope:managed-terrain`, `systems:public-contract`, `systems:terrain-kernel`, `systems:loader-schema`, `contract:finite-options`, `validation:hosted-matrix`, and `risk:schema-requiredness`.
  - Routine hosted terrain matrices should not automatically imply high actual validation burden when they run cleanly without live fix loops.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:public-contract`
- `systems:terrain-kernel`
- `systems:native-contract-fixtures`
- `systems:docs`
- `validation:contract`
- `validation:public-client-smoke`
- `validation:hosted-matrix`
- `validation:undo`
- `host:routine-matrix`
- `host:undo`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:docs-examples`
- `risk:contract-drift`
- `risk:schema-requiredness`
- `volatility:low`
- `friction:medium`
- `rework:low`
- `confidence:high`
<!-- SIZE:TAGS:END -->
