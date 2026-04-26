# Size: MTA-04 Implement Bounded Grade Edit MVP

**Task ID**: `MTA-04`  
**Title**: Implement Bounded Grade Edit MVP  
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
- **Primary Scope Area**: bounded terrain grade edits and regeneration
- **Likely Systems Touched**:
  - public `edit_terrain_surface` contract
  - runtime loader, dispatcher, facade, and command factory
  - terrain edit command
  - heightmap mutation model
  - bounded edit kernel
  - derived output regeneration
  - validation and evidence reporting
  - README and native contract fixtures
- **Validation Class**: mixed
- **Likely Analog Class**: stateful geometry edit with regenerated output

### Identity Notes
- First managed terrain editing capability; edits state and regenerates output rather than modifying an existing TIN in place. Step 05 planning refined the shape into a public terrain-owned MCP tool, so the predicted profile treats contract/schema/docs parity as part of the core surface.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds visible grade-edit behavior for managed terrain. |
| Technical Change Surface | 3 | Likely touches command orchestration, terrain state, edit kernels, output regeneration, and evidence. |
| Hidden Complexity Suspicion | 4 | Boundaries, interpolation, units, and regeneration invariants can easily become messy. |
| Validation Burden Suspicion | 4 | Requires numerical assertions, geometry output checks, and hosted verification. |
| Dependency / Coordination Suspicion | 3 | Depends on adoption and storage foundations being stable enough to edit. |
| Scope Volatility Suspicion | 3 | MVP edit limits may need narrowing as kernel contracts become concrete. |
| Confidence | 2 | Desired behavior is clear, but exact kernel and proof strategy remain unplanned. |

### Early Signals
- `eval_ruby` geometry mutation is explicitly unsuitable for managed terrain edits.
- The public capability should remain coarse while flatten/smooth/ramp-like operations stay internal.
- SketchUp Undo can cover user-level reversal rather than a custom history flow.

### Early Estimate Notes
- Seed reflects a high-friction runtime feature centered on controlled state mutation and regeneration.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 3 | Adds the first public managed terrain edit workflow with target-height mutation, constraints, regeneration, and evidence, while deliberately excluding ramp/fairing/tiling. |
| Technical Change Surface | 4 | Touches public schema, dispatcher/facade/factory wiring, terrain request validation, pure edit kernel, repository load/save path, output regeneration, evidence, docs, and contract fixtures. |
| Implementation Friction Risk | 3 | Bounded sample math, bilinear fixed controls, conservative preserve masking, output cleanup, and SketchUp operation failure handling are likely to resist a straight-line implementation. |
| Validation Burden Risk | 4 | Requires domain math tests, contract/schema/refusal coverage, command failure injection, docs parity, hosted SketchUp undo/output/metadata checks, and timing evidence. |
| Dependency / Coordination Risk | 3 | Depends on MTA-03 terrain creation/adoption/output behavior, existing runtime contract infrastructure, and hosted SketchUp verification access. |
| Discovery / Ambiguity Risk | 2 | Major design decisions are resolved, but host behavior around output cleanup, undo coherence, and missing/stale derived output can still surface surprises. |
| Scope Volatility Risk | 3 | Rectangle-only target-height/full-regeneration scope is intentionally narrow, but consensus and premortem both exposed material split pressure around representative-case fit, performance, and future tiling. |
| Rework Risk | 3 | Fixed-control semantics, output cleanup safety, and public contract parity could force revisiting early slices if skeleton coverage is incomplete. |
| Confidence | 3 | Supported by detailed planning, MTA-03 retest evidence, UE research, and model consensus; confidence is not very high because hosted behavior still must prove the plan. |

### Top Assumptions
- MTA-03 create/adopt/state/output behavior remains available as reported in the live retest and current runtime shape.
- Full output regeneration can be reused or narrowly extended without introducing chunked output ownership in MTA-04.
- `HeightmapState` v1 regular-grid semantics are sufficient for the target-height MVP and no-data states can refuse.
- Hosted SketchUp verification is available for undo, metadata/name/tag preservation, output regeneration, and timing.

### Estimate Breakers
- Existing derived output cannot be safely identified/cleared without broader output metadata or a generated-child ownership model.
- Fixed-control bilinear protection proves incompatible with the requested preserve-mask/target-height behavior and requires a different constraint model.
- Runtime contract/schema infrastructure cannot expose the nested request shape without larger refactoring.
- Hosted near-cap regeneration is unacceptable even for the MVP, forcing partial/chunked regeneration into MTA-04.
- MTA-03 implementation changes materially from the retested contract before MTA-04 implementation starts.

