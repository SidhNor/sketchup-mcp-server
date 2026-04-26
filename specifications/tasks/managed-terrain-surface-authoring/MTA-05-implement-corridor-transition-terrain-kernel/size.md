# Size: MTA-05 Implement Corridor Transition Terrain Kernel

**Task ID**: `MTA-05`  
**Title**: Implement Corridor Transition Terrain Kernel  
**Status**: `calibrated`  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-26  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: [summary.md](./summary.md)  

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: feature
- **Primary Scope Area**: terrain transition kernel for corridor-style grade changes
- **Likely Systems Touched**:
  - public `edit_terrain_surface` contract extension
  - request validation and native loader schema
  - corridor transition kernel contracts
  - `SampleWindow`-based sample windows and changed-region evidence
  - heightmap edit math
  - compact transition evidence
  - terrain edit command dispatch and regeneration flow
  - numerical test fixtures
  - README and native contract fixtures
- **Validation Class**: regression-heavy
- **Likely Analog Class**: public terrain edit mode extension

### Identity Notes
- Makes corridor/ramp-like transition behavior concrete through the existing public `edit_terrain_surface` tool, not through a new public tool.
- Consumes MTA-07 `SampleWindow` as the shared sample-window and changed-region primitive while adding corridor-specific frame and weighting math.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new supported public edit mode for corridor transitions through `edit_terrain_surface`. |
| Technical Change Surface | 4 | Touches public schema, request validation, kernel math, evidence, command dispatch, docs, fixtures, and hosted verification. |
| Hidden Complexity Suspicion | 4 | Corridor frame math, cosine side blend, conservative sample-window clipping, fixed controls, preserve zones, and edge behavior are risk-heavy. |
| Validation Burden Suspicion | 4 | Requires deterministic numerical tests, contract tests, compact evidence checks, and hosted terrain-output verification. |
| Dependency / Coordination Suspicion | 3 | Depends on MTA-04 edit flow and MTA-07 `SampleWindow`, but does not require a persisted schema migration. |
| Scope Volatility Suspicion | 2 | Step 05 resolved the public shape and kernel primitive split; remaining volatility is mainly implementation tolerance and performance guardrails. |
| Confidence | 3 | Public contract, UE implementation input, and `SampleWindow` integration direction are now settled enough for predicted planning. |

### Early Signals
- Local UE source reread supports a two-control corridor frame with center full weight and cosine side blend.
- Public surface extends existing `edit_terrain_surface` with `operation.mode: "corridor_transition"` and `region.type: "corridor"` rather than adding a new tool.
- `region.width` is the full-weight corridor width in meters; `region.sideBlend.distance` is an additional meter-based shoulder on each side.
- `SampleWindow` should own candidate grid clipping and `changedRegion` summaries; `CorridorFrame` should own oriented corridor math and per-sample weights.
- Persisted `heightmap_grid` remains v1 unless a separate migration task is created.

### Early Estimate Notes
- Seed was refreshed during Step 05 after the task shifted from an underspecified internal-kernel shape to a public edit-mode extension with MTA-07 `SampleWindow` reuse.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds a new public terrain edit mode for representative corridor/ramp-like workflows, but keeps it within one existing tool. |
| Technical Change Surface | 4 | Touches public schema, request validation, kernel math, evidence, command dispatch, docs, fixtures, and hosted verification. |
| Implementation Friction Risk | 3 | Corridor geometry, cosine side blending, fixed/preserve constraints, and command/evidence integration create meaningful implementation resistance. |
| Validation Burden Risk | 4 | Requires numerical unit coverage, public contract tests, command integration tests, docs/examples parity, and hosted terrain-output checks. |
| Dependency / Coordination Risk | 2 | MTA-04 and MTA-07 foundations exist; remaining dependency risk is mainly hosted verification availability and preserving public contract coordination. |
| Discovery / Ambiguity Risk | 2 | Public shape and UE-derived math are settled, but edge tolerances, bounds expansion, and near-cap behavior may still reveal implementation details. |
| Scope Volatility Risk | 2 | Step 05 reduced volatility; remaining split pressure would come from validation/performance surprises or preserve/fixed-control interactions. |
| Rework Risk | 3 | MTA-04 analog showed live output behavior and contract integration can force revisits; corridor math adds additional edge-case rework risk. |
| Confidence | 3 | Estimate is supported by task planning, calibrated analogs, local UE source, MTA-07 implementation, Grok review, and premortem corrections; hosted output evidence is still pending. |

