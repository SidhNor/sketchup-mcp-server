# Size: MTA-05 Implement Corridor Transition Terrain Kernel

**Task ID**: `MTA-05`  
**Title**: Implement Corridor Transition Terrain Kernel  
**Status**: `challenged`  
**Created**: 2026-04-24  
**Last Updated**: 2026-04-26  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)  
**Related Summary**: none yet  

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