### Predicted Signals
- New public mutating tool requires loader schema, dispatcher/factory/facade routing, native contract fixtures, README, and examples to move together.
- The command must coordinate repository state, SketchUp operation boundaries, output regeneration, metadata preservation, and refusal behavior.
- Prior terrain/storage analogs showed hosted SketchUp checks exposed issues local doubles missed.
- Consensus agreed on the core MVP but contested tolerance defaults, stale-output handling, and performance expectations, indicating validation/rework pressure.

### Predicted Estimate Notes
- Prediction is based on the finalized `plan.md` created on 2026-04-26 and planning evidence captured in `/tmp/mta-04-interim-planning-artifact.md`. The main outside-view adjustment is validation: prior SketchUp-hosted terrain work had moderate implementation friction but high validation burden, so this profile treats hosted and contract proof as the dominant closeout risk. Challenge review raised scope volatility from 2 to 3 because representative-case fit and full-regeneration performance may force follow-up split decisions even though MTA-04 itself remains narrow.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers
- Public `edit_terrain_surface` is a real contract expansion and must move loader schema, dispatcher/factory/facade wiring, contract fixtures, docs, and examples together.
- Domain-first implementation order is correct: request validation and pure kernel before evidence, command orchestration, runtime wiring, docs, and hosted smoke.
- Validation burden is the dominant risk because correctness depends on numerical kernel behavior, refusal details, SketchUp operation coherence, output regeneration, metadata preservation, and hosted timing.
- `evidence.warnings` should be stable and always present, and finite public options must be discoverable through schema and refusal details.
- `constraintRefs` should remain unchanged for MTA-04 because request controls are operation-scoped and durable constraint management would widen the task.

### Contested Drivers
- Fixed-control tolerance default was contested. `gpt-5.4` preferred a grid-relative default, `grok-4.20` preferred mandatory tolerance, and final planning chose optional `0.01` meters to keep the public contract usable while reporting effective tolerance in evidence.
- Missing/stale derived output behavior was contested. Final planning distinguishes required regenerated SketchUp model output from optional evidence payload: output regeneration must succeed, but an empty or derived-only owner can be regenerated from valid state; unexpected child/user content refuses.
- Performance was contested. `grok-4.20` argued full regeneration should block MVP finalization; final planning keeps full regeneration because the user explicitly accepted it for MTA-04, while requiring hosted timing and documentation of near-cap risk.
- Representative-case fit was contested in premortem. Final planning keeps rectangle-only target-height scope but adds an implementation guardrail: if the representative bounded case cannot be expressed, implementation must stop and split rather than widen silently.

### Missing Evidence
- Hosted edit/undo/output/metadata timing evidence for the final public tool path.
- Proof that output cleanup can identify safe derived faces/edges without deleting unexpected user content.
- Representative bounded target-height case evidence using the public request shape.
- Failure-injection evidence for repository save and output regeneration abort behavior.
- Contract parity evidence across loader schema, refusal payloads, native fixtures, README, and examples.

### Recommendation
- Proceed with the finalized MTA-04 plan, but treat validation as high-risk and scope volatility as high. Do not add polygon, incremental output, tiling, force mode, or durable constraint management in MTA-04. If the representative-case gate fails, split follow-up scope instead of changing the MVP during implementation.

### Challenge Notes
- Predicted `Scope Volatility Risk` was raised from 2 to 3 after consensus and premortem because the narrow MVP is stable by design but still faces material external pressure from representative-case fit and performance. Other predicted scores remain unchanged: the plan already scored technical surface and validation burden at high/very-high levels.
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
| Functional Scope | 3 | Delivered the planned first public bounded terrain edit MVP: target-height rectangle edits with blend, fixed controls, preserve zones, regeneration, undo coherence, and evidence. |
| Technical Change Surface | 4 | Touched public schema/routing, command factory/facade, request validation, pure heightmap kernel, repository save/load orchestration, mesh regeneration, evidence, native fixtures, README, task metadata, and tests. |
| Implementation Friction | 3 | Core plan held, but review and live testing exposed several meaningful fixes: sample-evidence default behavior, no-data refusal wording, real `Sketchup::Entities` traversal, and generated face winding. |
| Validation Burden | 4 | Required unit and integration tests, contract fixtures, lint/package checks, `grok-4.20` review, focused review after live fixes, and a broad public MCP/SketchUp retest matrix including undo, performance, evidence, and normals. |
| Dependency / Coordination Drag | 2 | Depended on MTA-02/MTA-03 terrain state and output foundations plus live SketchUp access, but no upstream ownership change blocked completion. |
| Discovery Encountered | 3 | Live checks discovered important host-specific behavior: adopted terrain state-coordinate semantics, unsupported `entities.groups` assumptions, output face winding, and the lack of a public no-data terrain fixture. |
| Scope Volatility | 2 | The rectangle target-height MVP stayed intact; volatility showed up as clarified coordinate semantics and a future polygonal preserve-zone follow-up rather than MTA-04 scope expansion. |
| Rework | 3 | Required post-review and live-driven rework across evidence behavior, output regeneration safety, mesh writer normals, tests, docs, and task metadata. |
| Final Confidence in Completeness | 3 | Final live suite passed for the public contract and performance/undo/output invariants; confidence is not `4` because no public live path exists for a real no-data terrain state. |
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