### Top Assumptions
- `SampleWindow` remains sufficient for candidate window clipping and changed-region summaries when composed with `CorridorFrame`.
- Public meter-based `width` and `sideBlend.distance` semantics remain stable through implementation.
- Full derived-output regeneration remains acceptable for MTA-05 performance and output correctness.
- Fixed controls can be handled by deterministic post-check/refusal without constraint solving.
- Hosted verification can cover at least one representative corridor transition and refusal-before-mutation path.

### Estimate Breakers
- Corridor edits require persisted schema changes or localized terrain-state storage beyond `heightmap_grid` v1.
- `SampleWindow` lacks a needed capability that forces broader grid/window abstraction work during MTA-05.
- Hosted SketchUp output reveals regeneration, normals, cleanup, or undo/abort failures comparable to or worse than MTA-04.
- Preserve-zone or fixed-control handling requires solving/interpolating around constraints rather than masking and refusal.
- Near-cap corridor performance is unacceptable with window-limited kernel work plus full regeneration.

### Predicted Signals
- Closest analog MTA-04 had actual technical surface 4 and validation burden 4 due to public contract, command, evidence, regeneration, docs, fixtures, and hosted output.
- MTA-04 actual implementation friction 3 and rework 3 came primarily from live SketchUp output and integration behavior, which MTA-05 also touches.
- MTA-07 reduces representation uncertainty by providing `SampleWindow`, but MTA-05 still owns oriented corridor geometry and weights.
- Local UE source provides strong implementation shape for two controls, center strip, side cosine blend, and conservative dirty bounds.
- Public contract changes require synchronized loader schema, request validation, dispatcher, tests, fixtures, README, and examples.

### Predicted Estimate Notes
- This prediction reflects the Step 05 rebaseline: MTA-05 is now a public `edit_terrain_surface` mode extension, not only an internal kernel task.
- Validation is expected to dominate closeout more than pure implementation because correctness spans numerical terrain math, public contract behavior, command atomicity, and hosted SketchUp output.
- Confidence is strong enough for premortem, but not very strong until hosted-output and edge-case assumptions are falsified.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Technical Change Surface remains `4`: the public tool contract, loader schema, request validation, command dispatch, kernel math, evidence, docs, fixtures, and hosted verification all move together.
- Validation Burden Risk remains `4`: MTA-04 actuals and this plan both require unit, command, native contract, docs/example parity, and hosted SketchUp checks.
- Implementation Friction Risk remains `3`: `SampleWindow` and UE research reduce discovery, but `CorridorFrame`, side-blend math, fixed controls, preserve zones, and command/evidence integration still carry real friction.
- Rework Risk remains `3`: the premortem found and corrected a real public schema issue, confirming that contract integration can force revisits if not tested directly.

### Contested Drivers
- Dependency / Coordination Risk could be argued as `3` because hosted verification is necessary, but MTA-04 and MTA-07 are already available and no schema migration or external service is planned; keep `2`.
- Discovery / Ambiguity Risk could be argued as `1` after UE reread and Grok review, but edge tolerances, bounds expansion, and near-cap behavior remain implementation-time unknowns; keep `2`.
- Scope Volatility Risk could rise if preserve-zone or fixed-control behavior demands constraint solving, but the finalized plan explicitly defers solving and uses hard masks/refusals; keep `2`.

### Missing Evidence
- Hosted SketchUp verification has not yet proven regenerated corridor output, undo/abort coherence, adopted-coordinate handling, or diagonal face/normals behavior.
- Near-cap performance has not yet been measured with window-limited kernel work plus full regeneration.
- Exact implementation tolerance choices for conservative bounds expansion and endpoint-match evidence remain to be proven by tests.

### Recommendation
- Confirm the predicted profile without score changes.
- Proceed to implementation with the finalized plan.
- Treat hosted verification, schema/docs parity, and bounds-expansion tests as non-negotiable acceptance gates.

### Challenge Notes
- Premortem surfaced one Tiger: existing schema required `operation.targetElevation`, which would have blocked corridor requests. The plan now requires schema-level `operation.mode` only and runtime mode-specific required-field validation.
- Grok-4.20 reviews supported the `SampleWindow` plus `CorridorFrame` split and confirmed no material phase reordering was needed.
- The challenge evidence narrows ambiguity but does not lower validation burden because correctness still spans public contract behavior and real SketchUp output.
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

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Added one new public terrain edit mode inside `edit_terrain_surface`, with visible corridor controls, side blend, fixed-control behavior, preserve-zone behavior, and transition evidence. |
| Technical Change Surface | 4 | Touched public schema, native runtime loader, request validation, command dispatch, two terrain kernels through shared fixed-control extraction, evidence shaping, README docs, contract fixtures, and live SketchUp verification. |
| Actual Implementation Friction | 2 | Core implementation followed the planned `CorridorFrame` + `SampleWindow` + `CorridorTransitionEdit` split. Friction came from fixed-control extraction, finite contract alignment, and a small live-discovered endpoint tolerance fix, not from redesign. |
| Actual Validation Burden | 4 | Validation dominated closeout: focused numerical tests, command/schema/fixture coverage, full CI/package, final Grok-4.20 review, and public MCP live SketchUp testing were all needed to prove correctness. |
| Actual Dependency Drag | 2 | MTA-04 and MTA-07 foundations were available, but live SketchUp MCP verification and user-provided retest evidence were required to finish the host-sensitive surface. |
| Actual Discovery Encountered | 2 | The planned shape held, but live testing exposed one exact-endpoint floating-point boundary issue and clarified that production bulk-output adoption belongs to MTA-08 rather than MTA-05. |
| Actual Scope Volatility | 1 | Scope stayed inside the planned corridor-transition mode. No persisted schema migration, new public tool, localized terrain representation, or production bulk-output adoption was added. |
| Actual Rework | 2 | Rework was contained: Grok review follow-ups, shared fixed-control extraction, strengthened tests, and a post-live endpoint tolerance fix. No broad rewrite or architecture change was required. |
| Final Confidence in Completeness | 4 | Confidence is very strong after full CI, final review follow-up, live MCP retest of the prior endpoint bug, normals checks, undo guard, and unmanaged-content preservation. |

### Actual Notes
- The prediction correctly identified public contract synchronization and hosted verification as the dominant cost drivers.
- Implementation friction was lower than predicted because the `SampleWindow` and existing edit-command substrate composed cleanly with the new corridor kernel.
- The dominant actual failure mode was not algorithm shape; it was host/live numeric boundary behavior on adopted terrain with non-zero origin and fractional spacing.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

### Automated Validation
- `bundle exec rake ci`
  - RuboCop: 175 files, no offenses
  - Ruby tests: 654 runs, 3013 assertions, 0 failures, 0 errors, 32 skips
  - Package verification: `dist/su_mcp-0.22.0.rbz`
- Focused post-live regression:
  - corridor transition/frame tests covered non-zero-origin fractional-spacing exact endpoint behavior
  - focused review-follow-up tests covered diagonal non-uniform bounds and native schema required-field exposure

### Review Validation
- Final Grok-4.20 Step 10 review after the live endpoint fix found no critical, high, or medium blockers.
- Review follow-ups addressed low-severity test/comment hardening:
  - explicit non-uniform diagonal corridor bounds coverage
  - stronger schema assertions that `operation.required` remains only `mode`
  - inline comment explaining the endpoint tolerance failure mode