- Full Ruby suite: `bundle exec rake ruby:test` passed with 620 runs, 2376 assertions, 0 failures, 0 errors, 31 skips after final changes.
- Focused terrain mesh suite: `bundle exec ruby -Itest test/terrain/terrain_mesh_generator_test.rb` passed with 6 runs, 22 assertions, 0 failures.
- Lint: `bundle exec rake ruby:lint` passed with 164 files inspected and no offenses.
- Package verification: `bundle exec rake package:verify` generated `dist/su_mcp-0.20.0.rbz`.
- Diff hygiene: `git diff --check` passed.
- PAL codereview with `grok-4.20` completed for the full implementation; follow-up fixes were applied. A focused `grok-4.20` review of the face-winding fix also completed; its nil-safe normal guard recommendation was applied.
- Final public MCP/SketchUp retest passed F01-F13 and F15-F18: create/edit, adopted irregular terrain coordinates, smooth blend, preserve zones, fixed controls, finite refusals, unsafe child refusal, edge/single/whole edits, edit chains, undo, evidence modes, near-cap performance, output normals, and multi-rectangle preserve approximations.
- Performance evidence: final near-cap 100x100 create about 20.2s; edit/regenerate about 23.2s; output 10,000 vertices / 19,602 faces; MCP responsive after the run.
- Residual gap: F14 no-data live check is partial because the public API cannot create a valid real no-data terrain. A grey-box missing-state stub refused before mutation with `terrain_state_load_failed`; automated no-data domain coverage remains the proof for `terrain_no_data_unsupported`.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

### Prediction Accuracy

- Functional scope matched prediction: the public edit MVP shipped without adding ramp, polygon, fairing, smoothing, chunked regeneration, or durable generated face/vertex IDs.
- Technical surface matched the very-high prediction because the task moved contract, runtime, command, domain kernel, output, evidence, docs, fixtures, and tests together.
- Validation burden matched the very-high prediction; final confidence depended on live SketchUp/public MCP checks rather than local tests alone.
- Dependency drag came in slightly lower than predicted because MTA-02/MTA-03 foundations were usable, and coordination centered on live verification rather than upstream redesign.

### Underestimated

- Live SketchUp output behavior: production `Sketchup::Entities` did not expose fake-only collection helpers, and generated face winding varied across create/edit/regenerate paths.
- The need to prove evidence defaults and caps through public-client behavior, not only unit tests.
- The public fixture gap for no-data terrain states, which left no-data live verification partial even though automated domain coverage existed.

### Overestimated

- Representative-case scope pressure. Rectangle target-height editing with blend, fixed controls, and multiple rectangle preserve zones covered the final representative cases without expanding MTA-04 to polygon/ramp/fairing behavior.
- Performance as a blocker. Near-cap full regeneration is slow and documented, but final live timings remained acceptable for the MVP.

### Dominant Actual Failure Mode

Live-host terrain output invariants were the dominant rework driver: real SketchUp entity traversal, deletion safety, undo/output coherence, and face-normal behavior had to be proven against the host instead of trusted from local fakes.

### Underweighted Early Signals

- Prior MTA-03 live work had already shown hosted SketchUp behavior can invalidate fake assumptions; that should have put more early pressure on output-entity traversal and face-normal checks.
- Full regeneration was known as validation-heavy, but visual/normal correctness was not initially explicit in the hosted smoke checklist.

### Retrieval Facets For Future Estimates

- public MCP mutation tool
- terrain state mutation
- derived SketchUp mesh regeneration
- host entity traversal
- output face winding
- fixed-control and preserve-zone evidence
- undo coherence
- near-cap full regeneration timing
- hosted/live validation
- public fixture gap for unsupported state shapes
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:feature`
- `scope:managed-terrain`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `validation:hosted-matrix`
- `validation:performance`
- `host:repeated-fix-loop`
- `risk:host-api-mismatch`
- `risk:performance-scaling`
- `volatility:high`
- `friction:high`
- `rework:high`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