### Live SketchUp MCP Validation
- Initial live pass covered baseline create, preserve zones, fixed-control conflict, invalid mode/region pairs, invalid corridor geometry, side-blend refusals, diagonal normals, unmanaged-content preservation, and near-cap performance.
- Initial live pass found the adopted-coordinate exact endpoint bug.
- Focused retest after the tolerance fix passed:
  - exact endpoint on adopted non-zero-origin terrain updated to `4.0`
  - stored state at column `80` / row `80` was `3.9999999999999996`
  - `endpointDeltas.end` was approximately `7.8e-13`
  - nearby interpolation samples, invalid geometry refusal, diagonal normals, unmanaged sentinel preservation, and one-step undo all passed.

### Validation Gaps
- Production output still uses the existing full SketchUp regeneration path. Bulk output adoption remains a separate MTA-08 task.
- Save/reopen persistence was not added as an MTA-05-specific live retest scenario.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### What Was Estimated Accurately
- **Functional Scope**: predicted `3`, actual `3`. The task added one meaningful public edit mode without expanding into a new public tool or broader sculpting workflow.
- **Technical Change Surface**: predicted `4`, actual `4`. The public contract, validation, command dispatch, kernel math, evidence, docs, fixtures, and hosted checks all moved together.
- **Validation Burden**: predicted `4`, actual `4`. Correctness required broad automated checks plus real SketchUp MCP verification and retesting after the live endpoint fix.
- **Dependency Drag**: predicted `2`, actual `2`. Existing MTA-04/MTA-07 foundations reduced implementation drag, but live-host validation remained a real coordination dependency.
- **Discovery**: predicted `2`, actual `2`. Edge tolerances and performance interpretation remained implementation-time findings, but no major unknown changed the approach.

### What Was Overestimated
- **Implementation Friction**: predicted `3`, actual `2`. The planned architecture held well; the main code friction was contained extraction and test hardening, not structural redesign.
- **Scope Volatility**: predicted `2`, actual `1`. The scope did not expand into production bulk output, persisted schema changes, localized state, or partial regeneration.
- **Rework**: predicted `3`, actual `2`. Review and live testing caused focused fixes, but the implementation did not require revisiting broad completed slices.

### What Was Underestimated
- No whole scored dimension was materially underestimated.
- A specific validation sub-risk was underweighted: exact endpoint inclusion on adopted terrain with non-zero origin and fractional spacing needed live public MCP evidence, not only local math tests.

### Early Signals That Mattered
- The premortem schema concern was real: `operation.targetElevation` had to move from schema-required to runtime mode-specific validation.
- The MTA-04 analog correctly predicted live SketchUp validation and undo/output behavior would be a closeout gate.
- The plan's edge-tolerance concern was justified; it manifested as the adopted-coordinate endpoint bug.

### Genuinely Unknowable Factors
- The exact floating-point endpoint drift on a fresh adopted terrain with non-zero origin and `0.1m` spacing was not fully knowable before live public-client testing.
- The observed cold/warm and near-cap timing split was measurable only in live SketchUp; it confirmed that corridor math was not the main performance cost.

### Future Analog Guidance
- Use this task as an analog for public terrain edit-mode extensions that combine:
  - finite MCP contract changes
  - SketchUp-free heightmap kernels
  - full derived-output regeneration
  - live numeric edge validation on adopted terrain coordinates
- Dominant actual failure mode: live host-coordinate numeric boundary behavior after otherwise-green local tests.
- Future estimates should keep validation burden high for terrain edit kernels even when implementation primitives are already available.
- Future estimates should avoid assuming bulk-output performance improvements are included unless the task explicitly owns production regeneration-path adoption.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:terrain-transition-kernel`
- `scope:public-edit-terrain-surface-mode`
- `contract:edit-terrain-surface`
- `validation:regression-heavy`
- `systems:kernel-heightmap-math-sample-window-command-loader-fixtures`
- `dependency:mta-04-bounded-grade-edit`
- `dependency:mta-07-sample-window`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
